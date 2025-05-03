##############################################################################
# STEP write_oas
##############################################################################

create_flow_step -name write_oas -owner flow -exclude_time_metric {
  P_msg_info "Generating an output oas"
  P_outputs_oas  [get_db flow_report_name] 
}
