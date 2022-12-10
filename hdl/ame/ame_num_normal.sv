/*
 * ame_num_normal.sv
 *
 *  Created on: 2022-08-18 16:40
 *      Author: Jack Chen <redchenjs@live.com>
 */

`timescale 1 ns / 1 ps

module ame_num_normal #(
    parameter COMP_DATA_BITS = 64
) (
    input logic clk_i,
    input logic rst_n_i,

    input  logic comp_init_i,
    output logic comp_done_o,

    input logic [$clog2(COMP_DATA_BITS)-1:0] comp_shift_i,

    // 64-bit Integer Input & Output
    input  logic [COMP_DATA_BITS-1:0] comp_data_i,
    output logic [COMP_DATA_BITS-1:0] comp_data_o
);

sra_64b #(
    .OUT_REG(1'b0)
) sra_64b (
    .clk_i(clk_i),
    .rst_n_i(rst_n_i),

    .init_i(comp_init_i),
    .done_o(comp_done_o),

    .arith_i(1'b1),
    .shift_i(comp_shift_i),

    .data_i(comp_data_i),
    .data_o(comp_data_o)
);

endmodule
