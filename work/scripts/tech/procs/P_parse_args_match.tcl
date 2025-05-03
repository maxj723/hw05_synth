proc P_parse_args_match {opt_list arg_to_check} {
  #puts "opt_list=$opt_list"
  set match ""
  regsub {^-no} $arg_to_check {-} noarg_to_check
  foreach a [list $noarg_to_check] {
  foreach o $opt_list {
    #puts "a=$a o=$o"
    if {$a == $o} {
      return $o
    } elseif {[regexp $a $o]} {
      if {$match != ""} {
        #puts "multiple"
        return "multiple"
      } else {
        set match $o
      }
    }
  }
  }
  return $match
}
