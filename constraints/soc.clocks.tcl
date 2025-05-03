# you can write more complex constraints if you want
# set_clock_uncertainty -setup 235 -from pxclk -to pxclk
# set_clock_uncertainty -setup 235 -from pxclk -to xtclk_13p5
# set_clock_uncertainty -setup 235 -from xtclk_13p5 -to pxclk
# set_clock_uncertainty -setup 235 -from xtclk_13p5 -to xtclk_13p5
#

create_clock -name clk -period 1000 -waveform {0 500} [get_ports {clk}]
set_clock_uncertainty -setup 50 [get_clocks clk]
set_clock_uncertainty -hold  50 [get_clocks clk]

