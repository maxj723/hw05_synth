##############################################################################
# STEP add_tap_cells
##############################################################################
create_flow_step -name add_tap_cells -skip_db -skip_metric -owner intel {

set wd $vars(INTEL_WS_X)
set ht $vars(INTEL_WS_Y)
set i 0 
floorplan_set_snap_rule -for PLK -grid IG -force
set macros_list ""
set macro_boxes ""
set macros_list [get_db insts -if {.base_cell.base_class == block || .base_cell.base_class == pad}]
if { $macros_list != ""} {
    set boxx ""
    foreach macro $macros_list {
    set m [ get_computed_shapes [get_db $macro .overlap_rects] ]  
    set boxx [get_computed_shapes  $m OR  $boxx]
    set macro_boxes [get_computed_shapes [get_computed_shapes $boxx   SIZEX $wd SIZEY $ht  ] OR [get_computed_shapes $boxx  ] ] 
    }
}


set single_height_tap $vars(INTEL_TAP_CELL)
set cellPtr [get_db base_cells -if {.name == $single_height_tap}]
set tap_cell_height [get_db $cellPtr .bbox.width ] ; # width always reports smaller edge. here width reports height
set tap_cell_width [get_db $cellPtr .bbox.length  ] ; # length always reports longer edge. here it is in x direction which is width
set top_boxes [get_computed_shapes [get_db designs .boundary] ANDNOT [get_computed_shapes [get_db designs .boundary] SIZEX -$wd SIZEY -$ht]]

set all_boxes [get_computed_shapes  $macro_boxes OR $top_boxes]

foreach box $all_boxes {
        #create_place_blockage -area \{$box\} -name macro_ws_$i -type hard 
        #
        set point1 [lindex $box 0]
        set point2 [lindex $box 1]
        set point3 [lindex $box 2]
        set point4 [lindex $box 3]
        set new_bbox_1 [list [expr $point1-[expr 1*$tap_cell_width]] [expr $point2-[expr 1*$tap_cell_height]] [expr $point1+[expr 1*$tap_cell_width]] [expr $point2+[expr 1*$tap_cell_height]]]
        set new_bbox_2 [list [expr $point3-[expr 1*$tap_cell_width]] [expr $point2-[expr 1*$tap_cell_height]] [expr $point3+[expr 1*$tap_cell_width]] [expr $point2+[expr 1*$tap_cell_height]]]
        set new_bbox_3 [list [expr $point3-[expr 1*$tap_cell_width]] [expr $point4-[expr 1*$tap_cell_height]] [expr $point3+[expr 1*$tap_cell_width]] [expr $point4+[expr 1*$tap_cell_height]]]
        set new_bbox_4 [list [expr $point1-[expr 1*$tap_cell_width]] [expr $point4-[expr 1*$tap_cell_height]] [expr $point1+[expr 1*$tap_cell_width]] [expr $point4+[expr 1*$tap_cell_height]]]
        create_place_blockage -area $new_bbox_1 -name tap_cell_blockage_macro -type hard
        create_place_blockage -area $new_bbox_2 -name tap_cell_blockage_macro -type hard
        create_place_blockage -area $new_bbox_3 -name tap_cell_blockage_macro -type hard
        create_place_blockage -area $new_bbox_4 -name tap_cell_blockage_macro -type hard

            }
                         
proc P_add_tap_cells_single_height {} {
  global vars
        set_cell_edge_spacing tap1 tap2 -spacing $vars(INTEL_TAP_GAP)
        set_cell_edge_spacing tap2 tap2 -spacing $vars(INTEL_TAP_GAP)
        set_cell_edge_spacing tap1 tap1 -spacing $vars(INTEL_TAP_GAP)
      if { [get_db base_cell:$vars(INTEL_TAP_CELL) .left_edge_type] != "tap1"  }  {
        set_cell_edge_type -cell $vars(INTEL_TAP_CELL) -left tap1
      }
      if { [get_db base_cell:$vars(INTEL_TAP_CELL) .right_edge_type] != "tap1" }  {
        set_cell_edge_type -cell $vars(INTEL_TAP_CELL) -right tap1
      }
  set upf_available [string is space [get_flow_config -quiet init_power_intent_files 1801]]
  if {!($upf_available)} {
 
set pd_names [get_db power_domains .name]
foreach pd $pd_names {
     

  if { [get_db base_cell:$vars(INTEL_TAP_CELL) .left_edge_type] != "tap1"  }  {
        set_cell_edge_type -cell $vars(INTEL_TAP_CELL)  -left tap1
      }
      if { [get_db base_cell:$vars(INTEL_TAP_CELL) .right_edge_type] != "tap1" }  {
        set_cell_edge_type -cell $vars(INTEL_TAP_CELL) -right tap1
      }
     add_well_taps -power_domain $pd -cell_interval $vars(INTEL_TAP_GAP) -cell $vars(INTEL_TAP_CELL) -prefix TAP_1H -incremental $vars(INTEL_TAP_CELL)

}
} else {
add_well_taps -cell_interval $vars(INTEL_TAP_GAP) -cell $vars(INTEL_TAP_CELL) -prefix TAP_1H -incremental $vars(INTEL_TAP_CELL)
}
  delete_cell_edge_spacing tap1 tap2
  delete_cell_edge_spacing tap1 tap1
  delete_cell_edge_spacing tap2 tap2
 
}


#####Add TAP cell with 2H and 1H height cells througout the design ########

P_add_tap_cells_single_height
delete_obj [get_db place_blockages tap_cell_blockage_macro]

#############################################################################
}
