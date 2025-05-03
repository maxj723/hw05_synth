##############################################################################
# STEP ndr_definition
##############################################################################
create_flow_step -name ndr_definition -skip_db -skip_metric -owner intel {

set is_ndr_define 0
set ndr_rule [get_db route_rules .name ]
if { $ndr_rule ne "" } {
        set is_ndr_define 1
        P_msg_info "NDR rules defined in DEF file. skipping ndr_definition step"
} else {
        set is_ndr_define 0
}

if { $is_ndr_define == 0 } {

create_route_rule \
  -name ndr_wideW_m3_m8  \
  -width { \
    m1 0.068 \
    m2 0.044 \
    m3 0.108 \
    m4 0.108 \
    m5 0.108 \
    m6 0.160 \
    m7 0.360 \
    m8 0.360 \
      }

}
}
