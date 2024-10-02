# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_static_text $IPINST -name "XCOM" -parent ${Page_0} -text {Xcom Configuration}
  #Adding Group
  set Communication_Options [ipgui::add_group $IPINST -name "Communication Options" -parent ${Page_0}]
  ipgui::add_param $IPINST -name "CH" -parent ${Communication_Options}
  ipgui::add_param $IPINST -name "SYNC" -parent ${Communication_Options} -widget checkBox

  #Adding Group
  set Debug [ipgui::add_group $IPINST -name "Debug" -parent ${Page_0}]
  ipgui::add_param $IPINST -name "DEBUG" -parent ${Debug} -widget comboBox



}

proc update_PARAM_VALUE.CH { PARAM_VALUE.CH } {
	# Procedure called to update CH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CH { PARAM_VALUE.CH } {
	# Procedure called to validate CH
	return true
}

proc update_PARAM_VALUE.DEBUG { PARAM_VALUE.DEBUG } {
	# Procedure called to update DEBUG when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DEBUG { PARAM_VALUE.DEBUG } {
	# Procedure called to validate DEBUG
	return true
}

proc update_PARAM_VALUE.SYNC { PARAM_VALUE.SYNC } {
	# Procedure called to update SYNC when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SYNC { PARAM_VALUE.SYNC } {
	# Procedure called to validate SYNC
	return true
}


proc update_MODELPARAM_VALUE.SYNC { MODELPARAM_VALUE.SYNC PARAM_VALUE.SYNC } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SYNC}] ${MODELPARAM_VALUE.SYNC}
}

proc update_MODELPARAM_VALUE.DEBUG { MODELPARAM_VALUE.DEBUG PARAM_VALUE.DEBUG } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DEBUG}] ${MODELPARAM_VALUE.DEBUG}
}

proc update_MODELPARAM_VALUE.CH { MODELPARAM_VALUE.CH PARAM_VALUE.CH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CH}] ${MODELPARAM_VALUE.CH}
}

