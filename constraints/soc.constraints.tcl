set delay_value 666
set clock_name [get_clocks clk]
set_input_delay  -clock $clock_name $delay_value [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay -clock $clock_name $delay_value [all_outputs]


#Default input transition or loading cons
#-----------------------------------------

set my_driving_cell b0mbfn000al1n08x5
if {[get_lib_cells */$my_driving_cell -quiet] != ""} {
    set_driving_cell -lib_cell $my_driving_cell [all_inputs]
    puts "==>INFORMATION: Setting driving cell to $my_driving_cell"
} else {
    set_input_transition 50 [all_inputs]
    puts "==>INFORMATION: Specified driving cell $my_driving_cell was not found. Setting default input transition as 50"
}


set_load 10 [all_outputs]
set_max_transition 350 *
set_max_fanout 30 [get_designs fdkex]
set_max_area 0

