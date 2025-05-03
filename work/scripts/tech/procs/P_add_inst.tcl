####################################
###########################################################################################################
# The following procedure run addInst and places the instance after checking for variant
###########################################################################################################
proc P_add_inst {args} {
  global vars
  parse_proc_arguments -args $args inputs
  set cell $inputs(-cell)
  set inst $inputs(-inst)
  set x $inputs(-x)
  set y $inputs(-y)
  set ori $inputs(-ori)
  set module [P_get_module_name_for_power_domain_from_coord -x $x -y $y ]
  set cell_widths [get_db [get_db base_cells $cell] .bbox.width]
  set box "[format "%.3f" [expr $x + 0.045]]  [format "%.3f"  [expr $y + .105]] [format "%.3f" [expr $x + $cell_widths -0.045]] [format "%.3f"  [expr $y + .106]]"
  if { [P_check_overlap -box $box] == 0 &&  [P_check_inside_core -x $x -y $y ] == 1  } {
    create_inst -physical -cell $cell -inst ${module}${inst} -status fixed -orient $ori
    place_inst  ${module}${inst} $x $y $ori -fixed
  }
}

define_proc_arguments P_add_inst  \
-info "This procedure will add inst . "  \
-define_args {
    {-cell   "Specify the cell to add " "val" string required }
    {-inst   "Specify the inst name to add it to " "val" string required }
    {-x      "Specify x coord to place the inst" "val" string required }
    {-y      "Specify y coord to place the inst" "val" string required }
    {-ori    "Specify orient for the cell" "val" string required }
  }
