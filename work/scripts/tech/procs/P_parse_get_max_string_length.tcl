proc P_parse_get_max_string_length {opts min0 min1} {
  set max0 [list $min0]
  set max1 [list $min1]
  foreach {key val} $opts {
    if {[regexp {^-} $key]} {
      array set val_a $val
      lappend max0 [string length $key]
      if [info exists val_a(default)] {
        lappend max1 [string length $val_a(default)]
      }
    }
  }
  set max0 [lindex [lsort -int -decr $max0] 0]
  set max1 [lindex [lsort -int -decr $max1] 0]
  return [list  $max0 $max1 ]
}
