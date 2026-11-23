-- Offline test: the unit helper and the UI wrappers, with stubs for the game's globals.
local fails, passes = 0, 0
local function check(cond, msg)
    if cond then passes = passes + 1 else fails = fails + 1; print("FAIL: " .. msg) end
end
local function near(a, b) return math.abs(a - b) < 0.005 end

local calls = {}
getText = function(key, a)
    calls[#calls + 1] = key
    if a ~= nil then return key .. "(" .. tostring(a) .. ")" end
    return key
end
function round(n, d) local m = 10 ^ (d or 0); return math.floor(n * m + 0.5) / m end
require = function() end   -- the game's files are stubbed below
local function load(rel) dofile(MOD_LUA .. "/" .. rel) end

load("client/ImperialUnits/IU_Units.lua")
local IU = ImperialUnits
check(near(IU.litresToGallons(3.785411784), 1), "3.785 L is one gallon")
check(near(IU.kgToPounds(1), 2.20), "1 kg is 2.20 lb")
check(near(IU.gramsToOunces(1000), 35.27), "1000 g is 35.27 oz")
check(IU.gallonsText(20) == "5.28 gal", "20 L reads 5.28 gal, got " .. IU.gallonsText(20))
check(IU.gallonsText(0) == "0.00 gal", "empty reads 0.00 gal")

-- withGetText puts getText back, also when the wrapped function errors
local before = getText
IU.withGetText(function(k) if k == "X" then return "swapped" end end, function()
    check(getText("X") == "swapped", "replacer text wins")
    check(getText("Y", 5) == "Y(5)", "other keys fall through with their arguments")
end)
check(getText == before, "getText restored after success")
local ok = pcall(IU.withGetText, function() end, function() error("boom") end)
check(not ok and getText == before, "getText restored after an error, error passed on")

-- Stubs of the game's three windows, then our wrappers.
local drawn = {}
ISFeedingTroughUI = { render = function(self) self.labelWater:setName("5000 / 20000 mL") end }
ISDesignationZoneAnimalZoneUI = {
    calcWater = function() return 20000 end,
    render = function(self) drawn.zone = getText("IGUI_DesignationZone_Water") .. self:calcWater() .. getText("IGUI_Milliliter") end,
}
ISAnimalUI = { render = function() drawn.kg = getText("IGUI_AnimalWeight", 12.5); drawn.g = getText("IGUI_AnimalWeightG", 250) end }
load("client/ImperialUnits/IU_Hooks.lua")

local label, wrapped = nil, 0
local win = {
    item = { getWater = function() return 5 end, getMaxWater = function() return 20 end },
    labelWater = { setName = function(_, t) label = t end },
    ignoreChildren = { contains = function() return false end },
    shrinkWrap = function() wrapped = wrapped + 1 end,
}
ISFeedingTroughUI.render(win)
check(label == "1.32 gal / 5.28 gal", "trough window label, got " .. tostring(label))
check(wrapped == 1, "trough window shrinks to the new text")

ISDesignationZoneAnimalZoneUI.render({ calcWater = ISDesignationZoneAnimalZoneUI.calcWater })
check(drawn.zone == "IGUI_DesignationZone_Water5.28 gal", "zone water line, got " .. tostring(drawn.zone))
check(ISDesignationZoneAnimalZoneUI.calcWater({}) == 20000, "calcWater unchanged outside the draw")

ISAnimalUI.render({})
check(drawn.kg == "27.56 lbs", "animal weight in lbs, got " .. tostring(drawn.kg))
check(drawn.g == "8.82 oz", "small animal weight in oz, got " .. tostring(drawn.g))

-- Trough tooltip file: loads and shows gallons.
local tip
Events = { DoSpecialTooltip = { Add = function(f) tip = f end } }
CGlobalObjectSystem = { derive = function() return {} end, RegisterSystemClass = function() end, new = function() return {} end }
Mouse = { isRightDown = function() return false end }
local labels = {}
local trough = { getCurrentFeedAmount = function() return 0 end, getWater = function() return 5 end, getMaxWater = function() return 20 end }
local layoutItem = { setLabel = function(_, t) labels[#labels + 1] = t end }
local layout = { addItem = function() return layoutItem end, render = function() return 0 end }
local tooltip = {
    DrawTextureScaled = function() end, getTexture = function() end, getWidth = function() return 100 end, getHeight = function() return 50 end,
    DrawTextCentre = function() end, getFont = function() end, adjustWidth = function() end, beginLayout = function() return layout end,
    setHeight = function() end, endLayout = function() end, setWidth = function() end, setMeasureOnly = function() end,
}
getPlayer = function() return nil end
getTextManager = function() return { getFontHeight = function() return 10 end } end
CFeedingTroughSystem = nil
load("client/FeedingTrough/CFeedingTroughSystem.lua")
CFeedingTroughSystem.instance = { getLuaObjectOnSquare = function() return { getIsoObject = function() return trough end } end }
tip(tooltip, {})
local found
for _, t in ipairs(labels) do if t:find("1.32 gal / 5.28 gal", 1, true) then found = true end end
check(found, "trough tooltip shows gallons, labels: " .. table.concat(labels, " | "))

print(string.format("%d passed, %d failed", passes, fails))
return fails
