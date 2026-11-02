
`timescale 1ns/1ps

module processing_element #(
    parameter int DATA_WIDTH = 8,
    parameter int ACC_WIDTH  = 32
) (
    input  logic                         clk,
    input  logic                         rst_n,
    input  logic                         enable,
    input  logic                         clear_acc,
    input  logic                         valid_in,

    input  logic signed [DATA_WIDTH-1:0] a_in,
    input  logic signed [DATA_WIDTH-1:0] b_in,

    output logic signed [DATA_WIDTH-1:0] a_out,
    output logic signed [DATA_WIDTH-1:0] b_out,
    output logic signed [ACC_WIDTH-1:0]  acc,
    output logic                         valid_out
);

    localparam int PRODUCT_WIDTH = 2 * DATA_WIDTH;

    logic signed [PRODUCT_WIDTH-1:0] product;
    logic signed [ACC_WIDTH-1:0] product_ext;

    initial begin
        if (DATA_WIDTH < 1)
            $fatal(1, "DATA_WIDTH must be at least 1");

        if (ACC_WIDTH < PRODUCT_WIDTH)
            $fatal(1, "ACC_WIDTH must be >= 2*DATA_WIDTH");
    end

    assign product = a_in * b_in;

    assign product_ext = {
        {(ACC_WIDTH - PRODUCT_WIDTH){product[PRODUCT_WIDTH-1]}},
        product
    };

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_out     <= '0;
            b_out     <= '0;
            acc       <= '0;
            valid_out <= 1'b0;
        end else if (enable) begin
            a_out     <= a_in;
            b_out     <= b_in;
            valid_out <= valid_in;

            if (clear_acc)
                acc <= '0;
            else if (valid_in)
                acc <= acc + product_ext;
        end
    end

endmodule
