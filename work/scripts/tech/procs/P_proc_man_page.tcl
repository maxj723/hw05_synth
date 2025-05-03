proc P_proc_man_page {opts_l} {
  array set opts_a $opts_l

  puts "\nNAME"
  puts [P_prepend_s $opts_a(proc_name) "  "]
  
  puts "\nINFO"
  puts [P_prepend_s $opts_a(info) "  "]

  puts "\nSUMMARY"
  puts [P_prepend_s $opts_a(summary) "  "]

  puts "\nARGUMENTS"
  foreach opt $opts_a(opt_list) {
    puts "  $opt : $opts_a($opt,type) - $opts_a($opt,info)"
    if {$opts_a($opt,default) != ""} {
      puts "    Default value : $opts_a($opt,default)"
    }
    if {$opts_a($opt,check) != ""} {
      puts "    Value check   : $opts_a($opt,check)"
    }
    if {$opts_a($opt,description) != ""} {
      puts [P_prepend_s $opts_a($opt,description) "    "]
    }
    puts ""
  }

  puts "DESCRIPTION"
  puts [P_prepend_s $opts_a(description) "  "]

  puts -nonewline "\nUSAGE"
  P_proc_usage $opts_l ""

  puts "DATE"
  puts "  [clock format [clock seconds]]\n\n"
}
