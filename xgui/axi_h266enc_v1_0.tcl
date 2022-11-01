# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "COMP_DATA_BITS" -parent ${Page_0}
  ipgui::add_param $IPINST -name "COMP_DATA_IDX_BITS" -parent ${Page_0}


}

proc update_PARAM_VALUE.COMP_DATA_BITS { PARAM_VALUE.COMP_DATA_BITS } {
	# Procedure called to update COMP_DATA_BITS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.COMP_DATA_BITS { PARAM_VALUE.COMP_DATA_BITS } {
	# Procedure called to validate COMP_DATA_BITS
	return true
}

proc update_PARAM_VALUE.COMP_DATA_IDX_BITS { PARAM_VALUE.COMP_DATA_IDX_BITS } {
	# Procedure called to update COMP_DATA_IDX_BITS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.COMP_DATA_IDX_BITS { PARAM_VALUE.COMP_DATA_IDX_BITS } {
	# Procedure called to validate COMP_DATA_IDX_BITS
	return true
}


proc update_MODELPARAM_VALUE.COMP_DATA_BITS { MODELPARAM_VALUE.COMP_DATA_BITS PARAM_VALUE.COMP_DATA_BITS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.COMP_DATA_BITS}] ${MODELPARAM_VALUE.COMP_DATA_BITS}
}

proc update_MODELPARAM_VALUE.COMP_DATA_IDX_BITS { MODELPARAM_VALUE.COMP_DATA_IDX_BITS PARAM_VALUE.COMP_DATA_IDX_BITS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.COMP_DATA_IDX_BITS}] ${MODELPARAM_VALUE.COMP_DATA_IDX_BITS}
}

