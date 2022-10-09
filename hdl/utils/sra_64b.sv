/*
 * sra_64b.sv
 *
 *  Created on: 2022-10-09 16:05
 *      Author: Jack Chen <redchenjs@live.com>
 */

`timescale 1 ns / 1 ps

module sra_64b(
    input logic clk_i,
    input logic rst_n_i,

    input  logic init_i,
    output logic done_o,

    input  logic       arith_i,
    input logic [63:0] shift_i,

    input  logic [63:0] data_i,
    output logic [63:0] data_o
);

logic        [63:0] data_r;
logic [63:1] [63:0] data_mux;

always_comb begin
    for (int i = 1; i < 64; i++) begin
        for (int j = 0; j < i; j++) begin
            data_mux[i][63 - j] = arith_i & data_i[63];
        end

        for (int j = i; j < 64; j++) begin
            data_mux[i][j - i] = data_i[j];
        end
    end

    for (int i = 0; i < 64; i++) begin
        if (shift_i[i]) begin
            data_r = data_mux[i];
        end
    end

    if (~|shift_i) begin
        data_r = data_i;
    end
end

always_ff @(posedge clk_i or negedge rst_n_i)
begin
    if (!rst_n_i) begin
        done_o <= 'b0;
        data_o <= 'b0;
    end else begin
        done_o <= init_i;
        data_o <= init_i ? data_r : 'b0;
    end
end

endmodule
