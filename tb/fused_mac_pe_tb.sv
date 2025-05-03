module fused_mac_tb;

  // Parameter Overrides (optional)
  parameter DATA_WIDTH = 8; 
  parameter ACC_WIDTH  = 20;
  parameter OVFLW_BITS = 3;  

  // Input/Output Ports
  reg clk;
  reg reset;
  reg [DATA_WIDTH-1:0] a_in;
  reg [DATA_WIDTH-1:0] b_in;
  reg start;
  wire [ACC_WIDTH-1:0] mac_result;
  wire done;

  // Instantiate the Design Under Test (DUT)
  fused_mac #(
    .DATA_WIDTH(DATA_WIDTH),
    .ACC_WIDTH(ACC_WIDTH),
    .OVFLW_BITS(OVFLW_BITS),
    .VECTOR_SIZE(4)
  ) dut (
    .clk(clk),
    .reset(reset),
    .a_in(a_in),
    .b_in(b_in),
    .start(start),
    .mac_result(mac_result),
    .done(done)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 10ns clock period 
  end

  // Stimulus and Test Logic
  initial begin
    // Initialize values
    reset = 1;
    a_in = 0; 
    b_in = 0;
    start = 0;

    #10; // Allow for a reset period
    reset = 0;

    // Test Case 1: Simple MAC
    a_in = 2; 
    b_in = 3;
    start = 1; 
    #10; 
    start = 0;

    // Wait for completion, check result
    @(posedge done);  
    if (mac_result !== 2 * 3 * 4) begin // Expected: 24
      $display("Test Case 1 Failed!");
    end else begin
      $display("Test Case 1 Passed!");
    end


    #100 $finish; 
  end 
endmodule

