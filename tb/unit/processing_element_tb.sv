`timescale 1ns/1ps


module processing_element_tb;

localparam int DATA_WIDTH = 8;
localparam int ACC_WIDTH  = 32;

logic clk;
logic rst_n;
logic enable;
logic clear_acc;
logic valid_in;

logic signed [DATA_WIDTH-1:0] a_in;
logic signed [DATA_WIDTH-1:0] b_in;

logic signed [DATA_WIDTH-1:0] a_out;
logic signed [DATA_WIDTH-1:0] b_out;
logic signed [ACC_WIDTH-1:0] acc;
logic valid_out;

processing_element #(
.DATA_WIDTH(DATA_WIDTH),
.ACC_WIDTH(ACC_WIDTH)
) dut (
.clk(clk),
.rst_n(rst_n),
.enable(enable),
.clear_acc(clear_acc),
.valid_in(valid_in),
.a_in(a_in),
.b_in(b_in),
.a_out(a_out),
.b_out(b_out),
.acc(acc),
.valid_out(valid_out)
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
rst_n     = 0;
enable    = 0;
clear_acc = 0;
valid_in  = 0;
a_in      = 0;
b_in      = 0;

repeat (2) @(posedge clk);
#1;

check_acc(0, "Reset");
if (valid_out !== 1'b0)
$fatal(1, "FAIL: valid_out not cleared by reset");

@(negedge clk);
rst_n  = 1;
enable = 1;

@(posedge clk);
#1;
check_acc(0, "Initial idle cycle");

@(negedge clk);
clear_acc = 1;

@(posedge clk);
#1;
check_acc(0, "Clear accumulator");

@(negedge clk);
clear_acc = 0;
valid_in  = 1;
a_in      = 3;
b_in      = 4;

@(posedge clk);
#1;
check_acc(12, "First MAC operation");

if (a_out !== 3 || b_out !== 4 || valid_out !== 1'b1)
$fatal(1, "FAIL: First operand forwarding");

$display("PASS: First operand forwarding");

@(negedge clk);
a_in = -5;
b_in = 6;

@(posedge clk);
#1;
check_acc(-18, "Signed MAC accumulation");

if (a_out !== -5 || b_out !== 6 || valid_out !== 1'b1)
$fatal(1, "FAIL: Signed operand forwarding");

$display("PASS: Signed operand forwarding");

@(negedge clk);
valid_in = 0;
a_in = 100;
b_in = 100;

@(posedge clk);
#1;
check_acc(-18, "Invalid input holds accumulator");

if (valid_out !== 1'b0)
$fatal(1, "FAIL: valid_out should be low");

$display("PASS: Invalid input validity");

@(negedge clk);
enable = 0;
valid_in = 1;
a_in = 2;
b_in = 3;

@(posedge clk);
#1;
check_acc(-18, "Disabled PE holds accumulator");

if (a_out !== 100 || b_out !== 100 || valid_out !== 1'b0)
$fatal(1, "FAIL: Disabled PE changed registered outputs");

$display("PASS: Disabled PE holds registers");

@(negedge clk);
enable = 1;

@(posedge clk);
#1;
check_acc(-12, "Resume accumulation after stall");

if (a_out !== 2 || b_out !== 3 || valid_out !== 1'b1)
$fatal(1, "FAIL: Forwarding after stall");

$display("PASS: Forwarding after stall");

$display("--------------------------------");
$display("ALL PE TESTS PASSED");
$display("--------------------------------");

$finish;
end

endmodule