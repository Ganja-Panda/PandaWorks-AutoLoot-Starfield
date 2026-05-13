ScriptName PWAL:Input:UtilityMenuScript Extends TerminalMenu Hidden

; ==============================================================
; PandaWorks Studios - PandaWorks Auto Loot
; Author: Ganja Panda
; Version: 1.00
; Created: 04-10-2026
; License: Copyright (c) 2026 PandaWorks Studios. All rights reserved.
; Script: UtilityMenuScript
; Type: Input / Terminal Menu Controller
; Purpose:
;   Handles the main PWAL Utilities terminal menu page.
;   Refreshes utility toggle tokens and routes quick-access
;   inventory actions into the command/service layer.
;
; Responsibilities:
;   - Refresh Looting and Logging tokens on menu enter
;   - Toggle global looting enable/disable state
;   - Toggle global logging enable/disable state
;   - Route Lodge Safe open action to CommandServices
;   - Route PandaWorks Inventory open action to CommandServices
;   - Route Home Ship Cargo open action to CommandServices
;   - Ignore submenu/navigation rows safely
;
; Non-Responsibilities:
;   - No direct transfer implementation
;   - No loot scanning
;   - No destination resolving
;   - No install/update logic
;   - No terminal submenu navigation handling
; ==============================================================

; ==============================================================
; Properties
; ==============================================================

Group FrameworkServices
	PWAL:Core:LoggerScript Property Logger Auto Const
	PWAL:System:CommandServicesScript Property CommandServices Auto Const
EndGroup

Group Terminal
	TerminalMenu Property CurrentTerminalMenu Auto Const Mandatory
EndGroup

Group UtilityGlobals_AutoFill
	GlobalVariable Property PWAL_GLOB_Utilities_Toggle_Looting Auto Const Mandatory
	GlobalVariable Property PWAL_GLOB_Utilities_Toggle_Logging Auto Const Mandatory
EndGroup

Group DisplayMessages
	Message Property PWAL_MSG_Menu_On Auto Const Mandatory
	Message Property PWAL_MSG_Menu_Off Auto Const Mandatory
	Message Property PWAL_MSG_Utilities_Unavailable Auto Const
EndGroup

Group RuntimeConfig
	Int Property VALUE_OFF = 0 Auto Const
	Int Property VALUE_ON = 1 Auto Const
EndGroup

; ==============================================================
; Events
; ==============================================================

Event OnTerminalMenuEnter(TerminalMenu akTerminalBase, ObjectReference akTerminalRef)
	If akTerminalBase != CurrentTerminalMenu
		Return
	EndIf

	LogDebug("UtilityMenu", "OnTerminalMenuEnter triggered.")
	RefreshUtilityTokens(akTerminalRef)
EndEvent

Event OnTerminalMenuItemRun(Int auiMenuItemID, TerminalMenu akTerminalBase, ObjectReference akTerminalRef)
	If akTerminalBase != CurrentTerminalMenu
		Return
	EndIf

	If auiMenuItemID == 0
		LogDebug("UtilityMenu", "Transfer Items submenu selected; CK handles navigation.")
		Return
	ElseIf auiMenuItemID == 1
		RunToggleLooting()
	ElseIf auiMenuItemID == 2
		RunToggleLogging()
	ElseIf auiMenuItemID == 3
		RunOpenLodgeSafe()
	ElseIf auiMenuItemID == 4
		RunOpenPandaWorksInventory()
	ElseIf auiMenuItemID == 5
		RunOpenShipCargo()
	Else
		LogDebug("UtilityMenu", "Ignoring unmapped menu item ID: " + (auiMenuItemID as String))
	EndIf

	RefreshUtilityTokens(akTerminalRef)
EndEvent

; ==============================================================
; Core Execution
; ==============================================================

Function RunToggleLooting()
	ToggleBoolGlobal(PWAL_GLOB_Utilities_Toggle_Looting, "Looting")
EndFunction

Function RunToggleLogging()
	ToggleBoolGlobal(PWAL_GLOB_Utilities_Toggle_Logging, "Logging")
EndFunction

Function RunOpenLodgeSafe()
	If CommandServices == None
		LogError("UtilityMenu", "RunOpenLodgeSafe failed: CommandServices property is not filled.")
		ShowMessage(PWAL_MSG_Utilities_Unavailable)
		Return
	EndIf

	Bool bSuccess = CommandServices.OpenLodgeSafe()

	If !bSuccess
		LogWarn("UtilityMenu", "OpenLodgeSafe returned false.")
		ShowMessage(PWAL_MSG_Utilities_Unavailable)
	EndIf
EndFunction

Function RunOpenPandaWorksInventory()
	If CommandServices == None
		LogError("UtilityMenu", "RunOpenPandaWorksInventory failed: CommandServices property is not filled.")
		ShowMessage(PWAL_MSG_Utilities_Unavailable)
		Return
	EndIf

	Bool bSuccess = CommandServices.OpenPandaWorksInventory()

	If !bSuccess
		LogWarn("UtilityMenu", "OpenPandaWorksInventory returned false.")
		ShowMessage(PWAL_MSG_Utilities_Unavailable)
	EndIf
EndFunction

Function RunOpenShipCargo()
	If CommandServices == None
		LogError("UtilityMenu", "RunOpenShipCargo failed: CommandServices property is not filled.")
		ShowMessage(PWAL_MSG_Utilities_Unavailable)
		Return
	EndIf

	Bool bSuccess = CommandServices.OpenShipCargo()

	If !bSuccess
		LogWarn("UtilityMenu", "OpenShipCargo returned false.")
		ShowMessage(PWAL_MSG_Utilities_Unavailable)
	EndIf
EndFunction

; ==============================================================
; Token Display
; ==============================================================

Function RefreshUtilityTokens(ObjectReference akTerminalRef)
	If akTerminalRef == None
		LogWarn("UtilityMenu", "RefreshUtilityTokens failed: terminal ref is None.")
		Return
	EndIf

	RefreshBoolToken(akTerminalRef, "Looting", PWAL_GLOB_Utilities_Toggle_Looting)
	RefreshBoolToken(akTerminalRef, "Logging", PWAL_GLOB_Utilities_Toggle_Logging)
EndFunction

Function RefreshBoolToken(ObjectReference akTerminalRef, String asTokenName, GlobalVariable akSettingGlobal)
	If akTerminalRef == None
		Return
	EndIf

	If akSettingGlobal == None
		LogWarn("UtilityMenu", "RefreshBoolToken skipped: " + asTokenName + " global is None.")
		Return
	EndIf

	Message akReplacementMessage = PWAL_MSG_Menu_Off

	If akSettingGlobal.GetValueInt() > 0
		akReplacementMessage = PWAL_MSG_Menu_On
	EndIf

	akTerminalRef.AddTextReplacementData(asTokenName, akReplacementMessage as Form)
	LogDebug("UtilityMenu", "Bool token refreshed: " + asTokenName)
EndFunction

; ==============================================================
; Utility Helpers
; ==============================================================

Int Function ToggleBoolGlobal(GlobalVariable akGlobal, String asLabel)
	If akGlobal == None
		LogWarn("UtilityMenu", "ToggleBoolGlobal failed: " + asLabel + " global is None.")
		Return VALUE_OFF
	EndIf

	Int iNewValue = VALUE_ON

	If akGlobal.GetValueInt() > 0
		iNewValue = VALUE_OFF
	EndIf

	akGlobal.SetValueInt(iNewValue)

	LogDebug("UtilityMenu", asLabel + " changed to " + (iNewValue as String))

	Return iNewValue
EndFunction

Function ShowMessage(Message akMessage)
	If akMessage != None
		akMessage.Show()
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