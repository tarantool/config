package = "config"
version = "scm-1"
source = {
    url    = 'git+https://github.com/tarantool/config.git',
    branch = "master",
}

description = {
    summary = "Tarantool app configurator",
    detailed = [[
        This module allows you to configure your Tarantool apps from
        configuration files, command line arguments and environment variables.

        It gives you the ability to mix and match different ways of
        configuration, so your app can work unmodified during local
        development, as a systemd service, or as part of Docker image.
    ]],
    homepage = "https://github.com/tarantool/config",
    license = "BSD",
}

dependencies = {
    "lua >= 5.1"
}

build = {
    type = 'builtin',
    modules = {
        ['config'] = 'config.lua',
    }
}
