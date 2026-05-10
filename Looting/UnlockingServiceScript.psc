ScriptName PWAL:Looting:UnlockingServiceScript Extends Quest Hidden

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.00
; Created: 04-10-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: UnlockingServiceScript
; Type: Looting / Unlocking Service
; Purpose:
;   Handles container unlock decisions and unlock attempts for PWAL.
;
; Responsibilities:
;   - Determine whether a locked container may be auto-unlocked
;   - Respect auto-unlock settings
;   - Respect skill-check settings
;   - Attempt key-required / digipick-capable unlock paths
;   - Return whether container access is available
;
; Non-Responsibilities:
;   - No scanning
;   - No loot transfer
;   - No destination logic
;   - No ownership mutation
; ==============================================================

; ==============================================================
; Properties
; ==============================================================

Group FrameworkServices_AutoFill
	PWAL:Core:LoggerScript Property Logger Auto Const Mandatory
EndGroup

; ==============================================================
; Public API
; ==============================================================

Bool Function EnsureContainerAccess(ObjectReference akContainer, PWAL:Looting:LootEffectScript akEffectContext)
	If akContainer == None
		LogWarn("UnlockingService", "EnsureContainerAccess aborted: akContainer is None.")
		Return false
	EndIf

	If akEffectContext == None
		LogWarn("UnlockingService", "EnsureContainerAccess aborted: akEffectContext is None.")
		Return false
	EndIf

	If !akContainer.IsLocked()
		LogDebug("UnlockingService", "EnsureContainerAccess: container already unlocked.")
		Return true
	EndIf

	If !akEffectContext.CanAutoUnlock()
		LogDebug("UnlockingService", "EnsureContainerAccess denied: auto unlock is disabled.")
		Return false
	EndIf

	TryUnlock(akContainer, akEffectContext)

	If akContainer.IsLocked()
		LogDebug("UnlockingService", "EnsureContainerAccess failed: container remains locked.")
		Return false
	EndIf

	LogDebug("UnlockingService", "EnsureContainerAccess succeeded: container unlocked.")
	Return true
EndFunction

; ==============================================================
; Unlock Pipeline
; ==============================================================

Function TryUnlock(ObjectReference akContainer, PWAL:Looting:LootEffectScript akEffectContext)
	Bool bLockSkillCheck
	Bool bIsOwned
	Int iLockLevel
	Int iRequiresKey
	Int iInaccessible

	If akContainer == None || akEffectContext == None
		Return
	EndIf

	LogDebug("UnlockingService", "TryUnlock called with container: " + akContainer)

	bLockSkillCheck = akEffectContext.UseAutoUnlockSkillCheck()
	bIsOwned = akContainer.HasOwner()
	iLockLevel = akContainer.GetLockLevel()

	If akEffectContext.LockLevel_RequiresKey == None || akEffectContext.LockLevel_Inaccessible == None
		LogWarn("UnlockingService", "TryUnlock aborted: required lock level globals are not filled.")
		Return
	EndIf

	iRequiresKey = akEffectContext.LockLevel_RequiresKey.GetValueInt()
	iInaccessible = akEffectContext.LockLevel_Inaccessible.GetValueInt()

	If iLockLevel == iInaccessible
		HandleInaccessibleLock()
	ElseIf iLockLevel == iRequiresKey
		HandleRequiresKey(akContainer, bIsOwned, akEffectContext)
	Else
		HandleDigipickUnlock(akContainer, bIsOwned, bLockSkillCheck, akEffectContext)
	EndIf
EndFunction

Function HandleInaccessibleLock()
	LogDebug("UnlockingService", "HandleInaccessibleLock called.")
EndFunction

Function HandleRequiresKey(ObjectReference akContainer, Bool bIsOwned, PWAL:Looting:LootEffectScript akEffectContext)
	Key akKey

	If akContainer == None || akEffectContext == None
		Return
	EndIf

	LogDebug("UnlockingService", "HandleRequiresKey called with container: " + akContainer)

	akKey = akContainer.GetKey()
	If akKey == None
		LogDebug("UnlockingService", "Locked container ignored: requires key but container returned no key.")
		Return
	EndIf

	FindKey(akKey, akEffectContext)

	If akEffectContext.GetPlayerRef().GetItemCount(akKey as Form) > 0
		LogDebug("UnlockingService", "Key found.")
		akContainer.Unlock(bIsOwned)
		LogDebug("UnlockingService", "Container unlocked with key.")
	Else
		LogDebug("UnlockingService", "Locked container ignored: requires key.")
	EndIf
EndFunction

Function HandleDigipickUnlock(ObjectReference akContainer, Bool bIsOwned, Bool bLockSkillCheck, PWAL:Looting:LootEffectScript akEffectContext)
	ObjectReference akPlayerRef

	If akContainer == None || akEffectContext == None
		Return
	EndIf

	LogDebug("UnlockingService", "HandleDigipickUnlock called with container: " + akContainer)

	akPlayerRef = akEffectContext.GetPlayerRef()
	If akPlayerRef == None
		LogWarn("UnlockingService", "HandleDigipickUnlock aborted: PlayerRef is None.")
		Return
	EndIf

	If akEffectContext.Digipick == None
		LogWarn("UnlockingService", "HandleDigipickUnlock aborted: Digipick property is not filled.")
		Return
	EndIf

	If akPlayerRef.GetItemCount(akEffectContext.Digipick as Form) == 0
		FindDigipick(akEffectContext)
	EndIf

	If akPlayerRef.GetItemCount(akEffectContext.Digipick as Form) > 0
		If !bLockSkillCheck || (bLockSkillCheck && CanUnlock(akContainer, akEffectContext))
			akContainer.Unlock(bIsOwned)

			If !akContainer.IsLocked()
				Game.RewardPlayerXP(10, false)
				akPlayerRef.RemoveItem(akEffectContext.Digipick as Form, 1, false, None)
				LogDebug("UnlockingService", "Container unlocked with digipick.")
			EndIf
		Else
			LogDebug("UnlockingService", "Locked container ignored: failed skill check.")
		EndIf
	Else
		LogDebug("UnlockingService", "Locked container ignored: no digipick.")
	EndIf
EndFunction

; ==============================================================
; Search Helpers
; ==============================================================

Function FindDigipick(PWAL:Looting:LootEffectScript akEffectContext)
	ObjectReference[] akSearchLocations
	Int iIndex
	ObjectReference akPlayerRef

	If akEffectContext == None
		Return
	EndIf

	akPlayerRef = akEffectContext.GetPlayerRef()
	If akPlayerRef == None || akEffectContext.Digipick == None
		Return
	EndIf

	LogDebug("UnlockingService", "FindDigipick called.")

	akSearchLocations = new ObjectReference[2]
	akSearchLocations[0] = akEffectContext.GetPWALInventoryContainerRef()
	akSearchLocations[1] = akEffectContext.GetLodgeSafeRef()

	iIndex = 0
	While iIndex < akSearchLocations.Length
		If akSearchLocations[iIndex] != None
			If akSearchLocations[iIndex].GetItemCount(akEffectContext.Digipick as Form) > 0
				LogDebug("UnlockingService", "Digipick found in " + akSearchLocations[iIndex])
				akSearchLocations[iIndex].RemoveItem(akEffectContext.Digipick as Form, -1, true, akPlayerRef)
				Return
			EndIf
		EndIf
		iIndex += 1
	EndWhile
EndFunction

Function FindKey(Key akKey, PWAL:Looting:LootEffectScript akEffectContext)
	ObjectReference[] akSearchLocations
	Int iIndex
	ObjectReference akPlayerRef

	If akKey == None || akEffectContext == None
		Return
	EndIf

	akPlayerRef = akEffectContext.GetPlayerRef()
	If akPlayerRef == None
		Return
	EndIf

	LogDebug("UnlockingService", "FindKey called with key: " + akKey)

	akSearchLocations = new ObjectReference[2]
	akSearchLocations[0] = akEffectContext.GetPWALInventoryContainerRef()
	akSearchLocations[1] = akEffectContext.GetLodgeSafeRef()

	iIndex = 0
	While iIndex < akSearchLocations.Length
		If akSearchLocations[iIndex] != None
			If akSearchLocations[iIndex].GetItemCount(akKey as Form) > 0
				LogDebug("UnlockingService", "Key found in " + akSearchLocations[iIndex])
				akSearchLocations[iIndex].RemoveItem(akKey as Form, -1, true, akPlayerRef)
				Return
			EndIf
		EndIf
		iIndex += 1
	EndWhile
EndFunction

; ==============================================================
; Skill Check Helpers
; ==============================================================

Bool Function CanUnlock(ObjectReference akContainer, PWAL:Looting:LootEffectScript akEffectContext)
	Int iLockLevel
	Int[] aiLockLevels
	Bool[] abCanUnlock
	Int iIndex
	ObjectReference akPlayerRef

	If akContainer == None || akEffectContext == None
		Return false
	EndIf

	LogDebug("UnlockingService", "CanUnlock called with container: " + akContainer)

	akPlayerRef = akEffectContext.GetPlayerRef()
	If akPlayerRef == None
		Return false
	EndIf

	If akEffectContext.LockLevel_Novice == None || akEffectContext.LockLevel_Advanced == None || akEffectContext.LockLevel_Expert == None || akEffectContext.LockLevel_Master == None
		LogWarn("UnlockingService", "CanUnlock aborted: one or more lock level globals are not filled.")
		Return false
	EndIf

	If akEffectContext.PWAL_CNDF_LockCheck_Advanced == None || akEffectContext.PWAL_CNDF_LockCheck_Expert == None || akEffectContext.PWAL_CNDF_LockCheck_Master == None
		LogWarn("UnlockingService", "CanUnlock aborted: one or more lock condition forms are not filled.")
		Return false
	EndIf

	iLockLevel = akContainer.GetLockLevel()

	aiLockLevels = new Int[4]
	aiLockLevels[0] = akEffectContext.LockLevel_Novice.GetValueInt()
	aiLockLevels[1] = akEffectContext.LockLevel_Advanced.GetValueInt()
	aiLockLevels[2] = akEffectContext.LockLevel_Expert.GetValueInt()
	aiLockLevels[3] = akEffectContext.LockLevel_Master.GetValueInt()

	abCanUnlock = new Bool[4]
	abCanUnlock[0] = true
	abCanUnlock[1] = akEffectContext.PWAL_CNDF_LockCheck_Advanced.Istrue(akPlayerRef, None)
	abCanUnlock[2] = akEffectContext.PWAL_CNDF_LockCheck_Expert.Istrue(akPlayerRef, None)
	abCanUnlock[3] = akEffectContext.PWAL_CNDF_LockCheck_Master.Istrue(akPlayerRef, None)

	iIndex = 0
	While iIndex < aiLockLevels.Length
		If iLockLevel == aiLockLevels[iIndex]
			LogDebug("UnlockingService", "CanUnlock: " + abCanUnlock[iIndex])
			Return abCanUnlock[iIndex]
		EndIf
		iIndex += 1
	EndWhile

	LogDebug("UnlockingService", "CanUnlock: false")
	Return false
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