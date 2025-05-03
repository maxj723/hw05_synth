// Simple Data Memory (RAM)
module data_mem #(
    parameter int DATA_WIDTH = 32,
    parameter int ADDR_WIDTH = 10 // Assuming 2^10 = 1024 words max
) (
    input logic clk,
    input logic [DATA_WIDTH-1:0] addr,
    input logic [DATA_WIDTH-1:0] wdata,
    input logic we,
    output logic [DATA_WIDTH-1:0] rdata
);
    logic [DATA_WIDTH-1:0] mem [(1<<ADDR_WIDTH)-1:0];
    logic [ADDR_WIDTH-1:0] mem_addr;

    assign mem_addr = addr[ADDR_WIDTH+1:2]; // Use appropriate bits for word address

    // Synchronous write
    always_ff @(posedge clk) begin
        if (we) begin
            mem[mem_addr] <= wdata;
            $display("[%t] MEM: Write %h to Addr %h (word %d)", $time, wdata, addr, mem_addr);
        end
    end

    // Asynchronous read (common simplification, or could be registered)
    // If registered, reads happen one cycle later. Let's keep it simple.
    // Note: If write and read happen on same cycle to same addr, read gets *old* value.
    assign rdata = mem[mem_addr];

    // Optional: Initialize data memory if needed
    initial begin
        for (int i = 0; i < (1<<ADDR_WIDTH); i++) begin
            mem[i] = 32'hDEADBEEF; // Initialize to noticeable value
        end
        // mem[0] = 32'h0; // Example initialization
    end

endmodule

