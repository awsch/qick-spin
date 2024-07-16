#######################################
## QICK DESIGN 111

set_property PACKAGE_PIN C17      [get_ports "PMOD0_0"] ;# PMOD0_0
set_property PACKAGE_PIN M18      [get_ports "PMOD0_1"] ;# PMOD0_1
set_property PACKAGE_PIN H16      [get_ports "PMOD0_2"] ;# PMOD0_2
set_property PACKAGE_PIN H17      [get_ports "PMOD0_3"] ;# PMOD0_3
set_property IOSTANDARD  LVCMOS12 [get_ports PMOD0*]

set_property PACKAGE_PIN J16      [get_ports "adc0_over_threshold1"] ;# PMOD0_4
set_property PACKAGE_PIN K16      [get_ports "adc0_over_threshold2"] ;# PMOD0_5
set_property PACKAGE_PIN H15      [get_ports "adc0_over_voltage"] ;# PMOD0_6
set_property PACKAGE_PIN J15      [get_ports "adc0_over_range"] ;# PMOD0_7
set_property IOSTANDARD  LVCMOS12 [get_ports "adc0_over_*"] ;# 

## COM PORTS
set_property PACKAGE_PIN L14      	[get_ports qcom_i[0] ] ;#PMOD1_0
set_property PACKAGE_PIN L15      	[get_ports qcom_i[1] ] ;#PMOD1_1
set_property PACKAGE_PIN M13      	[get_ports qcom_i[2] ] ;#PMOD1_2
set_property PACKAGE_PIN N13      	[get_ports qcom_i[3] ] ;#PMOD1_3
set_property PACKAGE_PIN M15      	[get_ports qcom_o[0] ] ;#PMOD1_4
set_property PACKAGE_PIN N15      	[get_ports qcom_o[1] ] ;#PMOD1_5
set_property PACKAGE_PIN M14      	[get_ports qcom_o[2] ] ;#PMOD1_6
set_property PACKAGE_PIN N14      	[get_ports qcom_o[3] ] ;#PMOD1_7
set_property IOSTANDARD  LVCMOS12 	[get_ports qcom*] ;#PMOD1

set_property PACKAGE_PIN L14      	[get_ports trig_o] ;#PMOD1_0
set_property IOSTANDARD  LVCMOS12 	[get_ports trig_o] ;#PMOD1

#set_property PACKAGE_PIN L14      	[get_ports PMOD1_0] ;#PMOD1_0
#set_property PACKAGE_PIN L15      	[get_ports PMOD1_1] ;#PMOD1_1
#set_property PACKAGE_PIN M13      	[get_ports PMOD1_2] ;#PMOD1_2
#set_property PACKAGE_PIN N13      	[get_ports PMOD1_3] ;#PMOD1_3
#set_property PACKAGE_PIN M15      	[get_ports PMOD1_4] ;#PMOD1_4
#set_property PACKAGE_PIN N15      	[get_ports PMOD1_5] ;#PMOD1_5
#set_property PACKAGE_PIN M14      	[get_ports PMOD1_6] ;#PMOD1_6
#set_property PACKAGE_PIN N14      	[get_ports PMOD1_7] ;#PMOD1_7
#set_property IOSTANDARD  LVCMOS12 	[get_ports PMOD1*] ;#PMOD1

set_property BITSTREAM.CONFIG.UNUSEDPIN PULLUP [current_design]
set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN ENABLE [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
