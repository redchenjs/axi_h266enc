/*
 * test_data_syn.sv
 *
 *  Created on: 2021-06-09 16:40
 *      Author: Jack Chen <redchenjs@live.com>
 */

`timescale 1ns / 1ps

module test_data_syn;

logic clk_i;
logic rst_n_i;

logic data_i;

logic data_o;

data_syn data_syn(
    .clk_i(clk_i),
    .rst_n_i(rst_n_i),

    .data_i(data_i),

    .data_o(data_o)
);

initial begin
    clk_i   <= 1'b1;
    rst_n_i <= 1'b0;

    data_i <= 1'b0;

    #2 rst_n_i <= 1'b1;
end

always begin
    #2.5 clk_i <= ~clk_i;
end

always begin
    #3 data_i <= ~data_i;

    #100 rst_n_i <= 1'b1;
    #25 $stop;
end

endmodule
