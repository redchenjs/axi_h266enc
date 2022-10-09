/*
 * test_ame_num_compare.sv
 *
 *  Created on: 2022-09-15 18:10
 *      Author: Jack Chen <redchenjs@live.com>
 */

`timescale 1 ns / 1 ps

module test_ame_num_compare;

parameter COMP_DATA_BITS = 64;
parameter COMP_DATA_IDX_BITS = 3;

logic clk_i;
logic rst_n_i;

logic comp_init_i;
logic comp_done_o;

// 5 Integer Input
logic [5:0] [COMP_DATA_BITS-1:0] comp_data_i;

// 1 Data & 1 Index Output
logic     [COMP_DATA_BITS-1:0] comp_data_o;
logic [COMP_DATA_IDX_BITS-1:0] comp_data_idx_o;

ame_num_compare #(
    .COMP_DATA_BITS(COMP_DATA_BITS),
    .COMP_DATA_IDX_BITS(COMP_DATA_IDX_BITS)
) ame_num_compare (
    .clk_i(clk_i),
    .rst_n_i(rst_n_i),

    .comp_init_i(comp_init_i),
    .comp_done_o(comp_done_o),

    .comp_data_i(comp_data_i),
    .comp_data_o(comp_data_o),

    .comp_data_idx_o(comp_data_idx_o)
);

initial begin
    $dumpfile("test_ame_num_compare.vcd");
    $dumpvars(0, test_ame_num_compare);

    clk_i   = 1'b0;
    rst_n_i = 1'b0;

    comp_init_i = 'b0;
    comp_data_i = 'b0;

    #2 rst_n_i = 1'b1;
end

always begin
    #2.5 clk_i = ~clk_i;
end

always begin
    #5 comp_init_i = 1'b1;

    // DUMMY DATA
    for (integer i = 0; i < 64; i++) begin
        #5 comp_data_i  = { $random, $random, $random, $random,
                            $random, $random, $random, $random,
                            $random, $random, $random, $random };
    end

    #5 comp_init_i = 1'b0;

    #75 rst_n_i = 1'b0;
    #25 $finish;
end

endmodule
