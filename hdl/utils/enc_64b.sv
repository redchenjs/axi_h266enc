/*
 * enc_64b.sv
 *
 *  Created on: 2022-10-09 16:42
 *      Author: Jack Chen <redchenjs@live.com>
 */

`timescale 1 ns / 1 ps

module enc_64b(
    input logic clk_i,
    input logic rst_n_i,

    input  logic init_i,
    output logic done_o,

    input  logic [63:0] data_i,
    output logic  [5:0] data_o
);

logic       [7:0] enc_8b_or;
logic       [2:0] enc_8b_msb;
logic [7:0] [2:0] enc_8b_lsb;

logic [5:0] data_r;

generate
    for (genvar i = 0; i < 8; i++) begin
        assign enc_8b_or[i] = |data_i[i * 8 + 7 : i * 8];

        enc_8b enc_8b_lsb_enc(
            .rst_n_i(init_i),

            .data_i(data_i[i * 8 + 7 : i * 8]),
            .data_o(enc_8b_lsb[i])
        );
    end
endgenerate

enc_8b enc_8b_msb_enc(
    .rst_n_i(init_i),

    .data_i(enc_8b_or),
    .data_o(enc_8b_msb)
);

assign data_r = {enc_8b_msb, enc_8b_lsb[enc_8b_msb]};

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
