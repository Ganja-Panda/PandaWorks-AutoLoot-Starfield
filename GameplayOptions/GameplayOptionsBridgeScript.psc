ScriptName PWAL:GameplayOptions:GameplayOptionsBridgeScript Extends Quest Hidden

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.0.1
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
;   - Install, protect, configure, equip, or disable the Gravitic Stowage Matrix effects
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
	GameplayOption Property PWAL_GPOF_GSM Auto Const Mandatory
EndGroup

Group GraviticStowageMatrix
	Armor Property PWAL_ARMO_GraviticStowageChronomark Auto Const Mandatory
	ReferenceAlias Property PWAL_GSM_ChronomarkAlias Auto Const Mandatory

	ObjectMod Property PWAL_OMOD_GSM_Ammo_25 Auto Const Mandatory
	ObjectMod Property PWAL_OMOD_GSM_Ammo_50 Auto Const Mandatory
	ObjectMod Property PWAL_OMOD_GSM_Ammo_75 Auto Const Mandatory
	ObjectMod Property PWAL_OMOD_GSM_Ammo_Weightless Auto Const Mandatory

	ObjectMod Property PWAL_OMOD_GSM_ArmorApparel_25 Auto Const Mandatory
	ObjectMod Property PWAL_OMOD_GSM_ArmorApparel_50 Auto Const Mandatory
	ObjectMod Property PWAL_OMOD_GSM_ArmorApparel_75 Auto Const Mandatory
	ObjectMod Property PWAL_OMOD_GSM_ArmorApparel_Weightless Auto Const Mandatory

	ObjectMod Property PWAL_OMOD_GSM_BooksDataslates_25 Auto Const Mandatory
	ObjectMod Property PWAL_OMOD_GSM_BooksDataslates_50 Auto Const Mandatory
	ObjectMod Property PWAL_OMOD_GSM_BooksDataslates_75 Auto Const Mandatory
	ObjectMod Property PWAL_OMOD_GSM_BooksDataslates_Weightless Auto Const Mandatory

	ObjectMod Property PWAL_OMOD_GSM_Consumables_25 Auto Const Mandatory
	ObjectMod Property PWAL_OMOD_GSM_Consumables_50 Auto Const Mandatory
	ObjectMod Property PWAL_OMOD_GSM_Consumables_75 Auto Const Mandatory
	ObjectMod Property PWAL_OMOD_GSM_Consumables_Weightless Auto Const Mandatory

	ObjectMod Property PWAL_OMOD_GSM_JunkMisc_25 Auto Const Mandatory
	ObjectMod Property PWAL_OMOD_GSM_JunkMisc_50 Auto Const Mandatory
	ObjectMod Property PWAL_OMOD_GSM_JunkMisc_75 Auto Const Mandatory
	ObjectMod Property PWAL_OMOD_GSM_JunkMisc_Weightless Auto Const Mandatory

	ObjectMod Property PWAL_OMOD_GSM_Resources_25 Auto Const Mandatory
	ObjectMod Property PWAL_OMOD_GSM_Resources_50 Auto Const Mandatory
	ObjectMod Property PWAL_OMOD_GSM_Resources_75 Auto Const Mandatory
	ObjectMod Property PWAL_OMOD_GSM_Resources_Weightless Auto Const Mandatory

	ObjectMod Property PWAL_OMOD_GSM_Weapons_25 Auto Const Mandatory
	ObjectMod Property PWAL_OMOD_GSM_Weapons_50 Auto Const Mandatory
	ObjectMod Property PWAL_OMOD_GSM_Weapons_75 Auto Const Mandatory
	ObjectMod Property PWAL_OMOD_GSM_Weapons_Weightless Auto Const Mandatory
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
	Int Property GSM_PROFILE_25 = 1 Auto Const
	Int Property GSM_PROFILE_50 = 2 Auto Const
	Int Property GSM_PROFILE_75 = 3 Auto Const
	Int Property GSM_PROFILE_WEIGHTLESS = 4 Auto Const

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
			ElseIf akChangedOption == PWAL_GPOF_GSM
				HandleGSMOption(PWAL_GPOF_GSM.GetValue())
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

Function HandleGSMOption(Float afValue)
	Int iProfile = afValue as Int
	LogInfo("GameplayOptionsBridge", "GSM Gameplay Option changed. Value=" + (iProfile as String))

	If afValue != (iProfile as Float) || iProfile < VALUE_DISABLED || iProfile > GSM_PROFILE_WEIGHTLESS
		LogWarn("GameplayOptionsBridge", "Invalid GSM Gameplay Option value received: " + (afValue as String))
		Return
	EndIf

	If iProfile == VALUE_DISABLED
		DisableGSM()
	Else
		ApplyGSMProfile(iProfile)
	EndIf
EndFunction

Function DisableGSM()
	If PWAL_GSM_ChronomarkAlias == None
		LogError("GameplayOptionsBridge", "DisableGSM failed: PWAL_GSM_ChronomarkAlias is not filled.")
		Return
	EndIf

	ObjectReference watchRef = PWAL_GSM_ChronomarkAlias.GetRef()

	If watchRef == None
		LogDebug("GameplayOptionsBridge", "GSM is already disabled and no protected Chronomark exists.")
		Return
	EndIf

	If watchRef.GetBaseObject() != PWAL_ARMO_GraviticStowageChronomark
		LogError("GameplayOptionsBridge", "DisableGSM failed: alias contains the wrong base form.")
		Return
	ElseIf !watchRef.IsQuestItem()
		LogError("GameplayOptionsBridge", "DisableGSM failed: aliased Chronomark is not a Quest Object.")
		Return
	EndIf

	RemoveKnownGSMMods(watchRef)
	LogInfo("GameplayOptionsBridge", "GSM disabled. Protected PWAL Gravitic Chronomark preserved.")
EndFunction

Function ApplyGSMProfile(Int aiProfile)
	If !ValidateGSMProperties()
		Return
	EndIf

	Actor akPlayerActor = Game.GetPlayer()
	If akPlayerActor == None
		LogError("GameplayOptionsBridge", "ApplyGSMProfile failed: Game.GetPlayer() returned None.")
		Return
	EndIf

	ObjectReference watchRef = EnsureProtectedChronomark(akPlayerActor)
	If watchRef == None
		LogError("GameplayOptionsBridge", "ApplyGSMProfile failed: protected PWAL Gravitic Chronomark is unavailable.")
		Return
	EndIf

	RemoveKnownGSMMods(watchRef)

	Bool bProfileApplied = ApplyGSMProfileMods(watchRef, aiProfile)
	If !bProfileApplied
		RemoveKnownGSMMods(watchRef)
		LogError("GameplayOptionsBridge", "OMOD application failed. GSM profile was not equipped.")
		LogWarn("GameplayOptionsBridge", "Incomplete GSM profile was rolled back.")
		Return
	EndIf

	akPlayerActor.EquipItem(PWAL_ARMO_GraviticStowageChronomark, false, true)
	If aiProfile == GSM_PROFILE_25
		LogInfo("GameplayOptionsBridge", "25% profile applied.")
	ElseIf aiProfile == GSM_PROFILE_50
		LogInfo("GameplayOptionsBridge", "50% profile applied.")
	ElseIf aiProfile == GSM_PROFILE_75
		LogInfo("GameplayOptionsBridge", "75% profile applied.")
	Else
		LogInfo("GameplayOptionsBridge", "Weightless profile applied.")
	EndIf
EndFunction

ObjectReference Function EnsureProtectedChronomark(Actor akPlayer)
	If akPlayer == None
		LogError("GameplayOptionsBridge", "EnsureProtectedChronomark failed: player is None.")
		Return None
	ElseIf PWAL_ARMO_GraviticStowageChronomark == None
		LogError("GameplayOptionsBridge", "EnsureProtectedChronomark failed: PWAL_ARMO_GraviticStowageChronomark is not filled.")
		Return None
	ElseIf PWAL_GSM_ChronomarkAlias == None
		LogError("GameplayOptionsBridge", "EnsureProtectedChronomark failed: PWAL_GSM_ChronomarkAlias is not filled.")
		Return None
	EndIf

	ObjectReference watchRef = PWAL_GSM_ChronomarkAlias.GetRef()
	If watchRef != None
		If watchRef.GetBaseObject() != PWAL_ARMO_GraviticStowageChronomark
			LogError("GameplayOptionsBridge", "EnsureProtectedChronomark failed: alias contains the wrong base form.")
			Return None
		ElseIf !watchRef.IsQuestItem()
			LogError("GameplayOptionsBridge", "EnsureProtectedChronomark failed: aliased Chronomark is not a Quest Object.")
			Return None
		EndIf

		LogDebug("GameplayOptionsBridge", "Existing protected PWAL Gravitic Chronomark reused.")
		Return watchRef
	EndIf

	Form akChronomarkForm = PWAL_ARMO_GraviticStowageChronomark as Form
	Int iItemCount = akPlayer.GetItemCount(akChronomarkForm)
	If iItemCount <= 0
		akPlayer.AddItem(akChronomarkForm, 1, true)
		LogInfo("GameplayOptionsBridge", "PWAL Gravitic Chronomark added.")
	ElseIf iItemCount > 1
		Int iDuplicateCount = iItemCount - 1
		Int iRemovedCount = akPlayer.RemoveItem(akChronomarkForm, iDuplicateCount, true)
		LogInfo("GameplayOptionsBridge", "Duplicate PWAL Gravitic Chronomark removed before alias conversion. Count=" + (iRemovedCount as String))
	Else
		LogInfo("GameplayOptionsBridge", "Existing PWAL Gravitic Chronomark reused before alias conversion.")
	EndIf

	Int iVerifiedItemCount = akPlayer.GetItemCount(akChronomarkForm)
	If iVerifiedItemCount != 1
		LogError("GameplayOptionsBridge", "EnsureProtectedChronomark failed: expected one Chronomark before alias conversion. Count=" + (iVerifiedItemCount as String))
		Return None
	EndIf

	watchRef = akPlayer.MakeAliasedRefFromInventory(akChronomarkForm, PWAL_GSM_ChronomarkAlias)
	If watchRef == None
		LogError("GameplayOptionsBridge", "EnsureProtectedChronomark failed: MakeAliasedRefFromInventory returned None.")
		Return None
	ElseIf PWAL_GSM_ChronomarkAlias.GetRef() != watchRef
		LogError("GameplayOptionsBridge", "EnsureProtectedChronomark failed: alias does not contain the converted Chronomark reference.")
		Return None
	ElseIf watchRef.GetBaseObject() != PWAL_ARMO_GraviticStowageChronomark
		LogError("GameplayOptionsBridge", "EnsureProtectedChronomark failed: converted reference has the wrong base form.")
		Return None
	ElseIf !watchRef.IsQuestItem()
		LogError("GameplayOptionsBridge", "EnsureProtectedChronomark failed: converted Chronomark is not a Quest Object.")
		Return None
	EndIf

	LogInfo("GameplayOptionsBridge", "PWAL Gravitic Chronomark permanently protected as a Quest Object.")
	Return watchRef
EndFunction

Bool Function ApplyGSMProfileMods(ObjectReference watchRef, Int aiProfile)
	Bool bSuccess = true

	If aiProfile == GSM_PROFILE_25
		bSuccess = AttachGSMMod(watchRef, PWAL_OMOD_GSM_Ammo_25, "PWAL_OMOD_GSM_Ammo_25") && bSuccess
		bSuccess = AttachGSMMod(watchRef, PWAL_OMOD_GSM_ArmorApparel_25, "PWAL_OMOD_GSM_ArmorApparel_25") && bSuccess
		bSuccess = AttachGSMMod(watchRef, PWAL_OMOD_GSM_BooksDataslates_25, "PWAL_OMOD_GSM_BooksDataslates_25") && bSuccess
		bSuccess = AttachGSMMod(watchRef, PWAL_OMOD_GSM_Consumables_25, "PWAL_OMOD_GSM_Consumables_25") && bSuccess
		bSuccess = AttachGSMMod(watchRef, PWAL_OMOD_GSM_JunkMisc_25, "PWAL_OMOD_GSM_JunkMisc_25") && bSuccess
		bSuccess = AttachGSMMod(watchRef, PWAL_OMOD_GSM_Resources_25, "PWAL_OMOD_GSM_Resources_25") && bSuccess
		bSuccess = AttachGSMMod(watchRef, PWAL_OMOD_GSM_Weapons_25, "PWAL_OMOD_GSM_Weapons_25") && bSuccess
	ElseIf aiProfile == GSM_PROFILE_50
		bSuccess = AttachGSMMod(watchRef, PWAL_OMOD_GSM_Ammo_50, "PWAL_OMOD_GSM_Ammo_50") && bSuccess
		bSuccess = AttachGSMMod(watchRef, PWAL_OMOD_GSM_ArmorApparel_50, "PWAL_OMOD_GSM_ArmorApparel_50") && bSuccess
		bSuccess = AttachGSMMod(watchRef, PWAL_OMOD_GSM_BooksDataslates_50, "PWAL_OMOD_GSM_BooksDataslates_50") && bSuccess
		bSuccess = AttachGSMMod(watchRef, PWAL_OMOD_GSM_Consumables_50, "PWAL_OMOD_GSM_Consumables_50") && bSuccess
		bSuccess = AttachGSMMod(watchRef, PWAL_OMOD_GSM_JunkMisc_50, "PWAL_OMOD_GSM_JunkMisc_50") && bSuccess
		bSuccess = AttachGSMMod(watchRef, PWAL_OMOD_GSM_Resources_50, "PWAL_OMOD_GSM_Resources_50") && bSuccess
		bSuccess = AttachGSMMod(watchRef, PWAL_OMOD_GSM_Weapons_50, "PWAL_OMOD_GSM_Weapons_50") && bSuccess
	ElseIf aiProfile == GSM_PROFILE_75
		bSuccess = AttachGSMMod(watchRef, PWAL_OMOD_GSM_Ammo_75, "PWAL_OMOD_GSM_Ammo_75") && bSuccess
		bSuccess = AttachGSMMod(watchRef, PWAL_OMOD_GSM_ArmorApparel_75, "PWAL_OMOD_GSM_ArmorApparel_75") && bSuccess
		bSuccess = AttachGSMMod(watchRef, PWAL_OMOD_GSM_BooksDataslates_75, "PWAL_OMOD_GSM_BooksDataslates_75") && bSuccess
		bSuccess = AttachGSMMod(watchRef, PWAL_OMOD_GSM_Consumables_75, "PWAL_OMOD_GSM_Consumables_75") && bSuccess
		bSuccess = AttachGSMMod(watchRef, PWAL_OMOD_GSM_JunkMisc_75, "PWAL_OMOD_GSM_JunkMisc_75") && bSuccess
		bSuccess = AttachGSMMod(watchRef, PWAL_OMOD_GSM_Resources_75, "PWAL_OMOD_GSM_Resources_75") && bSuccess
		bSuccess = AttachGSMMod(watchRef, PWAL_OMOD_GSM_Weapons_75, "PWAL_OMOD_GSM_Weapons_75") && bSuccess
	Else
		bSuccess = AttachGSMMod(watchRef, PWAL_OMOD_GSM_Ammo_Weightless, "PWAL_OMOD_GSM_Ammo_Weightless") && bSuccess
		bSuccess = AttachGSMMod(watchRef, PWAL_OMOD_GSM_ArmorApparel_Weightless, "PWAL_OMOD_GSM_ArmorApparel_Weightless") && bSuccess
		bSuccess = AttachGSMMod(watchRef, PWAL_OMOD_GSM_BooksDataslates_Weightless, "PWAL_OMOD_GSM_BooksDataslates_Weightless") && bSuccess
		bSuccess = AttachGSMMod(watchRef, PWAL_OMOD_GSM_Consumables_Weightless, "PWAL_OMOD_GSM_Consumables_Weightless") && bSuccess
		bSuccess = AttachGSMMod(watchRef, PWAL_OMOD_GSM_JunkMisc_Weightless, "PWAL_OMOD_GSM_JunkMisc_Weightless") && bSuccess
		bSuccess = AttachGSMMod(watchRef, PWAL_OMOD_GSM_Resources_Weightless, "PWAL_OMOD_GSM_Resources_Weightless") && bSuccess
		bSuccess = AttachGSMMod(watchRef, PWAL_OMOD_GSM_Weapons_Weightless, "PWAL_OMOD_GSM_Weapons_Weightless") && bSuccess
	EndIf

	Return bSuccess
EndFunction

Bool Function AttachGSMMod(ObjectReference watchRef, ObjectMod akMod, String asModName)
	If !watchRef.AttachMod(akMod)
		LogError("GameplayOptionsBridge", "OMOD application failed: " + asModName)
		Return false
	EndIf

	Return true
EndFunction

Function RemoveKnownGSMMods(ObjectReference watchRef)
	watchRef.RemoveMod(PWAL_OMOD_GSM_Ammo_25)
	watchRef.RemoveMod(PWAL_OMOD_GSM_Ammo_50)
	watchRef.RemoveMod(PWAL_OMOD_GSM_Ammo_75)
	watchRef.RemoveMod(PWAL_OMOD_GSM_Ammo_Weightless)
	watchRef.RemoveMod(PWAL_OMOD_GSM_ArmorApparel_25)
	watchRef.RemoveMod(PWAL_OMOD_GSM_ArmorApparel_50)
	watchRef.RemoveMod(PWAL_OMOD_GSM_ArmorApparel_75)
	watchRef.RemoveMod(PWAL_OMOD_GSM_ArmorApparel_Weightless)
	watchRef.RemoveMod(PWAL_OMOD_GSM_BooksDataslates_25)
	watchRef.RemoveMod(PWAL_OMOD_GSM_BooksDataslates_50)
	watchRef.RemoveMod(PWAL_OMOD_GSM_BooksDataslates_75)
	watchRef.RemoveMod(PWAL_OMOD_GSM_BooksDataslates_Weightless)
	watchRef.RemoveMod(PWAL_OMOD_GSM_Consumables_25)
	watchRef.RemoveMod(PWAL_OMOD_GSM_Consumables_50)
	watchRef.RemoveMod(PWAL_OMOD_GSM_Consumables_75)
	watchRef.RemoveMod(PWAL_OMOD_GSM_Consumables_Weightless)
	watchRef.RemoveMod(PWAL_OMOD_GSM_JunkMisc_25)
	watchRef.RemoveMod(PWAL_OMOD_GSM_JunkMisc_50)
	watchRef.RemoveMod(PWAL_OMOD_GSM_JunkMisc_75)
	watchRef.RemoveMod(PWAL_OMOD_GSM_JunkMisc_Weightless)
	watchRef.RemoveMod(PWAL_OMOD_GSM_Resources_25)
	watchRef.RemoveMod(PWAL_OMOD_GSM_Resources_50)
	watchRef.RemoveMod(PWAL_OMOD_GSM_Resources_75)
	watchRef.RemoveMod(PWAL_OMOD_GSM_Resources_Weightless)
	watchRef.RemoveMod(PWAL_OMOD_GSM_Weapons_25)
	watchRef.RemoveMod(PWAL_OMOD_GSM_Weapons_50)
	watchRef.RemoveMod(PWAL_OMOD_GSM_Weapons_75)
	watchRef.RemoveMod(PWAL_OMOD_GSM_Weapons_Weightless)
EndFunction

Bool Function ValidateGSMProperties()
	If PWAL_ARMO_GraviticStowageChronomark == None
		LogError("GameplayOptionsBridge", "ApplyGSMProfile failed: PWAL_ARMO_GraviticStowageChronomark property is not filled.")
		Return false
	ElseIf PWAL_GSM_ChronomarkAlias == None
		LogError("GameplayOptionsBridge", "ValidateGSMProperties failed: PWAL_GSM_ChronomarkAlias is not filled.")
		Return false
	EndIf

	If PWAL_OMOD_GSM_Ammo_25 == None
		LogError("GameplayOptionsBridge", "ValidateGSMProperties failed: PWAL_OMOD_GSM_Ammo_25 is not filled.")
		Return false
	ElseIf PWAL_OMOD_GSM_Ammo_50 == None
		LogError("GameplayOptionsBridge", "ValidateGSMProperties failed: PWAL_OMOD_GSM_Ammo_50 is not filled.")
		Return false
	ElseIf PWAL_OMOD_GSM_Ammo_75 == None
		LogError("GameplayOptionsBridge", "ValidateGSMProperties failed: PWAL_OMOD_GSM_Ammo_75 is not filled.")
		Return false
	ElseIf PWAL_OMOD_GSM_Ammo_Weightless == None
		LogError("GameplayOptionsBridge", "ValidateGSMProperties failed: PWAL_OMOD_GSM_Ammo_Weightless is not filled.")
		Return false
	ElseIf PWAL_OMOD_GSM_ArmorApparel_25 == None
		LogError("GameplayOptionsBridge", "ValidateGSMProperties failed: PWAL_OMOD_GSM_ArmorApparel_25 is not filled.")
		Return false
	ElseIf PWAL_OMOD_GSM_ArmorApparel_50 == None
		LogError("GameplayOptionsBridge", "ValidateGSMProperties failed: PWAL_OMOD_GSM_ArmorApparel_50 is not filled.")
		Return false
	ElseIf PWAL_OMOD_GSM_ArmorApparel_75 == None
		LogError("GameplayOptionsBridge", "ValidateGSMProperties failed: PWAL_OMOD_GSM_ArmorApparel_75 is not filled.")
		Return false
	ElseIf PWAL_OMOD_GSM_ArmorApparel_Weightless == None
		LogError("GameplayOptionsBridge", "ValidateGSMProperties failed: PWAL_OMOD_GSM_ArmorApparel_Weightless is not filled.")
		Return false
	ElseIf PWAL_OMOD_GSM_BooksDataslates_25 == None
		LogError("GameplayOptionsBridge", "ValidateGSMProperties failed: PWAL_OMOD_GSM_BooksDataslates_25 is not filled.")
		Return false
	ElseIf PWAL_OMOD_GSM_BooksDataslates_50 == None
		LogError("GameplayOptionsBridge", "ValidateGSMProperties failed: PWAL_OMOD_GSM_BooksDataslates_50 is not filled.")
		Return false
	ElseIf PWAL_OMOD_GSM_BooksDataslates_75 == None
		LogError("GameplayOptionsBridge", "ValidateGSMProperties failed: PWAL_OMOD_GSM_BooksDataslates_75 is not filled.")
		Return false
	ElseIf PWAL_OMOD_GSM_BooksDataslates_Weightless == None
		LogError("GameplayOptionsBridge", "ValidateGSMProperties failed: PWAL_OMOD_GSM_BooksDataslates_Weightless is not filled.")
		Return false
	ElseIf PWAL_OMOD_GSM_Consumables_25 == None
		LogError("GameplayOptionsBridge", "ValidateGSMProperties failed: PWAL_OMOD_GSM_Consumables_25 is not filled.")
		Return false
	ElseIf PWAL_OMOD_GSM_Consumables_50 == None
		LogError("GameplayOptionsBridge", "ValidateGSMProperties failed: PWAL_OMOD_GSM_Consumables_50 is not filled.")
		Return false
	ElseIf PWAL_OMOD_GSM_Consumables_75 == None
		LogError("GameplayOptionsBridge", "ValidateGSMProperties failed: PWAL_OMOD_GSM_Consumables_75 is not filled.")
		Return false
	ElseIf PWAL_OMOD_GSM_Consumables_Weightless == None
		LogError("GameplayOptionsBridge", "ValidateGSMProperties failed: PWAL_OMOD_GSM_Consumables_Weightless is not filled.")
		Return false
	ElseIf PWAL_OMOD_GSM_JunkMisc_25 == None
		LogError("GameplayOptionsBridge", "ValidateGSMProperties failed: PWAL_OMOD_GSM_JunkMisc_25 is not filled.")
		Return false
	ElseIf PWAL_OMOD_GSM_JunkMisc_50 == None
		LogError("GameplayOptionsBridge", "ValidateGSMProperties failed: PWAL_OMOD_GSM_JunkMisc_50 is not filled.")
		Return false
	ElseIf PWAL_OMOD_GSM_JunkMisc_75 == None
		LogError("GameplayOptionsBridge", "ValidateGSMProperties failed: PWAL_OMOD_GSM_JunkMisc_75 is not filled.")
		Return false
	ElseIf PWAL_OMOD_GSM_JunkMisc_Weightless == None
		LogError("GameplayOptionsBridge", "ValidateGSMProperties failed: PWAL_OMOD_GSM_JunkMisc_Weightless is not filled.")
		Return false
	ElseIf PWAL_OMOD_GSM_Resources_25 == None
		LogError("GameplayOptionsBridge", "ValidateGSMProperties failed: PWAL_OMOD_GSM_Resources_25 is not filled.")
		Return false
	ElseIf PWAL_OMOD_GSM_Resources_50 == None
		LogError("GameplayOptionsBridge", "ValidateGSMProperties failed: PWAL_OMOD_GSM_Resources_50 is not filled.")
		Return false
	ElseIf PWAL_OMOD_GSM_Resources_75 == None
		LogError("GameplayOptionsBridge", "ValidateGSMProperties failed: PWAL_OMOD_GSM_Resources_75 is not filled.")
		Return false
	ElseIf PWAL_OMOD_GSM_Resources_Weightless == None
		LogError("GameplayOptionsBridge", "ValidateGSMProperties failed: PWAL_OMOD_GSM_Resources_Weightless is not filled.")
		Return false
	ElseIf PWAL_OMOD_GSM_Weapons_25 == None
		LogError("GameplayOptionsBridge", "ValidateGSMProperties failed: PWAL_OMOD_GSM_Weapons_25 is not filled.")
		Return false
	ElseIf PWAL_OMOD_GSM_Weapons_50 == None
		LogError("GameplayOptionsBridge", "ValidateGSMProperties failed: PWAL_OMOD_GSM_Weapons_50 is not filled.")
		Return false
	ElseIf PWAL_OMOD_GSM_Weapons_75 == None
		LogError("GameplayOptionsBridge", "ValidateGSMProperties failed: PWAL_OMOD_GSM_Weapons_75 is not filled.")
		Return false
	ElseIf PWAL_OMOD_GSM_Weapons_Weightless == None
		LogError("GameplayOptionsBridge", "ValidateGSMProperties failed: PWAL_OMOD_GSM_Weapons_Weightless is not filled.")
		Return false
	EndIf

	Return true
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
