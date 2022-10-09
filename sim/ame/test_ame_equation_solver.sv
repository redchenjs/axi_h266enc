/*
 * test_ame_equation_solver
 *
 *  Created on: 2022-09-17 23:33
 *      Author: Jack Chen <redchenjs@live.com>
 */

`timescale 1 ns / 1 ps

module test_ame_equation_solver;

parameter COMP_DATA_BITS = 64;
parameter COMP_DATA_IDX_BITS = 3;

logic clk_i;
logic rst_n_i;

logic comp_init_i;
logic comp_done_o;

logic affine_param6_i;

// 4 x 5 Integer Input              // 6 x 7 Integer Input
// --- --- --- --- --- --- | --     // --- --- --- --- --- --- | --
// --- --- --- --- --- --- | --     // A00 A01 A02 A03 A04 A05 | B0
// --- --- --- --- --- --- | --     // A10 A11 A12 A13 A14 A15 | B1
// --- --- A22 A23 A24 A25 | B2     // A20 A21 A22 A23 A24 A25 | B2
// --- --- A32 A33 A34 A35 | B3     // A30 A31 A32 A33 A34 A35 | B3
// --- --- A42 A43 A44 A45 | B4     // A40 A41 A42 A43 A44 A45 | B4
// --- --- A52 A53 A54 A55 | B5     // A50 A51 A52 A53 A54 A55 | B5
// --- --- --- --- --- --- | --     // --- --- --- --- --- --- | --
logic [5:0] [6:0] [COMP_DATA_BITS-1:0] comp_data_i;

// 4 Fixed Point Results            // 6 Fixed Point Results
// --- --- --- --- --- --- | --     // --- --- --- --- --- --- | --
//  --  --  X2  X3  X4  X5 | --     //  X0  X1  X2  X3  X4  X5 | --
// --- --- --- --- --- --- | --     // --- --- --- --- --- --- | --
logic [5:0] [COMP_DATA_BITS-1:0] comp_data_o;

ame_equation_solver #(
    .COMP_DATA_BITS(COMP_DATA_BITS),
    .COMP_DATA_IDX_BITS(COMP_DATA_IDX_BITS)
) ame_equation_solver (
    .clk_i(clk_i),
    .rst_n_i(rst_n_i),

    .comp_init_i(comp_init_i),
    .comp_done_o(comp_done_o),

    .affine_param6_i(affine_param6_i),

    .comp_data_i(comp_data_i),
    .comp_data_o(comp_data_o)
);

initial begin
    $dumpfile("test_ame_equation_solver.vcd");
    $dumpvars(0, test_ame_equation_solver);

    clk_i   = 1'b0;
    rst_n_i = 1'b0;

    comp_init_i = 'b0;
    comp_data_i = 'b0;

    affine_param6_i = 'b0;

    #2 rst_n_i = 1'b1;
end

always begin
    #2.5 clk_i = ~clk_i;
end

always begin
    #5 comp_data_i = {
        {-64'd1, -64'd1,  64'd1,  64'd2,  64'd3,  64'd0,  64'd0 },
        { 64'd1, -64'd2, -64'd4, -64'd1,  64'd0,  64'd0,  64'd0 },
        { 64'd0,  64'd1,  64'd1,  64'd1,  64'd1,  64'd0,  64'd0 },
        { 64'd1,  64'd2,  64'd2,  64'd1,  64'd0,  64'd0,  64'd0 },
        { 64'd0,  64'd0,  64'd0,  64'd0,  64'd0,  64'd0,  64'd0 },
        { 64'd0,  64'd0,  64'd0,  64'd0,  64'd0,  64'd0,  64'd0 }
    };

    #5 comp_init_i = 1'b1;

    #1000 comp_init_i = 1'b0;

    #75 rst_n_i = 1'b0;
    #25 $finish;
end

endmodule