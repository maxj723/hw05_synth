##############################################################################
# STEP global_net_connect
##############################################################################
create_flow_step -name global_net_connect -skip_db -skip_metric -owner intel {

  # If the User has Macors/Blocks in the design which run on a different power supply,
  # The User should add global net connect command after the below commands, If override switch is used.
  # (example) globalNetConnect $vars(ground_nets_2) -type pgpin -pin vss* -inst Macro_ABC -override
  # (example) globalNetConnect $vars(ground_nets_2) -type pgpin -pin vcc* -inst Macro_ABC -override
  if {[llength [get_db pg_nets -if .is_power]] <= 0} {
    create_net -name [get_flow_config init_power_nets] -power -physical
  }
  if {[llength [get_db pg_nets -if .is_ground]] <= 0} {
    create_net -name [get_flow_config init_ground_nets]  -ground -physical
  }
  
  
  # Ground
  set lib_cell_gnd_pins [get_db -unique [get_db insts .base_cell.pg_base_pins -if .pg_type==primary_ground] .base_name]
  set gnd [get_db  [get_db pg_nets -if .is_ground ] .name]
  if {[llength $gnd] > 1 } then { 
        P_msg_error "More than one ground net exist in the design. Please check the design inputs. There will be issues with global connect due to more than one ground net"
        exit 1
  }
  foreach gnd_pin $lib_cell_gnd_pins {
  connect_global_net $gnd -type pg_pin -pin_base_name $gnd_pin
  connect_global_net $gnd -type tie_lo -pin_base_name $gnd_pin
  }
  

  # Power
  set lib_cell_pwr_pins [get_db -unique [get_db insts .base_cell.pg_base_pins -if .pg_type==primary_power] .base_name]
  set pwr [get_db  [get_db pg_nets -if .is_power ] .name]
  if {[llength $pwr] > 1 } then { 
        P_msg_error "More than one power net exist in the design. Please check the design inputs. There will be issues with global connect due to more than one power net"
        exit 1
  }
  foreach pwr_pin $lib_cell_pwr_pins {
  connect_global_net $pwr -type pg_pin -pin_base_name $pwr_pin
  connect_global_net $pwr -type tie_hi -pin_base_name $pwr_pin
  }

  commit_global_net_rules

}
