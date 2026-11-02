
`timescale 1ns/1ps

module mac_unit #(
    parameter int DATA_WIDTH = 8,
    parameter int ACC_WIDTH  = 32
) (
    input  logic                         clk,
    input  logic                         rst_n,
    input  logic                         enable,
    input  logic signed [DATA_WIDTH-1:0] a,
    input  logic signed [DATA_WIDTH-1:0] b,
    output logic signed [ACC_WIDTH-1:0]  acc
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

    assign product = a * b;

    assign product_ext = {
        {(ACC_WIDTH - PRODUCT_WIDTH){product[PRODUCT_WIDTH-1]}},
        product
    };

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            acc <= '0;
        else if (enable)
            acc <= acc + product_ext;
    end

endmodule
