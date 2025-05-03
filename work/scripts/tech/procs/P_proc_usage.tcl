proc P_proc_usage {opts_l message} {
  array set opts_a $opts_l
  puts [join $opts_a(usage) "\n"]
  if {$message != ""} {
    puts "\n$message"
  }
  puts  ""
  return ""
}
