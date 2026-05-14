ScriptName PWAL:System:PlayerBootstrapAliasScript Extends ReferenceAlias Hidden

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.00
; Created: 04-10-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: PlayerBootstrapAliasScript
; Type: System / Player Alias Bootstrap
; Purpose:
;   Ensures the player receives the PWAL framework perks required
;   to activate the auto-loot ability and MagicEffect chain.
;
; Responsibilities:
;   - Run player bootstrap when the Player alias initializes
;   - Run player bootstrap after loading a save
;   - Add missing PWAL framework perks from PWAL_FLST_Script_Perks
;   - Avoid duplicate perk application
;   - Log bootstrap activity through LoggerScript
;
; Non-Responsibilities:
;   - No terminal activation logic
;   - No runtime framework startup ownership
;   - No loot scanning
;   - No item transfer logic
;   - No destination routing
; ==============================================================

; ==============================================================
; Properties
; ==============================================================

Group FrameworkServices
	PWAL:Core:LoggerScript Property Logger Auto Const
EndGroup

Group Player
	Actor Property PlayerRef Auto Const Mandatory
EndGroup

Group PlayerBootstrap
	FormList Property PWAL_FLST_Script_Perks Auto Const Mandatory
EndGroup

; ==============================================================
; Events
; ==============================================================

Event OnAliasInit()
	LogInfo("PlayerBootstrap", "OnAliasInit triggered.")
	EnsurePlayerPerks("OnAliasInit")
EndEvent

Event OnPlayerLoadGame()
	LogInfo("PlayerBootstrap", "OnPlayerLoadGame triggered.")
	EnsurePlayerPerks("OnPlayerLoadGame")
EndEvent

; ==============================================================
; Player Bootstrap
; ==============================================================

Function EnsurePlayerPerks(String asReason)
	Actor akPlayerActor = PlayerRef

	LogInfo("PlayerBootstrap", "EnsurePlayerPerks requested by " + asReason + ".")

	If akPlayerActor == None
		akPlayerActor = Game.GetPlayer()
	EndIf

	If akPlayerActor == None
		LogError("PlayerBootstrap", "EnsurePlayerPerks failed: PlayerRef and Game.GetPlayer() are None.")
		Return
	EndIf

	If PWAL_FLST_Script_Perks == None
		LogError("PlayerBootstrap", "EnsurePlayerPerks failed: PWAL_FLST_Script_Perks property is not filled.")
		Return
	EndIf

	Int iIndex = 0
	Int iCount = PWAL_FLST_Script_Perks.GetSize()

	LogInfo("PlayerBootstrap", "Ensuring player perks. Count=" + (iCount as String))

	While iIndex < iCount
		Perk akCurrentPerk = PWAL_FLST_Script_Perks.GetAt(iIndex) as Perk

		If akCurrentPerk != None
			If !akPlayerActor.HasPerk(akCurrentPerk)
				akPlayerActor.AddPerk(akCurrentPerk, false)
				LogInfo("PlayerBootstrap", "Added missing perk at index " + (iIndex as String) + ".")
			Else
				LogDebug("PlayerBootstrap", "Player already has perk at index " + (iIndex as String) + ".")
			EndIf
		Else
			LogWarn("PlayerBootstrap", "Skipping None/non-perk entry at index " + (iIndex as String) + ".")
		EndIf

		iIndex += 1
	EndWhile

	LogInfo("PlayerBootstrap", "Player perk bootstrap complete.")
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