require 'optparse'
require 'yaml'

module BepastyClient
  class Cli
    def self.run
      cli = new
      cli.run
    end

    def run
      parse
      load_config

      if @server.nil?
        warn 'Specify server URL using option --server or via config file'
        exit(false)
      end

      client = Client.new(@server, password: @password, verbose: @verbose)
      client.setup

      if @files.empty?
        puts client.upload_io(STDIN, **@upload_opts)
      else
        @files.each do |path|
          file_loc = File.open(path, 'r') do |f|
            client.upload_io(f, **@upload_opts)
          end

          if @files.length > 1
            puts "#{path}: #{file_loc}"
          else
            puts file_loc
          end
        end
      end

    rescue Error => e
      warn "Error occurred: #{e.message}"
      exit(false)
    end

    protected
    def parse
      @upload_opts = {}

      OptionParser.new do |parser|
        parser.banner = "Usage: #{$0} [options] FILE..."

        parser.on('-h', '--help', 'Show help message and exit') do |v|
          puts parser
          exit
        end

        parser.on('-v', '--verbose', 'Enable verbose output') do |v|
          @verbose = true
        end

        parser.on('-s', '--server=SERVER', 'bepasty server URL') do |v|
          @server = v
        end

        parser.on('-p', '--password=PASSWORD', 'bepasty server password') do |v|
          @password = v
        end

        parser.on('--password-file=FILE', 'Read bepasty server password from a file') do |v|
          @password = File.read(v).strip
        end

        parser.on('-f', '--filename=NAME', 'File name including extension') do |v|
          @upload_opts[:filename] = v
        end

        parser.on('-t', '--content-type=TYPE', 'Content mime type') do |v|
          @upload_opts[:content_type] = v
        end

        parser.on(
          '--minute=[N]',
          OptionParser::DecimalInteger,
          'Keep the file for N minutes, defaults to 30 minutes',
        ) do |v|
          @upload_opts[:max_life] = {unit: :minutes, value: v || 30}
        end

        parser.on(
          '--hour=[N]',
          OptionParser::DecimalInteger,
          'Keep the file for N hours, defaults to 1 hour',
        ) do |v|
          @upload_opts[:max_life] = {unit: :hours, value: v || 1}
        end

        parser.on(
          '--day=[N]',
          OptionParser::DecimalInteger,
          'Keep the file for N days, defaults to 1 day',
        ) do |v|
          @upload_opts[:max_life] = {unit: :days, value: v || 1}
        end

        parser.on(
          '--week=[N]',
          OptionParser::DecimalInteger,
          'Keep the file for N weeks, defaults to 1 week',
        ) do |v|
          @upload_opts[:max_life] = {unit: :weeks, value: v || 1}
        end

        parser.on(
          '--month=[N]',
          OptionParser::DecimalInteger,
          'Keep the file for N months, defaults to 1 month',
        ) do |v|
          @upload_opts[:max_life] = {unit: :months, value: v || 1}
        end

        parser.on(
          '--forever',
          'Keep the file as long as possible',
        ) do |v|
          @upload_opts[:max_life] = {unit: :forever, value: 1}
        end
      end.parse!

      @files = ARGV.empty? ? [] : ARGV
    end

    def load_config
      cfg = load_config_file('/etc/bepastyrb.yml')

      conf_dir = ENV.fetch('XDG_CONFIG_HOME', '')
      conf_dir = File.join(Dir.home, '.config') if conf_dir.empty?

      cfg.update(load_config_file(File.join(conf_dir, 'bepastyrb.yml')))

      @verbose = true if cfg[:verbose]
      @server ||= cfg[:server]
      @password ||= cfg[:password]
      @upload_opts[:max_life] ||= cfg[:max_life]
    end

    def load_config_file(path)
      begin
        cfg = YAML.load_file(path)
      rescue Errno::ENOENT
        return {}
      end

      puts "Reading config at #{path}" if @verbose

      {
        verbose: cfg.fetch('verbose', false),
        server: cfg['server'],
        password: cfg['password_file'] ? File.read(cfg['password_file']).strip : cfg['password'],
        max_life: {
          unit: cfg.fetch('max_life', {}).fetch('unit', 'days').to_sym,
          value: cfg.fetch('max_life', {}).fetch('value', 1),
        },
      }
    end
  end
end
