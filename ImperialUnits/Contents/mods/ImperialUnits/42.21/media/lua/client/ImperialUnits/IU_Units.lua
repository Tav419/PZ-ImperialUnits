-- Imperial Units: conversion helpers. No game calls in here, so the tests can run it.
ImperialUnits = ImperialUnits or {}
local IU = ImperialUnits

IU.LITRES_PER_GALLON = 3.785411784
IU.POUNDS_PER_KG = 2.2046226218
IU.OUNCES_PER_GRAM = 0.03527396195

function IU.litresToGallons(litres) return litres / IU.LITRES_PER_GALLON end
function IU.kgToPounds(kg) return kg * IU.POUNDS_PER_KG end
function IU.gramsToOunces(grams) return grams * IU.OUNCES_PER_GRAM end

-- Two decimals, trailing zeros kept, so a column of amounts lines up ("1.32").
function IU.fmt(n) return string.format("%.2f", n) end

-- "1.32 gal" from litres.
function IU.gallonsText(litres) return IU.fmt(IU.litresToGallons(litres)) .. " gal" end

-- Runs fn(...) with the global getText wrapped: replacer(key, ...) returns a string
-- to replace that text, or nil to leave it to the game's own getText. getText is put
-- back afterwards even if fn raises an error. Used so the game's own drawing code
-- shows our units without copying that code.
function IU.withGetText(replacer, fn, ...)
    local prev = getText
    getText = function(key, ...)
        local r = replacer(key, ...)
        if r ~= nil then return r end
        return prev(key, ...)
    end
    local ok, err = pcall(fn, ...)
    getText = prev
    if not ok then error(err, 0) end
end
