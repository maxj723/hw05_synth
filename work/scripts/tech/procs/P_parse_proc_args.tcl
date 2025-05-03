proc P_parse_proc_args {proc_name opts proc_args} {
  set args $proc_args

  # Loop through the argument spec and set default values
  array set opts_a [P_parse_opts $proc_name $opts]
  set opt_list $opts_a(opt_list)
  array set type $opts_a(types)
  array set opt $opts_a(defaults) 


  # Loop through arguments passed to the proc and set values
  for {set i 0} {$i < [llength $args]} {incr i 1} {
    set arg_to_match  [lindex $args $i]
    set arg_name [P_parse_args_match $opt_list $arg_to_match]
    if {$arg_name == "multiple"} {
      P_proc_usage [array get opts_a] "  ERROR: Argument does not not specify a single argument : '$arg_to_match'" 
      return -level 2
    }

    # Check for unknown arg
    if {! [info exists type($arg_name)]} {
      P_proc_usage [array get opts_a] "  ERROR: Unknown argument : '$arg_to_match'" 
      return -level 2

    # toggle boolean value from 0->1 or 1->0 
    } elseif {$type($arg_name) eq "boolean"} {
      if [regexp {^-no} $arg_to_match] {
        set opt($arg_name) 0
      } else {
        set opt($arg_name) 1
      }

    # store value for optional args
    } elseif {$type($arg_name) eq "optional"} {
      set opt($arg_name)  [lindex $args [incr i]]

    # store value for required args
    } elseif {$type($arg_name) eq "required"} {
      set opt($arg_name)  [lindex $args [incr i]]
    }
  }

  # Help option
  if {[info exists opt(-help)] && $opt(-help)} {
    P_proc_usage [array get opts_a ] ""
    return -level 2
  }

  # Man option
  if {[info exists opt(-man)] && $opt(-man)} {
    P_proc_man_page [array get opts_a] 
    return -level 2
  }

  # Check to see if required arguments are missing
  foreach o $opt_list {
    if {$opts_a($o,type) eq "required" && $opt($o) == "undefined" } {
      P_proc_usage [array get opts_a] "  ERROR: Required argument missing: $o"
      return -level 2
    }
  }
 
  # Check file
  foreach o $opt_list {
    if {$opts_a($o,check) == "file" && ! [file exists $opt($o)]} {
      P_proc_usage [array get opts_a] "  ERROR: File '$o $opt($o)' does not exist."
      return -level 2
    }
  }

  # Check one of
  foreach o $opt_list {
    set check_key  [lindex $opts_a($o,check) 0]
    set check_val  [lindex $opts_a($o,check) 1]
    if { $check_key eq "one_of" &&  [lsearch $check_val $opt($o) ] < 0 } {
      P_proc_usage [array get opts_a] "  ERROR: Argument value '$o $opt($o)' must be one of : \{$check_val\}"
      return -level 2
    }
  }

  return [array get opt]
}
