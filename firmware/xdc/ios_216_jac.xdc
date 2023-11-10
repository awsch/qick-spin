### 216

## PMOD_0
set_property PACKAGE_PIN G15       [get_ports "PMOD0_0"] ;# Bank  88 VCCO - VCC1V8   - IO_L12N_AD8N_88
set_property PACKAGE_PIN G16       [get_ports "PMOD0_1"] ;# Bank  88 VCCO - VCC1V8   - IO_L12P_AD8P_88
set_property PACKAGE_PIN H14       [get_ports "PMOD0_2"] ;# Bank  88 VCCO - VCC1V8   - IO_L11N_AD9N_88
set_property PACKAGE_PIN H15       [get_ports "PMOD0_3"] ;# Bank  88 VCCO - VCC1V8   - IO_L11P_AD9P_88
set_property PACKAGE_PIN G13       [get_ports "PMOD0_4"] ;# Bank  88 VCCO - VCC1V8   - IO_L10N_AD10N_88
set_property PACKAGE_PIN H13       [get_ports "PMOD0_5"] ;# Bank  88 VCCO - VCC1V8   - IO_L10P_AD10P_88
set_property PACKAGE_PIN J13       [get_ports "PMOD0_6"] ;# Bank  88 VCCO - VCC1V8   - IO_L9N_AD11N_88
set_property PACKAGE_PIN J14       [get_ports "PMOD0_7"] ;# Bank  88 VCCO - VCC1V8   - IO_L9P_AD11P_88
set_property IOSTANDARD LVCMOS18   [get_ports "PMOD0*"]

## PMOD_1
set_property PACKAGE_PIN L17       [get_ports "PMOD1_0"] ;# Bank  88 VCCO - VCC1V8   - IO_L4N_AD12N_88
set_property PACKAGE_PIN M17       [get_ports "PMOD1_1"] ;# Bank  88 VCCO - VCC1V8   - IO_L4P_AD12P_88
set_property PACKAGE_PIN M14       [get_ports "PMOD1_2"] ;# Bank  88 VCCO - VCC1V8   - IO_L3N_AD13N_88
set_property PACKAGE_PIN N14       [get_ports "PMOD1_3"] ;# Bank  88 VCCO - VCC1V8   - IO_L3P_AD13P_88
set_property PACKAGE_PIN M15       [get_ports "PMOD1_4"] ;# Bank  88 VCCO - VCC1V8   - IO_L2N_AD14N_88
set_property PACKAGE_PIN N15       [get_ports "PMOD1_5"] ;# Bank  88 VCCO - VCC1V8   - IO_L2P_AD14P_88
set_property PACKAGE_PIN M16       [get_ports "PMOD1_6"] ;# Bank  88 VCCO - VCC1V8   - IO_L1N_AD15N_88
set_property PACKAGE_PIN N16       [get_ports "PMOD1_7"] ;# Bank  88 VCCO - VCC1V8   - IO_L1P_AD15P_88
set_property IOSTANDARD LVCMOS18   [get_ports "PMOD1*"]


## LED GPIO
set_property PACKAGE_PIN AN14      [get_ports "R_LED_tri_o[0]"] ;# Bank  64 VCCO - VCC1V2   - IO_T3U_N12_64
set_property PACKAGE_PIN AP16      [get_ports "R_LED_tri_o[1]"] ;# Bank  64 VCCO - VCC1V2   - IO_L19N_T3L_N1_DBC_AD9N_64
set_property PACKAGE_PIN AP14      [get_ports "R_LED_tri_o[2]"] ;# Bank  64 VCCO - VCC1V2   - IO_T2U_N12_64
set_property PACKAGE_PIN AU16      [get_ports "R_LED_tri_o[3]"] ;# Bank  64 VCCO - VCC1V2   - IO_L13N_T2L_N1_GC_QBC_64
set_property PACKAGE_PIN AW12      [get_ports "R_LED_tri_o[4]"] ;# Bank  64 VCCO - VCC1V2   - IO_T1U_N12_64
set_property PACKAGE_PIN AY16      [get_ports "R_LED_tri_o[5]"] ;# Bank  64 VCCO - VCC1V2   - IO_L7N_T1L_N1_QBC_AD13N_64
set_property PACKAGE_PIN BB12      [get_ports "R_LED_tri_o[6]"] ;# Bank  64 VCCO - VCC1V2   - IO_L1N_T0L_N1_DBC_64
set_property PACKAGE_PIN E25       [get_ports "R_LED_tri_o[7]"] ;# Bank  68 VCCO - VCC1V2   - IO_T3U_N12_68
set_property IOSTANDARD  LVCMOS12  [get_ports "R_LED*"] ;# Bank  64 VCCO - VCC1V2   - IO_T3U_N12_64

## LED PMOD
set_property PACKAGE_PIN C13       [get_ports "G_LED_0"] ;# Bank  87 VCCO - VCC1V8   - IO_L3N_AD13N_87
set_property PACKAGE_PIN D14       [get_ports "G_LED_1"] ;# Bank  87 VCCO - VCC1V8   - IO_L3P_AD13P_87
set_property IOSTANDARD  LVCMOS18  [get_ports "G_LED*"] ;# Bank  87 VCCO - VCC1V8   - IO_L3P_AD13P_87

## LED TRIG
set_property PACKAGE_PIN B26       [get_ports "B_LED_0"] ;# Bank  68 VCCO - VCC1V2   - IO_L19N_T3L_N1_DBC_AD9N_68
set_property IOSTANDARD  POD12_DCI [get_ports "B_LED_0"] ;# Bank  68 VCCO - VCC1V2   - IO_L19N_T3L_N1_DBC_AD9N_68




set_property BITSTREAM.CONFIG.UNUSEDPIN PULLUP [current_design]
set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN ENABLE [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
