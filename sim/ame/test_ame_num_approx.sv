/*
 * test_ame_num_approx.sv
 *
 *  Created on: 2022-09-01 10:33
 *      Author: Jack Chen <redchenjs@live.com>
 */

`timescale 1 ns / 1 ps

module test_ame_num_approx;

parameter COMP_DATA_BITS = 64;

logic clk_i;
logic rst_n_i;

logic comp_init_i;
logic comp_done_o;

// 64-bit Integer Input & Output
logic [COMP_DATA_BITS-1:0] comp_data_i;
logic [COMP_DATA_BITS-1:0] comp_data_o;

// Data MSB Sign
logic comp_data_sign_o;

ame_num_approx #(
    .COMP_DATA_BITS(COMP_DATA_BITS)
) ame_num_approx (
    .clk_i(clk_i),
    .rst_n_i(rst_n_i),

    .comp_init_i(comp_init_i),
    .comp_done_o(comp_done_o),

    .comp_data_i(comp_data_i),
    .comp_data_o(comp_data_o),

    .comp_data_sign_o(comp_data_sign_o)
);

initial begin
    $dumpfile("test_ame_num_approx.vcd");
    $dumpvars(0, test_ame_num_approx);

    clk_i   <= 1'b0;
    rst_n_i <= 1'b0;

    comp_init_i <= 'b0;
    comp_data_i <= 'b0;

    #2 rst_n_i <= 1'b1;
end

always begin
    #2.5 clk_i <= ~clk_i;
end

always begin
    #5 comp_init_i <= 1'b1;

    // DUMMY DATA
    for (integer i = 0; i < 64; i++) begin
        #5 comp_data_i <= {$random, $random};
        #5 comp_data_i <= {$random};
    end

    #5 comp_init_i <= 1'b0;

    #75 rst_n_i <= 1'b0;
    #25 $finish;
end

endmodule