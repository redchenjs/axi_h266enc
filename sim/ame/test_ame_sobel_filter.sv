/*
 * test_ame_sobel_filter.sv
 *
 *  Created on: 2022-07-17 16:50
 *      Author: Jack Chen <redchenjs@live.com>
 */

`timescale 1 ns / 1 ps

module test_ame_sobel_filter;

parameter LINE_DATA_BITS = 7;
parameter COMP_DATA_BITS = 8;

logic clk_i;
logic rst_n_i;

logic comp_init_i;
logic comp_done_o;

// 6 Pixel Buffer Input
// Horizontal Sobel Filter: Use Veritcal Memory
// Vertical Sobel Filter: Use Horizontal Memory
logic [5:0] [LINE_DATA_BITS-1:0] line_data_i;

// 4 x 4 = 16 Results
logic [3:0] [3:0] [COMP_DATA_BITS-1:0] comp_data_o;

ame_sobel_filter #(
    .LINE_DATA_BITS(LINE_DATA_BITS),
    .COMP_DATA_BITS(COMP_DATA_BITS)
) ame_sobel_filter (
    .clk_i(clk_i),
    .rst_n_i(rst_n_i),

    .comp_init_i(comp_init_i),
    .comp_done_o(comp_done_o),

    .line_data_i(line_data_i),

    .comp_data_o(comp_data_o)
);

initial begin
    $dumpfile("test_ame_sobel_filter.vcd");
    $dumpvars(0, test_ame_sobel_filter);

    clk_i   <= 1'b1;
    rst_n_i <= 1'b0;

    comp_init_i <= 'b0;
    line_data_i <= 'b0;

    #2 rst_n_i <= 1'b1;
end

always begin
    #2.5 clk_i <= ~clk_i;
end

always begin
    // DUMMY DATA
    for (integer i = 0; i < 8; i++) begin
        #5 comp_init_i <= 1'b1;
           line_data_i <= {$random, $random};

        #5 comp_init_i <= 1'b0;
           line_data_i <= {$random, $random};

        for (integer j = 0; j < 4; j++) begin
            #5 line_data_i <= {$random, $random};
        end
    end

    #75 rst_n_i <= 1'b0;
    #25 $stop;
end

endmodule
