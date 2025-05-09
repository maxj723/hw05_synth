module my_project #(
    parameter N = 4,
    parameter int DATA_WIDTH = 8
) (
    input logic clk,
    input logic reset,
    input logic start, // indicate data is in
    // Input Matrices
    input logic [DATA_WIDTH-1:0] A [0:N-1][0:N-1],
    input logic [DATA_WIDTH-1:0] B [0:N-1][0:N-1],
    
    // Output Matrix
    output logic [DATA_WIDTH*2-1:0] C [0:N-1][0:N-1],

    output logic done // indicate C is fully calculated. ready to be read
);

    logic [7:0] row, col, i;
    logic clear, en, inc_i, inc_col, inc_row;

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
        .clear(clear),
        .en(en),
        .inc_i(inc_i),
        .inc_col(inc_col),
        .inc_row(inc_row)
    );

    datapath #(
        .N(N),
        .DATA_WIDTH(DATA_WIDTH)
    ) dp (
        .clk(clk),
        .reset(reset),
        .A(A),
        .B(B),
        .row(row),
        .col(col),
        .i(i),
        .clear(clear),
        .en(en),
        .C(C)
    );
endmodule

module controller #(
    parameter N = 4 // Height or width of matrix--Limited to 256 due to 8bit limit on row/col reg
) (
    input logic clk,
    input logic reset,
    input logic start,

    output logic [7:0] row,
    output logic [7:0] col,
    output logic [7:0] i,
    output logic clear,
    output logic en,
    output logic inc_row,
    output logic inc_col,
    output logic inc_i,
    output logic done

);

    // States
    typedef enum logic [2:0] {IDLE, INIT, MULTIPLY, DONE} state_t;
    state_t state, next_state;

    // Initialize running row/col/i values to be updated by controller
    logic [7:0] row_update, col_update, i_update;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) state <= IDLE;
        else state <= next_state;
    end

    always_comb begin
        next_state = state;
        case (state)
            IDLE: if (start) next_state = INIT; // Wait for start to begin
            INIT: next_state = MULTIPLY;
            MULTIPLY: if (row_update == N-1 && col_update == N-1 && i_update == N) next_state = DONE; // Move to next state if finished with last n in matrix
            DONE: next_state = IDLE; // Return to idle after output
        endcase
    end

    assign clear = (state == INIT);
    assign en = (state == MULTIPLY);
    assign inc_i = (state == MULTIPLY) && (i_update < N); // Move to next index while not at end of row/col
    assign inc_col = (state == MULTIPLY) && (i_update == N); // Move to next col when index is at the end of row/col
    assign inc_row = (state == MULTIPLY) && (i_update == N) && (col_update == N-1); // Move to next row when all columns iterated
    assign done = (state == DONE); // Indicate when ouput matrix has been fully filled

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            row_update <= 0;
            col_update <= 0;
            i_update <= 0;
        end else begin
            if (state == INIT) begin
                row_update <= 0;
                col_update <= 0;
                i_update <= 0;
            end else if (state == MULTIPLY) begin
                if (inc_i) i_update <= i_update + 1;
                else if (inc_col || inc_row) i_update <= 0; // Only reset i_update if not last row/col => necessary for state transition
                
                if (inc_col) col_update <= col_update + 1;
                if (inc_row) col_update <= 0; // Reset cols if done with row
                
                if (inc_row) row_update <= row_update + 1;
            end
        end
    end

    assign row = row_update;
    assign col = col_update;
    assign i = i_update;
endmodule

module datapath #(
    parameter N = 4,
    parameter DATA_WIDTH = 8
) (
    input logic clk,
    input logic reset,
    input logic [DATA_WIDTH-1:0] A [0:N-1][0:N-1],
    input logic [DATA_WIDTH-1:0] B [0:N-1][0:N-1],
    input logic [7:0] row,
    input logic [7:0] col,
    input logic [7:0] i,
    input logic clear,
    input logic en,

    output logic [DATA_WIDTH*2-1:0] C [0:N-1][0:N-1]
);

    logic [DATA_WIDTH*2-1:0] temp_val_reg;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) temp_val_reg <= '0;
        else if (clear) temp_val_reg <= '0;
        else if (en) begin
            if ((row < N) && (col < N) && (i < N))
                temp_val_reg <= temp_val_reg + A[row][i] * B[i][col];
            else
                temp_val_reg <= 0;
        end
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            for (int i = 0; i < N; i++)
                for (int j = 0; j < N; j++)
                    C[i][j] <= '0;
        end else if (clear) begin
            if ((row < N) && (col < N))  // Only clear if indices are valid
                C[row][col] <= '0;
        end else if (en && i == N) begin
            if ((row < N) && (col < N))  // Only write if indices are valid
                C[row][col] <= temp_val_reg;
        end
    end
endmodule
