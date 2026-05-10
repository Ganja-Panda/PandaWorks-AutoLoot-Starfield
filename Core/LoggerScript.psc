ScriptName PWAL:Core:LoggerScript extends Quest

; ==============================================================
; PandaWorks Studios - PandaWork Auto Loot
; Author: Ganja Panda
; Version: 1.00
; Created: 04-10-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: LoggerScript
; Type: Core / Diagnostic Utility
; Purpose:
;   Central diagnostic and logging utility for the PWAL framework.
;   Provides standardized info, warning, error, and verbose debug
;   trace output when the PWAL logging utility toggle is enabled.
;
; Responsibilities:
;   - Format log messages consistently
;   - Respect the existing PWAL logging toggle global
;   - Provide centralized diagnostic trace helpers
;   - Normalize log source/message values
;   - Support verbose runtime inspection during development/testing
;
; Non-Responsibilities:
;   - No install/update logic
;   - No runtime management
;   - No UI messaging
;   - No side effects beyond trace output
; ==============================================================

; ==============================================================
; Properties
; ==============================================================

GlobalVariable Property PWAL_GLOB_Utilities_Toggle_Logging Auto
String Property sLogPrefix = "[PWAL]" Auto

; ==============================================================
; Public Logging API
; ==============================================================

Function Info(String asSource, String asMessage)
	Log("INFO", asSource, asMessage, false)
EndFunction

Function Warn(String asSource, String asMessage)
	Log("WARN", asSource, asMessage, false)
EndFunction

Function Error(String asSource, String asMessage)
	Log("ERROR", asSource, asMessage, true)
EndFunction

Function DebugLog(String asSource, String asMessage)
	Log("DEBUG", asSource, asMessage, false)
EndFunction

Function TraceDecision(String asSource, String asContext, Bool abDecision, String asReason)
	String sDecision = "false"

	If abDecision
		sDecision = "true"
	EndIf

	Log("DEBUG", asSource, asContext + " => " + sDecision + " | " + NormalizeMessage(asReason), false)
EndFunction

Function TraceValue(String asSource, String asLabel, String asValue)
	Log("DEBUG", asSource, NormalizeMessage(asLabel) + " = " + NormalizeMessage(asValue), false)
EndFunction

; ==============================================================
; Public State Helpers
; ==============================================================

Bool Function IsLoggingEnabled()
	If PWAL_GLOB_Utilities_Toggle_Logging == None
		Return true
	EndIf

	Return (PWAL_GLOB_Utilities_Toggle_Logging.GetValueInt() != 0)
EndFunction

; ==============================================================
; Internal Logging Pipeline
; ==============================================================

Function Log(String asLevel, String asSource, String asMessage, Bool abForce)
	If !ShouldLog(abForce)
		Return
	EndIf

	WriteTrace(BuildMessage(asLevel, asSource, asMessage))
EndFunction

Bool Function ShouldLog(Bool abForce)
	If abForce
		Return true
	EndIf

	Return IsLoggingEnabled()
EndFunction

Function WriteTrace(String asFinalMessage)
	Debug.Trace(asFinalMessage)
EndFunction

String Function BuildMessage(String asLevel, String asSource, String asMessage)
	String sLevel = NormalizeLevel(asLevel)
	String sSource = NormalizeSource(asSource)
	String sMessage = NormalizeMessage(asMessage)

	Return sLogPrefix + "[" + sLevel + "][" + sSource + "] " + sMessage
EndFunction

String Function NormalizeLevel(String asLevel)
	If asLevel == ""
		Return "INFO"
	EndIf

	Return asLevel
EndFunction

String Function NormalizeSource(String asSource)
	If asSource == ""
		Return "UnknownSource"
	EndIf

	Return asSource
EndFunction

String Function NormalizeMessage(String asMessage)
	If asMessage == ""
		Return "<empty message>"
	EndIf

	Return asMessage
EndFunction