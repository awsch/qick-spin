set clk_axi  [get_clocks -of_objects [get_nets -of_objects [get_pins d_1_i/zynq_ultra_ps_e_0/pl_clk0]]]
set clk_adc2 [get_clocks -of_objects [get_nets -of_objects [get_pins d_1_i/usp_rf_data_converter_0/clk_adc2]]]
set clk_dac2 [get_clocks -of_objects [get_nets -of_objects [get_pins d_1_i/usp_rf_data_converter_0/clk_dac2]]]
set clk_dac3 [get_clocks -of_objects [get_nets -of_objects [get_pins d_1_i/usp_rf_data_converter_0/clk_dac3]]]

set_clock_groups -name async_clks -asynchronous \
-group [get_clocks -include_generated_clocks [get_clocks $clk_axi ]] \
-group [get_clocks -include_generated_clocks [get_clocks $clk_adc2 ]] \
-group [get_clocks -include_generated_clocks [get_clocks $clk_dac2 ]] \
-group [get_clocks -include_generated_clocks [get_clocks $clk_dac3 ]]


#set_clock_group -name clk_axi_to_adc0_x2 -asynchronous \
#    -group [get_clocks $clk_axi] \
#    -group [get_clocks $clk_adc0_x2]
        
#set_clock_group -name clk_axi_to_dac0 -asynchronous \
#    -group [get_clocks $clk_axi] \
#    -group [get_clocks $clk_dac0]
            
#set_clock_group -name clk_axi_to_dac2 -asynchronous \
#    -group [get_clocks $clk_axi] \
#    -group [get_clocks $clk_dac2]
    
#set_clock_group -name clk_axi_to_tproc -asynchronous \
#    -group [get_clocks $clk_axi] \
#    -group [get_clocks $clk_tproc]
    
#set_clock_group -name clk_tproc_to_dac0 -asynchronous \
#    -group [get_clocks $clk_tproc] \
#    -group [get_clocks $clk_dac0]
    
#set_clock_group -name clk_tproc_to_dac2 -asynchronous \
#    -group [get_clocks $clk_tproc] \
#    -group [get_clocks $clk_dac2]
    
#set_clock_group -name clk_tproc_to_adc0_x2 -asynchronous \
#    -group [get_clocks $clk_tproc] \
#    -group [get_clocks $clk_adc0_x2]