// Simple Instruction Memory (ROM)
module instr_mem #(
    parameter int DATA_WIDTH = 32,
    parameter int ADDR_WIDTH = 10 // Assuming 2^10 = 1024 instructions max
) (
    input logic [DATA_WIDTH-1:0] addr,
    output logic [DATA_WIDTH-1:0] data
);
    logic [DATA_WIDTH-1:0] mem [(1<<ADDR_WIDTH)-1:0];
    logic [ADDR_WIDTH-1:0] read_addr;

    // Initialize memory (example: read from file)
    initial begin
        // Default to NOP (addi x0, x0, 0) which is 0x00000013
        for (int i = 0; i < (1<<ADDR_WIDTH); i++) begin
            mem[i] = 32'h00000013;
        end
        // Load program from hex file (students will create/provide this)
        // Use a conditional generate or parameter if needed for different tests
        $display("Loading instruction memory from program.hex...");
        $readmemh("program.hex", mem); // Expect program.hex in sim directory
    end

    // Combinational read (instruction memory is often modeled this way)
    // Assuming word-aligned addresses for instructions
    assign read_addr = addr[ADDR_WIDTH+1:2]; // Use appropriate bits for word address
    assign data = mem[read_addr];

endmodule
