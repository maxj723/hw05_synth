

# read the synthesized netlist
read_verilog synth/soc.v

# set design top
set_db design_top soc

# read the DEF files
read_def <path_to_def_file>/<def_file_name>.def

#create a floorplan
create_floorplan
report_floorplan
report_design

#create straps
create_power_straps ... # Specify layers, widths, spacing, etc.

#create rings
create_power_rings ... # Specify layers, widths, spacing, etc.


# create power pins
create_pg_pin ... # Specify locations and layers for power/ground pins

place_design ... # Specify placement strategy and constraints

create_clock ... # Specify clock source, period, and name

create_clock_tree ... # Specify clock tree options and constraints

route_design ... # Specify routing options and constraints

route_opt_design ... # Specify optimization goals and constraints

check_design_rules ... # Specify DRC rules and options

check_lvs ... # Specify LVS options

read_sdc <path_to_sdc_file>/<sdc_file_name>.sdc
report_timing ... # Specify timing constraints and report options

write_def <path_to_output_def>/<output_def_name>.def

write_gds <path_to_output_gds>/<output_gds_name>.gds



