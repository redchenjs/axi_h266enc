/*
 * ame_num_compute.sv
 *
 *  Created on: 2022-09-09 11:21
 *      Author: Jack Chen <redchenjs@live.com>
 */

`timescale 1 ns / 1 ps

module ame_num_compute #(
    parameter COMP_DATA_BITS = 64
) (
    input logic clk_i,
    input logic rst_n_i,

    input  logic comp_init_i,
    output logic comp_done_o,

    // 4 Integer Input: [3:0] => {M, D, L, C}
    input  logic [3:0] [COMP_DATA_BITS-1:0] comp_data_i,
    output logic       [COMP_DATA_BITS-1:0] comp_data_o
);

wire [COMP_DATA_BITS-1:0] M = comp_data_i[3];
wire [COMP_DATA_BITS-1:0] D = comp_data_i[2];
wire [COMP_DATA_BITS-1:0] L = comp_data_i[1];
wire [COMP_DATA_BITS-1:0] C = comp_data_i[0];

assign comp_data_o = comp_init_i ? (M * D - L * C) : comp_data_i[2];;

endmodule
