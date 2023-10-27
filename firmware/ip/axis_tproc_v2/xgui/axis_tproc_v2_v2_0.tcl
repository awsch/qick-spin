# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_static_text $IPINST -name "Introduction" -parent ${Page_0} -text {Values for Memory size Port quantity and register amount can be modified in order to make a smaller and Faster processor }
  #Adding Group
  set Memory_Configuration [ipgui::add_group $IPINST -name "Memory Configuration" -parent ${Page_0}]
  ipgui::add_param $IPINST -name "PMEM_AW" -parent ${Memory_Configuration}
  set DMEM_AW [ipgui::add_param $IPINST -name "DMEM_AW" -parent ${Memory_Configuration}]
  set_property tooltip {DmemAw} ${DMEM_AW}
  ipgui::add_param $IPINST -name "WMEM_AW" -parent ${Memory_Configuration}

  #Adding Group
  set IN_Port_Configuration [ipgui::add_group $IPINST -name "IN Port Configuration" -parent ${Page_0}]
  ipgui::add_param $IPINST -name "IN_PORT_QTY" -parent ${IN_Port_Configuration}

  #Adding Group
  set OUT_Port_Configuration [ipgui::add_group $IPINST -name "OUT Port Configuration" -parent ${Page_0}]
  ipgui::add_param $IPINST -name "OUT_DPORT_QTY" -parent ${OUT_Port_Configuration}
  ipgui::add_param $IPINST -name "OUT_WPORT_QTY" -parent ${OUT_Port_Configuration}

  ipgui::add_param $IPINST -name "REG_AW" -parent ${Page_0}
  ipgui::add_static_text $IPINST -name "dreg" -parent ${Page_0} -text {User can define the amount of 32-bits General Purpouse Data registers. This value impacts on the max freq of the processor.}
  #Adding Group
  set Peripherals [ipgui::add_group $IPINST -name "Peripherals" -parent ${Page_0}]
  set LFSR [ipgui::add_param $IPINST -name "LFSR" -parent ${Peripherals} -widget checkBox]
  set_property tooltip {Linear Feedback Shit Register} ${LFSR}
  set DIVIDER [ipgui::add_param $IPINST -name "DIVIDER" -parent ${Peripherals} -widget checkBox]
  set_property tooltip {32-bit Integer Divider (Quotient - Reminder)} ${DIVIDER}
  ipgui::add_param $IPINST -name "ARITH" -parent ${Peripherals} -widget checkBox
  ipgui::add_param $IPINST -name "TIME_CMP" -parent ${Peripherals} -widget checkBox

  #Adding Group
  set Options [ipgui::add_group $IPINST -name "Options" -parent ${Page_0}]
  ipgui::add_param $IPINST -name "TIME_READ" -parent ${Options} -widget checkBox



}

proc update_PARAM_VALUE.ARITH { PARAM_VALUE.ARITH } {
	# Procedure called to update ARITH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ARITH { PARAM_VALUE.ARITH } {
	# Procedure called to validate ARITH
	return true
}

proc update_PARAM_VALUE.DIVIDER { PARAM_VALUE.DIVIDER } {
	# Procedure called to update DIVIDER when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DIVIDER { PARAM_VALUE.DIVIDER } {
	# Procedure called to validate DIVIDER
	return true
}

proc update_PARAM_VALUE.DMEM_AW { PARAM_VALUE.DMEM_AW } {
	# Procedure called to update DMEM_AW when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DMEM_AW { PARAM_VALUE.DMEM_AW } {
	# Procedure called to validate DMEM_AW
	return true
}

proc update_PARAM_VALUE.IN_PORT_QTY { PARAM_VALUE.IN_PORT_QTY } {
	# Procedure called to update IN_PORT_QTY when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.IN_PORT_QTY { PARAM_VALUE.IN_PORT_QTY } {
	# Procedure called to validate IN_PORT_QTY
	return true
}

proc update_PARAM_VALUE.LFSR { PARAM_VALUE.LFSR } {
	# Procedure called to update LFSR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.LFSR { PARAM_VALUE.LFSR } {
	# Procedure called to validate LFSR
	return true
}

proc update_PARAM_VALUE.OUT_DPORT_QTY { PARAM_VALUE.OUT_DPORT_QTY } {
	# Procedure called to update OUT_DPORT_QTY when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.OUT_DPORT_QTY { PARAM_VALUE.OUT_DPORT_QTY } {
	# Procedure called to validate OUT_DPORT_QTY
	return true
}

proc update_PARAM_VALUE.OUT_WPORT_QTY { PARAM_VALUE.OUT_WPORT_QTY } {
	# Procedure called to update OUT_WPORT_QTY when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.OUT_WPORT_QTY { PARAM_VALUE.OUT_WPORT_QTY } {
	# Procedure called to validate OUT_WPORT_QTY
	return true
}

proc update_PARAM_VALUE.PMEM_AW { PARAM_VALUE.PMEM_AW } {
	# Procedure called to update PMEM_AW when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.PMEM_AW { PARAM_VALUE.PMEM_AW } {
	# Procedure called to validate PMEM_AW
	return true
}

proc update_PARAM_VALUE.REG_AW { PARAM_VALUE.REG_AW } {
	# Procedure called to update REG_AW when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.REG_AW { PARAM_VALUE.REG_AW } {
	# Procedure called to validate REG_AW
	return true
}

proc update_PARAM_VALUE.TIME_CMP { PARAM_VALUE.TIME_CMP } {
	# Procedure called to update TIME_CMP when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.TIME_CMP { PARAM_VALUE.TIME_CMP } {
	# Procedure called to validate TIME_CMP
	return true
}

proc update_PARAM_VALUE.TIME_READ { PARAM_VALUE.TIME_READ } {
	# Procedure called to update TIME_READ when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.TIME_READ { PARAM_VALUE.TIME_READ } {
	# Procedure called to validate TIME_READ
	return true
}

proc update_PARAM_VALUE.WMEM_AW { PARAM_VALUE.WMEM_AW } {
	# Procedure called to update WMEM_AW when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.WMEM_AW { PARAM_VALUE.WMEM_AW } {
	# Procedure called to validate WMEM_AW
	return true
}


proc update_MODELPARAM_VALUE.PMEM_AW { MODELPARAM_VALUE.PMEM_AW PARAM_VALUE.PMEM_AW } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.PMEM_AW}] ${MODELPARAM_VALUE.PMEM_AW}
}

proc update_MODELPARAM_VALUE.DMEM_AW { MODELPARAM_VALUE.DMEM_AW PARAM_VALUE.DMEM_AW } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DMEM_AW}] ${MODELPARAM_VALUE.DMEM_AW}
}

proc update_MODELPARAM_VALUE.WMEM_AW { MODELPARAM_VALUE.WMEM_AW PARAM_VALUE.WMEM_AW } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.WMEM_AW}] ${MODELPARAM_VALUE.WMEM_AW}
}

proc update_MODELPARAM_VALUE.REG_AW { MODELPARAM_VALUE.REG_AW PARAM_VALUE.REG_AW } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.REG_AW}] ${MODELPARAM_VALUE.REG_AW}
}

proc update_MODELPARAM_VALUE.IN_PORT_QTY { MODELPARAM_VALUE.IN_PORT_QTY PARAM_VALUE.IN_PORT_QTY } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.IN_PORT_QTY}] ${MODELPARAM_VALUE.IN_PORT_QTY}
}

proc update_MODELPARAM_VALUE.OUT_DPORT_QTY { MODELPARAM_VALUE.OUT_DPORT_QTY PARAM_VALUE.OUT_DPORT_QTY } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.OUT_DPORT_QTY}] ${MODELPARAM_VALUE.OUT_DPORT_QTY}
}

proc update_MODELPARAM_VALUE.OUT_WPORT_QTY { MODELPARAM_VALUE.OUT_WPORT_QTY PARAM_VALUE.OUT_WPORT_QTY } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.OUT_WPORT_QTY}] ${MODELPARAM_VALUE.OUT_WPORT_QTY}
}

proc update_MODELPARAM_VALUE.LFSR { MODELPARAM_VALUE.LFSR PARAM_VALUE.LFSR } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.LFSR}] ${MODELPARAM_VALUE.LFSR}
}

proc update_MODELPARAM_VALUE.DIVIDER { MODELPARAM_VALUE.DIVIDER PARAM_VALUE.DIVIDER } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DIVIDER}] ${MODELPARAM_VALUE.DIVIDER}
}

proc update_MODELPARAM_VALUE.ARITH { MODELPARAM_VALUE.ARITH PARAM_VALUE.ARITH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ARITH}] ${MODELPARAM_VALUE.ARITH}
}

proc update_MODELPARAM_VALUE.TIME_CMP { MODELPARAM_VALUE.TIME_CMP PARAM_VALUE.TIME_CMP } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.TIME_CMP}] ${MODELPARAM_VALUE.TIME_CMP}
}

proc update_MODELPARAM_VALUE.TIME_READ { MODELPARAM_VALUE.TIME_READ PARAM_VALUE.TIME_READ } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.TIME_READ}] ${MODELPARAM_VALUE.TIME_READ}
}

