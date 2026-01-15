local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

addon.locale = {}

-- English
addon.locale.enEN = {
    arenaTitle = "Arena",
    dungeonNotSupported = "Dungeons not supported",
    raidNotSupported = "Raids not supported"
}

-- Spanish
addon.locale.esES = {
    arenaTitle = "Arena",
}

addon.locale.esMX = addon.locale.esES

-- Portuguese
addon.locale.ptBR = {
    arenaTitle = "Arena",
}

-- French
addon.locale.frFR = {
    arenaTitle = "Arène",
}

-- German
addon.locale.deDE = {
    arenaTitle = "Arena",
}

-- Russian
addon.locale.ruRU = {
    arenaTitle = "Арена",
}
