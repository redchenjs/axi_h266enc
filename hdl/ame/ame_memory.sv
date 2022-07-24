/*
 * ame_memory.sv
 *
 *  Created on: 2022-07-24 13:40
 *      Author: Jack Chen <redchenjs@live.com>
 */

`timescale 1 ns / 1 ps

module ame_memory #(
    parameter DATA_RDREG = 1,
    parameter DATA_WIDTH = 16 * 8,
    parameter DATA_DEPTH = 512
) (
    input logic clk_i,
    input logic rst_n_i,

    input logic                          wr_en_i,
    input logic [$clog2(DATA_WIDTH)-1:0] wr_addr_i,
    input logic [DATA_WIDTH/8-1:0] [7:0] wr_data_i,
    input logic       [DATA_WIDTH/8-1:0] wr_byte_en_i,

    input  logic                          rd_en_i,
    input  logic [$clog2(DATA_WIDTH)-1:0] rd_addr_i,
    output logic [DATA_WIDTH/8-1:0] [7:0] rd_data_o
);

logic [DATA_WIDTH/8-1:0] [DATA_DEPTH-1:0] [7:0] memory;

generate
    for (genvar k = 0; k < DATA_WIDTH / 8; k++) begin
        always_ff @(posedge clk_i)
        begin
            if (wr_en_i & wr_byte_en_i[k]) begin
                memory[k][wr_addr_i] <= wr_data_i[k];
            end
        end
    end
endgenerate

if (!DATA_RDREG) begin
    assign rd_data_o = memory[rd_addr_i];
end else begin
    always_ff @(posedge clk_i)
    begin
        if (rd_en_i) begin
            rd_data_o <= memory[rd_addr_i];
        end
    end
end

endmodule
