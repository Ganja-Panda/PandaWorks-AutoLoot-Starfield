ScriptName PWAL:Input:SettingsMenuScript Extends TerminalMenu Hidden

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.00
; Created: 04-10-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: SettingsMenuScript
; Type: Input / Terminal Menu Controller
; Purpose:
;   Handles PWAL named-token settings menu pages that do not use
;   the generic ToggleAll / State# FormList framework.
;
; Responsibilities:
;   - Refresh named setting tokens on menu enter
;   - Cycle internal/city/wilderness radius globals
;   - Toggle unlock, corpse, container, and stealing settings
;   - Disable hostile stealing when stealing is disabled
;   - Always provide valid On/Off or numeric replacement data
;   - Ignore unmapped menu rows safely
;
; Non-Responsibilities:
;   - No filter ToggleAll handling
;   - No destination SendAll handling
;   - No loot scanning
;   - No item movement
;   - No install/update logic
; ==============================================================

; ==============================================================
; Properties
; ==============================================================

Group FrameworkServices
	PWAL:Core:LoggerScript Property Logger Auto Const
EndGroup

Group Terminal
	TerminalMenu Property CurrentTerminalMenu Auto Const Mandatory
EndGroup

Group PageMode
	Int Property MODE_GENERAL = 1 Auto Const
	Int Property MODE_CONTAINERS_CORPSES = 2 Auto Const
	Int Property MODE_STEALING = 3 Auto Const
	Int Property iSettingsPageMode = 0 Auto Const Mandatory
EndGroup

Group DisplayMessages
	Message Property PWAL_MSG_Menu_On Auto Const Mandatory
	Message Property PWAL_MSG_Menu_Off Auto Const Mandatory
EndGroup

Group Settings_Radius_AutoFill
	GlobalVariable Property PWAL_GLOB_Settings_Radius_Internal Auto Const
	GlobalVariable Property PWAL_GLOB_Settings_Radius_City Auto Const
	GlobalVariable Property PWAL_GLOB_Settings_Radius_Wilderness Auto Const
EndGroup

Group Settings_ContainersCorpses_AutoFill
	GlobalVariable Property PWAL_GLOB_Settings_Unlock_Auto Auto Const
	GlobalVariable Property PWAL_GLOB_Settings_Unlock_SkillCheck Auto Const
	GlobalVariable Property PWAL_GLOB_Settings_Corpses_Remove Auto Const
	GlobalVariable Property PWAL_GLOB_Settings_Container_TakeAll Auto Const
	GlobalVariable Property PWAL_GLOB_Settings_Corpses_TakeAll Auto Const
EndGroup

Group Settings_Stealing_AutoFill
	GlobalVariable Property PWAL_GLOB_Settings_Stealing_Allowed Auto Const
	GlobalVariable Property PWAL_GLOB_Settings_Stealing_IsHostile Auto Const
EndGroup

Group RuntimeConfig
	Int Property RADIUS_INTERNAL_01 = 2 Auto Const
	Int Property RADIUS_INTERNAL_02 = 4 Auto Const
	Int Property RADIUS_INTERNAL_03 = 8 Auto Const

	Int Property RADIUS_CITY_01 = 8 Auto Const
	Int Property RADIUS_CITY_02 = 16 Auto Const
	Int Property RADIUS_CITY_03 = 32 Auto Const

	Int Property RADIUS_WILDERNESS_01 = 32 Auto Const
	Int Property RADIUS_WILDERNESS_02 = 64 Auto Const
	Int Property RADIUS_WILDERNESS_03 = 128 Auto Const

	Int Property VALUE_OFF = 0 Auto Const
	Int Property VALUE_ON = 1 Auto Const
EndGroup

; ==============================================================
; Events
; ==============================================================

Event OnTerminalMenuEnter(TerminalMenu akTerminalBase, ObjectReference akTerminalRef)
	If akTerminalBase != CurrentTerminalMenu
		Return
	EndIf

	LogDebug("SettingsMenu", "OnTerminalMenuEnter triggered.")
	RefreshPageTokens(akTerminalRef)
EndEvent

Event OnTerminalMenuItemRun(Int auiMenuItemID, TerminalMenu akTerminalBase, ObjectReference akTerminalRef)
	If akTerminalBase != CurrentTerminalMenu
		Return
	EndIf

	If iSettingsPageMode == MODE_GENERAL
		RunGeneralMenuItem(auiMenuItemID)
	ElseIf iSettingsPageMode == MODE_CONTAINERS_CORPSES
		RunContainersCorpsesMenuItem(auiMenuItemID)
	ElseIf iSettingsPageMode == MODE_STEALING
		RunStealingMenuItem(auiMenuItemID)
	Else
		LogWarn("SettingsMenu", "Unknown settings page mode: " + (iSettingsPageMode as String))
	EndIf

	RefreshPageTokens(akTerminalRef)
EndEvent

; ==============================================================
; Core Execution
; ==============================================================

Function RunGeneralMenuItem(Int aiMenuItemID)
	If aiMenuItemID == 0
		CycleInternalRadius()
	ElseIf aiMenuItemID == 1
		CycleCityRadius()
	ElseIf aiMenuItemID == 2
		CycleWildernessRadius()
	Else
		LogDebug("SettingsMenu", "Ignoring unmapped General menu item ID: " + (aiMenuItemID as String))
	EndIf
EndFunction

Function RunContainersCorpsesMenuItem(Int aiMenuItemID)
	If aiMenuItemID == 0
		ToggleBoolGlobal(PWAL_GLOB_Settings_Unlock_Auto, "AutoUnlock")
	ElseIf aiMenuItemID == 1
		ToggleBoolGlobal(PWAL_GLOB_Settings_Unlock_SkillCheck, "AutoUnlockSkill")
	ElseIf aiMenuItemID == 2
		ToggleBoolGlobal(PWAL_GLOB_Settings_Corpses_Remove, "Corpses")
	ElseIf aiMenuItemID == 3
		ToggleBoolGlobal(PWAL_GLOB_Settings_Container_TakeAll, "TakeAllContainer")
	ElseIf aiMenuItemID == 4
		ToggleBoolGlobal(PWAL_GLOB_Settings_Corpses_TakeAll, "TakeAllCorpse")
	Else
		LogDebug("SettingsMenu", "Ignoring unmapped Containers/Corpses menu item ID: " + (aiMenuItemID as String))
	EndIf
EndFunction

Function RunStealingMenuItem(Int aiMenuItemID)
	If aiMenuItemID == 0
		ToggleBoolGlobal(PWAL_GLOB_Settings_Stealing_Allowed, "Stealing")

		If !GetGlobalBool(PWAL_GLOB_Settings_Stealing_Allowed)
			SetBoolGlobal(PWAL_GLOB_Settings_Stealing_IsHostile, false, "Hostile")
		EndIf
	ElseIf aiMenuItemID == 1
		If GetGlobalBool(PWAL_GLOB_Settings_Stealing_Allowed)
			ToggleBoolGlobal(PWAL_GLOB_Settings_Stealing_IsHostile, "Hostile")
		Else
			SetBoolGlobal(PWAL_GLOB_Settings_Stealing_IsHostile, false, "Hostile")
			LogDebug("SettingsMenu", "Hostile stealing forced off because stealing is disabled.")
		EndIf
	Else
		LogDebug("SettingsMenu", "Ignoring unmapped Stealing menu item ID: " + (aiMenuItemID as String))
	EndIf
EndFunction

; ==============================================================
; Radius Handling
; ==============================================================

Function CycleInternalRadius()
	If PWAL_GLOB_Settings_Radius_Internal == None
		LogWarn("SettingsMenu", "CycleInternalRadius failed: radius global is None.")
		Return
	EndIf

	Int iCurrentValue = PWAL_GLOB_Settings_Radius_Internal.GetValueInt()
	Int iNewValue = GetNextInternalRadius(iCurrentValue)

	PWAL_GLOB_Settings_Radius_Internal.SetValueInt(iNewValue)

	LogDebug("SettingsMenu", "InternalRadius changed from " + (iCurrentValue as String) + " to " + (iNewValue as String))
EndFunction

Function CycleCityRadius()
	If PWAL_GLOB_Settings_Radius_City == None
		LogWarn("SettingsMenu", "CycleCityRadius failed: radius global is None.")
		Return
	EndIf

	Int iCurrentValue = PWAL_GLOB_Settings_Radius_City.GetValueInt()
	Int iNewValue = GetNextCityRadius(iCurrentValue)

	PWAL_GLOB_Settings_Radius_City.SetValueInt(iNewValue)

	LogDebug("SettingsMenu", "CityRadius changed from " + (iCurrentValue as String) + " to " + (iNewValue as String))
EndFunction

Function CycleWildernessRadius()
	If PWAL_GLOB_Settings_Radius_Wilderness == None
		LogWarn("SettingsMenu", "CycleWildernessRadius failed: radius global is None.")
		Return
	EndIf

	Int iCurrentValue = PWAL_GLOB_Settings_Radius_Wilderness.GetValueInt()
	Int iNewValue = GetNextWildernessRadius(iCurrentValue)

	PWAL_GLOB_Settings_Radius_Wilderness.SetValueInt(iNewValue)

	LogDebug("SettingsMenu", "Wilderness changed from " + (iCurrentValue as String) + " to " + (iNewValue as String))
EndFunction

Int Function GetNextInternalRadius(Int aiCurrentValue)
	If aiCurrentValue < RADIUS_INTERNAL_01
		Return RADIUS_INTERNAL_01
	ElseIf aiCurrentValue == RADIUS_INTERNAL_01
		Return RADIUS_INTERNAL_02
	ElseIf aiCurrentValue == RADIUS_INTERNAL_02
		Return RADIUS_INTERNAL_03
	EndIf

	Return RADIUS_INTERNAL_01
EndFunction

Int Function GetNextCityRadius(Int aiCurrentValue)
	If aiCurrentValue < RADIUS_CITY_01
		Return RADIUS_CITY_01
	ElseIf aiCurrentValue == RADIUS_CITY_01
		Return RADIUS_CITY_02
	ElseIf aiCurrentValue == RADIUS_CITY_02
		Return RADIUS_CITY_03
	EndIf

	Return RADIUS_CITY_01
EndFunction

Int Function GetNextWildernessRadius(Int aiCurrentValue)
	If aiCurrentValue < RADIUS_WILDERNESS_01
		Return RADIUS_WILDERNESS_01
	ElseIf aiCurrentValue == RADIUS_WILDERNESS_01
		Return RADIUS_WILDERNESS_02
	ElseIf aiCurrentValue == RADIUS_WILDERNESS_02
		Return RADIUS_WILDERNESS_03
	EndIf

	Return RADIUS_WILDERNESS_01
EndFunction

; ==============================================================
; Token Display
; ==============================================================

Function RefreshPageTokens(ObjectReference akTerminalRef)
	If akTerminalRef == None
		LogWarn("SettingsMenu", "RefreshPageTokens failed: terminal ref is None.")
		Return
	EndIf

	If iSettingsPageMode == MODE_GENERAL
		RefreshGeneralTokens(akTerminalRef)
	ElseIf iSettingsPageMode == MODE_CONTAINERS_CORPSES
		RefreshContainersCorpsesTokens(akTerminalRef)
	ElseIf iSettingsPageMode == MODE_STEALING
		RefreshStealingTokens(akTerminalRef)
	Else
		LogWarn("SettingsMenu", "RefreshPageTokens failed: unknown settings page mode: " + (iSettingsPageMode as String))
	EndIf
EndFunction

Function RefreshGeneralTokens(ObjectReference akTerminalRef)
	RefreshRadiusToken(akTerminalRef, "InternalRadius", PWAL_GLOB_Settings_Radius_Internal)
	RefreshRadiusToken(akTerminalRef, "CityRadius", PWAL_GLOB_Settings_Radius_City)
	RefreshRadiusToken(akTerminalRef, "WildernessRadius", PWAL_GLOB_Settings_Radius_Wilderness)
EndFunction

Function RefreshContainersCorpsesTokens(ObjectReference akTerminalRef)
	RefreshBoolToken(akTerminalRef, "AutoUnlock", PWAL_GLOB_Settings_Unlock_Auto)
	RefreshBoolToken(akTerminalRef, "AutoUnlockSkill", PWAL_GLOB_Settings_Unlock_SkillCheck)
	RefreshBoolToken(akTerminalRef, "Corpses", PWAL_GLOB_Settings_Corpses_Remove)
	RefreshBoolToken(akTerminalRef, "TakeAllContainer", PWAL_GLOB_Settings_Container_TakeAll)
	RefreshBoolToken(akTerminalRef, "TakeAllCorpse", PWAL_GLOB_Settings_Corpses_TakeAll)
EndFunction

Function RefreshStealingTokens(ObjectReference akTerminalRef)
	RefreshBoolToken(akTerminalRef, "Stealing", PWAL_GLOB_Settings_Stealing_Allowed)
	RefreshBoolToken(akTerminalRef, "Hostile", PWAL_GLOB_Settings_Stealing_IsHostile)
EndFunction

Function RefreshRadiusToken(ObjectReference akTerminalRef, String asTokenName, GlobalVariable akRadiusGlobal)
	If akTerminalRef == None
		Return
	EndIf

	If akRadiusGlobal == None
		LogWarn("SettingsMenu", "RefreshRadiusToken skipped: " + asTokenName + " global is None.")
		Return
	EndIf

	akTerminalRef.AddTextReplacementValue(asTokenName, akRadiusGlobal.GetValue())
	LogDebug("SettingsMenu", "Radius token refreshed: " + asTokenName)
EndFunction

Function RefreshBoolToken(ObjectReference akTerminalRef, String asTokenName, GlobalVariable akSettingGlobal)
	If akTerminalRef == None
		Return
	EndIf

	If akSettingGlobal == None
		LogWarn("SettingsMenu", "RefreshBoolToken skipped: " + asTokenName + " global is None.")
		Return
	EndIf

	Message akReplacementMessage = PWAL_MSG_Menu_Off

	If akSettingGlobal.GetValueInt() > 0
		akReplacementMessage = PWAL_MSG_Menu_On
	EndIf

	akTerminalRef.AddTextReplacementData(asTokenName, akReplacementMessage as Form)
	LogDebug("SettingsMenu", "Bool token refreshed: " + asTokenName)
EndFunction

; ==============================================================
; Setting Helpers
; ==============================================================

Int Function ToggleBoolGlobal(GlobalVariable akGlobal, String asLabel)
	If akGlobal == None
		LogWarn("SettingsMenu", "ToggleBoolGlobal failed: " + asLabel + " global is None.")
		Return VALUE_OFF
	EndIf

	Int iNewValue = VALUE_ON

	If akGlobal.GetValueInt() > 0
		iNewValue = VALUE_OFF
	EndIf

	akGlobal.SetValueInt(iNewValue)

	LogDebug("SettingsMenu", asLabel + " changed to " + (iNewValue as String))

	Return iNewValue
EndFunction

Function SetBoolGlobal(GlobalVariable akGlobal, Bool abValue, String asLabel)
	If akGlobal == None
		LogWarn("SettingsMenu", "SetBoolGlobal failed: " + asLabel + " global is None.")
		Return
	EndIf

	If abValue
		akGlobal.SetValueInt(VALUE_ON)
	Else
		akGlobal.SetValueInt(VALUE_OFF)
	EndIf

	LogDebug("SettingsMenu", asLabel + " forced to " + (abValue as String))
EndFunction

Bool Function GetGlobalBool(GlobalVariable akGlobal)
	If akGlobal == None
		Return false
	EndIf

	Return akGlobal.GetValueInt() > 0
EndFunction

; ==============================================================
; Internal Logging Wrappers
; ==============================================================

Function LogInfo(String asSource, String asMessage)
	If Logger
		Logger.Info(asSource, asMessage)
	Else
		Debug.Trace("[PWAL][INFO][" + asSource + "] " + asMessage)
	EndIf
EndFunction

Function LogWarn(String asSource, String asMessage)
	If Logger
		Logger.Warn(asSource, asMessage)
	Else
		Debug.Trace("[PWAL][WARN][" + asSource + "] " + asMessage)
	EndIf
EndFunction

Function LogError(String asSource, String asMessage)
	If Logger
		Logger.Error(asSource, asMessage)
	Else
		Debug.Trace("[PWAL][ERROR][" + asSource + "] " + asMessage)
	EndIf
EndFunction

Function LogDebug(String asSource, String asMessage)
	If Logger
		Logger.DebugLog(asSource, asMessage)
	Else
		Debug.Trace("[PWAL][DEBUG][" + asSource + "] " + asMessage)
	EndIf
EndFunction