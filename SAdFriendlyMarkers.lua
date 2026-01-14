local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

addon.savedVarsGlobalName = "SAdFriendlyMarkers_Settings_Global"
addon.savedVarsPerCharName = "SAdFriendlyMarkers_Settings_Char"
addon.compartmentFuncName = "SAdFriendlyMarkers_Compartment_Func"

function addon:LoadConfig()
    self.config.version = "1.0"
    self.author = "Rôkk-Wyrmrest Accord"

        self.config.settings.markerStyle = {
        title = "markerStyle",
        controls = {{
                type = "dropdown",
                name = "markerTexture",
                default = "covenantDoubleArrow",
                options = {
                    { value = "covenantDoubleArrow", label = "markerStyleCovenantDoubleArrow" },
                    { value = "classIcon", label = "markerStyleClassIcon" },                    
                    { value = "azeriteArrow", label = "markerStyleAzeriteArrow" },
                    { value = "npeArrow", label = "markerStyleNpeArrow" },
                    { value = "forwardArrow", label = "markerStyleForwardArrow" },
                    { value = "spectateArrow", label = "markerStyleSpectateArrow" },
                    { value = "questIcon", label = "markerStyleQuestIcon" },
                    { value = "crosshair", label = "markerStyleCrosshair" },
                    { value = "nodeSelected", label = "markerStyleNodeSelected" },
                    { value = "flightArgus", label = "markerStyleFlightArgus" },
                    { value = "flightProgenitor", label = "markerStyleFlightProgenitor" },
                    { value = "characterCustomize", label = "markerStyleCharacterCustomize" },
                    { value = "prestige1", label = "markerStylePrestige1" },
                    { value = "prestige2", label = "markerStylePrestige2" },
                    { value = "prestige3", label = "markerStylePrestige3" },
                    { value = "prestige4", label = "markerStylePrestige4" },
                    { value = "housingOrb", label = "markerStyleHousingOrb" },
                    { value = "artifactNode", label = "markerStyleArtifactNode" },
                    { value = "plunderZone", label = "markerStylePlunderZone" },
                    { value = "plunderNameplate", label = "markerStylePlunderNameplate" },
                }
            },
            {
                type = "slider",
                name = "markerSize",
                default = 1.0,
                min = 0.5,
                max = 3.0,
                step = 0.1,
            },
            {
                type = "slider",
                name = "markerVerticalOffset",
                default = 28,
                min = -100,
                max = 100,
                step = 1,
            },
            {
                type = "slider",
                name = "markerWidth",
                default = 0,
                min = -5,
                max = 5,
                step = 0.5,
            },
        }
    }

    enableZoneControls = {}
    for _, zoneName in ipairs(addon.zones) do
        if zoneName == "dungeon" or zoneName == "raid" then
            table.insert(enableZoneControls, {
                type = "description",
                name = zoneName .."NotSupported"
            })
        else
            local controlName = "enabledIn" .. zoneName:sub(1,1):upper() .. zoneName:sub(2)
            table.insert(enableZoneControls, {
                type = "checkbox",
                name = controlName,
                default = true,
                persistent = true,
                onValueChange = addon.RefreshAllNameplates
            })
        end
    end

    self.config.settings.zones = {
        title = "enableInZoneTitle",
        controls = enableZoneControls
    }
end

addon.locale = {}

addon.locale.enEN = {
    dungeonNotSupported = "Dungeons not supported",
    raidNotSupported = "Raids not supported"
}