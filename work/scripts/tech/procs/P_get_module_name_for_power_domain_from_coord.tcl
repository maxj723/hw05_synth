proc P_get_module_name_for_power_domain_from_coord args {
  # get the name of this proc
  regsub {::} [lindex [info level 0] 0] {} proc_name

  # PROC OPTS ENTRY
  set opts {
    info    {This procedure will return the module name for cell placed at a certain x y coordinate.}
    usage "\n  Required"
    -x      { type {required}  default {} info {Specify x coord to find module name from }}
    -y      { type {required}  default {} info {Specify y coord to find module name from }}

    usage "\n  Misc"
    -help     { type  {boolean}   default {0}              info {shows this usage} }
    -man      { type  {boolean}   default {0}              info {shows man page} }

    man_page { The procedures will return the module name for an instance added at a certain coordinate for the lower left x/y coordinate.}

    description { The procedures will return the module name for an instance added at a certain coordinate for the lower left x/y coordinate.}
  }

  array set opt [P_parse_proc_args $proc_name $opts $args]
  
  ###################################################
  # Proc starts here
  ###################################################
  foreach pdName [get_db power_domains .name] {
    if {$pdName != ""} {
      if {[get_db [get_db power_domains $pdName] .is_default]} {
        continue
      }
      set box_area_dmn [get_db [get_db power_domains $pdName] .group.rects]
      if {$box_area_dmn == ""} {
        continue
      }
      set inner_list [get_computed_shapes -output polygon [get_db [get_db power_domains $pdName] .group.rects]]
      set newcoord [list $opt(-x) $opt(-y) [format %.3f [expr $opt(-x) + .001]] [format %.3f [expr $opt(-y) + .001]]]
      set shapeList [get_computed_shapes -output polygon $newcoord INSIDE $inner_list]
      if { [llength $shapeList] == 1 } {
        set module "[lindex [get_db [get_db power_domains $pdName] .group.members.name] end]/"
      }
    }
  }
  if {![info exists module]} {
    set module ""
  }
  return $module
}
