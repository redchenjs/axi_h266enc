/*
 * ame_line_buffer.sv
 *
 *  Created on: 2022-07-16 22:07
 *      Author: Jack Chen <redchenjs@live.com>
 */

`timescale 1 ns / 1 ps

module ame_line_buffer #(
    parameter DATA_WIDTH = 16 * 8,
    parameter DATA_DEPTH = 512
) (
    input logic clk_i,
    input logic rst_n_i,

    input logic                          wr_h_en_i,
    input logic [$clog2(DATA_WIDTH)-1:0] wr_h_addr_i,
    input logic   [DATA_WIDTH-1:0] [7:0] wr_h_data_i,

    input  logic                          rd_h_en_i,
    input  logic [$clog2(DATA_WIDTH)-1:0] rd_h_addr_i,
    output logic   [DATA_WIDTH-1:0] [7:0] rd_h_data_o,

    input  logic                          rd_v_en_i,
    input  logic [$clog2(DATA_WIDTH)-1:0] rd_v_addr_i,
    output logic   [DATA_WIDTH-1:0] [7:0] rd_v_data_o
);

logic [DATA_DEPTH-1:0] [DATA_WIDTH-1:0] [7:0] rd_v_data;

ame_memory #(
    .DATA_RDREG(1),
    .DATA_WIDTH(DATA_WIDTH),
    .DATA_DEPTH(DATA_DEPTH)
) ame_memory_h (
    .clk_i(clk_i),
    .rst_n_i(rst_n_i),

    .wr_en_i(wr_h_en_i),
    .wr_addr_i(wr_h_addr_i),
    .wr_data_i(wr_h_data_i),
    .wr_byte_en_i({DATA_WIDTH/8{1'b1}}),

    .rd_en_i(rd_h_en_i),
    .rd_addr_i(rd_h_addr_i),
    .rd_data_o(rd_h_data_o)
);

assign rd_v_data_o = rd_v_data[rd_v_addr_i];

generate
    for (genvar k = 0; k < DATA_DEPTH; k++) begin
        ame_memory #(
            .DATA_RDREG(1),
            .DATA_WIDTH(DATA_WIDTH),
            .DATA_DEPTH(1)
        ) ame_memory_v_k (
            .clk_i(clk_i),
            .rst_n_i(rst_n_i),

            .wr_en_i(wr_h_en_i),
            .wr_addr_i(1),
            .wr_data_i(wr_h_data_i),
            .wr_byte_en_i(wr_h_addr_i),

            .rd_en_i(rd_v_en_i),
            .rd_addr_i(1),
            .rd_data_o(rd_v_data[k])
        );
    end
endgenerate

endmodule
