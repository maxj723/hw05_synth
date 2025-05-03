module riscv_stub_tb2;

    parameter int DATA_WIDTH = 32;
    parameter int TIMEOUT_CYCLES = 500; // Add a timeout

    // Clock and reset signals
    logic clk;
    logic reset;

    // DUT Interface signals (wires are implicit for module ports)
    logic [DATA_WIDTH-1:0] instr_addr;
    logic [DATA_WIDTH-1:0] instr_data;
    logic [DATA_WIDTH-1:0] data_addr;
    logic [DATA_WIDTH-1:0] data_wdata;
    logic [DATA_WIDTH-1:0] data_rdata;
    logic data_we;

    // Instantiate instruction memory
    instr_mem #(
        .DATA_WIDTH(DATA_WIDTH)
        // Adjust ADDR_WIDTH if needed for larger programs
    ) imem (
        .addr(instr_addr),
        .data(instr_data)
    );

    // Instantiate data memory
    data_mem #(
        .DATA_WIDTH(DATA_WIDTH)
        // Adjust ADDR_WIDTH if needed
    ) dmem (
        .clk(clk),
        .addr(data_addr),
        .wdata(data_wdata),
        .we(data_we),
        .rdata(data_rdata)
    );


    // Instantiate the riscv_stub module
    riscv_stub #(
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .reset(reset),
        .instr_addr(instr_addr),
        .instr_data(instr_data),
        .data_addr(data_addr),
        .data_wdata(data_wdata),
        .data_rdata(data_rdata),
        .data_we(data_we)
    );

    // Clock generation
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk; // 10ns period
    end

    // Test scenario
    initial begin
        $display("Starting RISC-V Testbench...");

        // 1. Reset the processor
        reset = 1'b1;
        @(posedge clk);
        @(posedge clk);
        reset = 1'b0;
        $display("Reset released.");

        // 2. Run simulation until timeout or halt condition
        //    (A simple halt is an infinite loop like 'j halt')
        //    We detect halt by seeing PC not change for a few cycles
        logic [DATA_WIDTH-1:0] last_pc = 'x;
        int same_pc_count = 0;
        for (int i = 0; i < TIMEOUT_CYCLES; i++) begin
            @(posedge clk);

            // Optional: Display reduced info per cycle (e.g., PC and instruction)
            // $display("Cycle %3d: PC=%h, Instr=%h", i, dut.pc_reg, dut.instr_data);

            // Optional: Display WB stage info when write happens
             if (dut.MEM_WB_reg_write && dut.MEM_WB_rd != 0) begin
                 $display("[%t] Cycle %3d: WB: x%d <= %h", $time, i, dut.MEM_WB_rd, dut.MEM_WB_alu_result); // Adjust based on actual WB data mux
             end

             // Check for halt (PC stuck in the jump-to-self loop)
             if (dut.pc_reg == last_pc) begin
                same_pc_count++;
             end else begin
                same_pc_count = 0;
             end
             last_pc = dut.pc_reg;

             if (same_pc_count > 4) begin // PC stable for 5 cycles -> likely halted
                $display("PC stable at %h, assuming halted.", dut.pc_reg);
                break; // Exit loop
             end

             if (i == TIMEOUT_CYCLES - 1) begin
                 $error("TIMEOUT: Simulation reached %d cycles without halting.", TIMEOUT_CYCLES);
             end
        end

        // 3. Check final state (Assertions)
        //    Students MUST uncomment/modify the assertions based on the
        //    'program.hex' file loaded (e.g., test_alu.hex, test_mem.hex etc.)

        $display("\nFinal Register State:");
        for (int i=0; i<32; i=i+4) begin
           $display("  x%02d: %h  x%02d: %h  x%02d: %h  x%02d: %h",
                     i,   dut.reg_file[i],   i+1, dut.reg_file[i+1],
                     i+2, dut.reg_file[i+2], i+3, dut.reg_file[i+3]);
        end
        $display("Final PC: %h", dut.pc_reg);

        // --- ASSERTION SECTION ---
        // === Assertions for test_alu.hex ===
        /*
        assert(dut.reg_file[1] == 5) else $error("Assertion failed: x1 should be 5");
        assert(dut.reg_file[2] == 10) else $error("Assertion failed: x2 should be 10");
        assert(dut.reg_file[3] == 15) else $error("Assertion failed: x3 should be 15");
        assert(dut.reg_file[4] == 5) else $error("Assertion failed: x4 should be 5");
        assert(dut.reg_file[5] == -1) else $error("Assertion failed: x5 should be -1");
        assert(dut.reg_file[6] == 1) else $error("Assertion failed: x6 should be 1 (slti)");
        assert(dut.reg_file[7] == 0) else $error("Assertion failed: x7 should be 0 (slti)");
        assert(dut.reg_file[8] == 0) else $error("Assertion failed: x8 should be 0 (slti)");
        assert(dut.reg_file[9] == 1) else $error("Assertion failed: x9 should be 1 (slti)");
        assert(dut.reg_file[10] == 1) else $error("Assertion failed: x10 should be 1 (sltiu)");
        assert(dut.reg_file[11] == 0) else $error("Assertion failed: x11 should be 0 (sltiu)");
        assert(dut.reg_file[12] == 0) else $error("Assertion failed: x12 should be 0 (sltiu)");
        assert(dut.reg_file[13] == 1) else $error("Assertion failed: x13 should be 1 (andi)");
        assert(dut.reg_file[14] == 13) else $error("Assertion failed: x14 should be 13 (ori)");
        assert(dut.reg_file[15] == 10) else $error("Assertion failed: x15 should be 10 (xori)");
        assert(dut.reg_file[17] == 20) else $error("Assertion failed: x17 should be 20 (slli)");
        assert(dut.reg_file[18] == 20) else $error("Assertion failed: x18 should be 20 (sll)");
        assert(dut.reg_file[19] == 2) else $error("Assertion failed: x19 should be 2 (srli)");
        assert(dut.reg_file[20] == 1) else $error("Assertion failed: x20 should be 1 (srl)");
        assert(dut.reg_file[22] == -1) else $error("Assertion failed: x22 should be -1 (srai)");
        assert(dut.reg_file[23] == -1) else $error("Assertion failed: x23 should be -1 (sra)");
        assert(dut.reg_file[0] == 0) else $error("Assertion failed: x0 should always be 0"); // Check x0
        */

        // === Assertions for test_mem.hex ===
        /*
        assert(dut.reg_file[1] == 42) else $error("Assertion failed: x1 should be 42");
        assert(dut.reg_file[2] == 256) else $error("Assertion failed: x2 should be 256");
        assert(dut.reg_file[3] == 42) else $error("Assertion failed: x3 should be 42 (loaded from Mem[256])");
        assert(dut.reg_file[4] == -1) else $error("Assertion failed: x4 should be -1");
        assert(dut.reg_file[5] == -1) else $error("Assertion failed: x5 should be -1 (loaded from Mem[260])");
        assert(dut.reg_file[6] == 0) else $error("Assertion failed: x6 should be 0 (testing x0 read)");
        assert(dut.reg_file[0] == 0) else $error("Assertion failed: x0 should always be 0 (even after lw x0,...)");
        // Check memory directly (more robust) - student might need help with TB hierachy path
        // assert(tb.dmem.mem[256/4] == 42) else $error("Assertion failed: Mem[256] should be 42");
        // assert(tb.dmem.mem[260/4] == -1) else $error("Assertion failed: Mem[260] should be -1");
        */

        // === Assertions for test_hazard_fwd.hex ===
        /*
        assert(dut.reg_file[1] == 5) else $error("Assertion failed: x1 should be 5");
        assert(dut.reg_file[2] == 6) else $error("Assertion failed: x2 should be 6 (5+1, MEM->EX fwd)");
        assert(dut.reg_file[3] == 10) else $error("Assertion failed: x3 should be 10");
        assert(dut.reg_file[4] == 11) else $error("Assertion failed: x4 should be 11 (10+1, WB->EX fwd)");
        assert(dut.reg_file[5] == 20) else $error("Assertion failed: x5 should be 20");
        assert(dut.reg_file[6] == 25) else $error("Assertion failed: x6 should be 25 (20+5, MEM->EX & WB->EX fwd)");
        assert(dut.reg_file[7] == 31) else $error("Assertion failed: x7 should be 31 (25+6, MEM->EX & WB->EX fwd)");
        assert(dut.reg_file[0] == 0) else $error("Assertion failed: x0 should always be 0");
        */

        // === Assertions for test_hazard_stall.hex ===
        /*
        assert(dut.reg_file[1] == 77) else $error("Assertion failed: x1 should be 77");
        assert(dut.reg_file[2] == 128) else $error("Assertion failed: x2 should be 128");
        assert(dut.reg_file[3] == 77) else $error("Assertion failed: x3 should be 77 (loaded from Mem[128])");
        assert(dut.reg_file[4] == 78) else $error("Assertion failed: x4 should be 78 (77+1, requires stall + MEM->EX fwd)");
        assert(dut.reg_file[0] == 0) else $error("Assertion failed: x0 should always be 0");
        // Check memory directly
        // assert(tb.dmem.mem[128/4] == 77) else $error("Assertion failed: Mem[128] should be 77");
        */

        // === Assertions for test_jal.hex ===
        /*
        assert(dut.reg_file[1] == 8) else $error("Assertion failed: x1 (ra) should be 8 (PC+4 of JAL)");
        assert(dut.reg_file[2] == 0) else $error("Assertion failed: x2 should be 0 (flushed instruction)");
        assert(dut.reg_file[3] == 0) else $error("Assertion failed: x3 should be 0 (flushed instruction)");
        assert(dut.reg_file[4] == 4) else $error("Assertion failed: x4 should be 4 (first instruction at target)");
        assert(dut.reg_file[5] == 12) else $error("Assertion failed: x5 should be 12 (4 + 8)");
        assert(dut.reg_file[10] == 1) else $error("Assertion failed: x10 should be 1 (instruction before JAL)");
        assert(dut.reg_file[11] == 0) else $error("Assertion failed: x11 should be 0 (flushed instruction)");
        assert(dut.reg_file[0] == 0) else $error("Assertion failed: x0 should always be 0");
        assert(dut.pc_reg == 32'h1C) else $error("Assertion failed: Final PC should be at halt (0x1C)"); // Check final PC is halt addr
        */

        // 4. Finish
        $display("Simulation finished.");
        $finish;
    end

    // Optional: Waveform dumping
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, riscv_stub_tb); // Dump all signals in the TB and below
    end

endmodule
