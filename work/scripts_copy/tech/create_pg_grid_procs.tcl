##############################################################################
# STEP create_pg_grid_procs
##############################################################################
create_flow_step -name create_pg_grid_procs -skip_db -skip_metric -owner intel {
global vars
global env

###
proc P_add_SacrificalM1_for_via1_onFollowPin { args } {
  global vars
  global pgfile
  parse_proc_arguments -args $args inputs 
  set ground_offset $inputs(-gnd_offset)
  set power_offset $inputs(-pwr_offset)
  set upf_available [string is space [get_flow_config -quiet init_power_intent_files 1801]]
  if {!($upf_available)} {
  puts $pgfile "add_stripes -max_same_layer_jog_length 0 -set_to_set_distance [expr $vars(INTEL_MD_GRID_X)*4] -spacing $ground_offset -start_offset $ground_offset -stop_offset $vars(INTEL_WS_X) -layer m1 -width 0.068 -nets $vars(INTEL_GROUND_NET) -direction vertical"
   foreach pd [get_db [get_db power_domains -if {.is_virtual == false} ] .name] {
   P_create_PG_blockage -pwr_domain $pd -layer m1 -pullback 0.080
   puts $pgfile "add_stripes -max_same_layer_jog_length 0 -set_to_set_distance [expr $vars(INTEL_MD_GRID_X)*4] -spacing $power_offset -start_offset $power_offset -stop_offset $vars(INTEL_WS_X) -layer m1 -width 0.068 -nets [P_ret_primary_net -pwr_domain $pd] -direction vertical"
   puts $pgfile "delete_route_blockages -name intel_upf_pg_rb"
   puts $pgfile "delete_route_blockages -name intel_upf_pg_rb_expand"
   }
 } else {
  puts $pgfile "add_stripes -max_same_layer_jog_length 0 -set_to_set_distance [expr $vars(INTEL_MD_GRID_X)*4] -spacing $ground_offset -start_offset $ground_offset -stop_offset $vars(INTEL_WS_X) -layer m1 -width 0.068 -nets $vars(INTEL_GROUND_NET) -direction vertical"
  puts $pgfile "add_stripes -max_same_layer_jog_length 0 -set_to_set_distance [expr $vars(INTEL_MD_GRID_X)*4] -spacing $power_offset -start_offset $power_offset -stop_offset $vars(INTEL_WS_X) -layer m1 -width 0.068 -nets $vars(INTEL_POWER_NET) -direction vertical"
 }
}

define_proc_arguments P_add_SacrificalM1_for_via1_onFollowPin  \
-define_args {
  {-pwr_offset   "Specify M1 Offset for Power Sacrificial Stripe" "val" string required }
  {-gnd_offset   "Specify M1 Offset for Ground Sacrificial Stripe" "val" string required }
}

###

proc P_delete_SacrificalM1_for_via1_onFollowPin { } {
  global vars
  gui_deselect -all
  set net $vars(INTEL_GROUND_NET)
  select_vias -nets $net -cut_layer v1
  set_db selected .status cover
  select_routes -wires_only 0 -nets $net  -layer m1 -shapes stripe -status routed
  delete_routes -selected -net $net -layer m1 -shapes stripe -status routed
  select_vias -nets $net -cut_layer v1
  set_db selected .status routed
  gui_deselect -all
  set upf_available [string is space [get_flow_config -quiet init_power_intent_files 1801]]
  if {!($upf_available)} {
  foreach pd [get_db [get_db power_domains -if {.is_virtual == false} ] .name] { 
        set net [P_ret_primary_net -pwr_domain $pd]
        select_vias -net $net -cut_layer v1
        set_db selected .status cover
        select_routes -wires_only 0 -net $net  -layer m1 -shape STRIPE -status ROUTED
        delete_routes -selected -net $net -layer m1 -shape STRIPE -status ROUTED
        select_vias -net $net -cut_layer v1
        set_db selected .status routed
        gui_deselect -all
  }
 } else {
        set net $vars(INTEL_POWER_NET)
        select_vias -net $net -cut_layer v1
        set_db selected .status cover
        select_routes -wires_only 0 -net $net  -layer m1 -shape STRIPE -status ROUTED
        delete_routes -selected -net $net -layer m1 -shape STRIPE -status ROUTED
        select_vias -net $net -cut_layer v1
        set_db selected .status routed
        gui_deselect -all
 }
}

###
  proc P_addStripe_power_ground { args } {
  global pgfile
  global vars
  global pg_grid_dict
  parse_proc_arguments -args $args inputs 
  set stripe_layer_name $inputs(-stripe_layer)
  set stripe_generation_area $inputs(-stripe_gen_area)
  set inside_corner_area_blockage $inputs(-inside_corner_blockage)
  set INTEL_GROUND_NET_stripe_netName $inputs(-gnd_net)
  set INTEL_POWER_NET_stripe_netName  $inputs(-pwr_net)
  set stripe_strategy $inputs(-stripe_strategy)
  set power_domain $inputs(-power_domain)
  
  set lyr_direction [string tolower [get_db [get_db layers $stripe_layer_name] .direction]] 
  set INTEL_GROUND_NET_stripe_layer_period [dict get $pg_grid_dict $stripe_layer_name ground pitch] 
  set INTEL_POWER_NET_stripe_layer_period [dict get $pg_grid_dict $stripe_layer_name $stripe_strategy pitch] 
  set INTEL_GROUND_NET_stripe_layer_offset [lindex [dict get $pg_grid_dict $stripe_layer_name ground offset,width] 0]
  set INTEL_POWER_NET_stripe_layer_offset [lindex [dict get $pg_grid_dict $stripe_layer_name $stripe_strategy offset,width] 0]
  set INTEL_GROUND_NET_stripe_layer_width [lindex [dict get $pg_grid_dict $stripe_layer_name ground offset,width] 1]
  set INTEL_POWER_NET_stripe_layer_width [lindex [dict get $pg_grid_dict $stripe_layer_name $stripe_strategy offset,width] 1]
  if {$INTEL_GROUND_NET_stripe_layer_offset < $INTEL_POWER_NET_stripe_layer_offset} {
    set stripe_layer_offset [expr $INTEL_POWER_NET_stripe_layer_offset - $INTEL_POWER_NET_stripe_layer_width/2]
    set stripe_layer_nets "$INTEL_POWER_NET_stripe_netName $INTEL_GROUND_NET_stripe_netName "
    set stripe_layer_spacing  " [expr $INTEL_POWER_NET_stripe_layer_offset - $INTEL_GROUND_NET_stripe_layer_offset - [expr $INTEL_POWER_NET_stripe_layer_width+$INTEL_GROUND_NET_stripe_layer_width]/2] [expr  $INTEL_POWER_NET_stripe_layer_offset - $INTEL_GROUND_NET_stripe_layer_offset - [expr $INTEL_POWER_NET_stripe_layer_width+$INTEL_GROUND_NET_stripe_layer_width]/2 ] "
    set stripe_layer_width "$INTEL_POWER_NET_stripe_layer_width $INTEL_GROUND_NET_stripe_layer_width "
  } else {
    set stripe_layer_offset [expr $INTEL_GROUND_NET_stripe_layer_offset - $INTEL_GROUND_NET_stripe_layer_width/2]
    set stripe_layer_nets "$INTEL_GROUND_NET_stripe_netName $INTEL_POWER_NET_stripe_netName "
    set stripe_layer_spacing  " [expr $INTEL_GROUND_NET_stripe_layer_offset - $INTEL_POWER_NET_stripe_layer_offset - [expr $INTEL_POWER_NET_stripe_layer_width+$INTEL_GROUND_NET_stripe_layer_width]/2] [expr  $INTEL_GROUND_NET_stripe_layer_offset - $INTEL_POWER_NET_stripe_layer_offset - [expr $INTEL_POWER_NET_stripe_layer_width+$INTEL_GROUND_NET_stripe_layer_width]/2 ] "
    set stripe_layer_width "$INTEL_GROUND_NET_stripe_layer_width $INTEL_POWER_NET_stripe_layer_width "
  }
  if {$INTEL_GROUND_NET_stripe_layer_width == $INTEL_POWER_NET_stripe_layer_width} {
    set stripe_layer_width $INTEL_GROUND_NET_stripe_layer_width
  }
  ## Code to query the lower metal layer w.r.t to current layer on which stripe is being added
  
  set lef_layer_list [get_db [get_db layers -if .type==routing] .name]
  
  set lef_layer_index [lsearch -exact $lef_layer_list $stripe_layer_name]
  if {$lef_layer_index < 0 } {
  set stripe_lower_layer_name $stripe_layer_name
  set stripe_upper_layer_name [lindex $lef_layer_list [expr $lef_layer_index + 1]]
  puts " ## INFO ## Cant find the layer specified in the template."
  puts " ## INFO ## Check the names of the layer in the TECH LEF against the template layer names"
  } else {
  set stripe_upper_layer_name [lindex $lef_layer_list [expr $lef_layer_index + 1]]
  set stripe_lower_layer_name [lindex $lef_layer_list [expr $lef_layer_index - 1]]
  }
  #puts $pgfile "setAddStripeMode  -stacked_via_top_layer ${stripe_upper_layer_name}  -stacked_via_bottom_layer ${stripe_lower_layer_name}"
  puts $pgfile "set_db add_stripes_stacked_via_top_layer ${stripe_upper_layer_name}"
  puts $pgfile "set_db add_stripes_stacked_via_bottom_layer ${stripe_lower_layer_name}"
  if { ![dict exist  $pg_grid_dict $stripe_layer_name ground staple] && ![dict exist  $pg_grid_dict $stripe_layer_name $stripe_strategy staple]} { 
  puts $pgfile "add_stripes -block_ring_top_layer_limit ${stripe_layer_name}   \
         -max_same_layer_jog_length 0   \
         -set_to_set_distance ${INTEL_POWER_NET_stripe_layer_period}   \
         -spacing {${stripe_layer_spacing}}   \
         -start_offset ${stripe_layer_offset}   \
         -layer ${stripe_layer_name}   \
         -block_ring_bottom_layer_limit ${stripe_layer_name}   \
         -width {${stripe_layer_width}}   \
         -nets {$stripe_layer_nets}   \
         -direction $lyr_direction   \
         -area {$stripe_generation_area}   \
         -area_blockage {$inside_corner_area_blockage}   \
         -create_pins 1"
        } else {
  set_db add_stripes_use_fgc 1
  if {$INTEL_GROUND_NET_stripe_layer_offset >= $INTEL_POWER_NET_stripe_layer_offset} {
  set stripe_layer_offset [expr $INTEL_GROUND_NET_stripe_layer_offset - $INTEL_GROUND_NET_stripe_layer_width/2]
  set stripe_layer_nets "$INTEL_GROUND_NET_stripe_netName $INTEL_POWER_NET_stripe_netName "
  set stripe_layer_width "$INTEL_GROUND_NET_stripe_layer_width $INTEL_POWER_NET_stripe_layer_width "
  } else {
  set stripe_layer_offset [expr $INTEL_POWER_NET_stripe_layer_offset - $INTEL_POWER_NET_stripe_layer_width/2]
  set stripe_layer_nets "$INTEL_POWER_NET_stripe_netName $INTEL_GROUND_NET_stripe_netName "
  set stripe_layer_width "$INTEL_POWER_NET_stripe_layer_width $INTEL_GROUND_NET_stripe_layer_width "
  }
  if {$INTEL_GROUND_NET_stripe_layer_width == $INTEL_POWER_NET_stripe_layer_width} {
    set stripe_layer_width $INTEL_GROUND_NET_stripe_layer_width
  }
  set staple_layer_spacing [expr $INTEL_GROUND_NET_stripe_layer_period - $stripe_layer_width]
  set stapling_pattern_ground "[lindex [dict get $pg_grid_dict $stripe_layer_name ground staple start,length] 1] $INTEL_GROUND_NET_stripe_layer_offset [expr [dict get $pg_grid_dict $stripe_layer_name ground staple repeat]]:1"
 set stapling_pattern_power "[lindex [dict get $pg_grid_dict $stripe_layer_name ground staple start,length] 1] $INTEL_POWER_NET_stripe_layer_offset [expr [dict get $pg_grid_dict $stripe_layer_name ground staple repeat]]:1"

  if { $power_domain !="default" && $power_domain != "" } {
  set pwrDomain [get_db power_domains $power_domain ]
  foreach newpd $pwrDomain {
          if {$newpd != 0} {
        if {[get_db $newpd .is_default] == "false"} {
                lappend pd_nondefault [get_db $newpd .name]
        }
          }
  }
  puts "Non default powerdomain list $pd_nondefault"

 set stdcell_tile [lindex $vars(INTEL_STDCELL_TILE) 0] 
 set stripe_layer_offset  [expr $stripe_layer_offset -  [get_db [get_db sites -if {.name == $stdcell_tile}] .size.y]]
 
  puts $pgfile "select_obj $pd_nondefault"
  puts $pgfile "add_stripes -max_same_layer_jog_length 0     \
          -set_to_set_distance $INTEL_GROUND_NET_stripe_layer_period     \
          -spacing {$staple_layer_spacing}     \
          -start_offset $stripe_layer_offset     \
          -layer ${stripe_layer_name} -width {$stripe_layer_width}     \
          -nets {$INTEL_POWER_NET_stripe_netName}     \
          -direction $lyr_direction     \
          -area_blockage {$inside_corner_area_blockage}     \
          -stapling {$stapling_pattern_power}     \
          -over_power_domain 1"
   puts $pgfile "add_stripes -max_same_layer_jog_length 0     \
          -set_to_set_distance $INTEL_GROUND_NET_stripe_layer_period     \
          -spacing {$staple_layer_spacing}     \
          -start_offset $stripe_layer_offset     \
          -layer ${stripe_layer_name} -width {$stripe_layer_width}     \
          -nets {$INTEL_GROUND_NET_stripe_netName}     \
          -direction $lyr_direction     \
          -area_blockage {$inside_corner_area_blockage}     \
          -stapling {$stapling_pattern_ground}     \
          -over_power_domain 1"
  puts $pgfile "gui_deselect -all"
  } else {
  puts $pgfile "add_stripes -max_same_layer_jog_length 0     \
         -set_to_set_distance $INTEL_GROUND_NET_stripe_layer_period     \
         -spacing {$staple_layer_spacing}     \
         -start_offset $stripe_layer_offset     \
         -layer ${stripe_layer_name}     \
         -width {$stripe_layer_width}     \
         -nets {$INTEL_POWER_NET_stripe_netName}     \
         -direction $lyr_direction     \
         -area {$stripe_generation_area}     \
         -area_blockage {$inside_corner_area_blockage}     \
         -stapling {$stapling_pattern_power}"
puts $pgfile "add_stripes -max_same_layer_jog_length 0     \
         -set_to_set_distance $INTEL_GROUND_NET_stripe_layer_period     \
         -spacing {$staple_layer_spacing}     \
         -start_offset $stripe_layer_offset     \
         -layer ${stripe_layer_name}     \
         -width {$stripe_layer_width}     \
         -nets {$INTEL_GROUND_NET_stripe_netName}     \
         -direction $lyr_direction     \
         -area {$stripe_generation_area}     \
         -area_blockage {$inside_corner_area_blockage}     \
         -stapling {$stapling_pattern_ground}" 
        }
     }
}

define_proc_arguments P_addStripe_power_ground  \
-define_args {
  {-stripe_layer "Specify layer" "val" string required }
  {-stripe_strategy "specify power net strategy" "val" string required }
  {-stripe_gen_area   "Specify area to generate stripes" "val" string required }
  {-inside_corner_blockage      "Specify blockages for corners inside floorplan to avoid DRCs" "val" string required }
  {-pwr_net      "Specify popwer net name" "val" string required }
  {-gnd_net      "Specify ground net name" "val" string required }
  {-power_domain      "Specify power_domain name incase of low power,and is default for non low power designs" "val" string required }
}

###
  proc P_addStripe_ground { args } {
  global pgfile
  global vars
  global pg_grid_dict
  parse_proc_arguments -args $args inputs 
  set stripe_layer_name $inputs(-stripe_layer)
  set stripe_generation_area $inputs(-stripe_gen_area)
  set inside_corner_area_blockage $inputs(-inside_corner_blockage)
  set INTEL_GROUND_NET_stripe_netName $inputs(-gnd_net)
  set stripe_strategy $inputs(-stripe_strategy)
  set lyr_direction [string tolower [get_db [get_db layers $stripe_layer_name ] .direction]]
  set INTEL_GROUND_NET_stripe_layer_period [dict get $pg_grid_dict $stripe_layer_name ground pitch] 
  set INTEL_POWER_NET_stripe_layer_period [dict get $pg_grid_dict $stripe_layer_name $stripe_strategy pitch] 
  set INTEL_GROUND_NET_stripe_layer_offset [lindex [dict get $pg_grid_dict $stripe_layer_name ground offset,width] 0]
  set INTEL_POWER_NET_stripe_layer_offset [lindex [dict get $pg_grid_dict $stripe_layer_name $stripe_strategy offset,width] 0]
  set INTEL_GROUND_NET_stripe_layer_width [lindex [dict get $pg_grid_dict $stripe_layer_name ground offset,width] 1]
  set INTEL_POWER_NET_stripe_layer_width [lindex [dict get $pg_grid_dict $stripe_layer_name $stripe_strategy offset,width] 1]
  if {$INTEL_GROUND_NET_stripe_layer_offset==0} {
      set INTEL_GROUND_NET_stripe_layer_offset [expr $INTEL_GROUND_NET_stripe_layer_period - [expr $INTEL_GROUND_NET_stripe_layer_width/2]]
  } else {
      set INTEL_GROUND_NET_stripe_layer_offset [expr $INTEL_GROUND_NET_stripe_layer_offset - [expr $INTEL_GROUND_NET_stripe_layer_width/2]]
  }
  ## Code to query the lower metal layer w.r.t to current layer on which stripe is being added
  set lef_layer_list  [get_db [get_db layers -if {.type == routing}] .name]
  set lef_layer_index [lsearch -exact $lef_layer_list $stripe_layer_name]
  if {$lef_layer_index < 0 } {
  set stripe_lower_layer_name $stripe_layer_name
  set stripe_upper_layer_name [lindex $lef_layer_list [expr $lef_layer_index + 1]]
  puts " ## INFO ## Cant find the layer specified in the template."
  puts " ## INFO ## Check the names of the layer in the TECH LEF against the template layer names"
  } else {
  set stripe_upper_layer_name [lindex $lef_layer_list [expr $lef_layer_index + 1]]
  set stripe_lower_layer_name [lindex $lef_layer_list [expr $lef_layer_index - 1]]
  }
  puts $pgfile "set_db add_stripes_stacked_via_top_layer ${stripe_upper_layer_name}"
  puts $pgfile "set_db add_stripes_stacked_via_bottom_layer ${stripe_lower_layer_name}"
  puts $pgfile "add_stripes -block_ring_top_layer_limit ${stripe_layer_name}   \
         -max_same_layer_jog_length 0   \
         -set_to_set_distance ${INTEL_GROUND_NET_stripe_layer_period}   \
         -spacing {${INTEL_GROUND_NET_stripe_layer_period}}   \
         -start_offset ${INTEL_GROUND_NET_stripe_layer_offset}   \
         -layer ${stripe_layer_name}   \
         -block_ring_bottom_layer_limit ${stripe_layer_name}   \
         -width {${INTEL_GROUND_NET_stripe_layer_width}}   \
         -nets {${INTEL_GROUND_NET_stripe_netName}}   \
         -direction $lyr_direction   \
         -area {$stripe_generation_area}   \
         -area_blockage {$inside_corner_area_blockage}   \
         -create_pins 1"
}

define_proc_arguments P_addStripe_ground  \
-define_args {
  {-stripe_layer "Specify layer" "val" string required }
  {-stripe_strategy "specify power net strategy" "val" string required }
  {-stripe_gen_area   "Specify area to generate stripes" "val" string required }
  {-inside_corner_blockage      "Specify blockages for corners inside floorplan to avoid DRCs" "val" string required }
  {-gnd_net      "Specify ground net name" "val" string required }
}

###
proc P_addStripe_power { args } {
  global pgfile
  global vars
  global pg_grid_dict
  parse_proc_arguments -args $args inputs 
  set stripe_layer_name $inputs(-stripe_layer)
  set stripe_generation_area $inputs(-stripe_gen_area)
  set inside_corner_area_blockage $inputs(-inside_corner_blockage)
  set current_pd $inputs(-power_domain)
  set INTEL_POWER_NET_stripe_netName $inputs(-pwr_net)
  set stripe_strategy $inputs(-stripe_strategy)
  set Value $inputs(-flag) 
  set lyr_direction [string tolower [get_db [get_db layers $stripe_layer_name ] .direction]]
  set INTEL_GROUND_NET_stripe_layer_period [dict get $pg_grid_dict $stripe_layer_name ground pitch] 
  set INTEL_POWER_NET_stripe_layer_period [dict get $pg_grid_dict $stripe_layer_name $stripe_strategy pitch] 
  set INTEL_GROUND_NET_stripe_layer_offset [lindex [dict get $pg_grid_dict $stripe_layer_name ground offset,width] 0]
  set INTEL_POWER_NET_stripe_layer_offset [lindex [dict get $pg_grid_dict $stripe_layer_name $stripe_strategy offset,width] 0]
  set INTEL_GROUND_NET_stripe_layer_width [lindex [dict get $pg_grid_dict $stripe_layer_name ground offset,width] 1]
  set INTEL_POWER_NET_stripe_layer_width [lindex [dict get $pg_grid_dict $stripe_layer_name $stripe_strategy offset,width] 1]
  if {$INTEL_POWER_NET_stripe_layer_offset==0} {
      set INTEL_POWER_NET_stripe_layer_offset [expr $INTEL_POWER_NET_stripe_layer_period - [expr $INTEL_POWER_NET_stripe_layer_width/2]]
  } else {
      set INTEL_POWER_NET_stripe_layer_offset [expr $INTEL_POWER_NET_stripe_layer_offset - [expr $INTEL_POWER_NET_stripe_layer_width/2]]
  }
  ## Code to query the lower metal layer w.r.t to current layer on which stripe is being added
  set lef_layer_list  [get_db [get_db layers -if {.type == routing}] .name]
  set lef_layer_index [lsearch -exact $lef_layer_list $stripe_layer_name]
  if {$lef_layer_index < 0 } {
  set stripe_lower_layer_name $stripe_layer_name
  set stripe_upper_layer_name [lindex $lef_layer_list [expr $lef_layer_index + 1]]
  puts " ## INFO ## Cant find the layer specified in the template."
  puts " ## INFO ## Check the names of the layer in the TECH LEF against the template layer names"
  } else {
  set stripe_upper_layer_name [lindex $lef_layer_list [expr $lef_layer_index + 1]]
  set stripe_lower_layer_name [lindex $lef_layer_list [expr $lef_layer_index - 1]]
  }
 puts $pgfile "set_db add_stripes_stacked_via_top_layer ${stripe_upper_layer_name}"
 puts $pgfile "set_db add_stripes_stacked_via_bottom_layer ${stripe_lower_layer_name}"
  set 1_pd [P_ret_aon_net -pwr_domain $current_pd]
  set 2_pd [P_ret_primary_net -pwr_domain $current_pd]
         if { $Value == 1} {
         if { $1_pd eq $2_pd } {
     set INTEL_POWER_NET_stripe_layer_period [expr [dict get $pg_grid_dict $stripe_layer_name $stripe_strategy pitch]/2]
}
    }
     if { $Value == 2} {
     if { $1_pd eq $2_pd } {
    set INTEL_POWER_NET_stripe_layer_period [expr [dict get $pg_grid_dict $stripe_layer_name $stripe_strategy pitch]/2]
} }
  puts $pgfile "add_stripes -block_ring_top_layer_limit ${stripe_layer_name}   \
    -max_same_layer_jog_length 0   \
    -set_to_set_distance ${INTEL_POWER_NET_stripe_layer_period}   \
    -spacing {${INTEL_POWER_NET_stripe_layer_period}}   \
    -start_offset ${INTEL_POWER_NET_stripe_layer_offset}   \
    -layer ${stripe_layer_name}   \
    -block_ring_bottom_layer_limit ${stripe_layer_name}   \
    -width {${INTEL_POWER_NET_stripe_layer_width}}   \
    -nets {${INTEL_POWER_NET_stripe_netName}}   \
    -direction $lyr_direction   \
    -area {$stripe_generation_area}   \
    -area_blockage {$inside_corner_area_blockage}   \
    -create_pins 1"

}

define_proc_arguments P_addStripe_power  \
-define_args {
  {-stripe_layer "Specify layer" "val" string required }
  {-stripe_strategy "specify power net strategy" "val" string required }
  {-stripe_gen_area   "Specify area to generate stripes" "val" string required }
  {-inside_corner_blockage      "Specify blockages for corners inside floorplan to avoid DRCs" "val" string required }
  {-pwr_net      "Specify popwer net name" "val" string required }
  {-flag  "valuefor flags " "val" string required }
  {-power_domain "Power domain info" "val" string optional }

}

###
  proc P_stripe_generation_area { layer } {
  global vars
  global INTEL_PG_GRID_CONFIG
  global pg_grid_dict_1
  set pg_grid_dict_1 [dict create {*}$INTEL_PG_GRID_CONFIG]

  set stripe_layer_name $layer
        P_msg_info "Setting Offsets"
        ##Offsets for layer power stripe
        set layer_left_offset 0.0
        set layer_bottom_offset 0.0
        set layer_top_offset 0.0
        set layer_right_offset 0.0 
        if {$stripe_layer_name eq "m2" } {
          set layer_left_offset [dict get $pg_grid_dict_1 $stripe_layer_name pullback]
 set layer_right_offset [dict get $pg_grid_dict_1 $stripe_layer_name pullback]
        }
         if {$stripe_layer_name eq "m3" } {
          set layer_bottom_offset [dict get $pg_grid_dict_1 $stripe_layer_name pullback] 
 set layer_top_offset [dict get $pg_grid_dict_1 $stripe_layer_name pullback]
        }
        if {$stripe_layer_name eq "m4" } {
           set layer_left_offset [dict get $pg_grid_dict_1 $stripe_layer_name pullback] 
 set layer_right_offset [dict get $pg_grid_dict_1 $stripe_layer_name pullback]
        }
        if {$stripe_layer_name eq "m5" } {
          set layer_bottom_offset [dict get $pg_grid_dict_1 $stripe_layer_name pullback] 
 set layer_top_offset [dict get $pg_grid_dict_1 $stripe_layer_name pullback]
        }
        if {$stripe_layer_name eq "m6" } {
          set layer_left_offset [dict get $pg_grid_dict_1 $stripe_layer_name pullback] 
 set layer_right_offset [dict get $pg_grid_dict_1 $stripe_layer_name pullback]
        }
        if {$stripe_layer_name eq "m7" } {
          set layer_bottom_offset [dict get $pg_grid_dict_1 $stripe_layer_name pullback]
 set layer_top_offset [dict get $pg_grid_dict_1 $stripe_layer_name pullback]
        }
        if {$stripe_layer_name eq "m8" } {
          set layer_left_offset [dict get $pg_grid_dict_1 $stripe_layer_name pullback] 
 set layer_right_offset [dict get $pg_grid_dict_1 $stripe_layer_name pullback]
        }
        ##Add condition to change the core area if the metal layer is below m4
        # Headers and Template
        scan [get_db designs .bbox] "{%f %f %f %f}" _llx _lly _urx _ury
        set stripe_generation_area  [list [expr $_llx + $layer_left_offset] [expr $_lly + $layer_bottom_offset] [expr $_urx - $layer_right_offset] [expr $_ury - $layer_top_offset] ]
  }

###
  proc P_create_PG_blockage {args} {
      global pgfile
    parse_proc_arguments -args $args inputs
    set pd $inputs(-pwr_domain)
    set layer $inputs(-layer)
    set pb $inputs(-pullback)
    # Get boundaries for design and power domain
    # Get seperate holes and noholes boundary to take care of nested domains
    if {$pd != "default"} {
    if { [get_db [get_db power_domains $pd ] .group.rects] != "" }  {
      set pd_bndry [get_computed_shapes -output polygon [get_db [get_db power_domains $pd ] .group.rects] NOHOLES]
      set pd_bndry_holes [get_computed_shapes -output polygon [get_db [get_db power_domains $pd ] .group.rects] HOLES]
      set design_bndry [get_computed_shapes -output polygon [get_db designs .boundary]]
      # Get the shape for which blockage needs to be created
      set blkg_bndry [get_computed_shapes -output polygon $design_bndry ANDNOT $pd_bndry]
      # OR in the holes bndry in case of nested domains
      if { $pd_bndry_holes != ""} {
        set blkg_bndry [get_computed_shapes -output polygon $blkg_bndry OR $pd_bndry_holes]
      }
      # Compute polygon for default domain
      if { [get_db power_domains $pd -if .is_default] ne "" } {
        set blkg_bndry ""
        set blkg_bndry_1 ""
        set blkg_bndry_expand ""
        if {[get_db [get_db power_domains $pd] .is_default]} {
            foreach subpd [get_db [get_db power_domains -if {.is_default == false} ] .name] {
                if { [get_db [get_db power_domains $subpd ] .group.rects] != ""} {
                    set blkg_bndry_1 [get_db [get_db power_domains $subpd ] .group.rects]
                }
            }
        }
               
        foreach subpd [get_db [get_db power_domains -if .is_default==0 ] .name] {
          if { [get_db [get_db power_domains $subpd ] .group.rects] == ""} {
            continue
          }
          set blkg_bndry [get_computed_shapes -output polygon $blkg_bndry OR [get_computed_shapes -output polygon [get_db [get_db power_domains $subpd] .group.rects] NOHOLES]]
        }
        ####
        if { [get_db [get_db layers $layer ] .direction] eq "vertical" } {
        set top_domain_pb_blockage_box [get_computed_shapes [get_computed_shapes -output rect $pd_bndry] ANDNOT [get_computed_shapes -output rect $pd_bndry SIZEY -$pb]]
        set blkg_bndry_expand [get_computed_shapes $blkg_bndry_1  SIZEY $pb  ANDNOT [get_computed_shapes $blkg_bndry_1]]
        } elseif { [get_db [get_db layers $layer ] .direction] eq "horizontal" } {
        set top_domain_pb_blockage_box [get_computed_shapes [get_computed_shapes -output rect $pd_bndry] ANDNOT [get_computed_shapes -output rect $pd_bndry SIZEX -$pb]]
        set blkg_bndry_expand [get_computed_shapes $blkg_bndry_1  SIZEX $pb  ANDNOT [get_computed_shapes $blkg_bndry_1]] 
        }
        foreach box [get_computed_shapes -output rect $blkg_bndry_expand] {
        puts $pgfile "create_route_blockage -name intel_upf_pg_rb_expand -layers $layer -spacing 0.000 -rects {$box}"
        }
        foreach box [get_computed_shapes -output rect $top_domain_pb_blockage_box] {
        puts $pgfile "create_route_blockage -name intel_upf_pg_rb -layers $layer -spacing 0.000 -rects {$box}"
        }
        ####
      }
      foreach box [get_computed_shapes -output rect $blkg_bndry] {
        if { [get_db [get_db layers $layer] .direction] eq "horizontal" } {
          set box [get_computed_shapes -output rect $box SIZEX $pb]
        } elseif { [get_db [get_db layers $layer] .direction] eq "vertical" } {
          set box [get_computed_shapes -output rect $box SIZEY $pb]
        }
        puts $pgfile "create_route_blockage -name intel_upf_pg_rb -layers $layer -spacing 0.000 -rects $box"
      }
    }
  } else {
        ####
        set design_bndry [get_computed_shapes -output polygon [get_db designs .boundary]]
         
        if { [get_db [get_db layers $layer ] .direction] eq "vertical" } {
        set top_pb_blockage_box [get_computed_shapes [get_computed_shapes -output rect $design_bndry] ANDNOT [get_computed_shapes -output rect $design_bndry SIZEY -$pb]]
        } elseif { [get_db [get_db layers $layer ] .direction] eq "horizontal" } {
        set top_pb_blockage_box [get_computed_shapes [get_computed_shapes -output rect $design_bndry] ANDNOT [get_computed_shapes -output rect $design_bndry SIZEX -$pb]]
        }
        foreach box [get_computed_shapes -output rect $top_pb_blockage_box] {
        puts $pgfile "create_route_blockage -name pgGridBlk -layers $layer -spacing 0.000 -rects {$box}"
        }
        ####
  }
  }

  define_proc_arguments P_create_PG_blockage  \
  -info "Creates blockages all over the design except the provided power domain"  \
  -define_args {
    {"-pwr_domain" "Domain for which PG needs to be created" "" string required}
    {"-layer" "Layer for which blockage needs to be created" "" string required}
    {"-pullback" "Value of pullback needed in microns for Primary straps" "" string required}
  }

###
  proc P_generate_inside_corner_area_blockage_for_pg_mesh { layer } {
    set stripe_layer_name $layer 
    ###  Identify if there are any "inside" corners in the floorplan to address P/G Stripe to Interface Metal spacing violations
    scan [get_db designs .bbox] "{%f %f %f %f}" _llx _lly _urx _ury
    set perimeter [get_computed_shapes -output polygon [get_db designs .boundary]]
    set box_perim [get_computed_shapes -output rect [get_db designs .boundary]]
    set counter 0
    set inside_corner_obs50 []
    set inside_corner_obs60 []
    set inside_corner_obs80 []
    set ccount [llength $perimeter]
    foreach coord [lindex $perimeter $counter] {
      set corner_test 0
      set px [lindex $coord 0]
      set py [lindex $coord 1]
      if {$px != $_llx && $px != $_urx && $py != $_lly && $py != $_ury} {
        set point_test 0
        set test_x1 [expr $px + 0.001]
        set test_y1 [expr $py + 0.001]
        set test_x2 [expr $px + 0.001]
        set test_y2 [expr $py - 0.001]
        set test_x3 [expr $px - 0.001]
        set test_y3 [expr $py - 0.001]
        set test_x4 [expr $px - 0.001]
        set test_y4 [expr $py + 0.001]
        foreach box $box_perim {
          if {$test_x1>[lindex $box 0] && $test_x1<[lindex $box 2] && $test_y1>[lindex $box 1] && $test_y1<[lindex $box 3]} {incr point_test 1}
          if {$test_x2>[lindex $box 0] && $test_x2<[lindex $box 2] && $test_y2>[lindex $box 1] && $test_y2<[lindex $box 3]} {incr point_test 1}
          if {$test_x3>[lindex $box 0] && $test_x3<[lindex $box 2] && $test_y3>[lindex $box 1] && $test_y3<[lindex $box 3]} {incr point_test 1}
          if {$test_x4>[lindex $box 0] && $test_x4<[lindex $box 2] && $test_y4>[lindex $box 1] && $test_y4<[lindex $box 3]} {incr point_test 1}
        }
        if {$point_test == 3} {
          lappend inside_corner_obs50 [list [expr $px-0.05] [expr $py-0.05] [expr $px+0.05] [expr $py+0.05]]
          lappend inside_corner_obs60 [list [expr $px-0.06] [expr $py-0.06] [expr $px+0.06] [expr $py+0.06]]
          lappend inside_corner_obs80 [list [expr $px-0.08] [expr $py-0.08] [expr $px+0.08] [expr $py+0.08]]
        }
      }
      incr counter 1
    }
    if {[llength $inside_corner_obs50] == 0} {set inside_corner_obs50 [list [expr $_urx+1.000] [expr $_ury+1.000] [expr $_urx+1.001] [expr $_ury+1.001]] }
    if {[llength $inside_corner_obs60] == 0} {set inside_corner_obs60 [list [expr $_urx+1.000] [expr $_ury+1.000] [expr $_urx+1.001] [expr $_ury+1.001]] }
    if {[llength $inside_corner_obs80] == 0} {set inside_corner_obs80 [list [expr $_urx+1.000] [expr $_ury+1.000] [expr $_urx+1.001] [expr $_ury+1.001]] }
        if {$stripe_layer_name eq "m8" || $stripe_layer_name eq "m9"} {
          set inside_corner_area_blockage $inside_corner_obs50
        } elseif {$stripe_layer_name eq "m6" || $stripe_layer_name eq "m7" || $stripe_layer_name eq "m10" || $stripe_layer_name eq "m11"} {
          set inside_corner_area_blockage $inside_corner_obs50
        } elseif {$stripe_layer_name eq "m5"} {
          set inside_corner_area_blockage $inside_corner_obs80
        } else  {
          set inside_corner_area_blockage [list [expr $_urx+1.000] [expr $_ury+1.000] [expr $_urx+1.001] [expr $_ury+1.001]]
        }
    }

###
  proc create_pg_grid args {
  global vars
  global INTEL_PG_GRID_CONFIG
  global pgfile
  global pg_grid_dict 
  parse_proc_arguments -args $args opts
  set out_cmd_file $opts(-out_command_file)
  set pgfile [open $out_cmd_file w]
  set max_pg $opts(-max_pg_layer)
  ##edited for m5 max layer, should be removed 
  #set all_mtl_lyr_sort_list [dbGet [dbGet head.layers.type routing -p1].name]

###############
set b [get_db [get_db layers -if .type==routing] .name]
set c m$max_pg
set all_mtl_lyr_sort_list ""
foreach max_layers1 $b {
if {$max_layers1 == "m1"} { continue }
lappend all_mtl_lyr_sort_list $max_layers1
 if {$max_layers1 == $c } {
  break
  }
  }
  
  set pg_grid_dict [dict create {*}$INTEL_PG_GRID_CONFIG]
  set pg_pullback(va) $vars(pg_pullback_va)
  foreach pg_layer $pg_pullback(va) {
    set pullback_va([lindex $pg_layer 0],va) [lindex $pg_layer 1]
  }

  set cfg_pg_lyr_list [lsort -dictionary [dict keys $pg_grid_dict]]
  set cfg_pg_mtl_lyr_list {}
  set cfg_pg_mtl_lyr_idx_list {}
  set m1_width 0.068
  set m1_power_offset [expr [expr $vars(INTEL_MD_GRID_X)*3] - [expr $m1_width/2] + $vars(INTEL_WS_X)]
  set m1_ground_offset [expr [expr $vars(INTEL_MD_GRID_X)*2] - [expr $m1_width/2] + $vars(INTEL_WS_X)]
  P_add_SacrificalM1_for_via1_onFollowPin -pwr_offset $m1_power_offset -gnd_offset $m1_ground_offset
  foreach lyr_name $cfg_pg_lyr_list {
       lappend cfg_pg_mtl_lyr_list $lyr_name
      lappend cfg_pg_mtl_lyr_idx_list [lsearch -exact $all_mtl_lyr_sort_list $lyr_name]
    }
  set cfg_pg_mtl_lyr_idx_sort_list [lsort -integer $cfg_pg_mtl_lyr_idx_list]
  set cfg_pg_mtl_lyr_sort_list [lrange $all_mtl_lyr_sort_list [lindex $cfg_pg_mtl_lyr_idx_sort_list 0] [lindex $cfg_pg_mtl_lyr_idx_sort_list end]]
  foreach lyr $cfg_pg_mtl_lyr_sort_list {
  set upf_available [string is space [get_flow_config -quiet init_power_intent_files 1801]]
  if {!($upf_available)} {
  if { ![dict exist  $pg_grid_dict $lyr ground staple]} {
  set inside_corner_area_blockage [P_generate_inside_corner_area_blockage_for_pg_mesh $lyr]
  set stripe_generation_area [P_stripe_generation_area $lyr ]
  set temp_layer_dict [dict create {*}[dict get $pg_grid_dict {*}$lyr]]
  if {[regexp {primary} [dict keys $temp_layer_dict]]} {
  set stripe_strategy [lindex [dict keys $temp_layer_dict] [lsearch -regexp [dict keys $temp_layer_dict] "primary"]]
     } else {
  #set stripe_strategy [lindex [dict keys $temp_layer_dict] [lsearch -regexp [dict keys $temp_layer_dict] "aon"]]
  set stripe_strategy [lindex [dict keys [dict get $pg_grid_dict $lyr]] [lsearch -regexp [dict keys [dict get $pg_grid_dict $lyr]] "aon"]]
     }
  puts $pgfile "##PG Creation commands for net ground for whole design for layer $lyr"
  P_create_PG_blockage -pwr_domain "default" -layer $lyr -pullback [dict get $pg_grid_dict $lyr pullback]
  P_addStripe_ground -stripe_layer $lyr -stripe_strategy $stripe_strategy -stripe_gen_area $stripe_generation_area -inside_corner_blockage $inside_corner_area_blockage -gnd_net $vars(INTEL_GROUND_NET)
  puts $pgfile "delete_route_blockages -name pgGridBlk"
  
  foreach pd [get_db power_domains .name] {
  foreach str [dict keys $temp_layer_dict] {
  #if {!((($lyr == "m6") && [dbGet [dbGet top.pds.name $pd -p1].isDefault] && [regexp "aon," $str]) || (($lyr == "m7") && [dbGet [dbGet top.pds.name $pd -p1].isDefault] && [regexp "aon,1" $str]) || (($lyr == "m6") && [regexp "aon,2" $str])) } 
  if {!((($lyr == "m6") && ([P_ret_aon_net -pwr_domain $pd] == [P_ret_primary_net -pwr_domain $pd]) && [regexp "aon," $str]) || (($lyr == "m7") && [regexp "aon,1" $str]) || (($lyr == "m6") && [regexp "aon,2" $str])) } {
  if { ![regexp {pullback|ground|aux} $str] } {
  if {[regexp {primary} $str]} {
  set power_net [P_ret_primary_net -pwr_domain $pd]
  set stripe_strategy "power_va_primary"
     } else {
  set power_net [P_ret_aon_net -pwr_domain $pd]
  #set stripe_strategy [lindex [dict keys [dict get $pg_grid_dict $lyr]] [lsearch -regexp [dict keys [dict get $pg_grid_dict $lyr]] "aon"]]
  set stripe_strategy $str
     }
  set stripe_generation_area [P_stripe_generation_area $lyr ]

  puts $pgfile "##PG Creation command for domain $pd for layer $lyr"
  if { ($lyr == "m8" || $lyr == "m7" || $lyr == "m6" ) && $power_net == [P_ret_aon_net -pwr_domain [get_db [get_db power_domains -if {.is_default == true && .is_virtual == false}] .name]]} {
  set pb_value 0
  } else {
  set pb_value $pullback_va([lindex $lyr 0],va)
  } 
  P_create_PG_blockage -pwr_domain $pd -layer $lyr -pullback $pb_value
 set flag 0
 if {[get_db [get_db power_domains $pd ] .is_default] != "1" && $lyr == "m6" && $stripe_strategy == "power_va_primary"} {
  set flag 2
  }
  if {[get_db [get_db power_domains $pd ] .is_default] == "1" && $lyr == "m6" && $stripe_strategy == "power_va_primary"} {
  set flag 1 
  }
  P_addStripe_power -stripe_layer $lyr -stripe_strategy $stripe_strategy -stripe_gen_area $stripe_generation_area -inside_corner_blockage $inside_corner_area_blockage -pwr_net $power_net -flag $flag -power_domain $pd
  puts $pgfile "delete_route_blockages -name intel_upf_pg_rb"
  puts $pgfile "delete_route_blockages -name intel_upf_pg_rb_expand"
     }
    }
    }
   }
  } else {
     foreach pd [get_db [get_db power_domains -if {.is_virtual == 0}] .name] {
  set inside_corner_area_blockage [P_generate_inside_corner_area_blockage_for_pg_mesh $lyr]
  set staple_layer_dict [dict create {*}[dict get $pg_grid_dict {*}$lyr]]
  if {[regexp {primary} [dict keys $staple_layer_dict]]} {
  set power_net [P_ret_primary_net -pwr_domain $pd]
  set stripe_strategy [lindex [dict keys $staple_layer_dict] [lsearch -regexp [dict keys $staple_layer_dict] "primary"]]
     } else {
  set power_net [P_ret_aon_net -pwr_domain $pd]
  set stripe_strategy [lindex [dict keys $staple_layer_dict] [lsearch -regexp [dict keys $staple_layer_dict] "aon"]]
     }
  set stripe_generation_area [P_stripe_generation_area $lyr ]
  puts $pgfile "##PG Creation commands for domain $pd for layer $lyr"
  P_create_PG_blockage -pwr_domain $pd -layer $lyr -pullback [dict get $pg_grid_dict $lyr pullback]
  set flag 0
  P_addStripe_power_ground -stripe_layer $lyr -stripe_strategy $stripe_strategy -stripe_gen_area $stripe_generation_area -inside_corner_blockage $inside_corner_area_blockage -gnd_net $vars(INTEL_GROUND_NET) -pwr_net $power_net -power_domain $pd  
  puts $pgfile "delete_route_blockages -name intel_upf_pg_rb"
  puts $pgfile "delete_route_blockages -name intel_upf_pg_rb_expand"
     }
  }
   } else {
  set inside_corner_area_blockage [P_generate_inside_corner_area_blockage_for_pg_mesh $lyr]
  set stripe_strategy "power"
  set stripe_generation_area [P_stripe_generation_area $lyr ]
  puts $pgfile "##PG Creation commands for nets power and ground for whole design for layer $lyr"
  P_create_PG_blockage -pwr_domain "default" -layer $lyr -pullback [dict get $pg_grid_dict $lyr pullback]
  P_addStripe_power_ground -stripe_layer $lyr -stripe_strategy $stripe_strategy -stripe_gen_area $stripe_generation_area -inside_corner_blockage $inside_corner_area_blockage -gnd_net $vars(INTEL_GROUND_NET) -pwr_net $vars(INTEL_POWER_NET) -power_domain "default"
  puts $pgfile "delete_route_blockages -name pgGridBlk"
   }
	puts $pgfile "delete_route_blockages -name route_macro_blockage_expand_$lyr"
	puts $pgfile "delete_route_blockages -name route_va_blockage_expand_$lyr"
  }
close $pgfile
}
define_proc_arguments create_pg_grid  \
-define_args {
  {-out_command_file "Specify file name to write out commands to create pg mesh" "val" string required }
  {-max_pg_layer "Specify the top metal PG routing " "val" string required }
}
}
