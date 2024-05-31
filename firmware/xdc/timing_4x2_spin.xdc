# clk_axi    > 100 Mhz
# RF_IN_CLK  > 491.52 Mhz
# clk_adc0   > 245.76 Mhz
# clk_adc2   > 245.76 Mhz
# clk_adc0x2 > 491.52 Mhz
# clk_adc2x2 > 491.52 Mhz
# clk_dac0   > 491.52 Mhz

# c_clk > clk_adc0    = 245.76 Mhz 
# t_clk > clk_adc2x2  = 491.52 Mhz 

#ADC0 3.93216 GS
#ADC0 3.93216 GS
#DAC0 7.86432 GS

## Generated Clocks
set clk_axi  [get_clocks -of_objects [get_nets -of_objects [get_pins d_1_i/zynq_ultra_ps_e_0/pl_clk0]]]
set clk_adc0 [get_clocks -of_objects [get_nets -of_objects [get_pins d_1_i/usp_rf_data_converter_0/clk_adc0]]]
set clk_adc2 [get_clocks -of_objects [get_nets -of_objects [get_pins d_1_i/usp_rf_data_converter_0/clk_adc0]]]
set clk_dac0 [get_clocks -of_objects [get_nets -of_objects [get_pins d_1_i/usp_rf_data_converter_0/clk_dac0]]]

## Clock Wizards
set clk_adc0_x2 [get_clocks -of_objects [get_nets -of_objects [get_pins d_1_i/clk_adc0_x2/clk_out1]]]
set clk_adc2_x2 [get_clocks -of_objects [get_nets -of_objects [get_pins d_1_i/clk_adc2_x2/clk_out1]]]

## tProcessor Clocks
set c_clk  [get_clocks -of_objects [get_nets -of_objects [get_pins  d_1_i/qick_processor_0/c_clk_i] ] ]
set t_clk  [get_clocks -of_objects [get_nets -of_objects [get_pins  d_1_i/qick_processor_0/t_clk_i] ] ]

set_clock_groups -name async_clks -asynchronous \
-group [get_clocks [get_clocks $clk_axi  ]] \
-group [get_clocks [get_clocks $clk_adc0 ]] \
-group [get_clocks [get_clocks $clk_adc2 ]] \
-group [get_clocks [get_clocks $clk_dac0 ]] \
-group [get_clocks [get_clocks $clk_adc0_x2 ]] \
-group [get_clocks [get_clocks $clk_adc2_x2 ]] 



