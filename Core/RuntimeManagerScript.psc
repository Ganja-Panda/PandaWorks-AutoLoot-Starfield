ScriptName PWAL:Core:RuntimeManagerScript extends Quest

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.00
; Created: 04-10-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: RuntimeManagerScript
; Type: System / Lifecycle
; Purpose:
;   Central runtime lifecycle controller for the PWAL framework.
;   Owns framework startup state, readiness state, startup guards,
;   migration/uninstall runtime flags, and framework gating.
;
; Responsibilities:
;   - Own framework startup state
;   - Prevent startup reentry
;   - Expose framework readiness
;   - Coordinate startup phase flow
;   - Gate looting/runtime execution while unsafe
;
; Non-Responsibilities:
;   - No install implementation
;   - No migration implementation
;   - No startup validation implementation
;   - No looting logic
;   - No terminal/menu logic
; ==============================================================

; ==============================================================
; Properties
; ==============================================================

PWAL:Core:LoggerScript Property Logger Auto
PWAL:System:StartupValidatorScript Property StartupValidator Auto
PWAL:System:VersionManagerScript Property VersionManager Auto
PWAL:System:InstallManagerScript Property InstallManager Auto

; ==============================================================
; Runtime State Constants
; ==============================================================

Int Property STATE_UNINITIALIZED = 0 Auto Const
Int Property STATE_STARTING = 10 Auto Const
Int Property STATE_VALIDATING = 20 Auto Const
Int Property STATE_CHECKING_VERSION = 30 Auto Const
Int Property STATE_CHECKING_INSTALL = 40 Auto Const
Int Property STATE_FINALIZING = 50 Auto Const
Int Property STATE_READY = 100 Auto Const
Int Property STATE_SHUTDOWN = 900 Auto Const
Int Property STATE_ERROR = 999 Auto Const

; ==============================================================
; Runtime State
; ==============================================================

Bool Property bStartupInProgress = false Auto Hidden
Bool Property bRuntimeInitialized = false Auto Hidden
Bool Property bFrameworkReady = false Auto Hidden
Bool Property bMigrationsRunning = false Auto Hidden
Bool Property bUninstallPending = false Auto Hidden

Int Property iCurrentFrameworkState = 0 Auto Hidden
Int Property iLoopBudgetTotal = 100 Auto
Int Property iLoopBudgetLootingMax = 80 Auto
Int Property iLoopBudgetZoologyMax = 20 Auto

Int Property iLoopBudgetLootingInUse = 0 Auto Hidden
Int Property iLoopBudgetZoologyInUse = 0 Auto Hidden

; ==============================================================
; Quest Lifecycle
; ==============================================================

Event OnQuestInit()
	OnFrameworkStart()
EndEvent

; ==============================================================
; Public Lifecycle API
; ==============================================================

Function OnFrameworkStart()
	If bStartupInProgress
		LogWarn("RuntimeManager", "OnFrameworkStart blocked because startup is already in progress.")
		Return
	EndIf

	If bFrameworkReady && bRuntimeInitialized
		LogInfo("RuntimeManager", "OnFrameworkStart skipped because framework is already ready.")
		Return
	EndIf

	bStartupInProgress = true
	bFrameworkReady = false
	iCurrentFrameworkState = STATE_STARTING

	LogInfo("RuntimeManager", "Framework startup beginning.")
	LogRuntimeSnapshot("StartupBegin")

	If !RunStartupFlow()
		FailStartup("RunStartupFlow returned false.")
		Return
	EndIf

	bRuntimeInitialized = true
	bFrameworkReady = true
	bStartupInProgress = false
	iCurrentFrameworkState = STATE_READY

	LogInfo("RuntimeManager", "Framework startup complete. Runtime is ready.")
	LogRuntimeSnapshot("StartupComplete")
EndFunction

Function ShutdownFramework()
	LogInfo("RuntimeManager", "Framework shutdown requested.")

	bFrameworkReady = false
	bStartupInProgress = false
	bRuntimeInitialized = false
	bMigrationsRunning = false
	iCurrentFrameworkState = STATE_SHUTDOWN

	iLoopBudgetLootingInUse = 0
	iLoopBudgetZoologyInUse = 0

	LogRuntimeSnapshot("ShutdownComplete")
EndFunction

Function ResetRuntimeState()
	LogWarn("RuntimeManager", "Runtime state reset requested.")

	bStartupInProgress = false
	bRuntimeInitialized = false
	bFrameworkReady = false
	bMigrationsRunning = false
	bUninstallPending = false
	iCurrentFrameworkState = STATE_UNINITIALIZED

	iLoopBudgetLootingInUse = 0
	iLoopBudgetZoologyInUse = 0

	LogRuntimeSnapshot("RuntimeReset")
EndFunction

; ==============================================================
; Public Runtime Flags
; ==============================================================

Function SetMigrationRunning(Bool abValue)
	bMigrationsRunning = abValue

	If abValue
		LogInfo("RuntimeManager", "Migration runtime flag set to true.")
	Else
		LogInfo("RuntimeManager", "Migration runtime flag set to false.")
	EndIf
EndFunction

Function SetUninstallPending(Bool abValue)
	bUninstallPending = abValue

	If abValue
		LogWarn("RuntimeManager", "Uninstall pending flag set to true.")
	Else
		LogInfo("RuntimeManager", "Uninstall pending flag cleared.")
	EndIf
EndFunction

; ==============================================================
; Public State Queries
; ==============================================================

Bool Function IsFrameworkReady()
	Return bFrameworkReady
EndFunction

Bool Function IsStartupInProgress()
	Return bStartupInProgress
EndFunction

Bool Function IsRuntimeInitialized()
	Return bRuntimeInitialized
EndFunction

Bool Function IsMigrationRunning()
	Return bMigrationsRunning
EndFunction

Bool Function IsUninstallPending()
	Return bUninstallPending
EndFunction

Int Function GetFrameworkState()
	Return iCurrentFrameworkState
EndFunction

Bool Function CanRunLooting()
	If !bRuntimeInitialized
		LogDecision("CanRunLooting", false, "Runtime is not initialized.")
		Return false
	EndIf

	If !bFrameworkReady
		LogDecision("CanRunLooting", false, "Framework is not ready.")
		Return false
	EndIf

	If bStartupInProgress
		LogDecision("CanRunLooting", false, "Startup is in progress.")
		Return false
	EndIf

	If bMigrationsRunning
		LogDecision("CanRunLooting", false, "Migration is currently running.")
		Return false
	EndIf

	If bUninstallPending
		LogDecision("CanRunLooting", false, "Uninstall preparation is pending.")
		Return false
	EndIf

	LogDecision("CanRunLooting", true, "Framework state allows looting.")
	Return true
EndFunction

; ==============================================================
; Shared Loop Budget
; ==============================================================

Int Function RequestLootingLoopBudget(Int aiRequested)
	If aiRequested <= 0
		Return 0
	EndIf

	Int iGlobalAvailable = iLoopBudgetTotal - (iLoopBudgetLootingInUse + iLoopBudgetZoologyInUse)
	Int iLootingAvailable = iLoopBudgetLootingMax - iLoopBudgetLootingInUse

	If iGlobalAvailable <= 0
		LogDebug("RuntimeManager", "RequestLootingLoopBudget denied: no global loop budget available.")
		Return 0
	EndIf

	If iLootingAvailable <= 0
		LogDebug("RuntimeManager", "RequestLootingLoopBudget denied: no looting loop budget available.")
		Return 0
	EndIf

	Int iGranted = aiRequested

	If iGranted > iGlobalAvailable
		iGranted = iGlobalAvailable
	EndIf

	If iGranted > iLootingAvailable
		iGranted = iLootingAvailable
	EndIf

	iLoopBudgetLootingInUse += iGranted

	LogDebug("RuntimeManager", "Granted looting loop budget: " + iGranted)
	Return iGranted
EndFunction

Function ReleaseLootingLoopBudget(Int aiGranted)
	If aiGranted <= 0
		Return
	EndIf

	iLoopBudgetLootingInUse -= aiGranted

	If iLoopBudgetLootingInUse < 0
		iLoopBudgetLootingInUse = 0
	EndIf

	LogDebug("RuntimeManager", "Released looting loop budget: " + aiGranted)
EndFunction

Int Function RequestZoologyLoopBudget(Int aiRequested)
	If aiRequested <= 0
		Return 0
	EndIf

	Int iGlobalAvailable = iLoopBudgetTotal - (iLoopBudgetLootingInUse + iLoopBudgetZoologyInUse)
	Int iZoologyAvailable = iLoopBudgetZoologyMax - iLoopBudgetZoologyInUse

	If iGlobalAvailable <= 0
		LogDebug("RuntimeManager", "RequestZoologyLoopBudget denied: no global loop budget available.")
		Return 0
	EndIf

	If iZoologyAvailable <= 0
		LogDebug("RuntimeManager", "RequestZoologyLoopBudget denied: no zoology loop budget available.")
		Return 0
	EndIf

	Int iGranted = aiRequested

	If iGranted > iGlobalAvailable
		iGranted = iGlobalAvailable
	EndIf

	If iGranted > iZoologyAvailable
		iGranted = iZoologyAvailable
	EndIf

	iLoopBudgetZoologyInUse += iGranted

	LogDebug("RuntimeManager", "Granted zoology loop budget: " + iGranted)
	Return iGranted
EndFunction

Function ReleaseZoologyLoopBudget(Int aiGranted)
	If aiGranted <= 0
		Return
	EndIf

	iLoopBudgetZoologyInUse -= aiGranted

	If iLoopBudgetZoologyInUse < 0
		iLoopBudgetZoologyInUse = 0
	EndIf

	LogDebug("RuntimeManager", "Released zoology loop budget: " + aiGranted)
EndFunction

; ==============================================================
; Startup Flow
; ==============================================================

Bool Function RunStartupFlow()
	LogDebug("RuntimeManager", "RunStartupFlow entered.")

	If !RunStartupValidationPhase()
		Return false
	EndIf

	If !RunVersionCheckPhase()
		Return false
	EndIf

	If !RunInstallCheckPhase()
		Return false
	EndIf

	If !RunFinalizeStartupPhase()
		Return false
	EndIf

	Return true
EndFunction

Bool Function RunStartupValidationPhase()
	iCurrentFrameworkState = STATE_VALIDATING
	LogInfo("RuntimeManager", "Startup phase: validation begin.")

	If StartupValidator == None
		LogError("RuntimeManager", "Startup validation failed: StartupValidator property is not filled.")
		Return false
	EndIf

	If !StartupValidator.ValidateStartup()
		LogError("RuntimeManager", "Startup validation failed.")
		Return false
	EndIf

	LogDebug("RuntimeManager", "Startup validation phase completed successfully.")
	LogInfo("RuntimeManager", "Startup phase: validation complete.")
	Return true
EndFunction

Bool Function RunVersionCheckPhase()
	iCurrentFrameworkState = STATE_CHECKING_VERSION
	LogInfo("RuntimeManager", "Startup phase: version check begin.")

	If VersionManager == None
		LogError("RuntimeManager", "Version check failed: VersionManager property is not filled.")
		Return false
	EndIf

	If !VersionManager.HandleVersionState()
		LogError("RuntimeManager", "Version check failed.")
		Return false
	EndIf

	LogDebug("RuntimeManager", "Version check phase completed successfully.")
	LogInfo("RuntimeManager", "Startup phase: version check complete.")
	Return true
EndFunction

Bool Function RunInstallCheckPhase()
	iCurrentFrameworkState = STATE_CHECKING_INSTALL
	LogInfo("RuntimeManager", "Startup phase: install check begin.")

	If InstallManager == None
		LogError("RuntimeManager", "Install check failed: InstallManager property is not filled.")
		Return false
	EndIf

	If !InstallManager.HandleInstallState()
		LogError("RuntimeManager", "Install check failed.")
		Return false
	EndIf

	LogDebug("RuntimeManager", "Install check phase completed successfully.")
	LogInfo("RuntimeManager", "Startup phase: install check complete.")
	Return true
EndFunction

Bool Function RunFinalizeStartupPhase()
	iCurrentFrameworkState = STATE_FINALIZING
	LogInfo("RuntimeManager", "Startup phase: finalization begin.")

	; Future:
	; - Final runtime sanity checks
	; - Any post-install / post-migration runtime sync
	; - Final gating verification before ready state

	LogDebug("RuntimeManager", "Finalize startup phase currently operating as a runtime stub.")
	LogInfo("RuntimeManager", "Startup phase: finalization complete.")
	Return true
EndFunction

; ==============================================================
; Failure Handling
; ==============================================================

Function FailStartup(String asReason)
	bStartupInProgress = false
	bFrameworkReady = false
	bRuntimeInitialized = false
	iCurrentFrameworkState = STATE_ERROR

	iLoopBudgetLootingInUse = 0
	iLoopBudgetZoologyInUse = 0

	LogError("RuntimeManager", "Framework startup failed: " + asReason)
	LogRuntimeSnapshot("StartupFailed")
EndFunction

; ==============================================================
; Diagnostic Helpers
; ==============================================================

Function LogRuntimeSnapshot(String asContext)
	LogDebug("RuntimeManager", asContext + " | State=" + iCurrentFrameworkState)
	LogDebug("RuntimeManager", asContext + " | iLoopBudgetLootingInUse=" + iLoopBudgetLootingInUse)
	LogDebug("RuntimeManager", asContext + " | iLoopBudgetZoologyInUse=" + iLoopBudgetZoologyInUse)
	LogDecision(asContext + " | bStartupInProgress", bStartupInProgress, "Current startup flag snapshot.")
	LogDecision(asContext + " | bRuntimeInitialized", bRuntimeInitialized, "Current initialized flag snapshot.")
	LogDecision(asContext + " | bFrameworkReady", bFrameworkReady, "Current ready flag snapshot.")
	LogDecision(asContext + " | bMigrationsRunning", bMigrationsRunning, "Current migration flag snapshot.")
	LogDecision(asContext + " | bUninstallPending", bUninstallPending, "Current uninstall flag snapshot.")
EndFunction

Function LogDecision(String asContext, Bool abDecision, String asReason)
	String sDecision = "false"

	If abDecision
		sDecision = "true"
	EndIf

	If Logger
		Logger.TraceDecision("RuntimeManager", asContext, abDecision, asReason)
	Else
		Debug.Trace("[PWAL][DEBUG][RuntimeManager] " + asContext + " => " + sDecision + " | " + asReason)
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