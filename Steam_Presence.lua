--[[
    <meta name="author" content="giperfast, minindm">
    shit code prod.
]]--

ffi.cdef[[
	typedef struct {
		void* pad;
		void* pad;
		void* steam_friends; 
    } steam_api_ctx_t;
]]

local ref = gui.Reference("Settings");
local tab = gui.Tab(ref, "presense.tab", "Steam Presence");
local groupbox = gui.Groupbox(tab, "Steam Presence", 16, 16, 287.5, 50);
local editbox = gui.Editbox(groupbox, "presense.editbox", "Presence text");
--editbox:SetValue('AIMWARE BEST HACK')

local helper_mt = {}
local interface_mt = {}
local iface_ptr = ffi.typeof('void***')
local char_ptr = ffi.typeof('char*')
local nullptr = ffi.new('void*')

local function iFaceCast(raw)
    return ffi.cast(iface_ptr, raw)
end

local function IsValidPtr(p)
    return p ~= nullptr and p or nil
end

local function GetAdressOf(raw)
    return ffi.cast('int*', raw)[0]
end

local function function_cast(thisptr, index, typedef, tdef)
    local vtblptr = thisptr[0]
    if IsValidPtr(vtblptr) then
        local fnptr = vtblptr[index]
        if IsValidPtr(fnptr) then
            local ret = ffi.cast(typedef, fnptr)
            if IsValidPtr(ret) then
                return ret
            end
            error('function_cast: couldn\'t cast function typedef: ' ..tdef)
        end
        error('function_cast: function pointer is invalid, index might be wrong typedef: ' .. tdef)
    end
    error("function_cast: virtual table pointer is invalid, thisptr might be invalid typedef: " .. tdef)
end

local seen = {}
local function CheckOrCreateTypedef(tdef)
    if seen[tdef] then
        return seen[tdef]
    end
    local success, typedef = pcall(ffi.typeof, tdef)
    if not success then
        error("error while creating typedef for " ..  tdef .. "\n\t\t\terror: " .. typedef)
    end
    seen[tdef] = typedef
    return typedef
end

function interface_mt.GetVFunction(self, index, tdef)
    local thisptr = self[1]
    if IsValidPtr(thisptr) then
        local typedef = CheckOrCreateTypedef(tdef)
        local fn = function_cast(thisptr, index, typedef, tdef)
        if not IsValidPtr(fn) then
            error("get_vfunc: couldnt cast function (" .. index .. ")")
        end
        return function(...)
            return fn(thisptr, ...)
        end
    end
    error('get_vfunc: thisptr is invalid')
end

function helper_mt.GetClass(raw, module)
    if IsValidPtr(raw) then 
        local ptr = iFaceCast(raw)
        if IsValidPtr(ptr) then 
            return setmetatable({ptr, module}, {__index = interface_mt})
        else
            error("get_class: class pointer is invalid")
        end
    end
    error("get_class: argument is nullptr")
end

function helper_mt.FindPattern(module, signature, tdef, offset)
    local match = mem.FindPattern(module, signature)
    if IsValidPtr(match) then 
        if offset then 
            match = ffi.cast("char*", match) + offset
            if not IsValidPtr(match) then
                error("find_pattern: adding offset ("..offset..") returned nullptr", 2)
            end
        end
        local typedef = CheckOrCreateTypedef(tdef)
        local fn = ffi.cast(typedef, match)
        if IsValidPtr(fn) then
            return fn
        end
        error("find_pattern: couldnt cast function ("..tdef..")")
    end
    error("find_pattern: couldnt find signature ("..signature..")")
end

local helper = helper_mt
local steam_api = helper.FindPattern("client.dll", "FF 15 ?? ?? ?? ?? B9 ?? ?? ?? ?? E8 ?? ?? ?? ?? 6A", "steam_api_ctx_t**", 7)[0]
local steam_friends = helper.GetClass(steam_api.steam_friends)
local blank = "　"
local ISteamFriends_mt = {	
	SetRichPresence = steam_friends:GetVFunction(43, 'bool(__thiscall*)(void*, const char*, const char*)'),
	ClearRichPresence = steam_friends:GetVFunction(44, 'void(__thiscall*)(void*)'),
}
presence_changed = 0;
eeb_value = editbox:GetValue();
local button = gui.Button(groupbox, "Set presence", function()
    eeb_value = editbox:GetValue();
    presence_changed = globals.RealTime()-1;
end);

local button = gui.Button(groupbox, "Clear presence", function()
    ISteamFriends_mt.ClearRichPresence()
end);

function presence()
    if editbox:GetValue() ~= "" then
        if (globals.RealTime() - presence_changed > 1) then
            ISteamFriends_mt.SetRichPresence("steam_display", "#bcast_teamvsteammap")
            ISteamFriends_mt.SetRichPresence("team1", eeb_value .. string.rep(blank, (113 - #eeb_value)/2 ))
            ISteamFriends_mt.SetRichPresence("team2", string.rep(blank, 50))
            ISteamFriends_mt.SetRichPresence("map", "de_dust2")
            ISteamFriends_mt.SetRichPresence("game:mode", "competitive")
            ISteamFriends_mt.SetRichPresence("system:access", "private")
            presence_changed = globals.RealTime();
        end
    end
end

callbacks.Register("Draw", "presence", presence)
