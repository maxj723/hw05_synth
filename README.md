Max Johnson

902204711

my_project.sv is a simple matrix multiplier. It defaults to N=4 which means it can multiply two 4x4 matrices. The top module takes 3 inputs--a start signal, the first matrix A, and the second matrix B. Both matrices must be made of 8 bit numbers. Then it outputs a 4x4 matrix C and a done signal. The start signal notifies the module to start computing the output. The done signal notifies that the final answer is ready.


The project mainly consists of these files: 
- src/my_project.sv - main source code of matrix multiplier
- tb/my_project_tb.sv - test bench for matrix multiplier
- synth/my_project_synth.tcl - script for synthesizing
- synth/constraints/my_project.sdc - constraints for synthesizing

For simulation and testing, run this command: make run

For synthesis, run this command: genus -f my_project_synth.tcl

The matrix multiplier runs on a 5 ns clock period, resulting in 4949.283 ns of slack, 1.36590e-06 W of leakage power and 1.41606e-04 W dynamic power usage, and a total area of 1441.563 μm^2.