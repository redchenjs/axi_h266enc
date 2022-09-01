/*
 * ame_equation_solver.sv
 *
 *  Created on: 2022-08-18 16:25
 *      Author: Jack Chen <redchenjs@live.com>
 */

`timescale 1 ns / 1 ps

module ame_equation_solver #(
    parameter COMP_DATA_BITS = 64,
    parameter COMP_DATA_IDX_BITS = 3
) (
    input logic clk_i,
    input logic rst_n_i,

    input  logic comp_init_i,
    output logic comp_done_o,

    input logic affine_param6_i,

    // 4 x 5 Integer Input              // 6 x 7 Integer Input
    // --- --- --- --- --- --- | --     // --- --- --- --- --- --- | --
    // --- --- --- --- --- --- | --     // A00 A01 A02 A03 A04 A05 | B0
    // --- --- --- --- --- --- | --     // A10 A11 A12 A13 A14 A15 | B1
    // --- --- A22 A23 A24 A25 | B2     // A20 A21 A22 A23 A24 A25 | B2
    // --- --- A32 A33 A34 A35 | B3     // A30 A31 A32 A33 A34 A35 | B3
    // --- --- A42 A43 A44 A45 | B4     // A40 A41 A42 A43 A44 A45 | B4
    // --- --- A52 A53 A54 A55 | B5     // A50 A51 A52 A53 A54 A55 | B5
    // --- --- --- --- --- --- | --     // --- --- --- --- --- --- | --
    input logic [5:0] [6:0] [COMP_DATA_BITS-1:0] comp_data_i,

    // 4 Fixed Point Results            // 6 Fixed Point Results
    // --- --- --- --- --- --- | --     // --- --- --- --- --- --- | --
    //  --  --  X2  X3  X4  X5 | --     //  X0  X1  X2  X3  X4  X5 | --
    // --- --- --- --- --- --- | --     // --- --- --- --- --- --- | --
    output logic [5:0] [COMP_DATA_BITS-1:0] comp_data_o
);

typedef enum logic [2:0] {
    IDLE    = 'd0,
    PIVOT   = 'd1,
    COMPUTE = 'd2,
    NORMAL  = 'd3,
    DIVIDE  = 'd4
} state_t;

state_t ctl_sta;

logic [5:0] [6:0] comp_init;
logic       [2:0] comp_loop;
logic             comp_done;

logic     [COMP_DATA_BITS-1:0] comp_data_m;
logic [COMP_DATA_IDX_BITS-1:0] comp_data_m_index;
logic     [COMP_DATA_BITS-1:0] comp_data_m_approx;
logic                          comp_data_m_approx_sign;

logic [5:0] [6:0] [COMP_DATA_BITS-1:0] comp_data_compute;
logic [5:0] [6:0] [COMP_DATA_BITS-1:0] comp_data_normal;
logic       [5:0] [COMP_DATA_BITS-1:0] comp_data_divide;

ame_num_compare #(
    .COMP_DATA_BITS(64),
    .COMP_DATA_IDX_BITS(3)
) ame_num_compare (
    .clk_i(clk_i),
    .rst_n_i(rst_n_i),

    .comp_init_i('b1),
    .comp_done_o(),

    .comp_data_i({ comp_data_i[5][comp_loop],
                   comp_data_i[4][comp_loop],
                   comp_data_i[3][comp_loop],
                   comp_data_i[2][comp_loop],
                   comp_data_i[1][comp_loop],
                   comp_data_i[0][comp_loop] }),
    .comp_data_o(comp_data_m),

    .comp_data_idx_o(comp_data_m_index)
);

ame_num_approx #(
    .COMP_DATA_BITS(64)
) ame_num_approx (
    .clk_i(clk_i),
    .rst_n_i(rst_n_i),

    .comp_init_i('b1),
    .comp_done_o(),

    .comp_data_i(comp_data_m),
    .comp_data_o(comp_data_m_approx),

    .comp_data_sign_o(comp_data_m_approx_sign)
);

generate
    for (genvar i = 0; i < 6; i++) begin
        for (genvar j = 0; j < 7; j++) begin
            wire [COMP_DATA_BITS-1:0] M = comp_data_m;
            wire [COMP_DATA_BITS-1:0] D = comp_data_i[i][j];
            wire [COMP_DATA_BITS-1:0] L = comp_data_i[i][comp_loop];
            wire [COMP_DATA_BITS-1:0] C = comp_data_i[comp_data_m_index][j];

            ame_num_compute #(
                .COMP_DATA_BITS(64)
            ) ame_num_compute (
                .clk_i(clk_i),
                .rst_n_i(rst_n_i),

                .comp_init_i(comp_init[i][j]),
                .comp_done_o(),

                .comp_data_i({M, D, L, C}),
                .comp_data_o(comp_data_compute[i][j])
            );

            ame_num_normal #(
                .COMP_DATA_BITS(64)
            ) ame_num_normal (
                .clk_i(clk_i),
                .rst_n_i(rst_n_i),

                .comp_init_i(comp_init[i][j]),
                .comp_done_o(),

                .num_approx_i(comp_data_m_approx),
                .num_approx_sign_i(comp_data_m_approx_sign),

                .comp_data_i(comp_data_compute[i][j]),
                .comp_data_o(comp_data_normal[i][j])
            );
        end
    end
endgenerate

assign comp_done_o = comp_done;
assign comp_data_o = comp_data_divide;

always_ff @(posedge clk_i or negedge rst_n_i)
begin
    if (!rst_n_i) begin
        ctl_sta <= IDLE;

        comp_init <= 'd0;
        comp_loop <= 'd0;
        comp_done <= 'd0;
    end else begin
        case (ctl_sta)
            IDLE:
                ctl_sta <= comp_init_i ? PIVOT : IDLE;
            PIVOT:
                ctl_sta <= COMPUTE;
            COMPUTE:
                ctl_sta <= NORMAL;
            NORMAL:
                ctl_sta <= (comp_loop == 'd5) ? DIVIDE : PIVOT;
            DIVIDE:
                ctl_sta <= IDLE;
            default:
                ctl_sta <= IDLE;
        endcase

        case (ctl_sta)
            IDLE: begin
                comp_init <= 'b0;
                comp_loop <= affine_param6_i ? 'd0 : 'd2;
            end
            PIVOT: begin
                for (int i = 0; i < 6; i++) begin
                    for (int j = 0; j < 7; j++) begin
                        if (i[COMP_DATA_IDX_BITS-1:0] == comp_data_m_index) begin
                            comp_init[i][j] <= 1'b0;
                        end else begin
                            comp_init[i][j] <= 1'b1;
                        end
                    end
                end

                comp_loop <= comp_loop;
            end
            COMPUTE: begin
                comp_init <= comp_init;
                comp_loop <= comp_loop;
            end
            NORMAL: begin
                comp_init <= 'b0;
                comp_loop <= (comp_loop == 'd5) ? 'd0 : comp_loop + 'b1;
            end
            DIVIDE: begin
                comp_init <= 'b0;
                comp_loop <= 'd0;
            end
            default: begin
                comp_init <= 'b0;
                comp_loop <= 'd0;
            end
        endcase

        comp_done <= (ctl_sta == DIVIDE);
    end
end

endmodule
