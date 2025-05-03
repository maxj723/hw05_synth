proc P_msg_info { args } {
  set prefix "#INFO-MSG==> "
  puts "$prefix [join [concat $args] { }]"
}
