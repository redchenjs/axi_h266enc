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

logic [COMP_DATA_BITS-1:0] comp_data_t;

wire [COMP_DATA_BITS-1:0] comp_data_a = comp_data_i[COMP_DATA_BITS-1] ? -comp_data_i : comp_data_i;
wire [COMP_DATA_BITS-1:0] comp_data_b = comp_data_i[COMP_DATA_BITS-1] ? -comp_data_t : comp_data_t;

sra_64b #(
    .OUT_REG(1'b0)
) sra_64b (
    .clk_i(),
    .rst_n_i(),

    .init_i(comp_init_i),
    .done_o(),

    .arith_i(1'b1),
    .shift_i(comp_shift_i),

    .data_i(comp_data_a),
    .data_o(comp_data_t)
);

always_ff @(posedge clk_i or negedge rst_n_i)
begin
    if (!rst_n_i) begin
        comp_done_o <= 'b0;
        comp_data_o <= 'b0;
    end else begin
        comp_done_o <= comp_init_i;
        comp_data_o <= comp_init_i ? comp_data_b : comp_data_i;
    end
end

endmodule
