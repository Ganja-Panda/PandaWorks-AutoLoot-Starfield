ScriptName PWAL:Daemon Extends ScriptObject

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.00
; Created: 05-17-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: Daemon
; Type: System / CGF Hotkey Bridge
; Purpose:
;   Provides public CallGlobalFunction entry points for PWAL
;   hotkeys, console command runners, bat files, and external
;   command bindings.
;
; Responsibilities:
;   - Expose stable global CGF command names
;   - Forward terminal open commands to backend services
;   - Forward looting/logging toggle commands to backend services
;   - Forward inventory open commands to backend services
;   - Forward transfer commands to backend services
;   - Preserve legacy Lazy Panda-style command aliases where useful
;   - Keep hotkey-facing command names clean and stable
;
; Non-Responsibilities:
;   - No direct inventory opening logic
;   - No direct item transfer logic
;   - No terminal token handling
;   - No loot scanning
;   - No loot processing
;   - No loot validation
;   - No destination resolving
;   - No install/update logic
;   - No runtime state management
; ==============================================================



; ==============================================================
; Terminal / Toggles
; ==============================================================

Function OpenTerminal() Global
	PWAL:System:CommandServicesScript.GetScript().OpenTerminal()
EndFunction

Function ToggleLooting() Global
	PWAL:System:CommandServicesScript.GetScript().ToggleLooting()
EndFunction

Function ToggleLogging() Global
	PWAL:System:CommandServicesScript.GetScript().ToggleLogging()
EndFunction


; ==============================================================
; Inventories
; ==============================================================

Function OpenPandaWorks() Global
	PWAL:System:CommandServicesScript.GetScript().OpenPandaWorks()
EndFunction

Function OpenLodgeSafe() Global
	PWAL:System:CommandServicesScript.GetScript().OpenLodgeSafe()
EndFunction

Function OpenShipCargo() Global
	PWAL:System:CommandServicesScript.GetScript().OpenShipCargo()
EndFunction


; ==============================================================
; Transfers
; ==============================================================

Function SendPandaWorksToShip() Global
	PWAL:System:CommandServicesScript.GetScript().SendPandaWorksToShip()
EndFunction

Function SendResourcesToShip() Global
	PWAL:System:CommandServicesScript.GetScript().SendResourcesToShip()
EndFunction

Function SendPandaWorksToLodge() Global
	PWAL:System:CommandServicesScript.GetScript().SendPandaWorksToLodge()
EndFunction

Function SendValuablesToPlayer() Global
	PWAL:System:CommandServicesScript.GetScript().SendValuablesToPlayer()
EndFunction

Function SendCargoHoldToPandaWorks() Global
	PWAL:System:CommandServicesScript.GetScript().SendCargoHoldToPandaWorks()
EndFunction


; ==============================================================
; Legacy / Lazy Panda Compatibility Aliases
; ==============================================================

Function OpenHoldingInventory() Global
	PWAL:System:CommandServicesScript.GetScript().OpenPandaWorks()
EndFunction

Function MoveAllToShip() Global
	PWAL:System:CommandServicesScript.GetScript().SendPandaWorksToShip()
EndFunction

Function MoveResourcesToShip() Global
	PWAL:System:CommandServicesScript.GetScript().SendResourcesToShip()
EndFunction

Function MoveInventoryToLodgeSafe() Global
	PWAL:System:CommandServicesScript.GetScript().SendPandaWorksToLodge()
EndFunction

Function MoveValuablesToPlayer() Global
	PWAL:System:CommandServicesScript.GetScript().SendValuablesToPlayer()
EndFunction

Function MoveAllFromShipToPandaWorks() Global
	PWAL:System:CommandServicesScript.GetScript().SendCargoHoldToPandaWorks()
EndFunction