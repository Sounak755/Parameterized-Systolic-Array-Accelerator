
`timescale 1ns/1ps

module systolic_array_tb #(
    parameter int N = 4,
    parameter int NUM_TESTS = 10
);

    localparam int DW = 8;
    localparam int AW = 32;

    logic clk, rst_n, start, busy, done;
    logic [N*N*DW-1:0] a_matrix, b_matrix;
    logic signed [N*N*AW-1:0] c_matrix;

    logic signed [DW-1:0] a_values [0:N*N-1];
    logic signed [DW-1:0] b_values [0:N*N-1];

    integer expected [0:N*N-1];
    integer test_num, r, c, k;
    integer av, bv;
    integer comparisons;

    systolic_array #(
        .ARRAY_SIZE(N),
        .DATA_WIDTH(DW),
        .ACC_WIDTH(AW)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .a_matrix(a_matrix),
        .b_matrix(b_matrix),
        .busy(busy),
        .done(done),
        .c_matrix(c_matrix)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic run_operation;
        begin
            @(negedge clk);
            start = 1'b1;

            @(negedge clk);
            start = 1'b0;

            wait (done === 1'b1);
            #1;
        end
    endtask

    task automatic check_outputs(input integer test_id);
        integer idx;
        logic signed [AW-1:0] actual;
        begin
            for (idx = 0; idx < N*N; idx = idx + 1) begin
                actual = $signed(c_matrix[idx*AW +: AW]);

                if (actual !== expected[idx])
                    $fatal(1,
                        "FAIL N=%0d test=%0d C[%0d][%0d] expected=%0d actual=%0d",
                        N, test_id, idx/N, idx%N,
                        expected[idx], actual);

                comparisons = comparisons + 1;
            end

            $display("PASS: N=%0d test %0d/%0d",
                     N, test_id, NUM_TESTS);
        end
    endtask

    initial begin
        rst_n = 1'b0;
        start = 1'b0;
        a_matrix = '0;
        b_matrix = '0;
        comparisons = 0;

        repeat (2) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;

        for (test_num = 1;
             test_num <= NUM_TESTS;
             test_num = test_num + 1) begin

            // Full signed 8-bit operand range: -128 through 127.
            for (r = 0; r < N*N; r = r + 1) begin
                a_values[r] = $urandom_range(0, 255) - 128;
                b_values[r] = $urandom_range(0, 255) - 128;
            end

            // Pack operands in row-major order.
            a_matrix = '0;
            b_matrix = '0;

            for (r = 0; r < N*N; r = r + 1) begin
                a_matrix = a_matrix |
                    ({{(N*N*DW-DW){1'b0}}, a_values[r]}
                     << (r*DW));

                b_matrix = b_matrix |
                    ({{(N*N*DW-DW){1'b0}}, b_values[r]}
                     << (r*DW));
            end

            // Calculate reference C = A * B.
            for (r = 0; r < N; r = r + 1) begin
                for (c = 0; c < N; c = c + 1) begin
                    expected[r*N+c] = 0;

                    for (k = 0; k < N; k = k + 1) begin
                        av = a_values[r*N+k];
                        bv = b_values[k*N+c];

                        expected[r*N+c] =
                            expected[r*N+c] + av*bv;
                    end
                end
            end

            run_operation();
            check_outputs(test_num);

            if (busy !== 1'b0)
                $fatal(1, "FAIL: busy remains high for N=%0d", N);
        end

        $display("----------------------------------------");
        $display("ALL TESTS PASSED FOR N=%0d", N);
        $display("Matrix multiplications: %0d", NUM_TESTS);
        $display("Output comparisons: %0d", comparisons);
        $display("----------------------------------------");

        $finish;
    end

    initial begin
        #20000;
        $fatal(1, "FAIL: Timeout for N=%0d", N);
    end

endmodule
