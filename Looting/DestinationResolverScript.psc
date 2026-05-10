ScriptName PWAL:Looting:DestinationResolverScript extends Quest

; ==============================================================
; PandaWorks Studios - PandaWorks AutoLoot
; Author: Ganja Panda
; Version: 1.00
; Created: 04-10-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: DestinationResolverScript
; Type: Looting / Destination Resolution
; Purpose:
;   Resolves PWAL loot destinations from user-controlled globals.
;   Reads the default destination global and optional loot-group
;   destination override globals, then resolves the destination
;   code into a real runtime reference or void behavior.
;
; Responsibilities:
;   - Read the default destination global
;   - Read loot-group destination override globals
;   - Resolve destination codes into runtime references
;   - Detect void destination behavior
;   - Enforce hard player-only loot group rules
;
; Non-Responsibilities:
;   - No loot scanning
;   - No loot validation
;   - No transfer logic
;   - No item classification logic
;   - No destination-setting logic
; ==============================================================


; ==============================================================
; Properties
; ==============================================================

PWAL:Core:LoggerScript Property Logger Auto

; Default destination global
GlobalVariable Property PWAL_GLOB_Settings_Dest Auto

; --------------------------------------------------------------
; Loot group destination globals
;
; 0 = use default destination
; 1 = Player
; 2 = PandaWorks Inventory
; 3 = Player Ship Cargo
; 4 = Lodge Safe
; 5 = The Void
; --------------------------------------------------------------

; ALCH / Consumables
GlobalVariable Property PWAL_GLOB_Settings_Dest_ALCH_Aid Auto Const
GlobalVariable Property PWAL_GLOB_Settings_Dest_ALCH_Chems Auto Const
GlobalVariable Property PWAL_GLOB_Settings_Dest_ALCH_Drinks Auto Const
GlobalVariable Property PWAL_GLOB_Settings_Dest_ALCH_Food Auto Const

; ARMO / Armor
GlobalVariable Property PWAL_GLOB_Settings_Dest_ARMO_Apparel Auto Const
GlobalVariable Property PWAL_GLOB_Settings_Dest_ARMO_Backpacks Auto Const
GlobalVariable Property PWAL_GLOB_Settings_Dest_ARMO_Helmets Auto Const
GlobalVariable Property PWAL_GLOB_Settings_Dest_ARMO_Suits Auto Const

; BOOK / Lore
GlobalVariable Property PWAL_GLOB_Settings_Dest_BOOK_Dataslates Auto Const
GlobalVariable Property PWAL_GLOB_Settings_Dest_BOOK_Landmarks Auto Const
GlobalVariable Property PWAL_GLOB_Settings_Dest_BOOK_SkillMags Auto Const

; MISC
GlobalVariable Property PWAL_GLOB_Settings_Dest_MISC_AMMO Auto Const
GlobalVariable Property PWAL_GLOB_Settings_Dest_MISC_Contraband Auto Const
GlobalVariable Property PWAL_GLOB_Settings_Dest_MISC_CraftingItems Auto Const
GlobalVariable Property PWAL_GLOB_Settings_Dest_MISC_Currency Auto Const
GlobalVariable Property PWAL_GLOB_Settings_Dest_MISC_JunkItems Auto Const
GlobalVariable Property PWAL_GLOB_Settings_Dest_MISC_Keycards Auto Const
GlobalVariable Property PWAL_GLOB_Settings_Dest_MISC_Plushies Auto Const
GlobalVariable Property PWAL_GLOB_Settings_Dest_MISC_Snowglobes Auto Const

; RES / Inorganic
GlobalVariable Property PWAL_GLOB_Settings_Dest_RES_Inorganic_Common Auto Const
GlobalVariable Property PWAL_GLOB_Settings_Dest_RES_Inorganic_Exotic Auto Const
GlobalVariable Property PWAL_GLOB_Settings_Dest_RES_Inorganic_Rare Auto Const
GlobalVariable Property PWAL_GLOB_Settings_Dest_RES_Inorganic_Uncommon Auto Const
GlobalVariable Property PWAL_GLOB_Settings_Dest_RES_Inorganic_Unique Auto Const

; RES / Manufactured
GlobalVariable Property PWAL_GLOB_Settings_Dest_RES_Manufactured_Tier01 Auto Const
GlobalVariable Property PWAL_GLOB_Settings_Dest_RES_Manufactured_Tier02 Auto Const
GlobalVariable Property PWAL_GLOB_Settings_Dest_RES_Manufactured_Tier03 Auto Const

; RES / Organic
GlobalVariable Property PWAL_GLOB_Settings_Dest_RES_Organic_Common Auto Const
GlobalVariable Property PWAL_GLOB_Settings_Dest_RES_Organic_Exotic Auto Const
GlobalVariable Property PWAL_GLOB_Settings_Dest_RES_Organic_Legendary Auto Const
GlobalVariable Property PWAL_GLOB_Settings_Dest_RES_Organic_NonLethalHarvest Auto Const
GlobalVariable Property PWAL_GLOB_Settings_Dest_RES_Organic_Rare Auto Const
GlobalVariable Property PWAL_GLOB_Settings_Dest_RES_Organic_Uncommon Auto Const
GlobalVariable Property PWAL_GLOB_Settings_Dest_RES_Organic_Unique Auto Const

; WEAP / Weapons
GlobalVariable Property PWAL_GLOB_Settings_Dest_WEAP_Heavy Auto Const
GlobalVariable Property PWAL_GLOB_Settings_Dest_WEAP_Melee Auto Const
GlobalVariable Property PWAL_GLOB_Settings_Dest_WEAP_Pistols Auto Const
GlobalVariable Property PWAL_GLOB_Settings_Dest_WEAP_Rifles Auto Const
GlobalVariable Property PWAL_GLOB_Settings_Dest_WEAP_Shotguns Auto Const
GlobalVariable Property PWAL_GLOB_Settings_Dest_WEAP_Throwables Auto Const

; Runtime refs / aliases filled in CK
ObjectReference Property PlayerRef Auto Const
ObjectReference Property LodgeSafeRef Auto Const
ObjectReference Property PWAL_INV_REF Auto Const
ReferenceAlias Property PlayerHomeShip Auto Const


; ==============================================================
; Destination Constants
; ==============================================================

Int Property DEST_PLAYER = 1 Auto Const
Int Property DEST_PANDAWORKS = 2 Auto Const
Int Property DEST_PLAYER_SHIP = 3 Auto Const
Int Property DEST_LODGE_SAFE = 4 Auto Const
Int Property DEST_VOID = 5 Auto Const


; ==============================================================
; Loot Group Constants
;
; These are leaf-level loot groups, not broad menu categories.
; ==============================================================

Int Property LG_DEFAULT = 0 Auto Const

; ALCH
Int Property LG_ALCH_AID = 101 Auto Const
Int Property LG_ALCH_CHEMS = 102 Auto Const
Int Property LG_ALCH_DRINKS = 103 Auto Const
Int Property LG_ALCH_FOOD = 104 Auto Const

; ARMO
Int Property LG_ARMO_APPAREL = 201 Auto Const
Int Property LG_ARMO_BACKPACKS = 202 Auto Const
Int Property LG_ARMO_HELMETS = 203 Auto Const
Int Property LG_ARMO_SUITS = 204 Auto Const

; BOOK
Int Property LG_BOOK_DATASLATES = 301 Auto Const
Int Property LG_BOOK_LANDMARKS = 302 Auto Const
Int Property LG_BOOK_SKILLMAGS = 303 Auto Const

; MISC
Int Property LG_MISC_AMMO = 401 Auto Const
Int Property LG_MISC_CONTRABAND = 402 Auto Const
Int Property LG_MISC_CRAFTINGITEMS = 403 Auto Const
Int Property LG_MISC_CURRENCY = 404 Auto Const
Int Property LG_MISC_JUNKITEMS = 405 Auto Const
Int Property LG_MISC_KEYCARDS = 406 Auto Const
Int Property LG_MISC_PLUSHIES = 407 Auto Const
Int Property LG_MISC_SNOWGLOBES = 408 Auto Const

; RES / Inorganic
Int Property LG_RES_INORGANIC_COMMON = 501 Auto Const
Int Property LG_RES_INORGANIC_EXOTIC = 502 Auto Const
Int Property LG_RES_INORGANIC_RARE = 503 Auto Const
Int Property LG_RES_INORGANIC_UNCOMMON = 504 Auto Const
Int Property LG_RES_INORGANIC_UNIQUE = 505 Auto Const

; RES / Manufactured
Int Property LG_RES_MANUFACTURED_TIER01 = 601 Auto Const
Int Property LG_RES_MANUFACTURED_TIER02 = 602 Auto Const
Int Property LG_RES_MANUFACTURED_TIER03 = 603 Auto Const

; RES / Organic
Int Property LG_RES_ORGANIC_COMMON = 701 Auto Const
Int Property LG_RES_ORGANIC_EXOTIC = 702 Auto Const
Int Property LG_RES_ORGANIC_LEGENDARY = 703 Auto Const
Int Property LG_RES_ORGANIC_NONLETHALHARVEST = 704 Auto Const
Int Property LG_RES_ORGANIC_RARE = 705 Auto Const
Int Property LG_RES_ORGANIC_UNCOMMON = 706 Auto Const
Int Property LG_RES_ORGANIC_UNIQUE = 707 Auto Const

; WEAP
Int Property LG_WEAP_HEAVY = 801 Auto Const
Int Property LG_WEAP_MELEE = 802 Auto Const
Int Property LG_WEAP_PISTOLS = 803 Auto Const
Int Property LG_WEAP_RIFLES = 804 Auto Const
Int Property LG_WEAP_SHOTGUNS = 805 Auto Const
Int Property LG_WEAP_THROWABLES = 806 Auto Const


; ==============================================================
; Public API
; ==============================================================

Int Function ResolveDestinationCode(Int aiLootGroupCode = 0)
	If IsForcedPlayerLootGroup(aiLootGroupCode)
		LogDebug("DestinationResolver", "Loot group is hard-routed to player: " + aiLootGroupCode)
		Return DEST_PLAYER
	EndIf

	Int iLootGroupCode = ResolveLootGroupDestinationCode(aiLootGroupCode)

	If iLootGroupCode > 0
		LogDebug("DestinationResolver", "Using loot-group destination override code: " + iLootGroupCode)
		Return iLootGroupCode
	EndIf

	Int iDefaultCode = ResolveDefaultDestinationCode()
	LogDebug("DestinationResolver", "Using default destination code: " + iDefaultCode)
	Return iDefaultCode
EndFunction


Int Function ResolveDefaultDestinationCode()
	If PWAL_GLOB_Settings_Dest == None
		LogError("DestinationResolver", "ResolveDefaultDestinationCode failed: PWAL_GLOB_Settings_Dest property is not filled.")
		Return DEST_PLAYER
	EndIf

	Int iValue = PWAL_GLOB_Settings_Dest.GetValueInt()

	If !IsValidDestinationCode(iValue)
		LogWarn("DestinationResolver", "Default destination code is invalid. Falling back to DEST_PLAYER.")
		Return DEST_PLAYER
	EndIf

	Return iValue
EndFunction


Int Function ResolveLootGroupDestinationCode(Int aiLootGroupCode)
	GlobalVariable akLootGroupGlobal = GetLootGroupDestinationGlobal(aiLootGroupCode)

	If akLootGroupGlobal == None
		Return 0
	EndIf

	Int iValue = akLootGroupGlobal.GetValueInt()

	; Loot-group override globals should use:
	; 0 = no override, use default destination
	; 1-5 = explicit destination code
	If iValue == 0
		Return 0
	EndIf

	If !IsValidDestinationCode(iValue)
		LogWarn("DestinationResolver", "Loot-group destination code is invalid. Ignoring loot-group override.")
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

	If aiDestinationCode == DEST_PANDAWORKS
		If PWAL_INV_REF
			Return PWAL_INV_REF
		EndIf

		LogWarn("DestinationResolver", "PandaWorks destination requested, but PWAL_INV_REF property was not filled. Falling back to player.")
		If PlayerRef
			Return PlayerRef
		EndIf

		Return Game.GetPlayer()
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
		If LodgeSafeRef
			Return LodgeSafeRef
		EndIf

		LogWarn("DestinationResolver", "Lodge Safe destination requested, but LodgeSafeRef property was not filled. Falling back to player.")

		If PlayerRef
			Return PlayerRef
		EndIf

		Return Game.GetPlayer()
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


Bool Function IsForcedPlayerLootGroup(Int aiLootGroupCode)
	; These are progression / acquisition groups.
	; They should not be routeable through normal destination logic.

	If aiLootGroupCode == LG_BOOK_LANDMARKS
		Return true
	EndIf

	If aiLootGroupCode == LG_BOOK_SKILLMAGS
		Return true
	EndIf

	If aiLootGroupCode == LG_MISC_CURRENCY
		Return true
	EndIf

	If aiLootGroupCode == LG_MISC_KEYCARDS
		Return true
	EndIf

	Return false
EndFunction


GlobalVariable Function GetLootGroupDestinationGlobal(Int aiLootGroupCode)
	; ALCH
	If aiLootGroupCode == LG_ALCH_AID
		Return PWAL_GLOB_Settings_Dest_ALCH_Aid
	EndIf

	If aiLootGroupCode == LG_ALCH_CHEMS
		Return PWAL_GLOB_Settings_Dest_ALCH_Chems
	EndIf

	If aiLootGroupCode == LG_ALCH_DRINKS
		Return PWAL_GLOB_Settings_Dest_ALCH_Drinks
	EndIf

	If aiLootGroupCode == LG_ALCH_FOOD
		Return PWAL_GLOB_Settings_Dest_ALCH_Food
	EndIf

	; ARMO
	If aiLootGroupCode == LG_ARMO_APPAREL
		Return PWAL_GLOB_Settings_Dest_ARMO_Apparel
	EndIf

	If aiLootGroupCode == LG_ARMO_BACKPACKS
		Return PWAL_GLOB_Settings_Dest_ARMO_Backpacks
	EndIf

	If aiLootGroupCode == LG_ARMO_HELMETS
		Return PWAL_GLOB_Settings_Dest_ARMO_Helmets
	EndIf

	If aiLootGroupCode == LG_ARMO_SUITS
		Return PWAL_GLOB_Settings_Dest_ARMO_Suits
	EndIf

	; BOOK
	If aiLootGroupCode == LG_BOOK_DATASLATES
		Return PWAL_GLOB_Settings_Dest_BOOK_Dataslates
	EndIf

	If aiLootGroupCode == LG_BOOK_LANDMARKS
		Return PWAL_GLOB_Settings_Dest_BOOK_Landmarks
	EndIf

	If aiLootGroupCode == LG_BOOK_SKILLMAGS
		Return PWAL_GLOB_Settings_Dest_BOOK_SkillMags
	EndIf

	; MISC
	If aiLootGroupCode == LG_MISC_AMMO
		Return PWAL_GLOB_Settings_Dest_MISC_AMMO
	EndIf

	If aiLootGroupCode == LG_MISC_CONTRABAND
		Return PWAL_GLOB_Settings_Dest_MISC_Contraband
	EndIf

	If aiLootGroupCode == LG_MISC_CRAFTINGITEMS
		Return PWAL_GLOB_Settings_Dest_MISC_CraftingItems
	EndIf

	If aiLootGroupCode == LG_MISC_CURRENCY
		Return PWAL_GLOB_Settings_Dest_MISC_Currency
	EndIf

	If aiLootGroupCode == LG_MISC_JUNKITEMS
		Return PWAL_GLOB_Settings_Dest_MISC_JunkItems
	EndIf

	If aiLootGroupCode == LG_MISC_KEYCARDS
		Return PWAL_GLOB_Settings_Dest_MISC_Keycards
	EndIf

	If aiLootGroupCode == LG_MISC_PLUSHIES
		Return PWAL_GLOB_Settings_Dest_MISC_Plushies
	EndIf

	If aiLootGroupCode == LG_MISC_SNOWGLOBES
		Return PWAL_GLOB_Settings_Dest_MISC_Snowglobes
	EndIf

	; RES / Inorganic
	If aiLootGroupCode == LG_RES_INORGANIC_COMMON
		Return PWAL_GLOB_Settings_Dest_RES_Inorganic_Common
	EndIf

	If aiLootGroupCode == LG_RES_INORGANIC_EXOTIC
		Return PWAL_GLOB_Settings_Dest_RES_Inorganic_Exotic
	EndIf

	If aiLootGroupCode == LG_RES_INORGANIC_RARE
		Return PWAL_GLOB_Settings_Dest_RES_Inorganic_Rare
	EndIf

	If aiLootGroupCode == LG_RES_INORGANIC_UNCOMMON
		Return PWAL_GLOB_Settings_Dest_RES_Inorganic_Uncommon
	EndIf

	If aiLootGroupCode == LG_RES_INORGANIC_UNIQUE
		Return PWAL_GLOB_Settings_Dest_RES_Inorganic_Unique
	EndIf

	; RES / Manufactured
	If aiLootGroupCode == LG_RES_MANUFACTURED_TIER01
		Return PWAL_GLOB_Settings_Dest_RES_Manufactured_Tier01
	EndIf

	If aiLootGroupCode == LG_RES_MANUFACTURED_TIER02
		Return PWAL_GLOB_Settings_Dest_RES_Manufactured_Tier02
	EndIf

	If aiLootGroupCode == LG_RES_MANUFACTURED_TIER03
		Return PWAL_GLOB_Settings_Dest_RES_Manufactured_Tier03
	EndIf

	; RES / Organic
	If aiLootGroupCode == LG_RES_ORGANIC_COMMON
		Return PWAL_GLOB_Settings_Dest_RES_Organic_Common
	EndIf

	If aiLootGroupCode == LG_RES_ORGANIC_EXOTIC
		Return PWAL_GLOB_Settings_Dest_RES_Organic_Exotic
	EndIf

	If aiLootGroupCode == LG_RES_ORGANIC_LEGENDARY
		Return PWAL_GLOB_Settings_Dest_RES_Organic_Legendary
	EndIf

	If aiLootGroupCode == LG_RES_ORGANIC_NONLETHALHARVEST
		Return PWAL_GLOB_Settings_Dest_RES_Organic_NonLethalHarvest
	EndIf

	If aiLootGroupCode == LG_RES_ORGANIC_RARE
		Return PWAL_GLOB_Settings_Dest_RES_Organic_Rare
	EndIf

	If aiLootGroupCode == LG_RES_ORGANIC_UNCOMMON
		Return PWAL_GLOB_Settings_Dest_RES_Organic_Uncommon
	EndIf

	If aiLootGroupCode == LG_RES_ORGANIC_UNIQUE
		Return PWAL_GLOB_Settings_Dest_RES_Organic_Unique
	EndIf

	; WEAP
	If aiLootGroupCode == LG_WEAP_HEAVY
		Return PWAL_GLOB_Settings_Dest_WEAP_Heavy
	EndIf

	If aiLootGroupCode == LG_WEAP_MELEE
		Return PWAL_GLOB_Settings_Dest_WEAP_Melee
	EndIf

	If aiLootGroupCode == LG_WEAP_PISTOLS
		Return PWAL_GLOB_Settings_Dest_WEAP_Pistols
	EndIf

	If aiLootGroupCode == LG_WEAP_RIFLES
		Return PWAL_GLOB_Settings_Dest_WEAP_Rifles
	EndIf

	If aiLootGroupCode == LG_WEAP_SHOTGUNS
		Return PWAL_GLOB_Settings_Dest_WEAP_Shotguns
	EndIf

	If aiLootGroupCode == LG_WEAP_THROWABLES
		Return PWAL_GLOB_Settings_Dest_WEAP_Throwables
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