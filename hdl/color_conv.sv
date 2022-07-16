/*
 * color_conv.sv
 *
 *  Created on: 2022-04-04 11:05
 *      Author: Jack Chen <redchenjs@live.com>
 */

`timescale 1 ns / 1 ps

module color_conv(
    input logic clk_i,
    input logic rst_n_i,

    input logic color_conv_en_i,

    input logic [23:0] color_data_i,
    input logic        color_data_vld_i,

    output logic [23:0] color_data_o,
    output logic        color_data_vld_o
);

// RGB => YUV
// Y = 0.299 R + 0.587 G + 0.114 B
// U = -0.1687 R - 0.3313 G + 0.5 B + 128
// V = 0.5 R - 0.4187 G - 0.0813 B + 128

// YUV => RGB
// R = Y + 1.402 (V - 128)
// G = Y - 0.34414 (U - 128) - 0.71414 (V - 128)
// B = Y + 1.772 (U - 128)

logic [15:0] color_data_y;
logic        color_data_vld;

wire [7:0] color_data_r = color_data_i[23:16];
wire [7:0] color_data_g = color_data_i[15:8];
wire [7:0] color_data_b = color_data_i[7:0];

assign color_data_o     = color_conv_en_i ? {3{color_data_y[15:8]}} : color_data_i;
assign color_data_vld_o = color_conv_en_i ? color_data_vld : color_data_vld_i;

always_ff @(posedge clk_i or negedge rst_n_i)
begin
    if (!rst_n_i) begin
        color_data_y   <= 16'h0000;
        color_data_vld <= 1'b0;
    end else begin
        color_data_y   <= color_data_vld_i ? color_data_r * 77 + color_data_g * 150 + color_data_b * 29 : color_data_y;
        color_data_vld <= color_data_vld_i;
    end
end

endmodule
