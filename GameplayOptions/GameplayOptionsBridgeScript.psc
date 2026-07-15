ScriptName PWAL:GameplayOptions:GameplayOptionsBridgeScript Extends Quest Hidden

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.0.0
; Created: 07-15-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: GameplayOptionsBridgeScript
; Type: Gameplay Options / Native Settings Bridge
; Purpose:
;   Connects Starfield native Gameplay Options to existing PWAL
;   globals, ordered FormLists, and interface device references.
;
; Responsibilities:
;   - Enable or disable all normal loot categories
;   - Enable or disable all Always Loot item settings
;   - Route configurable loot categories to Player or PandaWorks
;   - Install or remove the handheld terminal
;   - Install or remove the utility device
;   - Enable or disable the PWAL looting runtime
;   - Respect FormList additions made by optional PWAL plugins
;   - Keep terminal controller globals synchronized
;
; Non-Responsibilities:
;   - No loot scanning
;   - No loot classification
;   - No destination resolution
;   - No item transfer processing
;   - No framework installation or update management
; ==============================================================

; ==============================================================
; Properties
; ==============================================================

Group FrameworkServices
	PWAL:Core:LoggerScript Property Logger Auto Const
EndGroup

Group GameplayOptions
	GameplayOption Property PWAL_GPOF_EnableAllCategories Auto Const Mandatory
	GameplayOption Property PWAL_GPOF_EnableAllAlwaysLoot Auto Const Mandatory
	GameplayOption Property PWAL_GPOF_SendLootTo Auto Const Mandatory
	GameplayOption Property PWAL_GPOF_HandheldTerminal Auto Const Mandatory
	GameplayOption Property PWAL_GPOF_UtilityDevice Auto Const Mandatory
	GameplayOption Property PWAL_GPOF_EnableLooting Auto Const Mandatory
EndGroup

Group GameplayOptionLists
	FormList Property PWAL_FLST_GPO_QuickStart_CategoryGlobals Auto Const Mandatory
	FormList Property PWAL_FLST_Menu_GLOB_AlwaysLoot Auto Const Mandatory
	FormList Property PWAL_FLST_GPO_QuickStart_DestinationGlobals Auto Const Mandatory
EndGroup

Group UtilityGlobals
	GlobalVariable Property PWAL_GLOB_Utilities_Toggle_Looting Auto Const Mandatory
EndGroup

Group InterfaceDevices
	Weapon Property PWAL_WEAP_Terminal Auto Const Mandatory
	Potion Property PWAL_POTION_Utilities_Device Auto Const Mandatory
EndGroup

Group GameplayOptionMessages
	Message Property PWAL_MSG_Looting_Enabled Auto Const
	Message Property PWAL_MSG_Looting_Disabled Auto Const
EndGroup

Group RuntimeConfig
	Int Property VALUE_DISABLED = 0 Auto Const
	Int Property VALUE_ENABLED = 1 Auto Const

	Int Property DEST_PLAYER = 1 Auto Const
	Int Property DEST_PANDAWORKS = 2 Auto Const
	Int Property DEST_PLAYER_SHIP = 3 Auto Const
	Int Property DEST_LODGE_SAFE = 4 Auto Const
EndGroup

; ==============================================================
; Events
; ==============================================================

Event OnQuestInit()
	RegisterForGameplayOptionChangedEvent()
EndEvent

Event OnGameplayOptionChanged(GameplayOption[] akChangedOptions)
	If akChangedOptions == None
		LogWarn("GameplayOptionsBridge", "OnGameplayOptionChanged received a None option array.")
	Else
		Int iIndex = 0
		Int iCount = akChangedOptions.Length

		LogDebug("GameplayOptionsBridge", "Processing changed gameplay options. Count=" + (iCount as String))

		While iIndex < iCount
			GameplayOption akChangedOption = akChangedOptions[iIndex]

			If akChangedOption == PWAL_GPOF_EnableAllCategories
				ApplyCategoryState()
			ElseIf akChangedOption == PWAL_GPOF_EnableAllAlwaysLoot
				ApplyAlwaysLootState()
			ElseIf akChangedOption == PWAL_GPOF_SendLootTo
				ApplyDestinationState()
			ElseIf akChangedOption == PWAL_GPOF_HandheldTerminal
				ApplyTerminalState()
			ElseIf akChangedOption == PWAL_GPOF_UtilityDevice
				ApplyUtilityDeviceState()
			ElseIf akChangedOption == PWAL_GPOF_EnableLooting
				ApplyLootingState()
			Else
				LogDebug("GameplayOptionsBridge", "Ignoring unrelated gameplay option at index " + (iIndex as String) + ".")
			EndIf

			iIndex += 1
		EndWhile
	EndIf

	GameplayOption.NotifyGameplayOptionUpdateFinished()
EndEvent

; ==============================================================
; Gameplay Option Handlers
; ==============================================================

Function ApplyCategoryState()
	Int iEnabledState = GetGameplayOptionBool(PWAL_GPOF_EnableAllCategories)

	LogInfo("GameplayOptionsBridge", "Applying category state=" + (iEnabledState as String))
	SetGlobalListValue(PWAL_FLST_GPO_QuickStart_CategoryGlobals, iEnabledState, "CategoryGlobals")
EndFunction

Function ApplyAlwaysLootState()
	Int iEnabledState = GetGameplayOptionBool(PWAL_GPOF_EnableAllAlwaysLoot)

	LogInfo("GameplayOptionsBridge", "Applying Always Loot state=" + (iEnabledState as String))
	SetGlobalListValue(PWAL_FLST_Menu_GLOB_AlwaysLoot, iEnabledState, "AlwaysLootGlobals")
EndFunction

Function ApplyDestinationState()
	If PWAL_GPOF_SendLootTo == None
		LogError("GameplayOptionsBridge", "ApplyDestinationState failed: PWAL_GPOF_SendLootTo property is not filled.")
		Return
	EndIf

	Int iOptionValue = PWAL_GPOF_SendLootTo.GetValue() as Int
	Int iDestination

	If iOptionValue == 0
		LogInfo("GameplayOptionsBridge", "Quick Start destination set to Default. Existing destination globals were preserved.")
		Return
	ElseIf iOptionValue == 1
		iDestination = DEST_PLAYER
	ElseIf iOptionValue == 2
		iDestination = DEST_PANDAWORKS
	ElseIf iOptionValue == 3
		iDestination = DEST_PLAYER_SHIP
	ElseIf iOptionValue == 4
		iDestination = DEST_LODGE_SAFE
	Else
		LogWarn("GameplayOptionsBridge", "ApplyDestinationState received unsupported option value=" + (iOptionValue as String))
		Return
	EndIf

	LogInfo("GameplayOptionsBridge", "Applying Quick Start destination=" + (iDestination as String))
	SetGlobalListValue(PWAL_FLST_GPO_QuickStart_DestinationGlobals, iDestination, "DestinationGlobals")
EndFunction

Function ApplyTerminalState()
	Int iEnabledState = GetGameplayOptionBool(PWAL_GPOF_HandheldTerminal)

	LogInfo("GameplayOptionsBridge", "Applying handheld terminal state=" + (iEnabledState as String))
	SetInterfaceDeviceState(PWAL_WEAP_Terminal as Form, iEnabledState, "HandheldTerminal")
EndFunction

Function ApplyUtilityDeviceState()
	Int iEnabledState = GetGameplayOptionBool(PWAL_GPOF_UtilityDevice)

	LogInfo("GameplayOptionsBridge", "Applying utility device state=" + (iEnabledState as String))
	SetInterfaceDeviceState(PWAL_POTION_Utilities_Device as Form, iEnabledState, "UtilityDevice")
EndFunction

Function ApplyLootingState()
	If PWAL_GLOB_Utilities_Toggle_Looting == None
		LogError("GameplayOptionsBridge", "ApplyLootingState failed: PWAL_GLOB_Utilities_Toggle_Looting property is not filled.")
		Return
	EndIf

	Int iEnabledState = GetGameplayOptionBool(PWAL_GPOF_EnableLooting)
	Int iCurrentState = NormalizeBoolValue(PWAL_GLOB_Utilities_Toggle_Looting.GetValueInt())

	If iCurrentState == iEnabledState
		LogDebug("GameplayOptionsBridge", "Looting state already matches requested value=" + (iEnabledState as String))
		Return
	EndIf

	PWAL_GLOB_Utilities_Toggle_Looting.SetValueInt(iEnabledState)

	If iEnabledState == VALUE_ENABLED
		ShowGameplayOptionMessage(PWAL_MSG_Looting_Enabled, "Looting enabled.")
	Else
		ShowGameplayOptionMessage(PWAL_MSG_Looting_Disabled, "Looting disabled.")
	EndIf

	LogInfo("GameplayOptionsBridge", "Looting state changed to " + (iEnabledState as String))
EndFunction

; ==============================================================
; Global List Helpers
; ==============================================================

Function SetGlobalListValue(FormList akGlobalList, Int aiValue, String asListName)
	If akGlobalList == None
		LogError("GameplayOptionsBridge", "SetGlobalListValue failed: " + asListName + " property is not filled.")
		Return
	EndIf

	Int iIndex = 0
	Int iCount = akGlobalList.GetSize()
	Int iChangedCount = 0

	If iCount <= 0
		LogWarn("GameplayOptionsBridge", "SetGlobalListValue skipped: " + asListName + " is empty.")
		Return
	EndIf

	While iIndex < iCount
		GlobalVariable akCurrentGlobal = akGlobalList.GetAt(iIndex) as GlobalVariable

		If akCurrentGlobal != None
			If akCurrentGlobal.GetValueInt() != aiValue
				akCurrentGlobal.SetValueInt(aiValue)
				iChangedCount += 1
			EndIf
		Else
			LogWarn("GameplayOptionsBridge", asListName + "[" + (iIndex as String) + "] is not a GlobalVariable.")
		EndIf

		iIndex += 1
	EndWhile

	LogInfo("GameplayOptionsBridge", asListName + " applied value=" + (aiValue as String) + ", Count=" + (iCount as String) + ", Changed=" + (iChangedCount as String))
EndFunction

; ==============================================================
; Interface Device Helpers
; ==============================================================

Function SetInterfaceDeviceState(Form akDeviceForm, Int aiEnabledState, String asDeviceName)
	LogInfo("GameplayOptionsBridge", asDeviceName + " requested state=" + (aiEnabledState as String))

	If akDeviceForm == None
		LogError("GameplayOptionsBridge", "SetInterfaceDeviceState failed: " + asDeviceName + " base form property is not filled.")
		Return
	EndIf

	Actor akPlayerActor = Game.GetPlayer()

	If akPlayerActor == None
		LogError("GameplayOptionsBridge", "SetInterfaceDeviceState failed: Game.GetPlayer() returned None.")
		Return
	EndIf

	Int iItemCount = akPlayerActor.GetItemCount(akDeviceForm)
	LogInfo("GameplayOptionsBridge", asDeviceName + " current player inventory count=" + (iItemCount as String))

	If aiEnabledState == VALUE_ENABLED
		If iItemCount <= 0
			akPlayerActor.AddItem(akDeviceForm, 1, false)
			LogInfo("GameplayOptionsBridge", asDeviceName + " added. Count=1")
		Else
			LogDebug("GameplayOptionsBridge", asDeviceName + " already present. Count=" + (iItemCount as String))
		EndIf
	Else
		If iItemCount > 0
			akPlayerActor.RemoveItem(akDeviceForm, iItemCount, false)
			LogInfo("GameplayOptionsBridge", asDeviceName + " removed. Count=" + (iItemCount as String))
		Else
			LogDebug("GameplayOptionsBridge", asDeviceName + " already absent. Count=0")
		EndIf
	EndIf
EndFunction

; ==============================================================
; Gameplay Option Helpers
; ==============================================================

Int Function GetGameplayOptionBool(GameplayOption akGameplayOption)
	If akGameplayOption == None
		LogError("GameplayOptionsBridge", "GetGameplayOptionBool failed: GameplayOption is None.")
		Return VALUE_DISABLED
	EndIf

	Return NormalizeBoolValue(akGameplayOption.GetValue() as Int)
EndFunction

Int Function NormalizeBoolValue(Int aiValue)
	If aiValue > 0
		Return VALUE_ENABLED
	EndIf

	Return VALUE_DISABLED
EndFunction

Function ShowGameplayOptionMessage(Message akMessage, String asFallbackLog)
	If akMessage != None
		akMessage.Show()
	Else
		LogWarn("GameplayOptionsBridge", asFallbackLog)
	EndIf
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
