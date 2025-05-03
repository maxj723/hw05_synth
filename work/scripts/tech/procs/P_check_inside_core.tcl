proc P_check_inside_core {args} {
  # get the name of this proc
  regsub {::} [lindex [info level 0] 0] {} proc_name

  # PROC OPTS ENTRY
  set opts {
    info    {This procedure a value greater than 0 if the coordinate exists inside design boundary.}
    usage "\n  Required"
    -x      { type {required}  default {} info {x coordinate to check if inside the design boundary.} }
    -y      { type {required}  default {} info {y coordinate to check if inside the design boundary.} }

    usage "\n  Misc"
    -help     { type  {boolean}   default {0}              info {shows this usage} }
    -man      { type  {boolean}   default {0}              info {shows man page} }

    man_page { The procedures will return greater than 0 if the coordinate exists inside the design boundary. }

    description { The procedures will return greater than 0 if the coordinate exists inside the design boundary. }

  }

  array set opt [P_parse_proc_args $proc_name $opts $args]

  ###################################################
  # Proc starts here
  ###################################################

  set inner_list [get_computed_shapes -output polygon [get_db designs .boundary ]]
  set newcoord [list $opt(-x) $opt(-y) [format "%.3f" [expr $opt(-x) + .001]] [format "%.3f" [expr $opt(-y) + .001]]]
  set shapeList [get_computed_shapes -output polygon $newcoord INSIDE $inner_list]
  return [llength $shapeList]
}
