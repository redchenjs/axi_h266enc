/*
 * ame_num_compare.sv
 *
 *  Created on: 2022-09-07 15:54
 *      Author: Jack Chen <redchenjs@live.com>
 */

`timescale 1 ns / 1 ps

module ame_num_compare #(
    parameter COMP_DATA_BITS = 64,
    parameter COMP_DATA_IDX_BITS = 3
) (
    input logic clk_i,
    input logic rst_n_i,

    input  logic comp_init_i,
    output logic comp_done_o,

    // 5 Integer Input & 1 Data Output
    input  logic [5:0] [COMP_DATA_BITS-1:0] comp_data_i,
    output logic       [COMP_DATA_BITS-1:0] comp_data_o,

    // Data Mask Input: Mask Bits
    input logic [5:0] comp_data_mask_i,

    // Data Index Output: Row Index
    output logic [COMP_DATA_IDX_BITS-1:0] comp_data_index_o
);

wire [5:0] [47:0] comp_data_t;

generate
    for (genvar i = 0; i < 6; i++) begin
        assign comp_data_t[i] = comp_data_mask_i[i] ? 'b0 : (comp_data_i[i][47] ? -comp_data_i[i][47:0] : comp_data_i[i][47:0]);
    end
endgenerate

wire MAX_0_1 = (comp_data_t[0] > comp_data_t[1]);
wire MAX_2_3 = (comp_data_t[2] > comp_data_t[3]);
wire MAX_4_5 = (comp_data_t[4] > comp_data_t[5]);

wire [47:0] D_MAX_0_1 = MAX_0_1 ? comp_data_t[0] : comp_data_t[1];
wire [47:0] D_MAX_2_3 = MAX_2_3 ? comp_data_t[2] : comp_data_t[3];
wire [47:0] D_MAX_4_5 = MAX_4_5 ? comp_data_t[4] : comp_data_t[5];

wire        MAX_A = (D_MAX_0_1 > D_MAX_2_3);
wire [47:0] D_MAX_A = MAX_A ? D_MAX_0_1 : D_MAX_2_3;

wire        MAX_B = (D_MAX_A > D_MAX_4_5);
wire [47:0] D_MAX_B = MAX_B ? D_MAX_A : D_MAX_4_5;

wire [COMP_DATA_IDX_BITS-1:0] I_MAX_0_1 = MAX_0_1 ? 'd0 : 'd1;
wire [COMP_DATA_IDX_BITS-1:0] I_MAX_2_3 = MAX_2_3 ? 'd2 : 'd3;
wire [COMP_DATA_IDX_BITS-1:0] I_MAX_4_5 = MAX_4_5 ? 'd4 : 'd5;

wire [COMP_DATA_IDX_BITS-1:0] I_MAX_A = MAX_A ? I_MAX_0_1 : I_MAX_2_3;
wire [COMP_DATA_IDX_BITS-1:0] I_MAX_B = MAX_B ? I_MAX_A   : I_MAX_4_5;

assign comp_done_o       = comp_init_i;
assign comp_data_o       = comp_data_i[I_MAX_B];
assign comp_data_index_o = I_MAX_B;

endmodule
