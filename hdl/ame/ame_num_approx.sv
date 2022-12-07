/*
 * ame_num_approx.sv
 *
 *  Created on: 2022-08-18 16:40
 *      Author: Jack Chen <redchenjs@live.com>
 */

`timescale 1 ns / 1 ps

module ame_num_approx #(
    parameter COMP_DATA_BITS = 64
) (
    input logic clk_i,
    input logic rst_n_i,

    input  logic comp_init_i,
    output logic comp_done_o,

    // 64-bit Integer Input & 6-bit Integer Output
    input  logic         [COMP_DATA_BITS-1:0] comp_data_i,
    output logic [$clog2(COMP_DATA_BITS)-1:0] comp_data_o
);

logic [COMP_DATA_BITS-1:0] comp_data_u;
logic [COMP_DATA_BITS-1:0] comp_data_p;

assign comp_data_u = comp_data_i[COMP_DATA_BITS-1] ? -comp_data_i : comp_data_i;

pri_64b #(
    .OUT_REG(1'b0)
) pri_64b (
    .clk_i(clk_i),
    .rst_n_i(rst_n_i),

    .init_i(comp_init_i),
    .done_o(),

    .data_i(comp_data_u),
    .data_o(comp_data_p)
);

enc_64b #(
    .OUT_REG(1'b1)
) enc_64b (
    .clk_i(clk_i),
    .rst_n_i(rst_n_i),

    .init_i(comp_init_i),
    .done_o(),

    .data_i(comp_data_p),
    .data_o(comp_data_o)
);

endmodule
