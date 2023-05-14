require 'base64'
require 'json'
require 'net/http'
require 'stringio'

module BepastyClient
  class Error < StandardError ; end

  class Client
    BODY_SIZE = 128*1024

    # @param server [String] bepasty server URL
    # @param password [String, nil]
    # @param verbose [Boolean]
    def initialize(server, password: nil, verbose: false)
      @server = server
      @password = password
      @verbose = verbose
    end

    # Fetch server settings
    def setup
      http_start('/apis/rest') do |uri, http|
        res = http.get(uri)

        case res
        when Net::HTTPSuccess
          settings = JSON.parse(res.body)

          @max_file_size = settings['MAX_ALLOWED_FILE_SIZE']
          @max_body_size = settings.fetch('MAX_BODY_SIZE', BODY_SIZE)

          if @verbose
            puts "Max file size = #{@max_file_size}"
            puts "Max body size = #{@max_body_size}"
          end
        else
          raise Error, "Failed to query server settings: HTTP #{res.code}, #{res.message}"
        end
      end
    end

    # Upload file
    # @param io [IO]
    # @param filename [String, nil]
    # @param content_type [String, nil]
    # @param max_life [Hash, nil]
    # @raise [Error]
    # @return [String] file URL
    def upload_io(io, filename: nil, content_type: nil, max_life: nil)
      if filename.nil? && io.respond_to?(:path)
        filename = File.basename(io.path)
      end

      max_life ||= {unit: :days, value: 1}

      sent_bytes = 0
      transaction_id = nil
      file_location = nil

      if io.respond_to?(:size)
        send_io = io
      else
        send_io = StringIO.new(io.read)
        content_type ||= 'text/plain'
      end

      if @max_file_size && send_io.size > @max_file_size
        raise Error, "File size #{send_io.size} exceeds server max file size of #{@max_file_size} bytes"
      end

      http_start('/apis/rest/items') do |uri, http|
        until send_io.eof?
          chunk = send_io.read(@max_body_size)

          req = Net::HTTP::Post.new(uri)
          req.basic_auth('bepasty', @password) if @password
          req['Content-Range'] = "bytes #{sent_bytes}-#{sent_bytes + chunk.size - 1}/#{send_io.size}"
          req['Transaction-ID'] = transaction_id if transaction_id
          req['Content-Type'] = content_type || ''
          req['Content-Filename'] = filename || ''
          req['Content-Length'] = send_io.size
          req['Maxlife-Unit'] = max_life[:unit].to_s.upcase
          req['Maxlife-Value'] = max_life[:value]

          req.body = Base64.encode64(chunk)

          if @verbose
            puts "Uploading chunk, Content-Range=#{req['Content-Range']}, Transaction-ID=#{transaction_id}"
          end

          res = http.request(req)

          case res
          when Net::HTTPSuccess
            if transaction_id.nil? && res['Transaction-ID']
              transaction_id = res['Transaction-ID']
            end

            file_location = res['Content-Location'] if res['Content-Location']
          else
            if res['Content-Type'] == 'application/json'
              err = JSON.parse(res.body)['error']
              raise Error, "bepasty error: code=#{err['code']}, message=#{err['message']}"
            else
              raise Error, "HTTP #{res.code}: #{res.message}"
            end
          end

          sent_bytes += chunk.size
        end
      end

      if file_location.nil?
        raise Error, 'Server did not disclose file location'
      end

      # bepasty returns REST item URL, we want web URL instead
      File.join(@server, file_location.split('/').last)
    end

    protected
    def http_start(path)
      uri = URI(File.join(@server, path))
      args = [uri.hostname, uri.port] + Array.new(5, nil) + [{use_ssl: uri.scheme == 'https'}]

      Net::HTTP.start(*args) do |http|
        yield(uri, http)
      end
    end
  end
end
