proc P_ret_aon_net {args} {
  global vars
  parse_proc_arguments -args $args inputs
  set pwr_domain $inputs(-pwr_domain)
set upf_available [string is space [get_flow_config -quiet init_power_intent_files 1801]]
if {!($upf_available)} {
  if { [info exists vars(aon,$pwr_domain)] && $vars(aon,$pwr_domain) != "" } {
      set aon_pwr $vars(aon,$pwr_domain)
  } else {
      set pd [ get_db power_domains $pwr_domain ]
      set  switch_name [get_db [get_db $pd] .power_switch_rule_name] 
      set aon_pwr ""
      if {[llength $switch_name] > 0 } {
        # now query that rule name for the details. This will return a list of lists to inspect
        # the "input_supply_port" list contains the info we need. 
        foreach value [eval_legacy "ieee1801::query_power_switch $switch_name -detailed"] {
           if {[lindex $value 0] == "input_supply_port"} {
              set inPwrPort [lindex [lindex $value 1] 1]
              # Input port could be the actual port "Vcc" or could be a indirect reference to the port "<domain>.primary.<type>" format.
              if {[regexp -nocase {([A-Z0-9_]+)\.primary} $inPwrPort tmp PD]} {
                 # indirect case - get the net name from the power domain attribute
                 set aon_pwr [ get_db [get_db power_domains $PD ] .primary_power_net.name]
              } else {
                 # direct case - find net of the power port
                 set aon_pwr [get_db [get_db ports $inPwrPort] .net.name] 
              }
          }
       }
     } elseif {[get_db power_domain:$pwr_domain .is_always_on] == "true"} {
        set aon_pwr [lindex [get_db [get_db power_domain:$pwr_domain] .primary_power_net.name] 0]
     } else {
        set aon_pwr [lindex [get_db power_domain:$pwr_domain .available_supply_nets.name] 0]

     } 
  }
}
return $aon_pwr
}

define_proc_arguments P_ret_aon_net  \
-info "Returns the always on power net for the provided power domain"  \
-define_args {
      {"-pwr_domain" "Domain for which the always on power net should be returned" "" string required}
    }
