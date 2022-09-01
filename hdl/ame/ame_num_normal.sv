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

    input logic [COMP_DATA_BITS-1:0] num_approx_i,
    input logic                      num_approx_sign_i,

    // 64-bit Integer Input & Output
    input  logic [COMP_DATA_BITS-1:0] comp_data_i,
    output logic [COMP_DATA_BITS-1:0] comp_data_o
);

logic                      [COMP_DATA_BITS-1:0] comp_data;
logic [COMP_DATA_BITS-1:0] [COMP_DATA_BITS-1:0] comp_data_mux;

always_comb begin
    comp_data_mux[0] = comp_data_i;

    for (int i = 1; i < COMP_DATA_BITS; i++) begin
        for (int j = 0; j < i; j++) begin
            comp_data_mux[i][COMP_DATA_BITS - j - 1] = 1'b0;
        end

        for (int j = i; j < COMP_DATA_BITS; j++) begin
            comp_data_mux[i][j - i] = comp_data_i[j];
        end
    end

    for (int i = 0; i < COMP_DATA_BITS; i++) begin
        if (num_approx_i[i]) begin
            comp_data = comp_data_mux[i];
        end
    end

    if (~|num_approx_i) begin
        comp_data = 'b0;
    end

    comp_data = num_approx_sign_i ? -comp_data : comp_data;
end

always_ff @(posedge clk_i or negedge rst_n_i)
begin
    if (!rst_n_i) begin
        comp_done_o <= 'b0;
        comp_data_o <= 'b0;
    end else begin
        comp_done_o <= comp_init_i;
        comp_data_o <= comp_init_i ? comp_data : 'b0;
    end
end

endmodule
