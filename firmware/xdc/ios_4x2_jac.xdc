#######################################
## QICK DESIGN 4x2  

## PMOD
set_property PACKAGE_PIN AF16 [ get_ports "PMOD0_0" ]
set_property PACKAGE_PIN AG17 [ get_ports "PMOD0_1" ]
set_property PACKAGE_PIN AJ16 [ get_ports "PMOD0_2" ]
set_property PACKAGE_PIN AK17 [ get_ports "PMOD0_3" ]
set_property PACKAGE_PIN AF15 [ get_ports "PMOD0_4" ]
set_property PACKAGE_PIN AF17 [ get_ports "PMOD0_5" ]
set_property PACKAGE_PIN AH17 [ get_ports "PMOD0_6" ]
set_property PACKAGE_PIN AK16 [ get_ports "PMOD0_7" ]
set_property IOSTANDARD LVCMOS18 [ get_ports "PMOD0*"]

set_property PACKAGE_PIN AW13 [ get_ports "PMOD1_0" ]
set_property PACKAGE_PIN AR13 [ get_ports "PMOD1_1" ]
set_property PACKAGE_PIN AU13 [ get_ports "PMOD1_2" ]
set_property PACKAGE_PIN AV13 [ get_ports "PMOD1_3" ]
set_property PACKAGE_PIN AU15 [ get_ports "PMOD1_4" ]
set_property PACKAGE_PIN AP14 [ get_ports "PMOD1_5" ]
set_property PACKAGE_PIN AT15 [ get_ports "PMOD1_6" ]
set_property PACKAGE_PIN AU14 [ get_ports "PMOD1_7" ]
set_property IOSTANDARD LVCMOS18 [ get_ports "PMOD1*"]


## USER LEDS
## CONECTED TO GPIO
set_property PACKAGE_PIN AR11 [ get_ports "W_LED_tri_o[0]" ]
set_property PACKAGE_PIN AW10 [ get_ports "W_LED_tri_o[1]" ]
set_property PACKAGE_PIN AT11 [ get_ports "W_LED_tri_o[2]" ]
set_property PACKAGE_PIN AU10 [ get_ports "W_LED_tri_o[3]" ]
set_property IOSTANDARD LVCMOS18 [ get_ports "W_LED*" ]

## CONECTED TO DATA PORTS
set_property PACKAGE_PIN AM7 [ get_ports "G_LED_0" ]
set_property IOSTANDARD LVCMOS18 [ get_ports "G_LED_0" ]
set_property PACKAGE_PIN AP8 [ get_ports "G_LED_1" ]
set_property IOSTANDARD LVCMOS18 [ get_ports "G_LED_1" ]

## CONECTED TO TRIG_1
set_property PACKAGE_PIN AN8 [ get_ports "B_LED_0" ]
set_property IOSTANDARD LVCMOS18 [ get_ports "B_LED_0" ]

set_property BITSTREAM.CONFIG.UNUSEDPIN PULLUP [current_design]
set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN ENABLE [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
