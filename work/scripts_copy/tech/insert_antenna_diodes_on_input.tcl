##############################################################################
# STEP insert_antenna_diodes_on_input
##############################################################################
create_flow_step -name insert_antenna_diodes_on_input -skip_db -skip_metric -owner intel {


######################################################################
#procedure to find out the power domain from the coordinate given
######################################################################
proc get_power_domain_from_block_ip_coord {x y} {
  global vars
  set module ""
  set upf_available [string is space [get_flow_config -quiet init_power_intent_files 1801]]
  if {!($upf_available)} {

     foreach pdName [get_db power_domains] {
          if {$pdName != "" && [get_db $pdName .is_default] == "false"} {
                 set box_area_dmn [get_db $pdName .group.rects]
                 if { $box_area_dmn != "" } {
                        set inner_list [get_computed_shapes -output polygon [get_db $pdName .group.rects]]
                        set newcoord [list [format "%.3f" [expr $x + .001]] [format "%.3f" [expr $y + .001]] $x $y]
                        set shapeList [get_computed_shapes -output polygon  $newcoord INSIDE $inner_list]
                        if {  [llength $shapeList] == 1 } {
                           set module "[lindex [get_db $pdName .group.members.name] end]/"
                           if {$module == ""} {
                             set module ""
                           }
                        }
                 }
          }
     }
  } else {
  set module ""
  }
  return $module
}


puts " ## INFO ## Attaching diode cells to each block-level inputs ports..."
set count 0
set diodeCell [get_db base_cells [get_flow_config route_design_antenna_cell_name]]
if {$diodeCell == ""} {
  puts " ## ERROR ## Couldn't find a diode cell in the library called [get_flow_config route_design_antenna_cell_name]"
  puts " ## ERROR ## Quitting..."
  error 1
}


get_db base_cell:[get_flow_config route_design_antenna_cell_name] .base_pins -foreach {set diodeCellFTermName [get_db base_cell:[get_flow_config route_design_antenna_cell_name] .base_pins.base_name]}

foreach port [get_db ports -if {.net.is_clock ==false && .direction==in}] {
        if { [get_db $port .net] ne "" } {
                set netName [get_db $port .net.name]
		set ftermName [get_db $port .name]
		set instName "IN_PORT_DIODE_${count}"
		set x [get_db $port .location.x]
		set y [get_db $port .location.y]
		set module [get_power_domain_from_block_ip_coord $x $y]
		create_inst -cell [get_flow_config route_design_antenna_cell_name] -inst ${module}${instName}
		place_inst ${module}${instName} $x $y -placed
		connect_pin -inst ${module}${instName} -pin $diodeCellFTermName -net $netName
		incr count
	}
}

place_detail
set_db [get_db insts -if {.name == "IN_PORT_DIODE_*"}] .place_status fixed
puts " ## INFO ## Done. Added $count diode cell(s)."

}
