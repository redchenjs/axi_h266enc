/*
 * test_ame_pri_8b.sv
 *
 *  Created on: 2022-09-01 16:17
 *      Author: Jack Chen <redchenjs@live.com>
 */

`timescale 1ns / 1ps

module test_ame_pri_8b;

logic rst_n_i;

logic carry_i;
logic carry_o;

logic [7:0] data_i;
logic [7:0] data_o;

ame_pri_8b ame_pri_8b(
    .rst_n_i(rst_n_i),

    .carry_i(carry_i),
    .carry_o(carry_o),

    .data_i(data_i),
    .data_o(data_o)
);

initial begin
    rst_n_i = 1'b0;

    #2 rst_n_i = 1'b1;
end

always begin
    data_i = 8'h00;

    carry_i = 1'b1;

    #12 data_i = 8'h17;
    #12 data_i = 8'h37;
    #12 data_i = 8'hcd;
    #12 data_i = 8'haa;
    #12 data_i = 8'h0a;
    #12 data_i = 8'h1f;
    #12 data_i = 8'h3d;
    #12 data_i = 8'hff;

    carry_i = 1'b0;

    #12 data_i = 8'h17;
    #12 data_i = 8'h37;
    #12 data_i = 8'hcd;
    #12 data_i = 8'haa;
    #12 data_i = 8'h0a;
    #12 data_i = 8'h1f;
    #12 data_i = 8'h3d;
    #12 data_i = 8'hff;

    #25 rst_n_i = 1'b0;
    #25 $finish;
end

endmodule
