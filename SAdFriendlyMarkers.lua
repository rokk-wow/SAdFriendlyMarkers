local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

addon.sadCore.savedVarsGlobalName = "SAdFriendlyMarkers_Settings_Global"
addon.sadCore.savedVarsPerCharName = "SAdFriendlyMarkers_Settings_Char"
addon.sadCore.compartmentFuncName = "SAdFriendlyMarkers_Compartment_Func"

addon.settings = {}
addon.settings.iconSize = 40
addon.settings.highlightSize = 55
addon.settings.borderSize = 64
addon.settings.classIconPath = "Interface/GLUES/CHARACTERCREATE/UI-CHARACTERCREATE-CLASSES"
addon.settings.unsupportedZones = { "dungeon", "raid" }
addon.settings.throttleTime = 0.1
addon.settings.updateDelay = 0.1
addon.settings.defaultVerticalOffset = 40
addon.settings.nameplateSizeOffset = 0
addon.settings.nameplateSizeOffsetMultiplier = 10
addon.settings.nameplateUpdateTimes = {}
addon.settings.nameplateUpdateTimer = nil
addon.settings.markers = {
    covenantDoubleArrow = { atlas = "CovenantSanctum-Renown-DoubleArrow", rotation = math.pi / 2, width = 48, height = 67 },
    azeriteArrow = { atlas = "Azerite-PointingArrow", rotation = 0, width = 62, height = 44 },
    npeArrow = { atlas = "NPE_ArrowDown", rotation = 0, width = 64, height = 64 },
    forwardArrow = { atlas = "common-icon-forwardarrow", rotation = -math.pi / 2, width = 45, height = 45 },
    spectateArrow = { atlas = "wowlabs-spectatecycling-arrowleft", rotation = math.pi / 2, width = 58, height = 55 },
    crosshair = { atlas = "Crosshair_unableAttack_128", rotation = 0, width = 64, height = 64 },
    nodeSelected = { atlas = "Customization_Fixture_Node_Selected", rotation = 0, width = 64, height = 64 },
    characterCustomize = { atlas = "charactercreate-icon-customize-body-selected", rotation = 0, width = 64, height = 65 },
    prestige1 = { atlas = "honorsystem-icon-prestige-1", rotation = 0, width = 64, height = 64 },
    prestige2 = { atlas = "honorsystem-icon-prestige-2", rotation = 0, width = 64, height = 64 },
    prestige3 = { atlas = "honorsystem-icon-prestige-3", rotation = 0, width = 64, height = 64 },
    prestige4 = { atlas = "honorsystem-icon-prestige-4", rotation = 0, width = 64, height = 64 },
    housingOrb = { atlas = "housing-layout-room-orb-ring-highlight", rotation = 0, width = 64, height = 64 },
    plunderZone = { atlas = "plunderstorm-map-zoneYellow-hover", rotation = 0, width = 64, height = 64 },
    plunderNameplate = { atlas = "plunderstorm-nameplates-icon-2", rotation = 0, width = 64, height = 64 },
}
addon.settings.arenaMarkers = {
    arena1 = { atlas = "services-number-1", rotation = 0, width = 71, height = 79 },
    arena2 = { atlas = "services-number-2", rotation = 0, width = 71, height = 79 },
    arena3 = { atlas = "services-number-3", rotation = 0, width = 71, height = 79 },
}
addon.settings.healerMarkers = {
    healer1 = { atlas = "Gamepad_Rev_Plus_64", rotation = 0, width = 64, height = 64 },
    healer2 = { atlas = "communities-icon-addgroupplus", rotation = 0, width = 64, height = 64 },
    healer3 = { atlas = "common-icon-redx", rotation = math.pi / 4, width = 25, height = 25 },
}

function addon:Initialize()
    self.sadCore.version = "1.0"
    self.author = "Rôkk-Wyrmrest Accord"

    local markerOptions = {}
    table.insert(markerOptions, { value = "classIcon", label = "markerStyleClassIcon" })
    
    for markerKey in pairs(self.settings.markers) do
        local labelKey = "markerStyle" .. markerKey:sub(1,1):upper() .. markerKey:sub(2)
        table.insert(markerOptions, {
            value = markerKey,
            label = labelKey,
            onValueChange = function() addon:RefreshAllNameplates() end
        })
    end

    self.sadCore.panels.markerStyle = {
        title = "markerStyle",
        controls = {
            {
                type = "header",
                name = "friendlyMarkersHeader"
            },
            {
                type = "dropdown",
                name = "markerTexture",
                default = "covenantDoubleArrow",
                options = markerOptions,
                onValueChange = function() addon:RefreshAllNameplates() end
            },
            {
                type = "slider",
                name = "markerSize",
                default = 150,
                min = 1,
                max = 500,
                step = 1,
                onValueChange = function() addon:RefreshAllNameplates() end
            },
            {
                type = "slider",
                name = "markerVerticalOffset",
                default = -20,
                min = -100,
                max = 100,
                step = 1,
                onValueChange = function() addon:RefreshAllNameplates() end
            },
            {
                type = "slider",
                name = "markerWidth",
                default = 0,
                min = -5,
                max = 5,
                step = 0.5,
                onValueChange = function() addon:RefreshAllNameplates() end
            },
            {
                type = "checkbox",
                name = "showFriendlyHealthBars",
                default = true,
                onValueChange = function() addon:RefreshAllNameplates() end
            },
            {
                type = "checkbox",
                name = "showFriendlyHealerIcon",
                default = false,
                onValueChange = function() addon:RefreshAllNameplates() end
            },
            {
                type = "header",
                name = "extraOptionsHeader"
            },
            {
                type = "checkbox",
                name = "enableArenaMarkers",
                default = false,
                onValueChange = function() addon:RefreshAllNameplates() end
            },
            {
                type = "slider",
                name = "arenaMarkerSize",
                default = 90,
                min = 1,
                max = 500,
                step = 1,
                onValueChange = function() addon:RefreshAllNameplates() end
            },
            {
                type = "slider",
                name = "arenaMarkerVerticalOffset",
                default = -20,
                min = -100,
                max = 100,
                step = 1,
                onValueChange = function() addon:RefreshAllNameplates() end
            },
            {
                type = "checkbox",
                name = "showEnemyHealerIcon",
                default = false,
                onValueChange = function() addon:RefreshAllNameplates() end
            },
        }
    }

    local enableZoneControls = {}
    for _, zoneName in ipairs(self.zones) do
        local supported = not tContains(self.settings.unsupportedZones, zoneName)
        
        if supported then
            table.insert(enableZoneControls, {
                type = "checkbox",
                name = "enabledIn" .. zoneName:sub(1,1):upper() .. zoneName:sub(2),
                default = true,
                persistent = true,
                onValueChange = function() addon:RefreshAllNameplates() end
            })
        else
            table.insert(enableZoneControls, {
                type = "description",
                name = zoneName .. "NotSupported"
            })
        end
    end

    self.sadCore.panels.zones = {
        title = "enableInZoneTitle",
        controls = enableZoneControls
    }
   
    self:RegisterEvent("PLAYER_ENTERING_WORLD", function(event, isInitialLogin, isReloadingUI)
        self:InitializeNameplates()
    end)

    self:RegisterEvent("CVAR_UPDATE", function(event, cvarName)
        self:CvarUpdate(cvarName)
    end)

    self:RegisterEvent("NAME_PLATE_UNIT_ADDED", function(eventTable, eventName, unit)
        if unit then
            local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
            if nameplate then
                self:ShowMarker(nameplate)
            end
        end
    end)

    self:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS", function(event)
        self:RefreshAllNameplates()
    end)

    self:RegisterEvent("ARENA_OPPONENT_UPDATE", function(event)
        self:RefreshAllNameplates()
    end)

    self:RegisterEvent("UNIT_FACTION", function(event, unit)
        if unit and string.match(unit, "nameplate") then
            local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
            if nameplate then
                self:ShowMarker(nameplate)
            end
        end
    end)
end

function addon:CvarUpdate(cvarName)
    if cvarName == "nameplateSize" then
        self.settings.nameplateSizeOffset = tonumber(GetCVar(cvarName)) * self.settings.nameplateSizeOffsetMultiplier
        
        if self.settings.nameplateUpdateTimer then
            self.settings.nameplateUpdateTimer:Cancel()
        end
        
        self.settings.nameplateUpdateTimer = C_Timer.NewTimer(self.settings.updateDelay, function()
            self:RefreshAllNameplates()
            self.settings.nameplateUpdateTimer = nil
        end)
    end
end

function addon:InitializeNameplates()
    local initialNameplateSize = GetCVar("nameplateSize") or "1"
    self.settings.nameplateSizeOffset = tonumber(initialNameplateSize) * self.settings.nameplateSizeOffsetMultiplier
    
    C_Timer.After(0.5, function()
        self:RefreshAllNameplates()
    end)
end

function addon:OnZoneChange(currentZone)
    self:RefreshAllNameplates()
end

function addon:RefreshAllNameplates()
    if tContains(self.settings.unsupportedZones, self.currentZone) then
        return
    end
    
    local isEnabled = true
    if self.savedVars.zones then
        local controlName = "enabledIn" .. self.currentZone:sub(1,1):upper() .. self.currentZone:sub(2)
        isEnabled = self.savedVars.zones[controlName]
    end
    
    local nameplates = C_NamePlate.GetNamePlates()
    for _, nameplate in ipairs(nameplates) do
        if isEnabled then
            self:ShowMarker(nameplate)
        else
            self:HideMarker(nameplate)
        end
    end
end

function addon:ShowMarker(nameplate)
    local unitFrame = nameplate and nameplate.UnitFrame
    if not nameplate or not unitFrame then
        return
    end
    
    local unit = unitFrame.unit
    if not unit then
        self:HideMarker(nameplate)
        return
    end
    
    local isPlayer = UnitIsPlayer(unit)
    local isSelf = UnitIsUnit(unit, "player")
    
    if not isPlayer or isSelf then
        self:HideMarker(nameplate)
        return
    end
    
    local isEnemy = UnitIsEnemy("player", unit)
    
    if isEnemy then
        if self.currentZone == "arena" and self.savedVars.markerStyle.enableArenaMarkers then
            self:ShowArenaMarker(nameplate, unitFrame, unit)
        else
            self:HideMarker(nameplate)
        end
        return
    end
    
    self:ShowFriendlyMarker(nameplate, unitFrame, unit)
end

function addon:ShowArenaMarker(nameplate, unitFrame, unit)
    local detectedArena = nil
    
    for i = 1, 3 do
        local arenaNameplate = C_NamePlate.GetNamePlateForUnit("arena" .. i)
        if arenaNameplate == nameplate then
            detectedArena = "arena" .. i
            break
        end
    end
    
    if not detectedArena then
        self:HideMarker(nameplate)
        return
    end
    
    local currentNameplateSize = tonumber(GetCVar("nameplateSize")) or 1
    local nameplateSizeOffset = currentNameplateSize * self.settings.nameplateSizeOffsetMultiplier
    local iconScale = self.savedVars.markerStyle.arenaMarkerSize / 100
    local verticalOffset = self.savedVars.markerStyle.arenaMarkerVerticalOffset + self.settings.defaultVerticalOffset + nameplateSizeOffset
    
    if nameplate.FriendlyClassIcon then
        nameplate.FriendlyClassIcon:Hide()
    end
    if nameplate.FriendlyClassArrow then
        nameplate.FriendlyClassArrow:Hide()
    end
    
    if unitFrame.healthBar then
        unitFrame.healthBar:SetAlpha(1)
    end
    if unitFrame.name then
        unitFrame.name:SetAlpha(1)
    end
    if unitFrame.RaidTargetFrame then
        unitFrame.RaidTargetFrame:SetAlpha(1)
    end
    
    local role = UnitGroupRolesAssigned(unit)
    if self.savedVars.markerStyle.showEnemyHealerIcon and role == "HEALER" then
        local healerMarkerInfo = self.settings.healerMarkers.healer1
        if healerMarkerInfo then
            local healerFrame = self:CreateHealerMarker(nameplate, healerMarkerInfo.width, healerMarkerInfo.height)
            healerFrame.icon:SetAtlas(healerMarkerInfo.atlas)
            healerFrame.icon:SetRotation(healerMarkerInfo.rotation)
            healerFrame.icon:SetDesaturated(true)
            healerFrame.icon:SetVertexColor(1, 0, 0)
            healerFrame:SetScale(iconScale)
            healerFrame:ClearAllPoints()
            healerFrame:SetPoint("BOTTOM", nameplate, "BOTTOM", 0, verticalOffset)
            healerFrame:Show()
        end
    else
        local arenaMarkerInfo = self.settings.arenaMarkers[detectedArena]
        if arenaMarkerInfo then
            local arenaFrame = self:CreateArenaMarker(nameplate, arenaMarkerInfo.width, arenaMarkerInfo.height)
            arenaFrame.icon:SetAtlas(arenaMarkerInfo.atlas)
            arenaFrame.icon:SetRotation(arenaMarkerInfo.rotation)
            arenaFrame:SetScale(iconScale)
            arenaFrame:ClearAllPoints()
            arenaFrame:SetPoint("BOTTOM", nameplate, "BOTTOM", 0, verticalOffset)
            arenaFrame:Show()
        end
    end
end

function addon:ShowFriendlyMarker(nameplate, unitFrame, unit)
    local _, class = UnitClass(unit)
    if not class then
        self:HideMarker(nameplate)
        return
    end
    
    local classColor = RAID_CLASS_COLORS[class]
    if not classColor then
        self:HideMarker(nameplate)
        return
    end
    
    local currentTime = GetTime()
    local lastUpdate = self.settings.nameplateUpdateTimes[nameplate]
    if lastUpdate and (currentTime - lastUpdate) < self.settings.throttleTime then
        return
    end
    self.settings.nameplateUpdateTimes[nameplate] = currentTime
    
    local currentNameplateSize = tonumber(GetCVar("nameplateSize")) or 1
    local nameplateSizeOffset = currentNameplateSize * self.settings.nameplateSizeOffsetMultiplier    
    local iconScale = self.savedVars.markerStyle.markerSize / 100
    local markerStyle = self.savedVars.markerStyle.markerTexture
    local verticalOffset = self.savedVars.markerStyle.markerVerticalOffset + self.settings.defaultVerticalOffset + nameplateSizeOffset
    local markerWidthValue = self.savedVars.markerStyle.markerWidth
    local markerWidth = 1.0 + (markerWidthValue * 0.15)
   
    if self.savedVars.markerStyle.showFriendlyHealthBars then
        if unitFrame.healthBar then
            unitFrame.healthBar:SetAlpha(1)
        end
        if unitFrame.name then
            unitFrame.name:SetAlpha(1)
        end
        if unitFrame.RaidTargetFrame then
            unitFrame.RaidTargetFrame:SetAlpha(1)
        end
    else
        if unitFrame.healthBar then
            unitFrame.healthBar:SetAlpha(0)
        end
        if unitFrame.name then
            unitFrame.name:SetAlpha(0)
        end
        if unitFrame.RaidTargetFrame then
            unitFrame.RaidTargetFrame:SetAlpha(0)
        end
    end
   
    if nameplate.FriendlyClassIcon then
        nameplate.FriendlyClassIcon:Hide()
    end
    if nameplate.FriendlyClassArrow then
        nameplate.FriendlyClassArrow:Hide()
    end
    if nameplate.ArenaNumberMarker then
        nameplate.ArenaNumberMarker:Hide()
    end
    if nameplate.HealerMarker then
        nameplate.HealerMarker:Hide()
    end
    
    if self.currentZone == "arena" and self.savedVars.markerStyle.showFriendlyHealerIcon then
        local role = UnitGroupRolesAssigned(unit)
        if role == "HEALER" then
            local healerMarkerInfo = self.settings.healerMarkers.healer1
            if healerMarkerInfo then
                local healerFrame = self:CreateHealerMarker(nameplate, healerMarkerInfo.width, healerMarkerInfo.height)
                healerFrame.icon:SetAtlas(healerMarkerInfo.atlas)
                healerFrame.icon:SetRotation(healerMarkerInfo.rotation)
                healerFrame.icon:SetDesaturated(true)
                healerFrame.icon:SetVertexColor(0, 1, 0)
                healerFrame:SetScale(iconScale)
                healerFrame:ClearAllPoints()
                healerFrame:SetPoint("BOTTOM", nameplate, "BOTTOM", 0, verticalOffset)
                healerFrame:Show()
                return
            end
        end
    end
    
    if markerStyle == "classIcon" then
        local iconFrame = self:CreateClassIcon(nameplate)
        iconFrame.icon:SetTexture(self.settings.classIconPath)
        iconFrame.icon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[class]))
        iconFrame:SetSize(self.settings.iconSize * markerWidth, self.settings.iconSize)
        iconFrame.icon:SetSize(self.settings.iconSize * markerWidth, self.settings.iconSize)
        iconFrame.mask:SetSize(self.settings.iconSize * markerWidth, self.settings.iconSize)
        iconFrame.border:SetSize(self.settings.borderSize * markerWidth, self.settings.borderSize)
        iconFrame.border:SetDesaturated(true)
        iconFrame.border:SetVertexColor(classColor.r, classColor.g, classColor.b)
        iconFrame:SetScale(iconScale)
        iconFrame:ClearAllPoints()
        iconFrame:SetPoint("BOTTOM", nameplate, "BOTTOM", 0, verticalOffset)        
        iconFrame:Show()
    else
        local styleInfo = self.settings.markers[markerStyle]
        if styleInfo then
            local width = styleInfo.width
            local height = styleInfo.height
            local isRotated90 = (styleInfo.rotation == math.pi / 2 or styleInfo.rotation == -math.pi / 2)
            local finalWidth = isRotated90 and width or (width * markerWidth)
            local finalHeight = isRotated90 and (height * markerWidth) or height
            local arrowFrame = self:CreateClassArrow(nameplate, finalWidth, finalHeight)
            arrowFrame.icon:SetAtlas(styleInfo.atlas)
            arrowFrame.icon:SetRotation(styleInfo.rotation)
            arrowFrame.icon:SetDesaturated(true)
            arrowFrame.icon:SetVertexColor(classColor.r, classColor.g, classColor.b)
            arrowFrame:SetScale(iconScale)
            arrowFrame:ClearAllPoints()
            arrowFrame:SetPoint("BOTTOM", nameplate, "BOTTOM", 0, verticalOffset)
            arrowFrame:Show()
        end
    end
end

function addon:HideMarker(nameplate)
    if nameplate.FriendlyClassIcon then
        nameplate.FriendlyClassIcon:Hide()
    end
    if nameplate.FriendlyClassArrow then
        nameplate.FriendlyClassArrow:Hide()
    end
    if nameplate.ArenaNumberMarker then
        nameplate.ArenaNumberMarker:Hide()
    end
    if nameplate.HealerMarker then
        nameplate.HealerMarker:Hide()
    end
end

function addon:CreateClassArrow(nameplate, width, height)
    if nameplate.FriendlyClassArrow then
        local w = width
        local h = height
        nameplate.FriendlyClassArrow:SetSize(h, w)
        nameplate.FriendlyClassArrow.icon:SetSize(w, h)
        return nameplate.FriendlyClassArrow
    end
    
    local w = width
    local h = height
    
    local arrowFrame = CreateFrame("Frame", nil, nameplate)
    arrowFrame:SetMouseClickEnabled(false)
    arrowFrame:SetAlpha(1)
    arrowFrame:SetIgnoreParentAlpha(true)
    arrowFrame:SetSize(h, w)
    arrowFrame:SetFrameStrata("HIGH")
    arrowFrame:SetPoint("CENTER", nameplate, "CENTER")
    
    arrowFrame.icon = arrowFrame:CreateTexture(nil, "BORDER")
    arrowFrame.icon:SetSize(w, h)
    arrowFrame.icon:SetDesaturated(false)
    arrowFrame.icon:SetPoint("CENTER", arrowFrame, "CENTER")
    
    arrowFrame:Hide()
    nameplate.FriendlyClassArrow = arrowFrame
    return arrowFrame
end

function addon:CreateClassIcon(nameplate)
    if nameplate.FriendlyClassIcon then
        return nameplate.FriendlyClassIcon
    end
    
    local iconFrame = CreateFrame("Frame", nil, nameplate)
    iconFrame:SetMouseClickEnabled(false)
    iconFrame:SetAlpha(1)
    iconFrame:SetIgnoreParentAlpha(true)
    iconFrame:SetSize(self.settings.iconSize, self.settings.iconSize)
    iconFrame:SetFrameStrata("HIGH")
    iconFrame:SetPoint("BOTTOM", nameplate, "BOTTOM", 0, 0)
    
    iconFrame.icon = iconFrame:CreateTexture(nil, "BORDER")
    iconFrame.icon:SetSize(self.settings.iconSize, self.settings.iconSize)
    iconFrame.icon:SetAllPoints(iconFrame)
    
    iconFrame.mask = iconFrame:CreateMaskTexture()
    iconFrame.mask:SetTexture("Interface/Masks/CircleMaskScalable")
    iconFrame.mask:SetSize(self.settings.iconSize, self.settings.iconSize)
    iconFrame.mask:SetAllPoints(iconFrame.icon)
    iconFrame.icon:AddMaskTexture(iconFrame.mask)
    
    iconFrame.border = iconFrame:CreateTexture(nil, "OVERLAY")
    iconFrame.border:SetAtlas("charactercreate-ring-metallight")
    iconFrame.border:SetSize(self.settings.borderSize, self.settings.borderSize)
    iconFrame.border:SetPoint("CENTER", iconFrame)
    
    iconFrame:Hide()
    nameplate.FriendlyClassIcon = iconFrame
    return iconFrame
end

function addon:CreateArenaMarker(nameplate, width, height)
    if nameplate.ArenaNumberMarker then
        nameplate.ArenaNumberMarker:SetSize(width, height)
        nameplate.ArenaNumberMarker.icon:SetSize(width, height)
        return nameplate.ArenaNumberMarker
    end
    
    local markerFrame = CreateFrame("Frame", nil, nameplate)
    markerFrame:SetMouseClickEnabled(false)
    markerFrame:SetAlpha(1)
    markerFrame:SetIgnoreParentAlpha(true)
    markerFrame:SetSize(width, height)
    markerFrame:SetFrameStrata("HIGH")
    markerFrame:SetPoint("CENTER", nameplate, "CENTER")
    
    markerFrame.icon = markerFrame:CreateTexture(nil, "OVERLAY")
    markerFrame.icon:SetSize(width, height)
    markerFrame.icon:SetPoint("CENTER", markerFrame, "CENTER")
    
    markerFrame:Hide()
    nameplate.ArenaNumberMarker = markerFrame
    return markerFrame
end

function addon:CreateHealerMarker(nameplate, width, height)
    if nameplate.HealerMarker then
        nameplate.HealerMarker:SetSize(width, height)
        nameplate.HealerMarker.icon:SetSize(width, height)
        return nameplate.HealerMarker
    end
    
    local markerFrame = CreateFrame("Frame", nil, nameplate)
    markerFrame:SetMouseClickEnabled(false)
    markerFrame:SetAlpha(1)
    markerFrame:SetIgnoreParentAlpha(true)
    markerFrame:SetSize(width, height)
    markerFrame:SetFrameStrata("HIGH")
    markerFrame:SetPoint("CENTER", nameplate, "CENTER")
    
    markerFrame.icon = markerFrame:CreateTexture(nil, "OVERLAY")
    markerFrame.icon:SetSize(width, height)
    markerFrame.icon:SetPoint("CENTER", markerFrame, "CENTER")
    
    markerFrame:Hide()
    nameplate.HealerMarker = markerFrame
    return markerFrame
end