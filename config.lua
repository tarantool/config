#!/usr/bin/env tarantool

local fio = require('fio')
local errno = require('errno')

local base_dir = fio.abspath(fio.dirname(arg[0]))

local function read_file(path)
    local file = fio.open(path)
    if file == nil then
        return nil, string.format('Failed to open file %s: %s', path, errno.strerror())
    end
    local buf = {}
    while true do
        local val = file:read(1024)
        if val == nil then
            return nil, string.format('Failed to read from file %s: %s', path, errno.strerror())
        elseif val == '' then
            break
        end
        table.insert(buf, val)
    end
    file:close()
    return table.concat(buf, '')
end


local function parse_string(str, app_name, instance_name)
    local sections = {'default'}

    if app_name ~= nil then
        table.insert(sections, app_name)

        if instance_name ~= nil then
            table.insert(sections, app_name .. '.' .. instance_name)
        end
    end

    local parsed = {}
    local current_section = nil

    for _, line in ipairs(string.split(str, '\n')) do
        line = line:strip()
        local section = line:match('^%[([^%[%]]+)%]$')
        if section ~= nil then
            current_section = string.strip(section)
            parsed[current_section] = parsed[current_section] or {}
        elseif current_section ~= nil then
            local argname, argvalue = line:match('^([%w|_]+)%s-=%s-(.+)$');

            if argname ~= nil then
                argname = string.lower(argname):gsub('-', '_')

                parsed[current_section][argname] = argvalue:strip()
            end
        end
    end

    local res = {}

    for _, section in ipairs(sections) do
        for argname, argvalue in pairs(parsed[section] or {}) do
            res[argname] = argvalue
        end
    end

    return res
end

local function parse_file(app_name, instance_name)
    local home = os.getenv('HOME')
    local candidates = {
        'tarantool.cfg',
        '.tarantool.cfg',
        fio.pathjoin('/etc/tarantool/tarantool.cfg'),
        fio.pathjoin(home, '/.config/tarantool/tarantool.cfg')
    }

    for _, candidate in ipairs(candidates) do
        if fio.path.exists(candidate) then
            local data, err = read_file(candidate)

            if data == nil then
                return nil, err
            end
            return parse_string(data, app_name, instance_name)
        end
    end

    return {}
end

local function parse_env()
    local res = {}
    for argname, argvalue in pairs(os.environ()) do
        argname = string.lower(argname)

        if string.startswith(argname, 'tarantool_') then
            argname = argname:gsub("^tarantool_", ''):gsub("-", "_")
            res[argname] = argvalue
        end
    end

    return res
end

local function parse_args()
    local res = {}

    for i=1,#arg do
        if (string.startswith(arg[i], '--')
                and arg[i+1] ~= nil
                and not string.startswith(arg[i+1], '--')) then

            local argname = string.lower(arg[i]:gsub("^%-%-", ''):gsub("-", "_"))
            local argvalue = arg[i+1]
            res[argname] = argvalue
        end
    end

    return res
end

local function merge(configs)
    local res = {}

    for _, config in ipairs(configs) do
        for argname, argvalue in pairs(config) do
            res[argname] = argvalue
        end
    end
    return res
end

local function find_rockspec(source_dir)
    for _, file in ipairs(fio.listdir(source_dir) or {}) do
        if string.endswith(file, '.rockspec') then
            return file
        end
    end
end

local function parse(options)
    local rockspec = find_rockspec(base_dir)
    options = options or {}

    if rockspec ~= nil then
        options.app_name = options.app_name or string.match(rockspec, '^(%g+)%-scm%-1%.rockspec$')
    end

    local configs = {
        parse_file(options.app_name, options.instance_name),
        parse_args(),
        parse_env()
    }

    return merge(configs)
end


return {parse=parse}
