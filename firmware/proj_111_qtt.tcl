###############################################################################
## FERMI RESEARCH LAB
###############################################################################
## Vivado Project Creation Script
###############################################################################

## Customizable Parameters

# Project Name 
set _xil_proj_name_  "top_111_Time_Tagger"
set timing_const     "timing_111_qtt.xdc"
set ios_const        "ios_111_qtt.xdc"
set bd_file          "bd_1adc_2dac_8t_qtt_23-1.tcl"
set board            "111"

# Posible board values : 111, 216, 4x2

###############################################################################
## Automated Script
###############################################################################

###############################################################################
# SET DIRECTORIES

# Set the reference directory for source file relative paths (by default the value is script directory path)
set origin_dir "."

# Use origin directory path location variable, if specified in the tcl shell
if { [info exists ::origin_dir_loc] } {
  set origin_dir $::origin_dir_loc
}

# Set the directory path for the original project from where this script was exported
set orig_proj_dir "[file normalize "$origin_dir/"]"

###############################################################################
# PROJECT

# Create project
create_project ${_xil_proj_name_} ./${_xil_proj_name_} -part xczu49dr-ffvf1760-2-e

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

###############################################################################
# SET PROJECT PROPERTIES

set obj [current_project]
set_property -name "default_lib" -value "xil_defaultlib" -objects $obj
set_property -name "enable_vhdl_2008" -value "1" -objects $obj
set_property -name "ip_cache_permissions" -value "read write" -objects $obj
set_property -name "ip_output_repo" -value "$proj_dir/${_xil_proj_name_}.cache/ip" -objects $obj
set_property -name "mem.enable_memory_map_generation" -value "1" -objects $obj
set_property -name "platform.board_id" -value "zcu216" -objects $obj
set_property -name "sim.central_dir" -value "$proj_dir/${_xil_proj_name_}.ip_user_files" -objects $obj
set_property -name "sim.ip.auto_export_scripts" -value "1" -objects $obj
set_property -name "simulator_language" -value "Mixed" -objects $obj

###############################################################################
# SET BOARD
set obj [current_project]

if { ${board} eq "111" } {
   # Board zcu_111
   puts "Board ZCU_111 Selected"
   set_property -name "board_part" -value "xilinx.com:zcu111:part0:1.4" -objects $obj
   set_property -name "platform.board_id" -value "zcu111" -objects $obj
} elseif { ${board} eq "216" } {
   # Board zcu_216
   puts "Board ZCU_216 Selected"
   set_property -name "board_part" -value "xilinx.com:zcu216:part0:2.0" -objects $obj
   set_property -name "platform.board_id" -value "zcu216" -objects $obj
} elseif { ${board} eq "216" } {
   # Board rfsoc_4x2
   puts "Board 4x2 Selected"
   set_property -name "board_part_repo_paths" -value "[file normalize "$origin_dir/board_files"]" -objects $obj
   set_property -name "board_part" -value "realdigital.org:rfsoc4x2:part0:1.0" -objects $obj
   set_property -name "platform.board_id" -value "rfsoc4x2" -objects $obj
} else {
   set errMsg "Board <$board> Not recognized, Options are 111, 216, 4x2 variable <board> to another value."
}

###############################################################################
# IP REPOSITORY

# Set IP repository paths
set obj [get_filesets sources_1]
set_property "ip_repo_paths" "[file normalize "$origin_dir/ip"]" $obj

# Rebuild user ip_repo's index before adding any source files
update_ip_catalog -rebuild


###############################################################################
# CONSTRAINTS

# Set 'constrs_1' fileset object
set obj [get_filesets constrs_1]

# Add/Import constrs file and set constrs file properties

set const_files [list \
	[ file normalize "$origin_dir/xdc/$timing_const"] 	\
	[ file normalize "$origin_dir/xdc/$ios_const"] 	\
]

add_files -fileset $obj $const_files


###############################################################################
# BLOCK DESIGN

# Source Block Design.
source [file normalize "$origin_dir/bd/$bd_file"]


###############################################################################
# MAKE WRAPPER

# Set sources_1 fileset object
set obj [get_filesets sources_1]

# Create HDL Wrapper.
make_wrapper -files [get_files d_1.bd] -top

# Add files to sources_1 fileset
set files [list \
  [file normalize "${origin_dir}/${_xil_proj_name_}/${_xil_proj_name_}.srcs/sources_1/bd/d_1/hdl/d_1_wrapper.v" ]\
]
add_files -fileset $obj $files

###############################################################################
# SYNTHESIS RUN

# Modify Current Synthesis
set_property strategy Flow_RuntimeOptimized [get_runs synth_1]
set_property name Flow_Fast [get_runs synth_1]

# Create Synthesis
create_run Performance -flow {Vivado Synthesis 2022} -strategy Flow_PerfOptimized_high

# Create Implementation NET DELAY
create_run Net_Delay -parent_run Performance -flow {Vivado Implementation 2022} -strategy Performance_NetDelay_high
set INC_DIR_Net_Delay [get_property directory [current_project]]/${_xil_proj_name_}.srcs/utils_1/imports/Net_Delay
set_property AUTO_INCREMENTAL_CHECKPOINT 1 [get_runs Net_Delay]
set_property AUTO_INCREMENTAL_CHECKPOINT.DIRECTORY $INC_DIR_Net_Delay [get_runs Net_Delay]

# Create Implementation Extra Timing Opt
create_run Timing -parent_run Performance -flow {Vivado Implementation 2022} -strategy Performance_ExtraTimingOpt
set INC_DIR_Timing [get_property directory [current_project]]/${_xil_proj_name_}.srcs/utils_1/imports/Timing
set_property AUTO_INCREMENTAL_CHECKPOINT.DIRECTORY $INC_DIR_Timing [get_runs Net_Delay]
set_property AUTO_INCREMENTAL_CHECKPOINT 1 [get_runs Timing]
set_property incremental_checkpoint.directive TimingClosure [get_runs Timing]

# Create Implementation Refine Placement
create_run Refine_Place -parent_run Performance -flow {Vivado Implementation 2022} -strategy Performance_RefinePlacement
set INC_DIR_Refine [get_property directory [current_project]]/${_xil_proj_name_}.srcs/utils_1/imports/Refine
set_property AUTO_INCREMENTAL_CHECKPOINT.DIRECTORY $INC_DIR_Refine [get_runs Refine_Place]
set_property AUTO_INCREMENTAL_CHECKPOINT 1 [get_runs Refine_Place]

current_run [get_runs Performance]
#launch_runs Performance Net_Delay Timing Refine_Place -jobs 5
