/*
 * ame_num_approx.sv
 *
 *  Created on: 2022-08-18 16:40
 *      Author: Jack Chen <redchenjs@live.com>
 */

`timescale 1 ns / 1 ps

module ame_num_approx #(
    parameter COMP_DATA_BITS = 64
) (
    input logic clk_i,
    input logic rst_n_i,

    input  logic comp_init_i,
    output logic comp_done_o,

    // 64-bit Integer Input & Output
    input  logic [COMP_DATA_BITS-1:0] comp_data_i,
    output logic [COMP_DATA_BITS-1:0] comp_data_o,

    // Data MSB Sign
    output logic comp_data_sign_o
);

logic [7:0] pri_8b_or;
logic [7:0] pri_8b_ci;
logic [7:0] pri_8b_ep;

logic [COMP_DATA_BITS-1:0] comp_data;
logic [COMP_DATA_BITS-1:0] comp_data_u;

assign comp_data_u = comp_data_i[COMP_DATA_BITS-1] ? -comp_data_i : comp_data_i;

generate
    for (genvar i = 0; i < COMP_DATA_BITS / 8; i++) begin: pri_8b_or_block
        assign pri_8b_or[i] = |comp_data_u[i * 8 + 7 : i * 8];
    end

    assign pri_8b_ci[0] = 1'b0;

    for (genvar i = 0; i < COMP_DATA_BITS / 8 - 1; i++) begin: pri_8b_ci_block
        assign pri_8b_ci[i + 1] = &comp_data_u[i * 8 + 7 : i * 8 + 6];
    end
endgenerate

pri_8b pri_8b_la(
    .rst_n_i(comp_init_i),

    .data_i(pri_8b_or),
    .data_o(pri_8b_ep)
);

generate
    for (genvar i = 0; i < COMP_DATA_BITS / 8; i++) begin: pri_8b_ep_block
        ame_pri_8b ame_pri_8b_ep_i(
            .rst_n_i(pri_8b_ep[i]),

            .carry_i(pri_8b_ci[i]),
            .carry_o(),

            .data_i(comp_data_u[i * 8 + 7 : i * 8]),
            .data_o(comp_data[i * 8 + 7 : i * 8])
        );
    end
endgenerate

always_ff @(posedge clk_i or negedge rst_n_i)
begin
    if (!rst_n_i) begin
        comp_done_o <= 'b0;
        comp_data_o <= 'b0;

        comp_data_sign_o <= 'b0;
    end else begin
        comp_done_o <= comp_init_i;
        comp_data_o <= comp_init_i ? comp_data : 'b0;

        comp_data_sign_o <= comp_init_i ? comp_data_i[COMP_DATA_BITS-1] : 'b0;
    end
end

endmodule
