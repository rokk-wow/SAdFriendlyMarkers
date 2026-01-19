local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

addon.savedVarsGlobalName = "SAdFriendlyMarkers_Settings_Global"
addon.savedVarsPerCharName = "SAdFriendlyMarkers_Settings_Char"
addon.compartmentFuncName = "SAdFriendlyMarkers_Compartment_Func"

addon.vars = {}
addon.vars.iconSize = 40
addon.vars.highlightSize = 55
addon.vars.borderSize = 64
addon.vars.classIconPath = "Interface/GLUES/CHARACTERCREATE/UI-CHARACTERCREATE-CLASSES"
addon.vars.unsupportedZones = { "dungeon", "raid" }
addon.vars.throttleTime = 0.1
addon.vars.updateDelay = 0.1
addon.vars.defaultVerticalOffset = 40
addon.vars.nameplateSizeOffset = 0
addon.vars.nameplateSizeOffsetMultiplier = 10
addon.vars.nameplateUpdateTimes = {}
addon.vars.markers = {
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

function addon:Initialize()
    self.sadCore.version = "1.0"
    self.author = "Rôkk-Wyrmrest Accord"

    local markerOptions = {}
    table.insert(markerOptions, { value = "classIcon", label = "markerStyleClassIcon" })
    
    local markerData = {}
    for markerKey in pairs(self.vars.markers) do
        local labelKey = "markerStyle" .. markerKey:sub(1,1):upper() .. markerKey:sub(2)
        local localizedLabel = self:L(labelKey)
        if localizedLabel:match("^%[.*%]$") then
            localizedLabel = markerKey
        end
        table.insert(markerData, { key = markerKey, labelKey = labelKey, label = localizedLabel })
    end
    
    table.sort(markerData, function(a, b)
        return a.label < b.label
    end)
    
    for _, data in ipairs(markerData) do
        table.insert(markerOptions, {
            value = data.key,
            label = data.labelKey,
            onValueChange = function() addon:RefreshAllNameplates() end
        })
    end

    self.sadCore.panels.markerStyle = {
        title = "markerStyle",
        controls = {{
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
        }
    }

    local enableZoneControls = {}
    for _, zoneName in ipairs(self.zones) do
        local isUnsupported = false
        for _, unsupportedZone in ipairs(self.vars.unsupportedZones) do
            if zoneName == unsupportedZone then
                isUnsupported = true
                break
            end
        end
        
        if isUnsupported then
            table.insert(enableZoneControls, {
                type = "description",
                name = zoneName .. "NotSupported"
            })
        else
            local controlName = "enabledIn" .. zoneName:sub(1,1):upper() .. zoneName:sub(2)
            table.insert(enableZoneControls, {
                type = "checkbox",
                name = controlName,
                default = true,
                persistent = true,
                onValueChange = function() addon:ApplyFriendlyMarkersForZone() end
            })
        end
    end

    self.sadCore.panels.zones = {
        title = "enableInZoneTitle",
        controls = enableZoneControls
    }

   
    self:Debug("Performing initial nameplate refresh")
    self:RefreshAllNameplates()
    self:Debug("Initialize complete")

    -- Event registrations moved to end of Initialize
    self:Debug("Registering NAME_PLATE_UNIT_ADDED event")
    self:RegisterEvent("NAME_PLATE_UNIT_ADDED", function(event, unit)
        self.Debug(self, "NAME_PLATE_UNIT_ADDED fired for unit: " .. tostring(unit))
        local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
        if nameplate and nameplate.UnitFrame then
            self.UpdateFriendlyMarker(self, nameplate, nameplate.UnitFrame)
        end
    end)
    
    self:Debug("Hooking CompactUnitFrame_UpdateName")
    hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
        if frame:IsForbidden() then return end
        
        if frame.unit and string.find(frame.unit, "nameplate") then
            self.Debug(self, "CompactUnitFrame_UpdateName hook fired for: " .. tostring(frame.unit))
            local nameplate = frame:GetParent()
            if nameplate then
                self.UpdateFriendlyMarker(self, nameplate, frame)
            end
        end
    end)

    local initialNameplateSize = GetCVar("nameplateSize") or "1"
    self.vars.nameplateSizeOffset = tonumber(initialNameplateSize) * self.vars.nameplateSizeOffsetMultiplier
    self:Debug(string.format("Initial nameplate size offset: %s (from nameplateSize=%s)", tostring(self.vars.nameplateSizeOffset), initialNameplateSize))

    self:Debug("Registering CVAR_UPDATE event for nameplate size changes")
    local nameplateUpdateTimer = nil
    self:RegisterEvent("CVAR_UPDATE", function(event, cvarName)
        if cvarName == "nameplateSize" then
            local value = GetCVar(cvarName)
            self.Debug(self, string.format("Nameplate size CVAR changed: %s = %s", cvarName, tostring(value)))
            self.vars.nameplateSizeOffset = tonumber(value) * self.vars.nameplateSizeOffsetMultiplier
            
            if nameplateUpdateTimer then
                nameplateUpdateTimer:Cancel()
            end
            
            nameplateUpdateTimer = C_Timer.NewTimer(self.vars.updateDelay, function()
                self.RefreshAllNameplates(self)
                nameplateUpdateTimer = nil
            end)
        end
    end)
end

function addon:OnZoneChange(currentZone)
    self:ApplyFriendlyMarkersForZone()
end

function addon:ApplyFriendlyMarkersForZone(currentZone, forceUpdate)
    for _, unsupportedZone in ipairs(self.vars.unsupportedZones) do
        if self.currentZone == unsupportedZone then
            return
        end
    end
       
    if not self.savedVars.zones then
        self:Debug("savedVars.zones not initialized yet")
        return
    end
    
    local controlName = "enabledIn" .. self.currentZone:sub(1,1):upper() .. self.currentZone:sub(2)
    local isEnabled = self.savedVars.zones[controlName]
    
    self:Debug(string.format("Friendly markers %s for zone: %s", isEnabled and "enabled" or "disabled", self.currentZone))
    
    if isEnabled then
        addon:RefreshAllNameplates()
    else
        local nameplates = C_NamePlate.GetNamePlates()
        for _, nameplate in ipairs(nameplates) do
            addon:HideMarker(nameplate)
        end
    end
end

function addon:CreateClassIcon(nameplate)
    if nameplate.FriendlyClassIcon then
        return nameplate.FriendlyClassIcon
    end
    
    local iconFrame = CreateFrame("Frame", nil, nameplate)
    iconFrame:SetMouseClickEnabled(false)
    iconFrame:SetAlpha(1)
    iconFrame:SetIgnoreParentAlpha(true)
    iconFrame:SetSize(self.vars.iconSize, self.vars.iconSize)
    iconFrame:SetFrameStrata("HIGH")
    iconFrame:SetPoint("BOTTOM", nameplate, "BOTTOM", 0, 0)
    
    iconFrame.icon = iconFrame:CreateTexture(nil, "BORDER")
    iconFrame.icon:SetSize(self.vars.iconSize, self.vars.iconSize)
    iconFrame.icon:SetAllPoints(iconFrame)
    
    iconFrame.mask = iconFrame:CreateMaskTexture()
    iconFrame.mask:SetTexture("Interface/Masks/CircleMaskScalable")
    iconFrame.mask:SetSize(self.vars.iconSize, self.vars.iconSize)
    iconFrame.mask:SetAllPoints(iconFrame.icon)
    iconFrame.icon:AddMaskTexture(iconFrame.mask)
    
    iconFrame.border = iconFrame:CreateTexture(nil, "OVERLAY")
    iconFrame.border:SetAtlas("charactercreate-ring-metallight")
    iconFrame.border:SetSize(self.vars.borderSize, self.vars.borderSize)
    iconFrame.border:SetPoint("CENTER", iconFrame)
    
    iconFrame:Hide()
    nameplate.FriendlyClassIcon = iconFrame
    return iconFrame
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

function addon:UpdateFriendlyMarker(nameplate, unitFrame)
    local currentTime = GetTime()
    local lastUpdate = self.vars.nameplateUpdateTimes[nameplate]
    if lastUpdate and (currentTime - lastUpdate) < self.vars.throttleTime then
        return
    end
    self.vars.nameplateUpdateTimes[nameplate] = currentTime
    
    self:Debug("UpdateFriendlyMarker called for unit: " .. tostring(unitFrame.unit))
    
    local unit = unitFrame.unit
    
    if not unit or UnitIsUnit(unit, "player") then
        self:Debug("Skipping: no unit or is player")
        self:HideMarker(nameplate)
        return
    end
    
    if not UnitPlayerControlled(unit) or UnitIsEnemy("player", unit) then
        self:Debug("Skipping: not player-controlled or is enemy")
        self:HideMarker(nameplate)
        return
    end
    
    if not UnitIsPlayer(unit) then
        self:Debug("Skipping: not a player")
        self:HideMarker(nameplate)
        return
    end
    
    local _, class = UnitClass(unit)
    if not class then
        self:Debug("Skipping: no class found")
        self:HideMarker(nameplate)
        return
    end
    
    local classColor = RAID_CLASS_COLORS[class]
    if not classColor then
        self:Debug("Skipping: no class color for class: " .. tostring(class))
        self:HideMarker(nameplate)
        return
    end
    
    self:Debug("Found friendly player: class=" .. tostring(class) .. " name=" .. tostring(UnitName(unit)))
    
    local currentNameplateSize = tonumber(GetCVar("nameplateSize")) or 1
    local nameplateSizeOffset = currentNameplateSize * addon.vars.nameplateSizeOffsetMultiplier
    
    local iconScale = self.savedVars.markerStyle.markerSize / 100
    local markerStyle = self.savedVars.markerStyle.markerTexture
    local verticalOffset = self.savedVars.markerStyle.markerVerticalOffset + addon.vars.defaultVerticalOffset + nameplateSizeOffset
    local markerWidthValue = self.savedVars.markerStyle.markerWidth
    local markerWidth = 1.0 + (markerWidthValue * 0.15)
    
    self:Debug(string.format("verticalOffset=%s (user=%s + default=%s + sizeOffset=%s, nameplateSize=%s)", 
        tostring(verticalOffset), 
        tostring(self.savedVars.markerStyle.markerVerticalOffset),
        tostring(addon.vars.defaultVerticalOffset),
        tostring(nameplateSizeOffset),
        tostring(currentNameplateSize)))
    self:Debug("Settings: markerStyle=" .. tostring(markerStyle) .. " scale=" .. tostring(iconScale))
    
    if nameplate.FriendlyClassIcon then
        nameplate.FriendlyClassIcon:Hide()
    end
    if nameplate.FriendlyClassArrow then
        nameplate.FriendlyClassArrow:Hide()
    end
    
    if markerStyle == "classIcon" then
        self:Debug("Creating/updating class icon")
        local iconFrame = self:CreateClassIcon(nameplate)
        iconFrame.icon:SetTexture(self.vars.classIconPath)
        iconFrame.icon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[class]))
        iconFrame:SetSize(self.vars.iconSize * markerWidth, self.vars.iconSize)
        iconFrame.icon:SetSize(self.vars.iconSize * markerWidth, self.vars.iconSize)
        iconFrame.mask:SetSize(self.vars.iconSize * markerWidth, self.vars.iconSize)
        iconFrame.border:SetSize(self.vars.borderSize * markerWidth, self.vars.borderSize)
        iconFrame.border:SetDesaturated(true)
        iconFrame.border:SetVertexColor(classColor.r, classColor.g, classColor.b)
        iconFrame:SetScale(iconScale)
        iconFrame:ClearAllPoints()
        iconFrame:SetPoint("BOTTOM", nameplate, "BOTTOM", 0, verticalOffset)
        
        self:Debug("Showing icon frame")
        iconFrame:Show()

    else
        local styleInfo = self.vars.markers[markerStyle]
        if styleInfo then
            self:Debug("Creating/updating arrow marker: " .. markerStyle)
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
            
            self:Debug("Showing arrow frame")
            arrowFrame:Show()
        else
            self:Debug("Unknown marker style: " .. tostring(markerStyle))
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
end

function addon:RefreshAllNameplates()
    self:Debug("RefreshAllNameplates called")
    self:Debug("addon.savedVars.markerStyle.markerTexture: " .. tostring(self.savedVars.markerStyle and self.savedVars.markerStyle.markerTexture or "not set"))
    local nameplates = C_NamePlate.GetNamePlates()
    for _, nameplate in ipairs(nameplates) do
        if nameplate.UnitFrame then
            self:UpdateFriendlyMarker(nameplate, nameplate.UnitFrame)
        end
    end
end

function addon:ToggleFriendlyMarkers(enabled)
    if enabled then
        self:RefreshAllNameplates()
    else
        local nameplates = C_NamePlate.GetNamePlates()
        for _, nameplate in ipairs(nameplates) do
            self:HideMarker(nameplate)
        end
    end
end
