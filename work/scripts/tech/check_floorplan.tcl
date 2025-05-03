##############################################################################
# STEP check_floorplan
##############################################################################
create_flow_step -name check_floorplan -skip_db -skip_metric -owner intel {

set x_div $vars(INTEL_MD_GRID_X)  
set y_div 0.090
set fp_boundary [get_computed_shapes [get_db current_design .boundary]]
set macro_blks [get_db insts -if {.base_cell.base_class == block || .base_cell.base_class == pad}]
#set pd_names [get_db current_design .groups.power_domain.name]
set pd_names [get_db power_domains]
set error_flag 0
P_msg_info "checking all vertical coordinates of Macro/Design are a multiple of 90n to avoid diff grid violations"

if {$macro_blks != ""} {
    foreach m_blks $macro_blks {
        set macro [split [regsub -all "\{||\}" [get_computed_shapes [get_db $m_blks .bbox]] ""] " "]
        set y [lindex $macro 1]
        if { [format "%.4f" [expr fmod( [expr $y*1000], [expr $y_div*1000] )]] != 0.0 } {
            P_msg_error "Block boundary vertical coordinate $y does not align with the diff grid requirement"
	        set error_flag 1
            return 1
        }
        set y [lindex $macro 3]
        if { [format "%.4f" [expr fmod( [expr $y*1000], [expr $y_div*1000] )]] != 0.0 } {
            P_msg_error "Block boundary vertical coordinate $y does not align with the diff grid requirement"
	        set error_flag 1
            return 1
        }
    }
}

foreach boundary $fp_boundary {
    set y [lindex $boundary 3]
    if { [format "%.4f" [expr fmod( [expr $y*1000], [expr $y_div*1000] )]] != 0.0 } {
        P_msg_error "Design boundary vertical coordinate $y does not align with the diff grid requirement"
	    set error_flag 1 
        return 1
    }
}

################################################################################################################
##Description :  This block of code is to Check if Voltage areas are on the double height stdcell site##########
################################################################################################################
set y_div_v [expr $vars(INTEL_MD_GRID_Y)*2 ]
P_msg_info "Checking to make sure voltage areas are on the double height stdcell site..."
set other_dmns [list]
set error_flag 0 
foreach power_dmn  $pd_names {
    if {$power_dmn != 0} {  
        if {[get_db $power_dmn .is_default] == "false"} {
            lappend other_dmns $power_dmn
        }
    } 
}

set total_pds [llength $other_dmns]
if {$total_pds != 0} {
    foreach domain  $other_dmns {
        if {[get_db $domain .group.rects] == ""} {
            P_msg_warn "No physical location found for power domain $domain. Please fix unless this is a virtual domain"
            continue
        }
        set box_locations [get_db $domain .group.rects]
        foreach k $box_locations {
            set x_ll [expr [lindex $k 0] / $x_div]
            set y_ll [expr [lindex $k 1] / $y_div_v]
            set x_ul [expr [lindex $k 2] / $x_div]
            set y_ul [expr [lindex $k 3] / $y_div_v]
            set int_x_ll [expr round ($x_ll)]
            set int_y_ll [expr round ($y_ll)]
            set int_x_ul [expr round ($x_ul)]
            set int_y_ul [expr round ($y_ul)]
            if {([expr $int_x_ll - $x_ll] != 0.0) || ([expr $int_y_ll - $y_ll] != 0.5) || ([expr $int_x_ul - $x_ul] != 0.0) || ([expr $int_y_ul - $y_ul] != 0.5) } {
                P_msg_error "Power domain $domain is not a aligend"
                set error_flag 1
                return 1
            }
        }
    }  
} else {
    P_msg_info "No Power domains Exist in the Design - skipping voltage area modular grid check"
}    
P_msg_info "Done: Checking to make sure voltage areas are on the modular grid..."

######################################################################################################################################
##Description : This block of code is to Check for narrow channel between macros or between macro and boundary narrow_channel_width < 1um 
######################################################################################################################################
set error_flag 0
delete_drc_markers
check_floorplan -narrow_channel $INTEL_WS_TO_WS_SPACING
set db_userType [get_db current_design .markers.user_type]
set db_box [get_db current_design .markers.bbox]
if {[regexp "narrowChannels" $db_userType] } {
    #puts $f "createPlaceBlockage -type hard -name NARROWCHANNEL -box $db_box
    P_msg_error "Detected the narrow channel width in the design at $db_box, please fix this issue first "
    set error_flag 1 
    return 1
}

###############################################################################################################################################
# Description : This block of code is to check if the outer whitespace for a macro satisfies the whitespace requirement ($INTEL_WS_X, $INTEL_WS_Y)  
###############################################################################################################################################
P_msg_info "Checking outer whitespace for all the blocks inside the design "
set macro_list [get_db insts -if {.base_cell.base_class == block || .base_cell.base_class == pad}]
if {$macro_list != ""} {
    foreach macro $macro_list {
        foreach  macro_box [get_computed_shapes [get_db $macro .overlap_rects] ] {
            if {[get_db [get_obj_in_area -area  $macro_box -obj_type place_blockage ] .rects] != ""} {
                set pb_box [get_computed_shapes [get_db [get_obj_in_area -area  $macro_box -obj_type place_blockage ] .rects] ]
	            for {set pb_counter 0} { $pb_counter < [llength $pb_box]} { incr pb_counter } {
 		            set ws_box [lindex $pb_box $pb_counter]
	 	            set X_width [expr [lindex $ws_box 2] - [lindex $ws_box 0]]
 		            set Y_height [expr [lindex $ws_box 3] - [lindex $ws_box 1]]
 		            if {$X_width > $Y_height} {
 			            set pb_width $Y_height
 			            set pb_dir "Horizontal"
 		            } else {
 			            set pb_width $X_width
  			            set pb_dir "Vertical"
  			        }
 	                if {$pb_dir == "Horizontal" && [expr $pb_width*1000] < [expr $vars(INTEL_WS_Y)*1000]} {
 		                P_msg_error "White Space blockage in horizontal at $ws_box is $pb_width < $vars(INTEL_WS_Y)"
		                set error_flag 1
	                    return 1
 	                } elseif {$pb_dir == "Vertical" && [expr $pb_width*1000] < [expr $vars(INTEL_WS_X)*1000]} {
 		                P_msg_error "White Space blockage in vertical at $ws_box is $pb_width < $vars(INTEL_WS_X)"
		                set error_flag 1
	                    return 1
		            }
 		        }
            } else {
                P_msg_error "No White space found for Macro [get_db $macro .name]"
                set error_flag 1
                return 1
            }
        }
    }
}
P_msg_info "Done : Checking outer whitespace for all the blocks inside the design" 

P_msg_info "Checking if partition dimension is modular-grid multiple"

 global env
 global vars
#Modular GRID Specific to Dot Process
global x_div
global y_div
#Block Floorplan Boundary
global fp_boundary
#Macro Blocks in Design
global macro_blks
#Top Level Terminals
global topTerm
#Power Domains within the Top Block
global pd_names

set x_div $vars(INTEL_MD_GRID_X)    
set y_div $vars(INTEL_MD_GRID_Y)
set fp_boundary [get_db designs .boundary]
set macro_blks [get_db insts -if {.base_cell.base_class == block || .base_cell.base_class == pad}]

set topTerm [get_db pins]
set pd_names [get_db power_domains]

    P_msg_info "Checking if coordinates of Floorplan are integer multiples of the modular grid."
    #redirect -file /dev/null {catch {set _bndry [compute_polygons -boolean or $poly_bndry $poly_bndry]}}
	set _bndry [lindex [get_computed_shapes -output polygon $fp_boundary OR $fp_boundary] 0]
    if { ! [info exists _bndry] } {
      P_msg_error "Floorplan is not valid, incomplete co-ordinate list passed"
    } elseif { $_bndry == 0 } {
      P_msg_error "Floorplan specified is not a valid polygon"
    } elseif { [llength $_bndry] == 0 } {
      P_msg_error "Floorplan specified has no defined area"
    } elseif { [llength $_bndry] < 4 } {
      P_msg_error "Floorplan specified is not a single polygon shape"
    } 
foreach new_bbox $_bndry {
set num_bbox [llength $new_bbox]    
for {set i 0} {$i<$num_bbox} {incr i} {
set x [lindex $new_bbox 0]
set y [lindex $new_bbox 1]
      if { [format "%.4f" [expr $x_div * (($x / $x_div) - round($x / $x_div))]] != 0.0 } {
        P_msg_error "Block boundary coordinate $x in location ($x,$y)is NOT n * $x_div."
        	}
      if { [format "%.4f" [expr $y_div * (($y / $y_div) - round($y / $y_div))]] != 0.0 } {
        P_msg_error "Block boundary coordinate $y in location ($x,$y) is NOT n * $y_div."
           }
 }   
}
P_msg_info "Done:Checking if partition dimension is modular-grid multiple"
	
###################################################################################################################
############################################################################################################
### Check if all macros are placed in the correct orientation
P_msg_info "Checking to make sure all macro cells have the correct orientation"
if {$macro_blks !=0} {
foreach inst $macro_blks {
set macro_name [get_db $inst .name]    
  set orientation [get_db $inst .orient]
  if {!([regexp -nocase {M(X|Y)} $orientation] || [regexp -nocase {R(0|180)} $orientation])} {
P_msg_error "The orientation of Macro cell $macro_name is incorrect. Should be either R0|MX|R180|MY..."
#Error - Stops for each loop
}
}
} else {
P_msg_info "No Macros in the Design: skipping orientation checks"
}
P_msg_info "Done: Checking to make sure all macro cells have the correct orientation..."

##############################################################################################################

#######Check if macros are on 1X of placement grid
P_msg_info "Checking if macros are placed on the modular grid..."
if {$macro_blks !=0} {
foreach inst $macro_blks {
  select_obj [get_db $inst .name]
  set instance [get_db $inst .name]
  set location_llx [get_db $inst .bbox.ll.x]
  set location_lly [get_db $inst .bbox.ll.y]
  set location_llx [expr $location_llx / $x_div]
  set location_lly [expr $location_lly / $y_div]
  set int_x [expr round($location_llx)]
  set int_y [expr round($location_lly)]
  if {([expr $int_x - $location_llx] != 0.0) || ([expr $int_y - $location_lly] != 0.0)} {
    P_msg_error "Macro cell $instance is not on the modular grid"
    # Don't use P_msg_error here.  It terminates the foreach loop.
  }
}
} else {
P_msg_info "No Macros exists in the Design:Skipping modular Grid check on Macros"
}
P_msg_info "Done: Checking if macros are placed on the modular grid..."





##################################################################################
## Check if ports are min width and min length                                  ##
##################################################################################
P_msg_info "Checking for ports that are not min width or min length..."
set topPin [get_db ports]
foreach port $topPin {
  set plength [get_db $port .depth]
  set pwidth [get_db $port .width]
  set player [get_db $port .layer.name]
  set pname [get_db $port .name]
  switch $player {
    "m3"  { set minlength 0.160 ; set sigwidth 0.044 }
    "m4"  { set minlength 0.160 ; set sigwidth 0.044 }
    "m5"  { set minlength 0.160 ; set sigwidth 0.044 }
    "m6"  { set minlength 0.160 ; set sigwidth 0.044 }
    "m7"  { set minlength 0.540 ; set sigwidth 0.180 }
    "m8"  { set minlength 0.540 ; set sigwidth 0.180 }
    "gmz" { set minlength 2.130 ; set sigwidth 0.540 }
    "gm0" { set minlength 2.130 ; set sigwidth 0.540 }
    "gmb" { set minlength 4.840 ; set sigwidth 1.000 }
  }
  set plength [format "%0.3f" $plength]
  set pwidth  [format "%0.3f" $pwidth]

  if { [expr $pwidth < $sigwidth] } {
    P_msg_error "Port $pname on layer $player has a width not matching the signal route width (signal: $sigwidth, actual: $pwidth)"
  } 
  if { [expr $plength < $minlength] } {
    P_msg_error "Port $pname on layer $player is not minimum length (min: $minlength, actual: $plength)"
  }

}
P_msg_info "Done: Checking for ports that are not min width or min length..."

####################################################################################################

### Check if Voltage areas are on modular-grid

P_msg_info "Checking to make sure voltage areas are on the modular grid..."
set other_dmns [list]

foreach power_dmn  $pd_names {
  if {$power_dmn != 0} {  
  if {[get_db $power_dmn .is_default] == "false"} {
    lappend  other_dmns $power_dmn
  }
 } 
}

set total_pds [llength $other_dmns]

if {$total_pds != 0} {
foreach domain  $other_dmns {
  if {[get_db $domain .group.rects] == ""} {
    P_msg_warn "No physical location found for power domain $domain. Please fix unless this is a virtual domain"
    continue
  }
  set box_locations [get_db $domain .group.rects]
  foreach k $box_locations {

    set x_ll [expr [lindex $k 0] / $x_div]
    set y_ll [expr [lindex $k 1] / $y_div]
    set x_ul [expr [lindex $k 2] / $x_div]
    set y_ul [expr [lindex $k 3] / $y_div]
    set int_x_ll [expr round ($x_ll)]
    set int_y_ll [expr round ($y_ll)]
    set int_x_ul [expr round ($x_ul)]
    set int_y_ul [expr round ($y_ul)]
    if {([expr $int_x_ll - $x_ll] != 0.0) || ([expr $int_y_ll - $y_ll] != 0.0) || ([expr $int_x_ul - $x_ul] != 0.0) || ([expr $int_y_ul - $y_ul] != 0.0) } {
      P_msg_error "Power domain $domain is not a intergral multiple of modular grid. Please contact your Intel representative."
    }
  }
}  
} else {
 P_msg_info "No Power domains Exist in the Design - skipping voltage area modular grid check"
}    
  P_msg_info "Done: Checking to make sure voltage areas are on the modular grid..."
####################################################################################################

########################################################################################################
###Check for Spacing requirements between Macros and also with respect to Floorplan boundary
P_msg_info "Checking for Spacing Requirements between Macros and Macro-Floorplan Boundary"
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
 
if {$macro_blks != 0} {
 foreach lst $macro_blks {   
  set mboundary_plain [get_computed_shapes -output polygon [get_db $lst .overlap_rects]]
  set macro_height [get_db $lst .bbox.length]
  set macro_width [get_db $lst .bbox.width]
  set mmbound  "[lindex [lindex $mboundary_plain 0] 0]"
  set mnew_b [concat [lindex $mboundary_plain 0]  \{$mmbound\}]
  set mboundary_tmp  \{$mnew_b\}
  set mboundary [lindex $mboundary_tmp 0]
  #set mboundary_reverse [lreverse $mboundary]
  #set mboundary $mboundary_reverse
  #puts "MBoundary is: $mboundary"
  # first determine the direction from the last point to the first point
  set startpoint [lindex $mboundary end-1]
  set endpoint [lindex $mboundary 0]
  set prev_direction [P_find_direction $startpoint $endpoint]
  set startpoint [lindex $mboundary 0]
  #set diebox [get_computed_shapes -output rect [get_db current_design .boundary]]
  set dieboxbnd [lindex [get_db current_design .boundary] 0]
  foreach endpoint $mboundary {
    #find the direction from $startpoint to $endpoint
    #is it going up, down, left, or right
	set x_div_mul [expr $x_div * 2]
    set direction [P_find_direction $startpoint $endpoint]
	#puts "Direction is :$direction"
    set startx [lindex $startpoint 0]
    set starty [lindex $startpoint 1]
    set endx [lindex $endpoint 0]
    set endy [lindex $endpoint 1]
   #puts "startX $startx"
   #puts "startY $starty"
   #puts "endx $endx"
   #puts "endy $endy"
   set pbox "[expr $startx-0.001] [expr $starty-0.001] [expr $startx+0.001] [expr $starty+0.001]"
   set ipbox [get_computed_shapes -output rect $pbox ANDNOT $dieboxbnd]
     if {$direction == "right"} {
   #puts "1st pbox $pbox and ipbox $ipbox"
   if {$ipbox != ""} {
    set ipbox_lx [lindex [lindex $ipbox 0] 0] 
    set ipbox_ly [expr [lindex [lindex $ipbox 0] 1] +0.001]
	set ipbox_ux [lindex [lindex $ipbox 0] 2]
	set ipbox_uy [lindex [lindex $ipbox 0] 3] 
	set ipbox_y [expr $ipbox_ly - $ipbox_uy]
	set ipbox_x [expr $ipbox_lx - $ipbox_ux]
	if {$ipbox_y == 0} {
    #Get floorplan boxes and see if Macro overlaps with it
    scan [list [get_computed_shapes -output rect [get_db current_design .boundary]]] "{{%f %f %f %f}}" fp_llx fp_lly fp_urx fp_ury
    #puts "Floorplan Boxes $fp_llx $fp_lly $fp_urx $fp_ury"
    #First check to see if Macro is on Floorplan Boundary or Atleast 2X (Modular Grid) Away from the floorplan Boundary
    set fp_overlap [expr $ipbox_ux -$fp_llx +0.001]
    #puts "Overlap value is:  $fp_overlap"
	if {($fp_overlap == 0) || ([expr $fp_overlap >= $x_div_mul])} {
	#Criteria for selecting Area to be searched is Y Direction (Die Boundary - Cell Height), X Direction ( fixed to X_Modular Grid + 0.01)
	set area_box "[expr $ipbox_ux-$x_div+0.001] [expr $ipbox_ly - 0] [expr $ipbox_ux-$x_div+0.001] [expr $ipbox_uy+$macro_height]"
	#puts "On Horizontal boundary: pbox - $pbox IP box $ipbox and also Area query box $area_box , Diebox- $dieboxbnd"
	#puts "Values $ipbox_lx and $ipbox_ux "	
	set macro_vic [get_db [get_obj_in_area -area "$area_box"] -if {.base_cell.base_class == block || .base_cell.base_class == pad}]	
	#puts "Macro in the vicinity [get_db $macro_vic .name] of another macro [get_db $lst .name]"
 if {($macro_vic !=0) && ($macro_vic != $lst)} {
    foreach mac $macro_vic {
     #Got another Macro
     #First see if MAcro is abutting
   	set macro_box [get_computed_shapes -output rect [get_db $lst .overlap_rects]]
    set adjacent_macro_loc [get_computed_shapes -output rect [get_db $mac .overlap_rects]]
    set adjacent_macro [get_db $mac .name]
    set x_coord_macro [lindex [lindex $macro_box 0] 0]
    set x_coord_adj_macro [lindex [lindex $adjacent_macro_loc 0] 2]
    set adj_box [expr $x_coord_macro - $x_coord_adj_macro]
       # puts "Direction is right macro_box $macro_box , Adj macro - $adjacent_macro , Adjacent Macro Loc - $adjacent_macro_loc Overlapping box - $adj_box"
        if {$adj_box != 0} {
	    #No abuttment of Macros- error msg print 
        set temp_var1 [get_db $lst .name]
        P_msg_error "For Every Macro on the Flooplan Boundary, Make sure the Macro-Macro edge distance is either 2X Modular Grid or Abutting each other for Macro pairs -$adjacent_macro and $temp_var1"
    	}
        }
    }    
	} else {
	set temp_var1 [get_db $lst.name]
	 P_msg_error "For every macro on ASIC Block edge, Make sure the Macro is either on the Floorplan boundary or atleast 2X Modular Grid away from the Floorplan $fp_urx boundary for Macro -  $temp_var1"
	}
	}
   }
 } elseif {$direction == "up"} {
   if {$ipbox != ""} {
    set ipbox_lx [lindex [lindex $ipbox 0] 0] 
    set ipbox_ly [expr [lindex [lindex $ipbox 0] 1] +0.001]
	set ipbox_ux [lindex [lindex $ipbox 0] 2]
	set ipbox_uy [lindex [lindex $ipbox 0] 3] 
	set ipbox_y [expr $ipbox_ly - $ipbox_uy]
	if {$ipbox_y == 0} {
    #Get floorplan boxes and see if Macro overlaps with it
    scan [list [get_computed_shapes -output rect [get_db designs .boundary]]] "{{%f %f %f %f}}" fp_llx fp_lly fp_urx fp_ury
    #puts "Floorplan Boxes $fp_llx $fp_lly $fp_urx $fp_ury"
	#First check to see if Macro is on Floorplan Boundary or Atleast 2X (Modular Grid) Away from the floorplan Boundary
	set fp_overlap [expr $fp_urx - $ipbox_ux -0.001]
    #puts "Overlap value is : $fp_overlap"
    if {($fp_overlap == 0) || ([expr $fp_overlap >= $x_div_mul])} {
    #Criteria for selecting Area to be searched is Y Direction (Die Boundary - Cell Height), X Direction ( fixed to X_Modular Grid + 0.01)
	set area_box "[expr $ipbox_ux+$x_div-0.001] [expr $ipbox_ly - 0] [expr $ipbox_ux+$x_div-0.001] [expr $ipbox_uy+$macro_height]"
	#puts "On Horizontal boundary: pbox - $pbox IP box $ipbox and also Area query box $area_box , Diebox- $dieboxbnd"
	#puts "Values $ipbox_lx and $ipbox_ux "	
	set macro_vic [get_db [get_obj_in_area -area "$area_box"] -if {.base_cell.base_class == block || .base_cell.base_class == pad}]	
	#puts "$macro_vic"
    #Check to see if it is The Same (for Rectilinear Types)
    if {($macro_vic !=0) && ($macro_vic != $lst)} {
	 foreach mac $macro_vic {
	 	#Got another Macro
        #First see if MAcro is abutting
    set macro_box [get_computed_shapes -output rect [get_db $lst .overlap_rects]]
    set adjacent_macro_loc [get_computed_shapes -output rect [get_db $mac .overlap_rects]]
    set adjacent_macro [get_db $mac .name]
    set x_coord_macro [lindex [lindex $macro_box 0] 2]
    set x_coord_adj_macro [lindex [lindex $adjacent_macro_loc 0] 0]
    set adj_box [expr $x_coord_macro - $x_coord_adj_macro]
     #puts "Direction is up macro_box $macro_box, Adj macro - $adjacent_macro , Adjacent Macro Loc - $adjacent_macro_loc Overlapping box - $adj_box"
     if {$adj_box != 0} {
      #No abuttment of Macro Cells, Error Msg print   
      set temp_var1 [get_db $lst .name]
      P_msg_error "For Every Macro on the Flooplan Boundary -Make sure the Macro-Macro Edge distance is either 2X Modular Grid or Abutting each other for Macro pair -$adjacent_macro and $temp_var1"
    }
    }
    }
 } else {
  set temp_var1 [get_db $lst .name]
  P_msg_error "For every macro on ASIC Block edge, Make sure the Macro is either on the Floorplan boundary or atleast 2X Modular Grid away from the Floorplan $fp_llx boundary for Macro - $temp_var1"
 }
}
}
} elseif {$direction == "left"} {
   if {$ipbox != ""} {
    set ipbox_lx [lindex [lindex $ipbox 0] 0] 
    set ipbox_ly [expr [lindex [lindex $ipbox 0] 1] +0.001]
	set ipbox_ux [lindex [lindex $ipbox 0] 2]
	set ipbox_uy [lindex [lindex $ipbox 0] 3] 
	set ipbox_y [expr $ipbox_ly - $ipbox_uy]
	set ipbox_x [expr $ipbox_lx - $ipbox_ux]
	#puts "ipbox_XS $ipbox_lx $ipbox_ux"
	if {$ipbox_y == 0} {
    #Get floorplan boxes and see if Macro overlaps with it
    scan [list [get_computed_shapes -output rect [get_db designs .boundary]]] "{{%f %f %f %f}}" fp_llx fp_lly fp_urx fp_ury
    #puts "Floorplan Boxes $fp_llx $fp_lly $fp_urx $fp_ury"
	#First check to see if Macro is on Floorplan Boundary or Atleast 2X (Modular Grid) Away from the floorplan Boundary
	set fp_overlap [expr $fp_urx - $ipbox_ux]
    #puts "Overlap value is:  $fp_overlap"
	if {($fp_overlap == 0) || ([expr $fp_overlap >= $x_div_mul])} {
	#Criteria for selecting Area to be searched is Y Direction (Die Boundary - Cell Height), X Direction ( fixed to X_Modular Grid + 0.01)
	set area_box "[expr $ipbox_ux+$x_div+0.001] [expr $ipbox_ly - 0] [expr $ipbox_ux+$x_div+0.001] [expr $ipbox_uy-$macro_height]"
	#puts "On Horizontal boundary: pbox - $pbox IP box $ipbox and also Area query box $area_box , Diebox- $dieboxbnd"
	#puts "Values $ipbox_lx and $ipbox_ux "	
	set macro_vic [get_db [get_obj_in_area -area "$area_box"] -if {.base_cell.base_class == block || .base_cell.base_class == pad}]	
	#puts "$macro_vic"
    if {($macro_vic !=0) && ($macro_vic != $lst)} {
	 foreach mac $macro_vic {
	 	#Got another Macro
        #First see if MAcro is abutting
    set macro_box [get_computed_shapes -output rect [get_db $lst .overlap_rects]]
    set adjacent_macro_loc [get_computed_shapes -output rect [get_db $mac .overlap_rects]]
    set adjacent_macro [get_db $mac .name]
    set x_coord_macro [lindex [lindex $macro_box 0] 2]
    set x_coord_adj_macro [lindex [lindex $adjacent_macro_loc 0] 0]
    set adj_box [expr $x_coord_macro - $x_coord_adj_macro]
    #puts "Direction is left macro_box $macro_box, Adj macro - $adjacent_macro , Adjacent Macro Loc - $adjacent_macro_loc Overlapping box - $adj_box"
        if {$adj_box != 0} {
	    P_msg_error "For Every Macro on the Flooplan Boundary -Make sure the Macro-Macro Edge distance is either 2X Modular Grid or Abutting each other for Macro pair -$adjacent_macro and [get_db $lst .name]"
    	}
        }
    }
	} else {
	 P_msg_error "For every macro on ASIC Block edge, Make sure the Macro is either on the Floorplan boundary or atleast 2X Modular Grid away from the Floorplan $fp_urx boundary for Macro - [get_db $lst .name]"
	}
	}
   }
 } elseif {$direction == "down"} {
   if {$ipbox != ""} {
    set ipbox_lx [lindex [lindex $ipbox 0] 0] 
    set ipbox_ly [expr [lindex [lindex $ipbox 0] 1] +0.001]
	set ipbox_ux [lindex [lindex $ipbox 0] 2]
	set ipbox_uy [lindex [lindex $ipbox 0] 3] 
	set ipbox_y [expr $ipbox_ly - $ipbox_uy]
	if {$ipbox_y == 0} {
    #Get floorplan boxes and see if Macro overlaps with it
    scan [list [get_computed_shapes -output rect [get_db designs .boundary]]] "{{%f %f %f %f}}" fp_llx fp_lly fp_urx fp_ury
    #puts "Floorplan Boxes $fp_llx $fp_lly $fp_urx $fp_ury"
	#First check to see if Macro is on Floorplan Boundary or Atleast 2X (Modular Grid) Away from the floorplan Boundary
	set fp_overlap [expr $ipbox_ux - $fp_llx-0.001]
	#puts "Overlap value is : $fp_overlap"
    if {($fp_overlap == 0) || ([expr $fp_overlap >= $x_div_mul])} {
    #Criteria for selecting Area to be searched is Y Direction (Die Boundary - Cell Height), X Direction ( fixed to X_Modular Grid + 0.01)
	set area_box "[expr $ipbox_ux-$x_div-0.001] [expr $ipbox_ly - 0] [expr $ipbox_ux-$x_div-0.001] [expr $ipbox_uy-$macro_height]"
	#puts "On Horizontal boundary: pbox - $pbox IP box $ipbox and also Area query box $area_box , Diebox- $dieboxbnd"
	#puts "Values $ipbox_lx and $ipbox_ux "	
    set macro_vic [get_db [get_obj_in_area -area "$area_box"] -if {.base_cell.base_class == block || .base_cell.base_class == pad}]	
	#puts "$macro_vic"
   if {($macro_vic !=0) && ($macro_vic != $lst)} {
    foreach mac $macro_vic {
     #Got another Macro
     #First see if MAcro is abutting
    set macro_box [get_computed_shapes -output rect [get_db $lst .overlap_rects]]
    set adjacent_macro_loc [get_computed_shapes -output rect [get_db $mac .overlap_rects]]
    set adjacent_macro [get_db $mac .name]
    set x_coord_macro [lindex [lindex $macro_box 0] 0]
    set x_coord_adj_macro [lindex [lindex $adjacent_macro_loc 0] 2]
    set adj_box [expr $x_coord_macro - $x_coord_adj_macro]
    # puts "Direction is down macro_box $macro_box, Adj macro - $adjacent_macro , Adjacent Macro Loc - $adjacent_macro_loc Overlapping box - $adj_box"
     if {$adj_box != 0} {
      P_msg_error "For Every Macro on the Flooplan Boundary -Make sure the Macro-Macro Edge distance is either 2X Modular Grid or Abutting each other for Macro pair -$adjacent_macro and [get_db $lst .name]"
    }
    }
   }
 } else {
  P_msg_error "For every macro on ASIC Block edge, Make sure the Macro is either on the Floorplan boundary or atleast 2X Modular Grid away from the Floorplan $fp_llx boundary for Macro - [get_db $lst .name]"
 }
}
}
} 
set startpoint $endpoint	
}
}
} else {
P_msg_info "No Macros in the design"
}
P_msg_info "Done: Checking for Spacing Requirements between Macros and Macro-Floorplan Boundary"
#######################################################################################################################
}

