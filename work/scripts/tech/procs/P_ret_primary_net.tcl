proc P_ret_primary_net {args} {
  parse_proc_arguments -args $args inputs
  set pwr_domain $inputs(-pwr_domain)
  report_power_domains -power_domain $pwr_domain -verbose -out_file .pd.rpt
  set fp [open ".pd.rpt" r]
  set rpt_pd [read $fp]
  close $fp
  set prim_pwr [lindex [regexp -inline -lineanchor -linestop {Primary power net:\s+(\S+)} $rpt_pd] 1]
  set prim_pwr [get_db [get_db power_domains $pwr_domain ] .primary_power_net.name]
  return $prim_pwr

}

define_proc_arguments P_ret_primary_net  \
-info "Returns the primary power net for the provided power domain"  \
-define_args {
      {"-pwr_domain" "Domain for which the primary power net should be returned" "" string required}
    }

