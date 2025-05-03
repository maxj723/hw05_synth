module fused_mac_pe_tb;

  // Parameters for flexibility
  parameter DATA_WIDTH = 8;
  parameter NUM_TESTS  = 10;

  // Signal declarations 
  logic clk;
  logic [DATA_WIDTH-1:0] a, b, c;
  logic [2*DATA_WIDTH-1:0] result; 

  // Instantiate the Fused MAC PE 
  fused_mac #( .DATA_WIDTH(DATA_WIDTH) ) dut (
    .clk(clk),
    .a(a),
    .b(b),
    .c(c),
    .result(result)
  );

  // Clock generation
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk; // Example 100 MHz clock
  end

  // Stimulus generation
  initial begin
    $display("Starting Fused MAC PE Testbench");

    // Test case 1
    #10; // Small delay for initial settling
    a = 8'd10;
    b = 8'd5;
    c = 8'd3;

    // More test cases - repeat with different values

    #100 $finish; // End simulation after some time
  end

  // Monitoring and result checking
  initial begin
    $monitor("Time: %0t, a = %d, b = %d, c = %d, result = %d", 
              $time, a, b, c, result);

    // Add assertions or calculate expected values for in-depth checks
    #100; // Wait for calculations
    if (result !== (a * b +c)) begin
      $error("Test failed!");
    end 
  end

endmodule

