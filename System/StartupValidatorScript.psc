ScriptName PWAL:System:StartupValidatorScript extends Quest

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.00
; Created: 04-10-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: StartupValidatorScript
; Type: System / Validation
; Purpose:
;   Validates required PWAL framework dependencies during startup.
;   Reports missing critical properties and determines whether
;   runtime startup may safely continue.
;
; Responsibilities:
;   - Validate critical startup properties
;   - Count startup validation errors and warnings
;   - Report validation findings through LoggerScript
;   - Return a clean pass/fail result for runtime startup
;
; Non-Responsibilities:
;   - No install logic
;   - No version/migration logic
;   - No repair/fix-up logic
;   - No looting logic
;   - No terminal/menu logic
; ==============================================================

; ==============================================================
; Properties
; ==============================================================

PWAL:Core:LoggerScript Property Logger Auto
PWAL:Core:RuntimeManagerScript Property RuntimeManager Auto

GlobalVariable Property PWAL_GLOB_Utilities_Toggle_Logging Auto
GlobalVariable Property PWAL_GLOB_System_Installed Auto
GlobalVariable Property PWAL_GLOB_Settings_Container_TakeAll Auto
GlobalVariable Property PWAL_GLOB_Settings_Corpses_TakeAll Auto
GlobalVariable Property PWAL_GLOB_Settings_Destination Auto

; ==============================================================
; Validation State
; ==============================================================

Int Property iLastErrorCount = 0 Auto Hidden
Int Property iLastWarningCount = 0 Auto Hidden
Bool Property bLastValidationPassed = false Auto Hidden

; ==============================================================
; Public API
; ==============================================================

Bool Function ValidateStartup()
	ResetValidationState()

	LogInfo("StartupValidator", "Startup validation beginning.")

	ValidateRequiredObjects()
	ValidateRequiredGlobals()

	bLastValidationPassed = (iLastErrorCount <= 0)

	If bLastValidationPassed
		LogInfo("StartupValidator", "Startup validation passed with " + iLastWarningCount + " warning(s).")
	Else
		LogError("StartupValidator", "Startup validation failed with " + iLastErrorCount + " error(s) and " + iLastWarningCount + " warning(s).")
	EndIf

	Return bLastValidationPassed
EndFunction

Int Function GetLastErrorCount()
	Return iLastErrorCount
EndFunction

Int Function GetLastWarningCount()
	Return iLastWarningCount
EndFunction

Bool Function GetLastValidationPassed()
	Return bLastValidationPassed
EndFunction

; ==============================================================
; Validation Passes
; ==============================================================

Function ValidateRequiredObjects()
	ValidateLogger()
	ValidateRuntimeManager()
EndFunction

Function ValidateRequiredGlobals()
	ValidateLoggingGlobal()
	ValidateInstalledGlobal()
	ValidateContainerTakeAllGlobal()
	ValidateCorpsesTakeAllGlobal()
	ValidateDestinationGlobal()
EndFunction

; ==============================================================
; Object Validation
; ==============================================================

Function ValidateLogger()
	If Logger == None
		AddError("Logger property is not filled.")
		Return
	EndIf

	LogDebug("StartupValidator", "Logger property validation passed.")
EndFunction

Function ValidateRuntimeManager()
	If RuntimeManager == None
		AddError("RuntimeManager property is not filled.")
		Return
	EndIf

	LogDebug("StartupValidator", "RuntimeManager property validation passed.")
EndFunction

; ==============================================================
; Global Validation
; ==============================================================

Function ValidateLoggingGlobal()
	If PWAL_GLOB_Utilities_Toggle_Logging == None
		AddError("PWAL_GLOB_Utilities_Toggle_Logging property is not filled.")
		Return
	EndIf

	LogDebug("StartupValidator", "Logging toggle global validation passed.")
EndFunction

Function ValidateInstalledGlobal()
	If PWAL_GLOB_System_Installed == None
		AddError("PWAL_GLOB_System_Installed property is not filled.")
		Return
	EndIf

	LogDebug("StartupValidator", "Installed global validation passed.")
EndFunction

Function ValidateContainerTakeAllGlobal()
	If PWAL_GLOB_Settings_Container_TakeAll == None
		AddError("PWAL_GLOB_Settings_Container_TakeAll property is not filled.")
		Return
	EndIf

	LogDebug("StartupValidator", "Container TakeAll global validation passed.")
EndFunction

Function ValidateCorpsesTakeAllGlobal()
	If PWAL_GLOB_Settings_Corpses_TakeAll == None
		AddError("PWAL_GLOB_Settings_Corpses_TakeAll property is not filled.")
		Return
	EndIf

	LogDebug("StartupValidator", "Corpses TakeAll global validation passed.")
EndFunction

Function ValidateDestinationGlobal()
	If PWAL_GLOB_Settings_Destination == None
		AddError("PWAL_GLOB_Settings_Destination property is not filled.")
		Return
	EndIf

	LogDebug("StartupValidator", "Destination global validation passed.")
EndFunction

; ==============================================================
; Validation State Helpers
; ==============================================================

Function ResetValidationState()
	iLastErrorCount = 0
	iLastWarningCount = 0
	bLastValidationPassed = false
EndFunction

Function AddError(String asMessage)
	iLastErrorCount += 1
	LogError("StartupValidator", asMessage)
EndFunction

Function AddWarning(String asMessage)
	iLastWarningCount += 1
	LogWarn("StartupValidator", asMessage)
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