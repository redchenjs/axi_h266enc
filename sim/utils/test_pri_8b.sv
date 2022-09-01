/*
 * test_pri_8b.sv
 *
 *  Created on: 2022-08-31 23:39
 *      Author: Jack Chen <redchenjs@live.com>
 */

`timescale 1ns / 1ps

module test_pri_8b;

logic rst_n_i;

logic [7:0] data_i;
logic [7:0] data_o;

pri_8b pri_8b(
    .rst_n_i(rst_n_i),

    .data_i(data_i),
    .data_o(data_o)
);

initial begin
    rst_n_i <= 1'b0;

    #2 rst_n_i <= 1'b1;
end

always begin
    data_i <= 8'h00;

    #12 data_i <= 8'h7a;
    #12 data_i <= 8'h4f;
    #12 data_i <= 8'hcd;
    #12 data_i <= 8'haa;
    #12 data_i <= 8'h0a;
    #12 data_i <= 8'h1f;
    #12 data_i <= 8'h3d;
    #12 data_i <= 8'hff;

    #25 rst_n_i <= 1'b0;
    #25 $finish;
end

endmodule
