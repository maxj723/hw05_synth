##############################################################################
# STEP add_tracks for 108pp
##############################################################################
create_flow_step -name add_tracks -skip_db -skip_metric -owner intel {

add_tracks -width_pitch_pattern {\
	{m1 offset 0.0 width 0.068 pitch 0.108} \
	{m2 offset 0.0 width 0.044 pitch 0.090} \
	{m3 offset 0.0 width 0.044 pitch 0.090} \
	{m4 offset 0.0 width 0.044 pitch 0.090} \
	{m5 offset 0.0 width 0.044 pitch 0.090} \
	{m6 offset 0.0 width 0.044 pitch 0.090} \
	{m7 offset 0.0 width 0.180 pitch 0.360} \
        {m8 offset 0.0 width 0.180 pitch 0.360} \
}
add_tracks -pitch_pattern {m6 offset 0.0 pitch 0.090} -mode replace

}

