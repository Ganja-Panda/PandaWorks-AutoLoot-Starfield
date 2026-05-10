ScriptName PWAL:Looting:DestinationResolverScript extends Quest

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.00
; Created: 04-10-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: DestinationResolverScript
; Type: Looting / Destination Resolution
; Purpose:
;   Resolves PWAL loot destinations from user-controlled globals.
;   Reads the default destination global and optional category
;   destination override globals, then resolves the destination
;   code into a real runtime reference or void behavior.
;
; Responsibilities:
;   - Read the default destination global
;   - Read category destination override globals
;   - Resolve destination codes into runtime references
;   - Detect void destination behavior
;
; Non-Responsibilities:
;   - No loot scanning
;   - No loot validation
;   - No transfer logic
;   - No category classification logic
;   - No destination-setting logic
; ==============================================================

; ==============================================================
; Properties
; ==============================================================

PWAL:Core:LoggerScript Property Logger Auto

; Default destination global
GlobalVariable Property PWAL_GLOB_Settings_Destination Auto

; Category destination globals
GlobalVariable Property PWAL_GLOB_Settings_Destination_Armor Auto
GlobalVariable Property PWAL_GLOB_Settings_Destination_Consumables Auto
GlobalVariable Property PWAL_GLOB_Settings_Destination_Lore Auto
GlobalVariable Property PWAL_GLOB_Settings_Destination_Misc Auto
GlobalVariable Property PWAL_GLOB_Settings_Destination_Resources Auto
GlobalVariable Property PWAL_GLOB_Settings_Destination_Weapons Auto

; Runtime refs / aliases filled in CK
ObjectReference Property PlayerRef Auto Const
ObjectReference Property LodgeSafeRef Auto Const
ObjectReference Property PWAL_CONT_Inventory_Reference Auto Const
ReferenceAlias Property PlayerHomeShip Auto Const

; ==============================================================
; Destination Constants
; ==============================================================

Int Property DEST_PLAYER = 1 Auto Const
Int Property DEST_GANJAPANDA = 2 Auto Const
Int Property DEST_PLAYER_SHIP = 3 Auto Const
Int Property DEST_LODGE_SAFE = 4 Auto Const
Int Property DEST_VOID = 5 Auto Const

; ==============================================================
; Category Constants
; ==============================================================

Int Property CAT_DEFAULT = 0 Auto Const
Int Property CAT_ARMOR = 10 Auto Const
Int Property CAT_CONSUMABLES = 20 Auto Const
Int Property CAT_LORE = 30 Auto Const
Int Property CAT_MISC = 40 Auto Const
Int Property CAT_RESOURCES = 50 Auto Const
Int Property CAT_WEAPONS = 60 Auto Const

; ==============================================================
; Public API
; ==============================================================

Int Function ResolveDestinationCode(Int aiCategoryCode = 0)
	Int iCategoryCode = ResolveCategoryDestinationCode(aiCategoryCode)

	If iCategoryCode > 0
		LogDebug("DestinationResolver", "Using category destination override code: " + iCategoryCode)
		Return iCategoryCode
	EndIf

	Int iDefaultCode = ResolveDefaultDestinationCode()
	LogDebug("DestinationResolver", "Using default destination code: " + iDefaultCode)
	Return iDefaultCode
EndFunction

Int Function ResolveDefaultDestinationCode()
	If PWAL_GLOB_Settings_Destination == None
		LogError("DestinationResolver", "ResolveDefaultDestinationCode failed: PWAL_GLOB_Settings_Destination property is not filled.")
		Return DEST_PLAYER
	EndIf

	Int iValue = PWAL_GLOB_Settings_Destination.GetValueInt()

	If !IsValidDestinationCode(iValue)
		LogWarn("DestinationResolver", "Default destination code is invalid. Falling back to DEST_PLAYER.")
		Return DEST_PLAYER
	EndIf

	Return iValue
EndFunction

Int Function ResolveCategoryDestinationCode(Int aiCategoryCode)
	GlobalVariable akCategoryGlobal = GetCategoryDestinationGlobal(aiCategoryCode)

	If akCategoryGlobal == None
		Return 0
	EndIf

	Int iValue = akCategoryGlobal.GetValueInt()

	; Category override globals should use:
	; 0 = no override, use default destination
	; 1-5 = explicit destination code
	If iValue == 0
		Return 0
	EndIf

	If !IsValidDestinationCode(iValue)
		LogWarn("DestinationResolver", "Category destination code is invalid. Ignoring category override.")
		Return 0
	EndIf

	Return iValue
EndFunction

ObjectReference Function ResolveDestinationRef(Int aiDestinationCode)
	If aiDestinationCode == DEST_PLAYER
		If PlayerRef
			Return PlayerRef
		EndIf

		LogWarn("DestinationResolver", "Player destination requested, but PlayerRef property was not filled. Falling back to Game.GetPlayer().")
		Return Game.GetPlayer()
	EndIf

	If aiDestinationCode == DEST_GANJAPANDA
		Return PWAL_CONT_Inventory_Reference
	EndIf

	If aiDestinationCode == DEST_PLAYER_SHIP
		If PlayerHomeShip
			ObjectReference akShipRef = PlayerHomeShip.GetRef()

			If akShipRef
				Return akShipRef
			EndIf
		EndIf

		LogWarn("DestinationResolver", "Player ship destination requested, but PlayerHomeShip alias was unavailable. Falling back to player.")
		If PlayerRef
			Return PlayerRef
		EndIf

		Return Game.GetPlayer()
	EndIf

	If aiDestinationCode == DEST_LODGE_SAFE
		Return LodgeSafeRef
	EndIf

	If aiDestinationCode == DEST_VOID
		Return None
	EndIf

	LogWarn("DestinationResolver", "Unknown destination code received. Falling back to player.")
	If PlayerRef
		Return PlayerRef
	EndIf

	Return Game.GetPlayer()
EndFunction

Bool Function IsVoidDestination(Int aiDestinationCode)
	Return (aiDestinationCode == DEST_VOID)
EndFunction

; ==============================================================
; Internal Helpers
; ==============================================================

Bool Function IsValidDestinationCode(Int aiDestinationCode)
	If aiDestinationCode < DEST_PLAYER
		Return false
	EndIf

	If aiDestinationCode > DEST_VOID
		Return false
	EndIf

	Return true
EndFunction

GlobalVariable Function GetCategoryDestinationGlobal(Int aiCategoryCode)
	If aiCategoryCode == CAT_ARMOR
		Return PWAL_GLOB_Settings_Destination_Armor
	EndIf

	If aiCategoryCode == CAT_CONSUMABLES
		Return PWAL_GLOB_Settings_Destination_Consumables
	EndIf

	If aiCategoryCode == CAT_LORE
		Return PWAL_GLOB_Settings_Destination_Lore
	EndIf

	If aiCategoryCode == CAT_MISC
		Return PWAL_GLOB_Settings_Destination_Misc
	EndIf

	If aiCategoryCode == CAT_RESOURCES
		Return PWAL_GLOB_Settings_Destination_Resources
	EndIf

	If aiCategoryCode == CAT_WEAPONS
		Return PWAL_GLOB_Settings_Destination_Weapons
	EndIf

	Return None
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