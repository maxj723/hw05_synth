proc P_check_overlap args {
  # get the name of this proc
  regsub {::} [lindex [info level 0] 0] {} proc_name

  # PROC OPTS ENTRY
  set opts {
    info    {This procedure will return the number of cells that overlay a set of coordinates provided.}
    usage "\n  Required"
    -box      { type {required}  default {} info {Box coordinates to check if there are any existing instance already located in that area.} }

    usage "\n  Misc"
    -help     { type  {boolean}   default {0}              info {shows this usage} }
    -man      { type  {boolean}   default {0}              info {shows man page} }

    man_page { The procedures will returns value greater than 0 if there are any cells within the box provided.} 

    description { The procedures will returns value greater than 0 if there are any cells within the box provided.} 

  }

  array set opt [P_parse_proc_args $proc_name $opts $args]

  ###################################################
  # Proc starts here
  ###################################################

  set box $opt(-box)
  set cellInst2 {}
  set cellInst [get_obj_in_area -area $box -obj_type inst]
  if {$cellInst!= ""} {
    foreach cell $cellInst {
      set inner_list [get_computed_shapes -output polygon [get_db $cell .place_halo_polygon]]
      set shapeList [get_computed_shapes -output polygon $box INSIDE $inner_list]
      if { [llength $shapeList] == 1 } {
        lappend cellInst2 $cell
      }
      set shapeList [get_computed_shapes -output polygon $box AND $inner_list]
      if { [llength $shapeList] == 1 } {
        lappend cellInst2 $cell
      }
    }
  }
  return [llength $cellInst2]
}
