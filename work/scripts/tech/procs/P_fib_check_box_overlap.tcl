proc P_fib_check_box_overlap {x1 y1 x2 y2} {
  global vars
  set win "{[format "%.3f" [expr $x1 + 0.045]] [format "%.3f" [expr $y1 + 0.035]] [format "%.3f" [expr $x2 - 0.045]] [format "%.3f" [expr $y2 - 0.035]]}"
  set cellInst [get_obj_in_area -areas $win -obj_type inst]
set cellInst2 {}
  if {$cellInst!= ""} {
    foreach cellInst_2 $cellInst {
      set tap [get_db $cellInst_2 .base_cell.name ]
      if {!($tap eq $vars(INTEL_TAP_CELL)) && ![regexp "TAP" [get_db $cellInst_2 .name]]} {
        if {[get_db $cellInst_2 .location.x]==0.0 && [get_db $cellInst_2 .location.y]==0.0 } {
          continue
        } else {
          set inner_list [get_computed_shapes -output polygon [get_db $cellInst_2 .bbox]]
          set shapeList [get_computed_shapes -output polygon $win INSIDE $inner_list]
          if {  [llength $shapeList] == 1 } {
            lappend cellInst2 $cellInst_2
          }
          set shapeList [get_computed_shapes -output polygon $win AND $inner_list]
          if {  [llength $shapeList] == 1 } {
            lappend cellInst2 $cellInst_2
          }
        }
      }
    }
  }
  return [llength $cellInst2]

}
