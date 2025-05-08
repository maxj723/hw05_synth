module my_project_tb;

    parameter int N = 4;
    parameter int DATA_WIDTH = 8;

    logic clk;
    logic reset;

    //controller signals
    logic start;
    logic [7:0] row, col, i;
    logic done;
    logic clear_ctrl, en_ctrl, inc_i, inc_col, inc_row;

    // datapath signals
    logic [DATA_WIDTH-1:0] A [0:N-1][0:N-1];
    logic [DATA_WIDTH-1:0] B [0:N-1][0:N-1];
    logic [DATA_WIDTH*2-1:0] C [0:N-1][0:N-1];
    logic [7:0] row_tb, col_tb, i_tb;
    logic clear_tb, en_tb;

    // matrix multilier signals
    logic [DATA_WIDTH*2-1:0] C_top [0:N-1][0:N-1];
    logic done_top;


    // instantiate controller
    controller #(
        .N(N)
    ) ctrl (
        .clk(clk),
        .reset(reset),
        .start(start),
        .row(row),
        .col(col),
        .i(i),
        .done(done),
        .clear(clear_ctrl),
        .en(en_ctrl),
        .inc_i(inc_i),
        .inc_col(inc_col),
        .inc_row(inc_row)
    );

    // Instantiate datapath
    datapath #(
        .N(N),
        .DATA_WIDTH(DATA_WIDTH)
    ) dp (
        .clk(clk),
        .reset(reset),
        .A(A),
        .B(B),
        .C(C),
        .row(row_tb),
        .col(col_tb),
        .i(i_tb),
        .clear(clear_tb),
        .en(en_tb)
    );

    // Instantiate matrix multiplier
    matrix_multiplier #(
        .N(N),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .A(A),
        .B(B),
        .C(C_top),
        .done(done_top)
    );

    // Clock generation
    always begin
        clk = 1'b0;
        #5;
        clk = 1'b1;
        #5;
    end

    
    initial begin

        // Initialize all testbench signals to 0
        start    = 0;
        reset    = 0;
        row_tb   = 0;
        col_tb   = 0;
        i_tb     = 0;
        clear_tb = 0;
        en_tb    = 0;

        // Controller test
        $display("\n----------Controller Tests----------");
        
        //reset
        reset = 1'b1;
        @(posedge clk);
        reset = 1'b0;
        @(posedge clk);
        // Confirm reset succeeded
        assert(ctrl.state == 0) else $error("Assertion failed: state should be INIT"); //Confirm it is in INIT
        assert(ctrl.row_update == 0) else $error("Assertion failed: row_update should be 0"); // confirm reg are reset
        assert(ctrl.col_update == 0) else $error("Assertion failed: col_update should be 0");
        assert(ctrl.i_update == 0) else $error("Assertion failed: i_update should be 0");
        $display("RESET TESTS COMPLETED");

        // Check IDLE -> INIT
        start = 1'b0;
        @(posedge clk);
        start = 1'b1;
        @(posedge clk);
        assert(ctrl.state == 1) else $error("Assertion failed: state should be 1");
        assert(ctrl.clear == 1) else $error("Assertion failed: clear should be 1");
        assert(ctrl.row_update == 0) else $error("Assertion failed: row_update should be 0"); // confirm reg are reset
        assert(ctrl.col_update == 0) else $error("Assertion failed: col_update should be 0");
        assert(ctrl.i_update == 0) else $error("Assertion failed: i_update should be 0");
        $display("IDLE -> INIT TESTS COMPLETED");

        // Check INIT -> MULTIPLY
        @(posedge clk);
        assert(ctrl.state == 2) else $error("Assertion failed: state should be 2");
        assert(ctrl.en == 1) else $error("Assertion failed: en should be true");
        assert(ctrl.inc_i == 1) else $error("Assertion failed: inc_i should be true");
        $display("INIT -> MULTIPLY TESTS COMPLETED");

        // Check MULTIPLY state
        @(posedge clk);
        assert(ctrl.i_update == 1) else $error("Assertion failed: i_update should be 1");
        // Testing inc_i and inc_col when at the end of a row
        repeat (N - 1) @(posedge clk); // Let i_update increment to N
        assert(ctrl.i_update == N) else $error("Assertion failed: i_update should be N");
        assert(ctrl.inc_i == 0) else $error("Assertion failed: inc_i should be false");
        assert(ctrl.inc_col == 1) else $error("Assertion failed: inc_col should be true");
        // Confirming column has been updated and i is reset
        @(posedge clk);
        assert(ctrl.col_update == 1) else $error("Assertion failed: col_update should be 1");
        assert(ctrl.i_update == 0) else $error("Assertion failed: i_update should be 0");
        assert(ctrl.inc_i == 1) else $error("Assertion failed: inc_i should be true");
        assert(ctrl.inc_col == 0) else $error("Assertion failed: inc_col should be false");
        // Testing inc_i and inc_col and inc_row when done with row
        repeat (N * (N-1)) @(posedge clk);
        repeat (2) @(posedge clk);
        assert(ctrl.inc_col == 1) else $error("Assertion failed: inc_col should be true");
        assert(ctrl.inc_i == 0) else $error("Assertion failed: inc_i should be 0");
        assert(ctrl.i_update == N) else $error("Assertion failed: i_update should be N");
        assert(ctrl.col_update == N-1) else $error("Assertion failed: col_update should be N-1");
        // Confirming row is updated, and column/i are reset
        @(posedge clk);
        assert(ctrl.row_update == 1) else $error("Assertion failed: row_update should be 1");
        assert(ctrl.col_update == 0) else $error("Assertion failed: col_update should be 0");
        assert(ctrl.i_update == 0) else $error("Assertion failed: i_update should be 0");
        assert(ctrl.inc_i == 1) else $error("Assertion failed: inc_i should be true");
        assert(ctrl.inc_col == 0) else $error("Assertion failed: inc_col should be false");
        assert(ctrl.inc_row == 0) else $error("Assertion failed: inc_row should be false");
        $display("MULTIPLY TESTS COMPLETED");

        // Check MULTIPLY -> DONE Transition
        start = 1'b0;
        repeat (N * N * (N-1)) @(posedge clk); // Iterate to the last n in matrix
        repeat (N * (N-1)) @(posedge clk);
        assert(ctrl.state == 3) else $error("Assertion failed: state should be 3");
        assert(ctrl.done == 1) else $error("Assertion failed: done should be 1");
        assert(ctrl.en == 0) else $error("Assertion failed: en should be 0");
        $display("MULTIPLY -> DONE TESTS COMPLETED");

        // Check DONE -> IDLE Transition
        @(posedge clk);
        assert(ctrl.state == 0) else $error("Assertion failed: state should be 3");
        assert(ctrl.done == 0) else $error("Assertion failed: done should be 0");
        $display("DONE -> IDLE TESTS COMPLETED");


        $display("\n----------Datapath Tests----------");

        //reset
        reset = 1'b1;
        @(posedge clk);
        reset = 1'b0;
        @(posedge clk);

        // Set A and B matrices (B is identity)
        A[0][0] = 1;
        B[0][0] = 1;

        // simple mu;ltiplication test and saving to C matrix
        en_tb = 1'b1;
        i_tb = 0;
        row_tb = 0;
        col_tb = 0;
        @(posedge clk);
        assert(dp.temp_val_reg == 1) else $error("Assertion failed: temp_val_reg should be 1");
        i_tb = N;
        @(posedge clk);
        assert(C[0][0] == 1) else $error("Assertion failed: C[0][0] should be 1");
        $display("SIMPLE MULTIPLY AND SAVE TESTS COMPLETED");

        // clear test
        en_tb = 1'b0;
        clear_tb = 1'b1;
        @(posedge clk);
        assert(C[0][0] == 0) else $error("Assertion failed: C[0][0] should be 0");
        assert(dp.temp_val_reg == 0) else $error("Assertion failed: temp_val_reg should be 0");
        $display("CLEAR TEST COMPELTED");

        // Reill part of matrix for reset test
        clear_tb = 1'b0;
        en_tb = 1'b1;
        i_tb = 0;
        row_tb = 0;
        col_tb = 0;
        @(posedge clk);
        i_tb = N;
        @(posedge clk);
        //Confirm there are values in C
        assert(C[0][0] == 1) else $error("Assertion failed: C[0][0] should be 1");
        reset = 1'b1;
        @(posedge clk);
        assert(C[0][0] == 0) else $error("Assertion failed: C[0][0] should be 0");
        assert(dp.temp_val_reg == 0) else $error("Assertion failed: temp_val_reg should be 0");
        $display("RESET TEST COMPELTED");


        // Matrix Multiplier test
        $display("\n----------Matrix Multiplier Tests----------");
        reset = 1'b1;
        @(posedge clk);
        reset = 1'b0;
        @(posedge clk);

        A = '{ '{0,1,2,3},
                '{4,5,6,7},
                '{8,9,10,11},
                '{12,13,14,15} };
        B = '{ '{0,4,8,12},
                '{1,5,9,13},
                '{2,6,10,14},
                '{3,7,11,15} };

        // C_answer = '{ '{14,38,62,86},
        //             '{38,126,214,302},
        //             '{62,214,366,518},
        //             '{86,302,518,734} };

        start = 1;
        @(posedge clk);
        start = 0;
        wait(done_top);
        
        assert(C_top[0][0] == 14) else $error("Assertion failed: C_top[0][0] should be 14");
        assert(C_top[0][1] == 38) else $error("Assertion failed: C_top[0][1] should be 38");
        assert(C_top[0][2] == 62) else $error("Assertion failed: C_top[0][2] should be 62");
        assert(C_top[0][3] == 86) else $error("Assertion failed: C_top[0][3] should be 86");

        assert(C_top[1][0] == 38) else $error("Assertion failed: C_top[1][0] should be 38");
        assert(C_top[1][1] == 126) else $error("Assertion failed: C_top[1][1] should be 126");
        assert(C_top[1][2] == 214) else $error("Assertion failed: C_top[1][2] should be 214");
        assert(C_top[1][3] == 302) else $error("Assertion failed: C_top[1][3] should be 302");

        assert(C_top[2][0] == 62) else $error("Assertion failed: C_top[2][0] should be 62");
        assert(C_top[2][1] == 214) else $error("Assertion failed: C_top[2][1] should be 214");
        assert(C_top[2][2] == 366) else $error("Assertion failed: C_top[2][2] should be 366");
        assert(C_top[2][3] == 518) else $error("Assertion failed: C_top[2][3] should be 518");

        assert(C_top[3][0] == 86) else $error("Assertion failed: C_top[3][0] should be 86");
        assert(C_top[3][1] == 302) else $error("Assertion failed: C_top[3][1] should be 302");
        assert(C_top[3][2] == 518) else $error("Assertion failed: C_top[3][2] should be 518");
        assert(C_top[3][3] == 734) else $error("Assertion failed: C_top[3][3] should be 734");
        $display("ALL MATRIX MULTIPLIER TESTS COMPLETED\n");


        $finish;
    end


endmodule