ScriptName PWAL:Input:HandHeldTerminalScript Extends ReferenceAlias

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.00
; Created: 04-10-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: HandHeldTerminalScript
; Type: Input / Player Alias Utility Bridge
; Purpose:
;   Handles use/equip of the PWAL portable terminal weapon from
;   the player alias and opens the PWAL terminal interface.
;
; Responsibilities:
;   - Validate required terminal input properties
;   - Detect player equip/use of PWAL terminal control weapon
;   - Open the PWAL terminal through CommandServices
;   - Unequip the terminal control weapon after activation
;
; Non-Responsibilities:
;   - No terminal menu token handling
;   - No settings mutation
;   - No looting logic
;   - No transfer logic
;   - No install/update logic
; ==============================================================

; ==============================================================
; Properties
; ==============================================================

Group FrameworkServices
	PWAL:Core:LoggerScript Property Logger Auto Const
	PWAL:System:CommandServicesScript Property CommandServices Auto Const Mandatory
EndGroup

Group Player
	Actor Property PlayerRef Auto Const Mandatory
EndGroup

Group UtilityItems
	Weapon Property PWAL_WEAP_Terminal Auto Const Mandatory
EndGroup

Group RuntimeState
	Bool Property bTerminalInputReady = false Auto Hidden
	Int Property TIMER_ENABLE_TERMINAL_INPUT = 101 Auto Const
	Float Property fTerminalInputDelay = 5.0 Auto Const
EndGroup

; ==============================================================
; Events
; ==============================================================

Event OnAliasInit()
	LogDebug("HandHeldTerminal", "OnAliasInit triggered.")
	ValidateProperties()

	bTerminalInputReady = false
	CancelTimer(TIMER_ENABLE_TERMINAL_INPUT)
	StartTimer(fTerminalInputDelay, TIMER_ENABLE_TERMINAL_INPUT)
EndEvent

Event OnPlayerLoadGame()
	LogDebug("HandHeldTerminal", "OnPlayerLoadGame triggered.")

	bTerminalInputReady = false
	CancelTimer(TIMER_ENABLE_TERMINAL_INPUT)
	StartTimer(fTerminalInputDelay, TIMER_ENABLE_TERMINAL_INPUT)
EndEvent

Event OnTimer(Int aiTimerID)
	If aiTimerID == TIMER_ENABLE_TERMINAL_INPUT
		bTerminalInputReady = true
		LogDebug("HandHeldTerminal", "Terminal input is now ready.")
	EndIf
EndEvent

Event OnItemEquipped(Form akBaseObject, ObjectReference akReference)
	If akBaseObject == None
		Return
	EndIf

	If akBaseObject != PWAL_WEAP_Terminal as Form
		Return
	EndIf

	If !bTerminalInputReady
		LogDebug("HandHeldTerminal", "Terminal equipped before input ready. Suppressing auto-open.")

		If PlayerRef != None
			PlayerRef.UnequipItem(PWAL_WEAP_Terminal as Form, false, true)
		EndIf

		Return
	EndIf

	If !(Game.IsMenuControlsEnabled() || Game.IsFavoritesControlsEnabled())
		LogDebug("HandHeldTerminal", "Terminal equipped, but menu/favorites controls are disabled. Ignoring.")
		Return
	EndIf

	LogDebug("HandHeldTerminal", "PWAL terminal control weapon equipped; opening terminal.")

	If CommandServices == None
		LogError("HandHeldTerminal", "CommandServices property is not filled.")
		Return
	EndIf

	CommandServices.OpenTerminal()

	If PlayerRef != None
		PlayerRef.UnequipItem(PWAL_WEAP_Terminal as Form, false, true)
	EndIf
EndEvent

; ==============================================================
; Validation
; ==============================================================

Function ValidateProperties()
	If PlayerRef == None
		LogError("HandHeldTerminal", "PlayerRef property is not filled.")
	EndIf

	If PWAL_WEAP_Terminal == None
		LogError("HandHeldTerminal", "PWAL_WEAP_Terminal property is not filled.")
	EndIf

	If CommandServices == None
		LogError("HandHeldTerminal", "CommandServices property is not filled.")
	EndIf
EndFunction

; ==============================================================
; Internal Logging Wrappers
; ==============================================================

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