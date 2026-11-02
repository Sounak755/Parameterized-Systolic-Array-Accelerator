
`timescale 1ns/1ps

module mac_unit_tb;

    localparam int DATA_WIDTH = 8;
    localparam int ACC_WIDTH  = 32;

    logic clk;
    logic rst_n;
    logic enable;
    logic signed [DATA_WIDTH-1:0] a;
    logic signed [DATA_WIDTH-1:0] b;
    logic signed [ACC_WIDTH-1:0] acc;

    mac_unit #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .a(a),
        .b(b),
        .acc(acc)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task automatic check_acc(
        input logic signed [ACC_WIDTH-1:0] expected,
        input string test_name
    );
        if (acc !== expected)
            $fatal(1, "FAIL: %s | Expected=%0d, Got=%0d",
                   test_name, expected, acc);

        $display("PASS: %s | acc=%0d", test_name, acc);
    endtask

    initial begin
        rst_n  = 0;
        enable = 0;
        a      = 0;
        b      = 0;

        repeat (2) @(posedge clk);
        #1;
        check_acc(0, "Asynchronous reset");

        @(negedge clk);
        rst_n  = 1;
        enable = 1;
        a      = 3;
        b      = 4;

        @(posedge clk);
        #1;
        check_acc(12, "Positive multiplication");

        @(negedge clk);
        a = -5;
        b = 6;

        @(posedge clk);
        #1;
        check_acc(-18, "Signed multiplication and accumulation");

        @(negedge clk);
        enable = 0;
        a = 100;
        b = 100;

        @(posedge clk);
        #1;
        check_acc(-18, "Accumulator hold when disabled");

        @(negedge clk);
        enable = 1;
        a = -8;
        b = -7;

        @(posedge clk);
        #1;
        check_acc(38, "Negative times negative");

        @(negedge clk);
        rst_n = 0;

        #1;
        check_acc(0, "Asynchronous reset during operation");

        @(negedge clk);
        rst_n = 1;
        enable = 1;
        a = 0;
        b = 127;

        @(posedge clk);
        #1;
        check_acc(0, "Zero multiplication");

        $display("--------------------------------");
        $display("ALL MAC UNIT TESTS PASSED");
        $display("--------------------------------");

        $finish;
    end

endmodule
