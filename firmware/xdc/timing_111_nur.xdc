# clk_axi    > 100 Mhz
# clk_adc0   > 64 Mhz
# clk_adc0x2 > 128 Mhz
# clk_dac0   > 409.6 Mhz

## Generated Clocks

## Clock Wizards

## tProcessor Clocks

set_clock_groups -name async_clks -asynchronous -group [get_clocks [get_clocks [get_clocks -of_objects [get_pins d_1_i/zynq_ultra_ps_e_0/pl_clk0]]]] -group [get_clocks [get_clocks [get_clocks -of_objects [get_pins d_1_i/usp_rf_data_converter_0/clk_adc0]]]] -group [get_clocks [get_clocks [get_clocks -of_objects [get_pins d_1_i/clk_adc0_x2/clk_out1]]]] -group [get_clocks [get_clocks [get_clocks -of_objects [get_pins d_1_i/usp_rf_data_converter_0/clk_dac1]]]]

