/*
 * ame_num_divide.sv
 *
 *  Created on: 2022-09-18 01:11
 *      Author: Jack Chen <redchenjs@live.com>
 */

`timescale 1 ns / 1 ps

module ame_num_divide #(
    parameter COMP_DATA_BITS = 64
) (
    input logic clk_i,
    input logic rst_n_i,

    input  logic comp_init_i,
    output logic comp_done_o,

    // 2 Integer Input: [1:0] => {divisor, dividend}
    input  logic [1:0] [COMP_DATA_BITS-1:0] comp_data_i,
    output logic       [COMP_DATA_BITS-1:0] comp_data_o
);

div_64b div_64b(
    .clk_i(clk_i),
    .rst_n_i(rst_n_i),

    .init_i(comp_init_i),
    .done_o(comp_done_o),

    .dividend_i(comp_data_i[0]),
    .divisor_i(comp_data_i[1]),

    .quotient_o(comp_data_o),
    .remainder_o()
);

endmodule
