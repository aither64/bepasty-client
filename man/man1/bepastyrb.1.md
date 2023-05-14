# bepastyrb 8                       2023-05-13                             1.0.0

## NAME
`bepastyrb` - upload files to bepasty servers

## SYNOPSIS
`bepastyrb` [*options*] [*file*...]

## DESCRIPTION
`bepastyrb` uploads one or more files to bepasty servers. If no *file* is given
as an argument, `bepastyrb` will read from standard input.

bepasty server URL needs to be given using option `-s`, `--server` or can be
set in a config file, see `CONFIG FILES`.

If no life time is set, it defaults to one day.

## OPTIONS
`-v`, `--verbose`
  Enable verbose output.

`-s`, `--server`=*SERVER*
  bepasty server URL.

`-p`, `--password`=*PASSWORD*
  bepasty server password.

`--password-file`=*FILE*
  Read bepasty server password from a file.

`-f`, `--filename`=*NAME*
  File name including extension. Can be used to provide name for files read
  from standard input or to override given file name.

`-t`, `--content-type`=*TYPE*
  Content mime type. If not given, the mime type is guessed by the bepasty server
  based on file name.

`--minute`=[*N*]
  Keep the file for *N* minutes, defaults to 15 minutes.

`--hour`=[*N*]
  Keep the file for *N* hours, defaults to 1 hour.

`--day`=[*N*]
  Keep the file for *N* days, defaults to 1 day.

`--week`=[*N*]
  Keep the file for *N* weeks, defaults to 1 week.

`--month`=[*N*]
  Keep the file for *N* months, defaults to 1 month.

`--forever`
  Keep the file as long as possible.

## CONFIG FILES
Config files can be used to provide default values for certain options.
Command-line options override settings found in config files. Config files are
read from the following locations:

  - `/etc/bepastyrb.yml`
  - `$XDG_CONFIG_HOME/bepastyrb.yml` or `~/.config/bepastyrb.yml`

Settings from user's config will override settings in `/etc`.

Example configuration:

```
# bepasty config file in YAML
server: https://bepasty.yourserver.tld
# password: optional password if the server uses it
# password_file: read password from a file
# max_life:
#   unit: days
#   value: 14
```

## SEE ALSO
bepasty server: https://bepasty-server.readthedocs.org/

## BUGS
Report bugs to https://github.com/aither64/ruby-bepasty-client.
