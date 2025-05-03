proc P_parse_opts {proc_name opts} {
  set opt_keys {usage info summary description}
  set arg_keys {type default info check description}
  set opts_a(proc_name) $proc_name

  # setup opt_keys to have array entries
  foreach i $opt_keys { set opts_a($i) ""}

  # get widths of args and default values so the usage looks nice
  lassign [P_parse_get_max_string_length $opts 15 15] arg_width default_width
  set usage [list]
  set opt_list [list]
  lappend usage ""
  lappend usage [format "  %-${arg_width}s    %-${default_width}s  %s " "Argument Name"   "Default Value"   "Description (arg_type) <check>"]
  lappend usage [format "  %-${arg_width}s    %-${default_width}s  %s " "---------------" "---------------" "---------------------------------------"]

  foreach {key val}  $opts {
    if {$key == "usage"} { 
      lappend usage $val
      continue
    }

    if {$key == "description"} { 
      set opts_a(description) $val
      continue
    }

    if {$key == "info"} { 
      set opts_a(info) $val
      continue
    }

    if {$key == "summary"} { 
      set opts_a(summary) $val
      lappend usage "\n  Summary"
      lappend usage [P_prepend_s $val "    "] 
      continue
    }

    if {[regexp {^-} $key]} {
      lappend opt_list $key
      foreach i $arg_keys { set opts_a($key,$i) ""}
      foreach {arg_key arg_val} $val {
        set opts_a($key,$arg_key) $arg_val
      }
      # For boolean
      if {$opts_a($key,type) eq "boolean" && $opts_a($key,default) eq ""} {
        set opts_a($key,default) 0
      }
      if {$opts_a($key,type) eq "required" && $opts_a($key,default) eq {}} {
        set opts_a($key,default) undefined
      }
      set chk $opts_a($key,check)
      if {$chk != ""} { set chk "<check $chk>" }
      set default $opts_a($key,default)
      if {$default eq ""} { set default "\"$default\"" }
      if {$default eq "undefined"} { set default "\"\"" }
      if {[regexp { } $default]} { set default "\"$default\"" }
      lappend usage [format "    %-${arg_width}s  %-${default_width}s  %s (%s) %s" $key  $default   [string totitle $opts_a($key,info)]  $opts_a($key,type) $chk]

    } else {
      if {! [regexp {\S*} $key]} {
        puts "ERROR : Unknown opt type: key='$key' val=$val'"; 
        return -level 2
      }
      lappend usage $val
 
    }
  }

  set proc_info ""
  if {$opts_a(info) ne ""} {
    set proc_info " - $opts_a(info)"
  }
  set usage [linsert $usage 0  "\n  Usage: $proc_name \[options\] required $proc_info"]
  set opts_a(opt_list) [lsort -uniq $opt_list]

  foreach o $opt_list {
    set type($o) $opts_a($o,type)
    set opt($o) $opts_a($o,default)
  }
  set opts_a(types) [array get type]
  set opts_a(defaults) [array get opt]
  set opts_a(usage) $usage

  #puts " [array get opts_a]"
  #parray opts_a
  return [array get opts_a]
}
