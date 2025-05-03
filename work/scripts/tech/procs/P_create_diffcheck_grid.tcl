proc P_create_diffcheck_grid {start width step stop {hard_macro_refs ""}} {
  global vars
  set tile_name $vars(INTEL_STDCELL_TILE)
  set SH_height [lindex [get_db [get_db [get_db rows] -if {.site.name == $tile_name } ] .site.size.y] 0]
  set my_list1 [get_computed_shapes -output rect  [get_db designs .boundary]]

  puts "Starting create_diffcheck_grid "
  puts "Deleting existing diffCheck layer objects"
  delete_routes -layer diffCheck -net _NULL
  puts "Done removing diffCheck "

  puts "Adding diffCheck across whole design "

  foreach k $my_list1 {
    scan $k "%f %f %f %f" b_llx b_lly b_urx b_ury
    set loop_counter_y [expr $start + $b_lly]
    while { $loop_counter_y < [expr $b_ury - $stop] } {
      create_shape -layer diffCheck -rect [list $b_llx $loop_counter_y  $b_urx [expr $loop_counter_y + $width]]
      set loop_counter_y [expr $loop_counter_y + $step]
    }
  }

  puts "Done adding diffCheck across whole design "

  # Remove user shapes over HIP/DIC

  puts "Getting hard macro cell list"
  set hard_macro_cells ""
  if {![info exists vars(hard_macro_refs)]} {
    set vars(hard_macro_refs) ""
  }

  if { $vars(hard_macro_refs) == "" } {
    ## Assuming all objects > 4x std.cell height to be macros
    foreach i [get_db insts -if .bbox.width>[expr 4 * $SH_height]] {
      if { $i != "" } {
        set temp_var [get_db $i .name]
        lappend  hard_macro_cells $i
      }
    }
  } else {
    foreach cell $vars(hard_macro_refs) {
      lappend hard_macro_cells [get_db insts -if .base_cell.name==${cell}]
    }
  }
  puts "Done getting hard macro cell list"

  puts "Carving out grid check over hard macro areas "

  foreach j $hard_macro_cells {

    if { $j != "" } {
       foreach boxVal [get_computed_shapes -output rect [get_db $j .overlap_rects]] {
        select_routes -layer diffCheck -net _NULL
        edit_cut_route -selected -box $boxVal
        delete_routes -layer diffCheck -net _NULL -area [get_computed_shapes -output rect $boxVal SIZE $width]
      }
    }
  }
}
