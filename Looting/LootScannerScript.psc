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
PWAL:Looting:LootProcessorScript Property LootProcessor Auto Const Mandatory

; ==============================================================
; Public API
; ==============================================================

Int Function Scan(PWAL:Looting:LootEffectScript akEffectContext)
	FormList akLootList
	ObjectReference[] akLootArray

	If akEffectContext == None
		LogWarn("LootScanner", "Scan aborted: akEffectContext is None.")
		Return 0
	EndIf

	If LootProcessor == None
		LogWarn("LootScanner", "Scan aborted: LootProcessor is None.")
		Return 0
	EndIf

	akLootList = akEffectContext.ActiveLootList
	If akLootList == None
		LogWarn("LootScanner", "Scan aborted: ActiveLootList is None.")
		Return 0
	EndIf

	If akLootList.GetSize() <= 0
		LogDebug("LootScanner", "Scan skipped: ActiveLootList is empty.")
		Return 0
	EndIf

	If akEffectContext.UsesMultipleKeywordScan()
		LogDebug("LootScanner", "Scan mode resolved: multiple keyword.")
		Return LocateLootByKeywordList(akLootList, akEffectContext)
	EndIf

	If akEffectContext.UsesKeywordScan()
		LogDebug("LootScanner", "Scan mode resolved: single keyword.")
		akLootArray = LocateLootBySingleKeyword(akLootList, akEffectContext)
		Return ProcessLocatedArray(akLootArray, akEffectContext)
	EndIf

	LogDebug("LootScanner", "Scan mode resolved: form list.")
	Return LocateLootByFormList(akLootList, akEffectContext)
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

Int Function LocateLootByFormList(FormList akLootList, PWAL:Looting:LootEffectScript akEffectContext)
	ObjectReference[] akLootArray
	Form akScanForm
	Int iIndex
	Int iProcessedTotal
	Float fRadius

	If akLootList == None || akEffectContext == None
		Return 0
	EndIf

	If LootProcessor == None
		LogWarn("LootScanner", "LocateLootByFormList aborted: LootProcessor is None.")
		Return 0
	EndIf

	fRadius = akEffectContext.GetRadius()
	iIndex = 0
	iProcessedTotal = 0

	While iIndex < akLootList.GetSize()
		akScanForm = akLootList.GetAt(iIndex)

		If akScanForm != None
			akLootArray = GetPlayerRefSafe().FindAllReferencesOfType(akScanForm, fRadius)

			If akLootArray != None
				LogDebug("LootScanner", "LocateLootByFormList found " + akLootArray.Length + " candidate(s) at form index " + iIndex + " form=" + akScanForm)
			EndIf

			If akLootArray != None && akLootArray.Length > 0
				iProcessedTotal += ProcessLocatedArray(akLootArray, akEffectContext)
			EndIf
		Else
			LogWarn("LootScanner", "LocateLootByFormList skipped invalid form at index " + iIndex)
		EndIf

		iIndex += 1
	EndWhile

	Return iProcessedTotal
EndFunction

Int Function LocateLootByKeywordList(FormList akLootList, PWAL:Looting:LootEffectScript akEffectContext)
	ObjectReference[] akLootArray
	Keyword akKeyword
	Int iIndex
	Int iProcessedTotal
	Float fRadius

	If akLootList == None || akEffectContext == None
		Return 0
	EndIf

	fRadius = akEffectContext.GetRadius()
	iIndex = 0
	iProcessedTotal = 0

	While iIndex < akLootList.GetSize()
		akKeyword = akLootList.GetAt(iIndex) as Keyword

		If akKeyword != None
			akLootArray = GetPlayerRefSafe().FindAllReferencesWithKeyword(akKeyword, fRadius)

			If akLootArray != None
				LogDebug("LootScanner", "LocateLootByKeywordList found " + akLootArray.Length + " candidate(s) at keyword index " + iIndex)
			EndIf

			If akLootArray != None && akLootArray.Length > 0
				If !(akLootArray.Length == 1 && akLootArray[0] == GetPlayerRefSafe())
					iProcessedTotal += ProcessLocatedArray(akLootArray, akEffectContext)
				EndIf
			EndIf
		Else
			LogWarn("LootScanner", "LocateLootByKeywordList skipped invalid keyword at index " + iIndex)
		EndIf

		iIndex += 1
	EndWhile

	Return iProcessedTotal
EndFunction

; ==============================================================
; Utility Helpers
; ==============================================================

Int Function ProcessLocatedArray(ObjectReference[] akLootArray, PWAL:Looting:LootEffectScript akEffectContext)
	If akLootArray == None
		Return 0
	EndIf

	If akLootArray.Length <= 0
		Return 0
	EndIf

	If LootProcessor == None
		LogWarn("LootScanner", "ProcessLocatedArray aborted: LootProcessor is None.")
		Return 0
	EndIf

	Return LootProcessor.ProcessCandidates(akLootArray, akEffectContext)
EndFunction

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