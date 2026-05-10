ScriptName PWAL:Looting:LootScannerScript Extends Quest Hidden

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.00
; Created: 04-10-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: LootScannerScript
; Type: Looting / Scanner Service
; Purpose:
;   Scans the world for loot candidates using the CK-configured
;   effect context supplied by LootEffectScript.
;
; Responsibilities:
;   - Read scan mode from LootEffectScript
;   - Scan by form type
;   - Scan by single keyword
;   - Scan by multiple keywords
;   - Return candidate references
;
; Non-Responsibilities:
;   - No validation
;   - No transfer logic
;   - No destination logic
;   - No unlock logic
; ==============================================================

; ==============================================================
; Properties
; ==============================================================

PWAL:Core:LoggerScript Property Logger Auto Const Mandatory
ObjectReference Property PlayerRef Auto Const Mandatory

; ==============================================================
; Public API
; ==============================================================

ObjectReference[] Function Scan(PWAL:Looting:LootEffectScript akEffectContext)
	FormList akLootList

	If akEffectContext == None
		LogWarn("LootScanner", "Scan aborted: akEffectContext is None.")
		Return None
	EndIf

	akLootList = akEffectContext.ActiveLootList
	If akLootList == None
		LogWarn("LootScanner", "Scan aborted: ActiveLootList is None.")
		Return None
	EndIf

	If akLootList.GetSize() <= 0
		LogDebug("LootScanner", "Scan skipped: ActiveLootList is empty.")
		Return None
	EndIf

	If akEffectContext.UsesMultipleKeywordScan()
		LogDebug("LootScanner", "Scan mode resolved: multiple keyword.")
		Return LocateLootByKeywordList(akLootList, akEffectContext)
	EndIf

	If akEffectContext.UsesKeywordScan()
		LogDebug("LootScanner", "Scan mode resolved: single keyword.")
		Return LocateLootBySingleKeyword(akLootList, akEffectContext)
	EndIf

	LogDebug("LootScanner", "Scan mode resolved: form type.")
	Return LocateLootByFormType(akLootList, akEffectContext)
EndFunction

; ==============================================================
; Scan Paths
; ==============================================================

ObjectReference[] Function LocateLootBySingleKeyword(FormList akLootList, PWAL:Looting:LootEffectScript akEffectContext)
	Keyword akKeyword
	ObjectReference[] akLootArray

	If akLootList == None || akEffectContext == None
		Return None
	EndIf

	akKeyword = akLootList.GetAt(0) as Keyword
	If akKeyword == None
		LogWarn("LootScanner", "LocateLootBySingleKeyword failed: first list entry is not a Keyword.")
		Return None
	EndIf

	akLootArray = GetPlayerRefSafe().FindAllReferencesWithKeyword(akKeyword, akEffectContext.GetRadius())

	If akLootArray != None
		LogDebug("LootScanner", "LocateLootBySingleKeyword found " + akLootArray.Length + " candidate(s).")
	EndIf

	Return akLootArray
EndFunction

ObjectReference[] Function LocateLootByKeywordList(FormList akLootList, PWAL:Looting:LootEffectScript akEffectContext)
	ObjectReference[] akAllResults
	ObjectReference[] akLootArray
	Keyword akKeyword
	Int iIndex

	If akLootList == None || akEffectContext == None
		Return None
	EndIf

	akAllResults = new ObjectReference[0]
	iIndex = 0

	While iIndex < akLootList.GetSize()
		akKeyword = akLootList.GetAt(iIndex) as Keyword

		If akKeyword != None
			akLootArray = GetPlayerRefSafe().FindAllReferencesWithKeyword(akKeyword, akEffectContext.GetRadius())

			If akLootArray != None && akLootArray.Length > 0
				akAllResults = AppendUniqueLootArray(akAllResults, akLootArray)
			EndIf
		Else
			LogWarn("LootScanner", "LocateLootByKeywordList skipped invalid keyword at index " + iIndex)
		EndIf

		iIndex += 1
	EndWhile

	If akAllResults != None
		LogDebug("LootScanner", "LocateLootByKeywordList found " + akAllResults.Length + " total candidate(s).")
	EndIf

	Return akAllResults
EndFunction

ObjectReference[] Function LocateLootByFormType(FormList akLootList, PWAL:Looting:LootEffectScript akEffectContext)
	Form akScanForm
	ObjectReference[] akLootArray

	If akLootList == None || akEffectContext == None
		Return None
	EndIf

	akScanForm = akLootList as Form
	If akScanForm == None
		LogWarn("LootScanner", "LocateLootByFormType failed: ActiveLootList could not be cast to Form.")
		Return None
	EndIf

	akLootArray = GetPlayerRefSafe().FindAllReferencesOfType(akScanForm, akEffectContext.GetRadius())

	If akLootArray != None
		LogDebug("LootScanner", "LocateLootByFormType found " + akLootArray.Length + " candidate(s).")
	EndIf

	Return akLootArray
EndFunction

; ==============================================================
; Array Helpers
; ==============================================================

ObjectReference[] Function AppendUniqueLootArray(ObjectReference[] akBaseArray, ObjectReference[] akAppendArray)
	ObjectReference[] akMerged
	ObjectReference akCandidate
	Int iBaseLength
	Int iAppendIndex
	Int iWriteIndex

	If akAppendArray == None || akAppendArray.Length <= 0
		Return akBaseArray
	EndIf

	If akBaseArray == None
		akBaseArray = new ObjectReference[0]
	EndIf

	akMerged = akBaseArray
	iAppendIndex = 0

	While iAppendIndex < akAppendArray.Length
		akCandidate = akAppendArray[iAppendIndex]

		If akCandidate != None
			If akCandidate != GetPlayerRefSafe()
				If !ArrayContainsRef(akMerged, akCandidate)
					iBaseLength = akMerged.Length
					akMerged = ResizeRefArray(akMerged, iBaseLength + 1)
					akMerged[iBaseLength] = akCandidate
				EndIf
			EndIf
		EndIf

		iAppendIndex += 1
	EndWhile

	Return akMerged
EndFunction

Bool Function ArrayContainsRef(ObjectReference[] akArray, ObjectReference akRef)
	Int iIndex

	If akArray == None || akRef == None
		Return false
	EndIf

	iIndex = 0
	While iIndex < akArray.Length
		If akArray[iIndex] == akRef
			Return true
		EndIf
		iIndex += 1
	EndWhile

	Return false
EndFunction

ObjectReference[] Function ResizeRefArray(ObjectReference[] akArray, Int aiNewSize)
	ObjectReference[] akNewArray
	Int iIndex
	Int iOldSize

	If aiNewSize < 0
		aiNewSize = 0
	EndIf

	akNewArray = new ObjectReference[aiNewSize]

	If akArray == None
		Return akNewArray
	EndIf

	iOldSize = akArray.Length
	If iOldSize > aiNewSize
		iOldSize = aiNewSize
	EndIf

	iIndex = 0
	While iIndex < iOldSize
		akNewArray[iIndex] = akArray[iIndex]
		iIndex += 1
	EndWhile

	Return akNewArray
EndFunction

; ==============================================================
; Utility Helpers
; ==============================================================

ObjectReference Function GetPlayerRefSafe()
	If PlayerRef != None
		Return PlayerRef
	EndIf

	Return Game.GetPlayer()
EndFunction

; ==============================================================
; Internal Logging Wrappers
; ==============================================================

Function LogWarn(String asSource, String asMessage)
	If Logger
		Logger.Warn(asSource, asMessage)
	Else
		Debug.Trace("[PWAL][WARN][" + asSource + "] " + asMessage)
	EndIf
EndFunction

Function LogDebug(String asSource, String asMessage)
	If Logger
		Logger.DebugLog(asSource, asMessage)
	Else
		Debug.Trace("[PWAL][DEBUG][" + asSource + "] " + asMessage)
	EndIf
EndFunction