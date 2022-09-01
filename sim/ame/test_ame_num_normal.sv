/*
 * test_ame_num_normal.sv
 *
 *  Created on: 2022-09-01 10:33
 *      Author: Jack Chen <redchenjs@live.com>
 */

`timescale 1 ns / 1 ps

module test_ame_num_normal;

parameter COMP_DATA_BITS = 64;

logic clk_i;
logic rst_n_i;

logic comp_init_i;
logic comp_done_o;

logic [COMP_DATA_BITS-1:0] num_approx_i;
logic                      num_approx_sign_i;

// 64-bit Integer Input & Output
logic [COMP_DATA_BITS-1:0] comp_data_i;
logic [COMP_DATA_BITS-1:0] comp_data_o;

ame_num_normal #(
    .COMP_DATA_BITS(COMP_DATA_BITS)
) ame_num_normal (
    .clk_i(clk_i),
    .rst_n_i(rst_n_i),

    .comp_init_i(comp_init_i),
    .comp_done_o(comp_done_o),

    .num_approx_i(num_approx_i),
    .num_approx_sign_i(num_approx_sign_i),

    .comp_data_i(comp_data_i),
    .comp_data_o(comp_data_o)
);

initial begin
    $dumpfile("test_ame_num_normal.vcd");
    $dumpvars(0, test_ame_num_normal);

    clk_i   = 1'b0;
    rst_n_i = 1'b0;

    comp_init_i = 'b0;
    comp_data_i = 'b0;

    num_approx_i = 'b0;

    #2 rst_n_i = 1'b1;
end

always begin
    #2.5 clk_i = ~clk_i;
end

always begin
    #5 comp_init_i = 1'b1;

    // DUMMY DATA
    for (integer i = 0; i < 64; i++) begin
        #5 comp_data_i  = {$random, $random};

           num_approx_i      = 1'b1 << i;
           num_approx_sign_i = i % 2;
    end

    #5 comp_init_i = 1'b0;

    #75 rst_n_i = 1'b0;
    #25 $finish;
end

endmodule
