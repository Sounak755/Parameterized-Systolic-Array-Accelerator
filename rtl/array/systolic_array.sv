
`timescale 1ns/1ps

module systolic_array #(
    parameter int ARRAY_SIZE = 2,
    parameter int DATA_WIDTH = 8,
    parameter int ACC_WIDTH  = 32
) (
    input  logic clk,
    input  logic rst_n,
    input  logic start,

    input logic signed [
        ARRAY_SIZE*ARRAY_SIZE*DATA_WIDTH-1:0
    ] a_matrix,

    input logic signed [
        ARRAY_SIZE*ARRAY_SIZE*DATA_WIDTH-1:0
    ] b_matrix,

    output logic busy,
    output logic done,

    output logic signed [
        ARRAY_SIZE*ARRAY_SIZE*ACC_WIDTH-1:0
    ] c_matrix
);

    localparam int COUNT_WIDTH =
        (3 * ARRAY_SIZE > 1) ? $clog2(3 * ARRAY_SIZE) : 1;

    localparam int LAST_CYCLE_VALUE = 3 * ARRAY_SIZE - 3;
    localparam logic [COUNT_WIDTH-1:0] LAST_CYCLE =
        COUNT_WIDTH'(LAST_CYCLE_VALUE);
    logic [COUNT_WIDTH-1:0] cycle_count;

    logic signed [DATA_WIDTH-1:0] a_left [0:ARRAY_SIZE-1];
    logic signed [DATA_WIDTH-1:0] b_top  [0:ARRAY_SIZE-1];

    logic a_left_valid [0:ARRAY_SIZE-1];
    logic b_top_valid  [0:ARRAY_SIZE-1];

    logic signed [DATA_WIDTH-1:0] a_bus
        [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];

    logic signed [DATA_WIDTH-1:0] b_bus
        [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];

    logic signed [ACC_WIDTH-1:0] acc_bus
        [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];

    logic valid_bus [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];

    logic a_valid_grid [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
    logic b_valid_grid [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];

    logic pe_enable;
    logic pe_clear;

    initial begin
        if (ARRAY_SIZE < 1)
            $fatal(1, "ARRAY_SIZE must be at least 1");

        if (DATA_WIDTH < 1)
            $fatal(1, "DATA_WIDTH must be at least 1");

        if (ACC_WIDTH < 2 * DATA_WIDTH)
            $fatal(1, "ACC_WIDTH must be >= 2*DATA_WIDTH");
    end

    assign pe_enable = busy || (start && !busy);
    assign pe_clear  = start && !busy;

    // Controller: start, execute, and signal completion.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy        <= 1'b0;
            done        <= 1'b0;
            cycle_count <= '0;
        end else begin
            done <= 1'b0;

            if (!busy) begin
                if (start) begin
                    busy        <= 1'b1;
                    cycle_count <= '0;
                end
            end else begin
                if (cycle_count == LAST_CYCLE) begin
                    busy        <= 1'b0;
                    done        <= 1'b1;
                    cycle_count <= '0;
                end else begin
                    cycle_count <= cycle_count + 1'b1;
                end
            end
        end
    end

    genvar r, c;

    generate
        // Inject A rows with row-dependent skew.
        for (r = 0; r < ARRAY_SIZE; r = r + 1) begin : ROW_INPUTS

            always_comb begin
                a_left[r]       = '0;
                a_left_valid[r] = 1'b0;

                if ((int'(cycle_count) >= r) &&
                    ((int'(cycle_count) - r) < ARRAY_SIZE)) begin

                    if (busy) begin
                        a_left[r] = a_matrix[
                            ((r * ARRAY_SIZE +
                              (int'(cycle_count) - r))
                             * DATA_WIDTH) +: DATA_WIDTH
                        ];

                        a_left_valid[r] = 1'b1;
                    end
                end
            end
        end

        // Inject B columns with column-dependent skew.
        for (c = 0; c < ARRAY_SIZE; c = c + 1) begin : COLUMN_INPUTS

            always_comb begin
                b_top[c]       = '0;
                b_top_valid[c] = 1'b0;

                if ((int'(cycle_count) >= c) &&
                    ((int'(cycle_count) - c) < ARRAY_SIZE)) begin

                    if (busy) begin
                        b_top[c] = b_matrix[
                            (((int'(cycle_count) - c) * ARRAY_SIZE + c)
                             * DATA_WIDTH) +: DATA_WIDTH
                        ];

                        b_top_valid[c] = 1'b1;
                    end
                end
            end
        end

        // Generate the processing-element grid.
        for (r = 0; r < ARRAY_SIZE; r = r + 1) begin : ROW_PES
            for (c = 0; c < ARRAY_SIZE; c = c + 1) begin : COL_PES

                wire signed [DATA_WIDTH-1:0] pe_a_in;
                wire signed [DATA_WIDTH-1:0] pe_b_in;
                wire pe_valid_in;

                if (c == 0) begin : LEFT_EDGE
                    assign pe_a_in = a_left[r];
                    assign a_valid_grid[r][c] = a_left_valid[r];
                end else begin : INTERNAL_A
                    assign pe_a_in = a_bus[r][c-1];
                    assign a_valid_grid[r][c] = valid_bus[r][c-1];
                end

                if (r == 0) begin : TOP_EDGE
                    assign pe_b_in = b_top[c];
                    assign b_valid_grid[r][c] = b_top_valid[c];
                end else begin : INTERNAL_B
                    assign pe_b_in = b_bus[r-1][c];
                    assign b_valid_grid[r][c] = valid_bus[r-1][c];
                end

                assign pe_valid_in =
                    a_valid_grid[r][c] && b_valid_grid[r][c];

                processing_element #(
                    .DATA_WIDTH(DATA_WIDTH),
                    .ACC_WIDTH(ACC_WIDTH)
                ) pe_inst (
                    .clk(clk),
                    .rst_n(rst_n),
                    .enable(pe_enable),
                    .clear_acc(pe_clear),
                    .valid_in(pe_valid_in),
                    .a_in(pe_a_in),
                    .b_in(pe_b_in),
                    .a_out(a_bus[r][c]),
                    .b_out(b_bus[r][c]),
                    .acc(acc_bus[r][c]),
                    .valid_out(valid_bus[r][c])
                );

                assign c_matrix[
                    ((r * ARRAY_SIZE + c) * ACC_WIDTH) +: ACC_WIDTH
                ] = acc_bus[r][c];

            end
        end
    endgenerate

endmodule
