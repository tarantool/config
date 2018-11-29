# Tarantool app configurator

This module allows you to configure your Tarantool apps from
configuration files, command line arguments and environment variables.

It gives you the ability to mix and match different ways of
configuration, so your app can work unmodified during local
development, as a systemd service, or as part of Docker image.

## Example usage

Create a file called `app.lua` with the following content:

```lua
#!/usr/bin/env tarantool

local config = require('config')
local yaml = require('yaml')

local cfg = config.parse({app_name="myapp", instance_name=nil})


print(cfg.some_option)
print(cfg.some_other_option)
```


Then you can pass `some_option` like this:

```sh
tarantool app.lua --some_option foobar
```

or via environment variable:

```sh
TARANTOOL_SOME_OPTION=foobar tarantool app.lua
```

or by placing the following configuration file to `$HOME/.config/tarantool/tarantool.ini`:

```ini
[default]

some_option = foobar

```

Alternatively, you can use yml format as well `$HOME/.config/tarantool/tarantool.yml`:

```ini
---

default:
  some_option: foobar

```

## How it works

The `config` module tries to read configuration options from multiple
sources and then merge them together according to the priority of the
source. Configuration files have lowest priority, then command line
options, then environment variables.

Configuration files have an `ini` or `yaml` format and have multiple
sections that allow to specify settings for all tarantool apps,
specific tarantool app or a specific instance of tarantool app.

`default` section of configuration file has global configuration,
then if there is a section called `myapp`, values from there will
override values from `default`, and then `myapp.instance_name`
with highest priority.


So the complete order looks like this:
- check `TARANTOOL_<VARNAME>` environment variable
- check `--<varname>` command line option
- check `<varname>=` in `[myapp.instance_name]` section of config file
- check `<varname>=` in `[myapp]` section of config file
- check `<varname>=` in `[default]` section of config file


All configuration values are treated as regular strings. It's your job
to convert them to other types.
