--[[
	          Copyright 2025 Kagehana. All rights reserved.

	Licensed under the Apache License, Version 2.0 (the 'License');
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

			  https://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an 'AS IS' BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
]]

-- shortcuts
local insert = table.insert
local concat = table.concat


-- project
local architect = {
	repository = '',
	ecosystem  = {},
	files      = {},
	exclusions = {},
	_logs      = {}
}





--[[
	{private function _log}

	Stores a log inside the architect's memory.

	@param str (string): The log.
]]
local function _log(str)
	local t     = os.date('*t')
	local stamp = ('%02d:%02d:%02d'):format(t.hour, t.min, t.sec)
	local log   = ('at %s:\n\n%s'):format(stamp, str)

	insert(architect._logs, (log:gsub('^[ \t]+', ''):gsub('\n[ \t]+', '\n')))
end




--[[
    {public function table.contains}

    Checks if a table contains a value.

    @param tbl (table): The table.
    @param val (any): The value.
]]
function table.contains(tbl, val)
    for k, v in pairs(tbl) do
        if v == val then
            return true
        end
    end

    return false
end




--[[
	{public function build}

	Establishes the architect and
	allows it to pre-load any given
	files.

	@param data (table): The configuration for the architect.
]]
function architect:build(data)
	self.repository = data.repository or {}
	self.ecosystem  = data.ecosystem  or {}
	self.files      = data.files      or {}
	self.exclusions = data.exclusions or {}

	for k, v in ipairs(data.files) do
        local path = (self.repository .. v)

        if not table.contains(self.exclusions, v) then
            self:get(v, true, false)
        else
            self:get(path)
        end

		_log('Got ' .. path)
	end
end




--[[
	{public function get}

	Either loads or establishes a chunk using a file, simulatenously
	integrating the architect's, and possibly your, ecosystem.

	@param path (string): The path, or identifier, for the file.
	@param integrate (bool): Whether or not to integrate, or rather, load, the chunk into the codespace. (default: true)
	@param exclude (bool): Whether or not to exclude the chunk from having your ecosystem integrated. (default: false)
]]
function architect:get(path, integrate, exclude)
	local chunk = loadstring(game:HttpGet('%s/%s.lua'):format(self.repository, path))
    local env   = setmetatable({}, {__index = getfenv(chunk)})

    if not exclude then
        setfenv(chunk, env)
    end

    if integrate then
        chunk()
    end

    insert(self.files, path)
end




--[[
    {private function _deepcopy}

    Deep-copies a table.

    @param tbl (table): The table to copy.
    @param seen (bool): Whether or not the value has been seen before.
]]
local function _deepcopy(obj, seen)
    if type(obj) ~= 'table' then
        return obj
    end

    seen = seen or {}

    if seen[obj] then
        return seen[obj]
    end

    local copy = {}

    seen[obj] = copy

    for k, v in pairs(obj) do
        copy[_deepcopy(k, seen)] = _deepcopy(v, seen)
    end

    local mt = getmetatable(obj)

    if mt and type(mt) ~= 'string' then
        setmetatable(copy, getmetatable(obj))
    end

	return copy
end




--[[
    {public method revert}

    Reverts all environments to their original
    states, and resets the architect's memory &
    configuration, essentially making it as though
    the architect was never established or used.
]]
local ogenv = _deepcopy(getgenv())
local ofenv = _deepcopy(getfenv(0))
local orenv = _deepcopy(getrenv())
local osenv = _deepcopy(getsenv())
local olenv = _deepcopy(_G)

function architect:revert()
    local gc = gcinfo()

    -- global
    for k, v in pairs(ogenv) do
        if not getgenv()[k] then
            getgenv()[k] = v
        end
    end

    for k, v in pairs(getgenv()) do
        if not ogenv[k] then
            getgenv()[k] = nil
        end
    end

    -- function
    for k, v in pairs(ofenv) do
        if not getfenv(0)[k] then
            getfenv(0)[k] = v
        end
    end

    for k, v in pairs(getfenv(0)) do
        if not ofenv[k] then
            getfenv(0)[k] = nil
        end
    end

    -- roblox
    for k, v in pairs(orenv) do
        if not getrenv()[k] then
            getrenv()[k] = v
        end
    end

    for k, v in pairs(getrenv()) do
        if not orenv[k] then
            getrenv()[k] = nil
        end
    end

    -- script
    for k, v in pairs(osenv) do
        if not getsenv()[k] then
            getsenv()[k] = v
        end
    end

    for k, v in pairs(getsenv()) do
        if not osenv[k] then
            getsenv()[k] = nil
        end
    end

    -- _G
    for k, v in pairs(olenv) do
        if not _G[k] then
            _G[k] = v
        end
    end

    for k, v in pairs(_G) do
        if not olenv[k] then
            _G[k] = nil
        end
    end

    _log('Reverted all environments to their original states.')

    self.repository = ''
    self.ecosystem  = {}
    self.files      = {}
    self.exclusions = {}
    self._logs      = {}

    _log('Reverted the architect\'s memory and configuration.')
    _log(('Freed up an estimated %dkb of memory'):format(gc - gcinfo()))
end




--[[
	Class system implementation. Meant for assistance with
	more structural programming, or rather, actual OOP.
]]

-- reformulated metadata for classes
local meta = {}

function meta:__call(...)
    return (setmetatable({}, self)):__init(...)
end

function meta:__tostring()
    return ('class: ' .. self.__name)
end




--[[
	{public method classify}

	Formulates a new class.

	@param name (string): The class' name/identifier.
	@param init (function): A pre-defined constructor for the class.
	@param ... (vararg): Any base/parent classes to inherit from.
]]
function architect:classify(name, ...)
    local new   = setmetatable({}, meta)
    local bases = {...}

    for _, base in ipairs(bases) do
        for k1, v1 in pairs(base) do
            if not k1:find('^__') then
                new[k1] = v1
            end
        end
    end

    new.__name  = name
    new.__bases = bases
    new.__index = new

    function new:__init(...)
        return self
    end

    return new
end
