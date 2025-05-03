proc P_find_direction {start end} {
  set startx [lindex $start 0]
  set starty [lindex $start 1]
  set endx [lindex $end 0]
  set endy [lindex $end 1]
  if {$startx == $endx && $starty==$endy} {
    return "nochange"
  } elseif {$startx<$endx && $starty==$endy} {
    return "right"
  } elseif {$startx==$endx && $starty<$endy} {
    return "up"
  } elseif {$startx>$endx && $starty==$endy} {
    return "left"
  } elseif {$startx==$endx && $starty>$endy} {
    return "down"
  } else {
    puts "Cannot determine direction:$startx:$starty:$endx:$endy:start and end"

  }
}
