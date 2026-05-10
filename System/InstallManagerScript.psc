ScriptName PWAL:System:InstallManagerScript extends Quest

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.00
; Created: 04-10-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: InstallManagerScript
; Type: System / Installation
; Purpose:
;   Manages first-install framework initialization and install-state
;   handling for PWAL. Responsible for applying one-time baseline
;   setup when the framework is being initialized on a save for the
;   first time.
;
; Responsibilities:
;   - Detect first-install state through VersionManager
;   - Run first-time framework setup
;   - Apply baseline/default install state
;   - Mark framework install state
;   - Persist framework version after successful install
;
; Non-Responsibilities:
;   - No version comparison ownership
;   - No migration implementation
;   - No runtime state ownership
;   - No looting logic
;   - No terminal/menu logic
; ==============================================================

; ==============================================================
; Properties
; ==============================================================

PWAL:Core:LoggerScript Property Logger Auto
PWAL:Core:RuntimeManagerScript Property RuntimeManager Auto
PWAL:System:VersionManagerScript Property VersionManager Auto

GlobalVariable Property PWAL_GLOB_System_Installed Auto
GlobalVariable Property PWAL_GLOB_Settings_Container_TakeAll Auto
GlobalVariable Property PWAL_GLOB_Settings_Corpses_TakeAll Auto
GlobalVariable Property PWAL_GLOB_Settings_Destination Auto

; ==============================================================
; Cached State
; ==============================================================

Bool Property bLastInstallCheckPassed = false Auto Hidden
Bool Property bLastInstallPerformed = false Auto Hidden

; ==============================================================
; Public API
; ==============================================================

Bool Function HandleInstallState()
	ResetInstallState()

	If VersionManager == None
		LogError("InstallManager", "HandleInstallState failed: VersionManager property is not filled.")
		Return false
	EndIf

	LogInfo("InstallManager", "Install state check beginning.")

	If !VersionManager.CheckVersionState()
		LogError("InstallManager", "Install state check failed because VersionManager.CheckVersionState() returned false.")
		Return false
	EndIf

	If VersionManager.GetLastVersionState() == VersionManager.VERSION_STATE_FIRST_INSTALL
		LogInfo("InstallManager", "Detected first install state. Beginning first-time setup.")

		If !RunFirstTimeSetup()
			LogError("InstallManager", "First-time setup failed.")
			Return false
		EndIf

		VersionManager.PersistExpectedVersion()

		bLastInstallCheckPassed = true
		bLastInstallPerformed = true

		LogInfo("InstallManager", "First-time setup completed successfully.")
		Return true
	EndIf

	LogInfo("InstallManager", "No first-time install work required.")
	bLastInstallCheckPassed = true
	bLastInstallPerformed = false
	Return true
EndFunction

Bool Function IsFirstInstall()
	If VersionManager == None
		LogError("InstallManager", "IsFirstInstall failed: VersionManager property is not filled.")
		Return false
	EndIf

	Return VersionManager.IsFirstInstall()
EndFunction

Bool Function IsInstalled()
	If PWAL_GLOB_System_Installed == None
		LogError("InstallManager", "IsInstalled failed: PWAL_GLOB_System_Installed property is not filled.")
		Return false
	EndIf

	Return (PWAL_GLOB_System_Installed.GetValueInt() != 0)
EndFunction

Bool Function RunFirstTimeSetup()
	LogInfo("InstallManager", "Running first-time framework setup.")

	If VersionManager == None
		LogError("InstallManager", "RunFirstTimeSetup failed: VersionManager property is not filled.")
		Return false
	EndIf

	If RuntimeManager == None
		LogError("InstallManager", "RunFirstTimeSetup failed: RuntimeManager property is not filled.")
		Return false
	EndIf

	If !EnsureBootstrapState()
		LogError("InstallManager", "RunFirstTimeSetup failed during EnsureBootstrapState().")
		Return false
	EndIf

	If !ApplyInstallDefaults()
		LogError("InstallManager", "RunFirstTimeSetup failed during ApplyInstallDefaults().")
		Return false
	EndIf

	If !MarkInstalled()
		LogError("InstallManager", "RunFirstTimeSetup failed during MarkInstalled().")
		Return false
	EndIf

	If !RunPostInstallValidation()
		LogError("InstallManager", "RunFirstTimeSetup failed during RunPostInstallValidation().")
		Return false
	EndIf

	LogInfo("InstallManager", "First-time framework setup completed successfully.")
	Return true
EndFunction

; ==============================================================
; Install Phases
; ==============================================================

Bool Function EnsureBootstrapState()
	LogInfo("InstallManager", "Ensuring bootstrap install state is valid.")

	If PWAL_GLOB_System_Installed == None
		LogError("InstallManager", "EnsureBootstrapState failed: PWAL_GLOB_System_Installed property is not filled.")
		Return false
	EndIf

	LogDebug("InstallManager", "Bootstrap state validated.")
	Return true
EndFunction

Bool Function ApplyInstallDefaults()
	LogInfo("InstallManager", "Applying baseline install defaults.")

	If PWAL_GLOB_Settings_Container_TakeAll == None
		LogError("InstallManager", "ApplyInstallDefaults failed: PWAL_GLOB_Settings_Container_TakeAll property is not filled.")
		Return false
	EndIf

	If PWAL_GLOB_Settings_Corpses_TakeAll == None
		LogError("InstallManager", "ApplyInstallDefaults failed: PWAL_GLOB_Settings_Corpses_TakeAll property is not filled.")
		Return false
	EndIf

	If PWAL_GLOB_Settings_Destination == None
		LogError("InstallManager", "ApplyInstallDefaults failed: PWAL_GLOB_Settings_Destination property is not filled.")
		Return false
	EndIf

	PWAL_GLOB_Settings_Container_TakeAll.SetValueInt(1)
	LogDebug("InstallManager", "Default applied: Container TakeAll = 1")

	PWAL_GLOB_Settings_Corpses_TakeAll.SetValueInt(1)
	LogDebug("InstallManager", "Default applied: Corpses TakeAll = 1")

	PWAL_GLOB_Settings_Destination.SetValueInt(1)
	LogDebug("InstallManager", "Default applied: Destination = 1 (Player)")

	Return true
EndFunction

Bool Function MarkInstalled()
	LogInfo("InstallManager", "Marking framework as installed.")

	If PWAL_GLOB_System_Installed == None
		LogError("InstallManager", "MarkInstalled failed: PWAL_GLOB_System_Installed property is not filled.")
		Return false
	EndIf

	PWAL_GLOB_System_Installed.SetValueInt(1)
	LogDebug("InstallManager", "Install marker applied: PWAL_GLOB_System_Installed = 1")

	Return true
EndFunction

Bool Function RunPostInstallValidation()
	LogInfo("InstallManager", "Running post-install validation hooks.")

	If PWAL_GLOB_System_Installed == None
		LogError("InstallManager", "RunPostInstallValidation failed: PWAL_GLOB_System_Installed property is not filled.")
		Return false
	EndIf

	If PWAL_GLOB_Settings_Container_TakeAll == None
		LogError("InstallManager", "RunPostInstallValidation failed: Container TakeAll global not filled.")
		Return false
	EndIf

	If PWAL_GLOB_Settings_Corpses_TakeAll == None
		LogError("InstallManager", "RunPostInstallValidation failed: Corpses TakeAll global not filled.")
		Return false
	EndIf

	If PWAL_GLOB_Settings_Destination == None
		LogError("InstallManager", "RunPostInstallValidation failed: Destination global not filled.")
		Return false
	EndIf

	If PWAL_GLOB_System_Installed.GetValueInt() != 1
		LogError("InstallManager", "Post-install validation failed: Installed marker not set correctly.")
		Return false
	EndIf

	If PWAL_GLOB_Settings_Container_TakeAll.GetValueInt() != 1
		LogError("InstallManager", "Post-install validation failed: Container TakeAll not set correctly.")
		Return false
	EndIf

	If PWAL_GLOB_Settings_Corpses_TakeAll.GetValueInt() != 1
		LogError("InstallManager", "Post-install validation failed: Corpses TakeAll not set correctly.")
		Return false
	EndIf

	If PWAL_GLOB_Settings_Destination.GetValueInt() != 1
		LogError("InstallManager", "Post-install validation failed: Destination not set correctly.")
		Return false
	EndIf

	LogInfo("InstallManager", "Post-install validation completed successfully.")
	Return true
EndFunction

Function MarkUninstalled()
	If PWAL_GLOB_System_Installed == None
		LogError("InstallManager", "MarkUninstalled failed: PWAL_GLOB_System_Installed property is not filled.")
		Return
	EndIf

	PWAL_GLOB_System_Installed.SetValueInt(0)
	LogInfo("InstallManager", "Framework install marker cleared.")
EndFunction

; ==============================================================
; State Accessors
; ==============================================================

Bool Function GetLastInstallCheckPassed()
	Return bLastInstallCheckPassed
EndFunction

Bool Function GetLastInstallPerformed()
	Return bLastInstallPerformed
EndFunction

Function ResetInstallState()
	bLastInstallCheckPassed = false
	bLastInstallPerformed = false
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