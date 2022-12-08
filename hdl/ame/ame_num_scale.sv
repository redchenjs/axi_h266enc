/*
 * ame_num_scale.sv
 *
 *  Created on: 2022-08-18 16:40
 *      Author: Jack Chen <redchenjs@live.com>
 */

`timescale 1 ns / 1 ps

module ame_num_scale #(
    parameter COMP_DATA_BITS = 64,
    parameter COMP_SCALE_BITS = 44
) (
    input logic clk_i,
    input logic rst_n_i,

    input  logic comp_init_i,
    output logic comp_done_o,

    output logic [$clog2(COMP_DATA_BITS)-1:0] comp_shift_o,

    // 4 Integer Input / Output: [3:0] => {M, D, L, C}
    input  logic [3:0] [COMP_DATA_BITS-1:0] comp_data_i,
    output logic [3:0] [COMP_DATA_BITS-1:0] comp_data_o
);

logic       [$clog2(COMP_DATA_BITS)-1:0] comp_shift;

logic [3:0]         [COMP_DATA_BITS-1:0] comp_data_u;
logic [3:0]         [COMP_DATA_BITS-1:0] comp_data_p;
logic [3:0] [$clog2(COMP_DATA_BITS)-1:0] comp_data_e;
logic [1:0]         [COMP_DATA_BITS-1:0] comp_data_s;
logic [3:0]         [COMP_DATA_BITS-1:0] comp_data_r;

wire [$clog2(COMP_DATA_BITS):0] MD_BITS = comp_data_e[3] + comp_data_e[2];
wire [$clog2(COMP_DATA_BITS):0] LC_BITS = comp_data_e[1] + comp_data_e[0];

wire MD_BITS_MAX = (MD_BITS >= LC_BITS);
wire MD_BITS_OVF = (MD_BITS > COMP_SCALE_BITS);
wire LC_BITS_OVF = (LC_BITS > COMP_SCALE_BITS);

wire [$clog2(COMP_DATA_BITS):0] MD_BITS_DIFF = (MD_BITS - COMP_SCALE_BITS);
wire [$clog2(COMP_DATA_BITS):0] LC_BITS_DIFF = (LC_BITS - COMP_SCALE_BITS);

assign comp_data_r[3] = comp_data_i[3][COMP_DATA_BITS-1] ? -comp_data_s[1] : comp_data_s[1];
assign comp_data_r[2] = comp_data_i[2];
assign comp_data_r[1] = comp_data_i[1][COMP_DATA_BITS-1] ? -comp_data_s[0] : comp_data_s[0];
assign comp_data_r[0] = comp_data_i[0];

generate
    for (genvar i = 0; i < 4; i++) begin
        assign comp_data_u[i] = comp_data_i[i][COMP_DATA_BITS-1] ? -comp_data_i[i] : comp_data_i[i];

        pri_64b #(
            .OUT_REG(1'b0)
        ) pri_64b (
            .clk_i(clk_i),
            .rst_n_i(rst_n_i),

            .init_i(1'b1),
            .done_o(),

            .data_i(comp_data_u[i]),
            .data_o(comp_data_p[i])
        );

        enc_64b #(
            .OUT_REG(1'b0)
        ) enc_64b (
            .clk_i(clk_i),
            .rst_n_i(rst_n_i),

            .init_i(1'b1),
            .done_o(),

            .data_i(comp_data_p[i]),
            .data_o(comp_data_e[i])
        );
    end
endgenerate

sra_64b #(
    .OUT_REG(1'b0)
) sra_64b_m (
    .clk_i(clk_i),
    .rst_n_i(rst_n_i),

    .init_i(1'b1),
    .done_o(),

    .arith_i(1'b0),
    .shift_i(comp_shift),

    .data_i(comp_data_u[3]),
    .data_o(comp_data_s[1])
);

sra_64b #(
    .OUT_REG(1'b0)
) sra_64b_l (
    .clk_i(clk_i),
    .rst_n_i(rst_n_i),

    .init_i(1'b1),
    .done_o(),

    .arith_i(1'b0),
    .shift_i(comp_shift),

    .data_i(comp_data_u[1]),
    .data_o(comp_data_s[0])
);

always_comb begin
    case ({MD_BITS_MAX, MD_BITS_OVF, LC_BITS_OVF}) inside
        3'b111, 3'b?10:
            comp_shift = MD_BITS_DIFF[$clog2(COMP_DATA_BITS)-1:0];
        3'b011, 3'b?01:
            comp_shift = LC_BITS_DIFF[$clog2(COMP_DATA_BITS)-1:0];
        default:
            comp_shift = 'b0;
    endcase
end

always_ff @(posedge clk_i) begin
    comp_data_o <= comp_data_r;
end

always_ff @(posedge clk_i or negedge rst_n_i)
begin
    if (!rst_n_i) begin
        comp_done_o  <= 'b0;
        comp_shift_o <= 'b0;
    end else begin
        comp_done_o  <= comp_init_i;
        comp_shift_o <= comp_shift;
    end
end

endmodule
