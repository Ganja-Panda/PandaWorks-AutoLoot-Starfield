ScriptName PWAL:System:VersionManagerScript extends Quest

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.00
; Created: 04-10-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: VersionManagerScript
; Type: System / Version Management
; Purpose:
;   Manages PWAL framework version state using the installed
;   save-bound version globals and the expected script version.
;   Detects first install, update required, current version,
;   and invalid/newer-than-script states.
;
; Responsibilities:
;   - Read installed version from PWAL version globals
;   - Define expected PWAL framework version in script
;   - Compare installed version against expected version
;   - Detect first install/update/current/newer-than-script states
;   - Coordinate migration runtime state with RuntimeManager
;   - Persist expected version back to installed globals when needed
;
; Non-Responsibilities:
;   - No install implementation
;   - No migration step implementation
;   - No looting logic
;   - No terminal/menu logic
; ==============================================================

; ==============================================================
; Properties
; ==============================================================

PWAL:Core:LoggerScript Property Logger Auto
PWAL:Core:RuntimeManagerScript Property RuntimeManager Auto

GlobalVariable Property PWAL_GLOB_Version_Major Auto
GlobalVariable Property PWAL_GLOB_Version_Minor Auto
GlobalVariable Property PWAL_GLOB_Version_Patch Auto

Int Property iExpectedVersionMajor = 1 Auto Const
Int Property iExpectedVersionMinor = 0 Auto Const
Int Property iExpectedVersionPatch = 0 Auto Const

; ==============================================================
; Version State Constants
; ==============================================================

Int Property VERSION_STATE_UNKNOWN = 0 Auto Const
Int Property VERSION_STATE_FIRST_INSTALL = 10 Auto Const
Int Property VERSION_STATE_UPDATE_REQUIRED = 20 Auto Const
Int Property VERSION_STATE_CURRENT = 30 Auto Const
Int Property VERSION_STATE_SCRIPT_OLDER_THAN_SAVE = 40 Auto Const
Int Property VERSION_STATE_INVALID = 99 Auto Const

; ==============================================================
; Cached State
; ==============================================================

Int Property iLastVersionState = 0 Auto Hidden
Bool Property bLastVersionCheckPassed = false Auto Hidden

; ==============================================================
; Public API
; ==============================================================

Bool Function HandleVersionState()
	If !CheckVersionState()
		LogError("VersionManager", "HandleVersionState failed during version check.")
		Return false
	EndIf

	If iLastVersionState == VERSION_STATE_FIRST_INSTALL
		LogInfo("VersionManager", "Version state resolved as FIRST_INSTALL.")
		Return true
	EndIf

	If iLastVersionState == VERSION_STATE_UPDATE_REQUIRED
		LogInfo("VersionManager", "Version state resolved as UPDATE_REQUIRED.")
		BeginMigration()

		; Future:
		; - Run migration/update steps here
		; - PersistExpectedVersion() on successful migration

		EndMigration()
		Return true
	EndIf

	If iLastVersionState == VERSION_STATE_CURRENT
		LogInfo("VersionManager", "Version state resolved as CURRENT.")
		Return true
	EndIf

	LogError("VersionManager", "HandleVersionState failed due to invalid version state.")
	Return false
EndFunction

Bool Function CheckVersionState()
	ResetVersionCheckState()

	If !ValidateVersionGlobals()
		iLastVersionState = VERSION_STATE_INVALID
		bLastVersionCheckPassed = false
		LogError("VersionManager", "Version state check failed: required version globals are not filled.")
		Return false
	EndIf

	LogInfo("VersionManager", "Version state check beginning.")
	LogDebug("VersionManager", "Installed version: " + BuildInstalledVersionString())
	LogDebug("VersionManager", "Expected version: " + BuildExpectedVersionString())

	If IsFirstInstall()
		iLastVersionState = VERSION_STATE_FIRST_INSTALL
		bLastVersionCheckPassed = true
		LogInfo("VersionManager", "Detected first install state.")
		Return true
	EndIf

	Int iComparison = CompareInstalledToExpected()

	If iComparison < 0
		iLastVersionState = VERSION_STATE_UPDATE_REQUIRED
		bLastVersionCheckPassed = true
		LogInfo("VersionManager", "Installed version is older than expected. Update is required.")
		Return true
	EndIf

	If iComparison == 0
		iLastVersionState = VERSION_STATE_CURRENT
		bLastVersionCheckPassed = true
		LogInfo("VersionManager", "Installed version matches expected version.")
		Return true
	EndIf

	iLastVersionState = VERSION_STATE_SCRIPT_OLDER_THAN_SAVE
	bLastVersionCheckPassed = false
	LogError("VersionManager", "Installed version is newer than the current script version.")
	Return false
EndFunction

Function PersistExpectedVersion()
	If !ValidateVersionGlobals()
		LogError("VersionManager", "PersistExpectedVersion failed: required version globals are not filled.")
		Return
	EndIf

	PWAL_GLOB_Version_Major.SetValueInt(iExpectedVersionMajor)
	PWAL_GLOB_Version_Minor.SetValueInt(iExpectedVersionMinor)
	PWAL_GLOB_Version_Patch.SetValueInt(iExpectedVersionPatch)

	LogInfo("VersionManager", "Persisted expected version to installed globals: " + BuildExpectedVersionString())
EndFunction

Function BeginMigration()
	If RuntimeManager
		RuntimeManager.SetMigrationRunning(true)
	EndIf

	LogInfo("VersionManager", "Migration runtime state entered.")
EndFunction

Function EndMigration()
	If RuntimeManager
		RuntimeManager.SetMigrationRunning(false)
	EndIf

	LogInfo("VersionManager", "Migration runtime state cleared.")
EndFunction

Bool Function IsFirstInstall()
	If GetInstalledVersionMajor() != 0
		Return false
	EndIf

	If GetInstalledVersionMinor() != 0
		Return false
	EndIf

	If GetInstalledVersionPatch() != 0
		Return false
	EndIf

	Return true
EndFunction

Bool Function IsUpdateRequired()
	Return (CompareInstalledToExpected() < 0)
EndFunction

Bool Function IsCurrent()
	Return (CompareInstalledToExpected() == 0)
EndFunction

Bool Function IsSaveNewerThanScript()
	Return (CompareInstalledToExpected() > 0)
EndFunction

Int Function GetLastVersionState()
	Return iLastVersionState
EndFunction

Bool Function GetLastVersionCheckPassed()
	Return bLastVersionCheckPassed
EndFunction

; ==============================================================
; Installed Version Accessors
; ==============================================================

Int Function GetInstalledVersionMajor()
	If PWAL_GLOB_Version_Major == None
		Return 0
	EndIf

	Return PWAL_GLOB_Version_Major.GetValueInt()
EndFunction

Int Function GetInstalledVersionMinor()
	If PWAL_GLOB_Version_Minor == None
		Return 0
	EndIf

	Return PWAL_GLOB_Version_Minor.GetValueInt()
EndFunction

Int Function GetInstalledVersionPatch()
	If PWAL_GLOB_Version_Patch == None
		Return 0
	EndIf

	Return PWAL_GLOB_Version_Patch.GetValueInt()
EndFunction

; ==============================================================
; Expected Version Accessors
; ==============================================================

Int Function GetExpectedVersionMajor()
	Return iExpectedVersionMajor
EndFunction

Int Function GetExpectedVersionMinor()
	Return iExpectedVersionMinor
EndFunction

Int Function GetExpectedVersionPatch()
	Return iExpectedVersionPatch
EndFunction

String Function BuildInstalledVersionString()
	Return IntToString(GetInstalledVersionMajor()) + "." + IntToString(GetInstalledVersionMinor()) + "." + IntToString(GetInstalledVersionPatch())
EndFunction

String Function BuildExpectedVersionString()
	Return IntToString(GetExpectedVersionMajor()) + "." + IntToString(GetExpectedVersionMinor()) + "." + IntToString(GetExpectedVersionPatch())
EndFunction

; ==============================================================
; Internal Comparison Logic
; ==============================================================

Int Function CompareInstalledToExpected()
	Int iInstalledMajor = GetInstalledVersionMajor()
	Int iInstalledMinor = GetInstalledVersionMinor()
	Int iInstalledPatch = GetInstalledVersionPatch()

	If iInstalledMajor < iExpectedVersionMajor
		Return -1
	EndIf

	If iInstalledMajor > iExpectedVersionMajor
		Return 1
	EndIf

	If iInstalledMinor < iExpectedVersionMinor
		Return -1
	EndIf

	If iInstalledMinor > iExpectedVersionMinor
		Return 1
	EndIf

	If iInstalledPatch < iExpectedVersionPatch
		Return -1
	EndIf

	If iInstalledPatch > iExpectedVersionPatch
		Return 1
	EndIf

	Return 0
EndFunction

Bool Function ValidateVersionGlobals()
	If PWAL_GLOB_Version_Major == None
		LogError("VersionManager", "PWAL_GLOB_Version_Major property is not filled.")
		Return false
	EndIf

	If PWAL_GLOB_Version_Minor == None
		LogError("VersionManager", "PWAL_GLOB_Version_Minor property is not filled.")
		Return false
	EndIf

	If PWAL_GLOB_Version_Patch == None
		LogError("VersionManager", "PWAL_GLOB_Version_Patch property is not filled.")
		Return false
	EndIf

	Return true
EndFunction

Function ResetVersionCheckState()
	iLastVersionState = VERSION_STATE_UNKNOWN
	bLastVersionCheckPassed = false
EndFunction

String Function IntToString(Int aiValue)
	Return "" + aiValue
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