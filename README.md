# ruby-bepasty-client
Ruby client and CLI for [bepasty-server](https://bepasty-server.readthedocs.org/).

## Installation
```
gem install ruby-bepasty-client
```

## Usage from command-line
Configure bepasty server address, so that we don't have to pass it on the command-line:

```bash
cat <<EOF > "${XDG_CONFIG_HOME:=.config}/bepastyrb.yml"
server: https://bepasty.yourserver.tld
EOF
```

Upload a file:

```
bepastyrb file.txt
```

Upload data from standard input:

```
uptime | bepastyrb
```

See [bepastyrb.1.md](./man/man1/bepastyrb.1.md) for more information.

## Usage from Ruby script

```ruby
require 'bepasty-client'

client = BepastyClient::Client.new('https://bepasty.yourserver.tld')

# Fetch server settings, e.g. max file size
client.setup

# Upload a file
File.open('file.txt') do |f|
  client.upload_io(f) # => https://bepasty.yourserver.tld/...
end

# Upload data from standard input
client.upload_io(STDIN) # => https://bepasty.yourserver.tld/...
```
