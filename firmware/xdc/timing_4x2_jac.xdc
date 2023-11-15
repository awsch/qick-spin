set clk_axi  [get_clocks -of_objects [get_nets -of_objects [get_pins d_1_i/zynq_ultra_ps_e_0/pl_clk0]]]
set clk_adc0 [get_clocks -of_objects [get_nets -of_objects [get_pins d_1_i/usp_rf_data_converter_0/clk_adc0]]]
set clk_dac0 [get_clocks -of_objects [get_nets -of_objects [get_pins d_1_i/usp_rf_data_converter_0/clk_dac0]]]
set clk_dac2 [get_clocks -of_objects [get_nets -of_objects [get_pins d_1_i/usp_rf_data_converter_0/clk_dac2]]]
set clk_adc0_x2 [get_clocks -of_objects [get_nets -of_objects [get_pins d_1_i/clk_adc0_x2/clk_out1]]]
set c_clk  [get_clocks -of_objects [get_nets -of_objects [get_pins  d_1_i/qick_processor_0/c_clk_i] ] ]
set t_clk  [get_clocks -of_objects [get_nets -of_objects [get_pins  d_1_i/qick_processor_0/t_clk_i] ] ]

set_clock_groups -name async_clks -asynchronous \
-group [get_clocks [get_clocks $clk_axi  ]] \
-group [get_clocks [get_clocks $clk_adc0 ]] \
-group [get_clocks [get_clocks $clk_dac0 ]] \
-group [get_clocks [get_clocks $clk_dac2 ]] \
-group [get_clocks [get_clocks $clk_adc0_x2 ]] \
-group [get_clocks [get_clocks $c_clk ]] \
-group [get_clocks [get_clocks $t_clk ]]

#set_clock_groups -name async_clks -asynchronous \
#-group [get_clocks -include_generated_clocks [get_clocks $clk_axi  ]] \
#-group [get_clocks -include_generated_clocks [get_clocks $clk_adc0 ]] \
#-group [get_clocks -include_generated_clocks [get_clocks $clk_dac0 ]] \
#-group [get_clocks -include_generated_clocks [get_clocks $clk_dac2 ]] \
#-group [get_clocks -include_generated_clocks [get_clocks $clk_adc0_x2 ]] \
#-group [get_clocks -include_generated_clocks [get_clocks $c_clk ]] \
#-group [get_clocks -include_generated_clocks [get_clocks $t_clk ]]


#-group [get_clocks -include_generated_clocks [get_clocks $clk_tproc ]]


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