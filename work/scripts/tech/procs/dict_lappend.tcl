proc dict_lappend {dictvar keylist args} {
  upvar 1 $dictvar dict
  if {[info exists dict] && [dict exists $dict {*}$keylist]} {
    set list [dict get $dict {*}$keylist]
  }
  lappend list [concat {*}$args]
  dict set dict {*}$keylist [concat {*}$list]
}
