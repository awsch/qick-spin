#######################################
## QICK DESIGN 111

## PMOD
set_property PACKAGE_PIN C17     [get_ports PMOD0_0];
set_property PACKAGE_PIN M18     [get_ports PMOD0_1];
set_property PACKAGE_PIN H16     [get_ports PMOD0_2];
set_property PACKAGE_PIN H17     [get_ports PMOD0_3];
set_property IOSTANDARD LVCMOS18 [get_ports PMOD0*]

set_property BITSTREAM.CONFIG.UNUSEDPIN PULLUP [current_design]
set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN ENABLE [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
