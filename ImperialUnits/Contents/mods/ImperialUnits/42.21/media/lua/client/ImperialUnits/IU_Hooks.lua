-- Imperial Units: wraps the game's UI code so it shows imperial units. Each wrapper
-- calls the game's own function, so a game update that changes those functions
-- carries over. The one exception is FeedingTrough/CFeedingTroughSystem.lua, which
-- is replaced as a whole file (see that file).
require "ImperialUnits/IU_Units"
require "FeedingTrough/ISUI/ISFeedingTroughUI"
require "ISUI/Animal/ISDesignationAnimalZoneUI"
require "ISUI/Animal/ISAnimalUI"

local IU = ImperialUnits

-- Feeding trough window: the game writes "5000 / 20000 mL"; write it in gallons
-- afterwards and shrink the window to fit the new, shorter text.
local origTroughRender = ISFeedingTroughUI.render
function ISFeedingTroughUI:render()
    origTroughRender(self)
    local water = IU.gallonsText(self.item:getWater()) .. " / " .. IU.gallonsText(self.item:getMaxWater())
    self.labelWater:setName(water)
    self:shrinkWrap(11, 11, function(_child)
        return not self.ignoreChildren:contains(_child.javaObject)
    end)
end

-- Animal zone window, "Available Water": calcWater returns millilitres and the line
-- adds the unit " mL". While that window draws, hand back gallons and " gal".
local origCalcWater = ISDesignationZoneAnimalZoneUI.calcWater
local zoneDrawing = false
function ISDesignationZoneAnimalZoneUI:calcWater()
    local ml = origCalcWater(self)
    if zoneDrawing then return IU.fmt(IU.litresToGallons(ml / 1000)) end
    return ml
end

local origZoneRender = ISDesignationZoneAnimalZoneUI.render
function ISDesignationZoneAnimalZoneUI:render()
    zoneDrawing = true
    local ok, err = pcall(IU.withGetText, function(key)
        if key == "IGUI_Milliliter" then return " gal" end
    end, origZoneRender, self)
    zoneDrawing = false
    if not ok then error(err, 0) end
end

-- Animal window, weight: the game passes kilograms (or grams under one kilogram).
local origAnimalRender = ISAnimalUI.render
function ISAnimalUI:render()
    IU.withGetText(function(key, amount)
        if key == "IGUI_AnimalWeight" then return IU.fmt(IU.kgToPounds(amount)) .. " lbs" end
        if key == "IGUI_AnimalWeightG" then return IU.fmt(IU.gramsToOunces(amount)) .. " oz" end
    end, origAnimalRender, self)
end
