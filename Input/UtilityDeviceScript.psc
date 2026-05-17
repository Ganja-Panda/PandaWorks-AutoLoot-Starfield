ScriptName PWAL:Input:UtilityDeviceScript Extends ActiveMagicEffect

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.00
; Created: 05-17-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: UtilityDeviceScript
; Type: Input / Aid Device Terminal Launcher
; Purpose:
;   Opens the PandaWorks Utilities terminal when the player uses
;   the PWAL utility aid item.
;
; Responsibilities:
;   - Handle utility aid item activation
;   - Activate the configured Utilities terminal reference
;   - Launch the Utilities terminal flow from the aid device
;   - Keep utility-device behavior separate from terminal page logic
;
; Non-Responsibilities:
;   - No hotkey handling
;   - No CGF command handling
;   - No inventory opening logic
;   - No transfer logic
;   - No terminal token handling
;   - No loot scanning
;   - No loot processing
;   - No loot validation
;   - No destination resolving
;   - No install/update logic
; ==============================================================


; ==============================================================
; Properties
; ==============================================================

Group FrameworkServices
	PWAL:Core:LoggerScript Property Logger Auto Const
EndGroup

Group RuntimeReferences
	ObjectReference Property PlayerRef Auto Const
	ObjectReference Property PWAL_TERM_REF_Utilities Auto Const Mandatory
EndGroup


; ==============================================================
; Events
; ==============================================================

Event OnEffectStart(ObjectReference akTarget, Actor akCaster, MagicEffect akBaseEffect, Float afMagnitude, Float afDuration)
	LogDebug("UtilityDevice", "Utility aid device used.")

	ObjectReference akActivator = PlayerRef

	If akActivator == None
		akActivator = Game.GetPlayer()
	EndIf

	If akActivator == None
		LogError("UtilityDevice", "Unable to open utility terminal: no player reference available.")
		Return
	EndIf

	If PWAL_TERM_REF_Utilities == None
		LogError("UtilityDevice", "Unable to open utility terminal: PWAL_TERM_REF_Utilities property is not filled.")
		Return
	EndIf

	PWAL_TERM_REF_Utilities.Activate(akActivator, false)
EndEvent


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