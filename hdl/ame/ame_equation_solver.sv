/*
 * ame_equation_solver.sv
 *
 *  Created on: 2022-08-18 16:25
 *      Author: Jack Chen <redchenjs@live.com>
 */

`timescale 1 ns / 1 ps

module ame_equation_solver #(
    parameter COMP_DATA_BITS = 64,
    parameter COMP_DATA_IDX_BITS = 3,
    parameter COMP_DATA_FRAC_BITS = 8
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
    SCALE   = 'd2,
    COMPUTE = 'd3,
    NORMAL  = 'd4,
    DIVIDE  = 'd5
} state_t;

state_t ctl_sta;

logic       comp_done;

logic [2:0] comp_loop_0_1;
logic [2:0] comp_loop_1_2;
logic [2:0] comp_loop_2_3;
logic [2:0] comp_loop_3_4;

logic                     [COMP_DATA_BITS-1:0] comp_data_a;
logic                 [COMP_DATA_IDX_BITS-1:0] comp_data_a_index;

logic                     [COMP_DATA_BITS-1:0] comp_data_m;
logic             [$clog2(COMP_DATA_BITS)-1:0] comp_data_m_shift;

logic [5:0]                                    comp_data_m_mask;

logic                 [COMP_DATA_IDX_BITS-1:0] comp_data_m_index;
logic                 [COMP_DATA_IDX_BITS-1:0] comp_data_m_index_1_2;
logic                 [COMP_DATA_IDX_BITS-1:0] comp_data_m_index_2_3;
logic                 [COMP_DATA_IDX_BITS-1:0] comp_data_m_index_3_4;

logic [5:0]           [COMP_DATA_IDX_BITS-1:0] comp_data_m_index_mux;
logic [5:0]           [COMP_DATA_IDX_BITS-1:0] comp_data_m_index_mux_1_2;
logic [5:0]           [COMP_DATA_IDX_BITS-1:0] comp_data_m_index_mux_2_3;
logic [5:0]           [COMP_DATA_IDX_BITS-1:0] comp_data_m_index_mux_3_4;

logic [5:0] [6:0] [$clog2(COMP_DATA_BITS)-1:0] comp_data_s_shift;
logic [5:0] [6:0] [$clog2(COMP_DATA_BITS)-1:0] comp_data_n_shift;

logic [5:0] [6:0]         [COMP_DATA_BITS-1:0] comp_data_t;

logic                                          comp_init_p;
logic                                          comp_done_p;
logic [5:0] [6:0] [3:0]   [COMP_DATA_BITS-1:0] comp_data_p;

logic [5:0] [6:0]                              comp_init_s;
logic [5:0] [6:0] [3:0]   [COMP_DATA_BITS-1:0] comp_data_s;

logic [5:0] [6:0]                              comp_init_c;
logic [5:0] [6:0]                              comp_done_c;
logic [5:0] [6:0]         [COMP_DATA_BITS-1:0] comp_data_c;

logic [5:0] [6:0]         [COMP_DATA_BITS-1:0] comp_data_n;

logic                                          comp_init_d;
logic [5:0]                                    comp_done_d;
logic [5:0]               [COMP_DATA_BITS-1:0] comp_data_d;

wire comp_data_zero = ~|comp_data_a;
wire comp_data_done =  &comp_done_d & ~comp_init_d;

assign comp_done_o = comp_done;

ame_num_compare #(
    .COMP_DATA_BITS(64),
    .COMP_DATA_IDX_BITS(3)
) ame_num_compare (
    .clk_i(clk_i),
    .rst_n_i(rst_n_i),

    .comp_init_i(comp_init_p),
    .comp_done_o(),

    .comp_data_i({ comp_data_t[5][comp_loop_0_1],
                   comp_data_t[4][comp_loop_0_1],
                   comp_data_t[3][comp_loop_0_1],
                   comp_data_t[2][comp_loop_0_1],
                   comp_data_t[1][comp_loop_0_1],
                   comp_data_t[0][comp_loop_0_1] }),
    .comp_data_o(comp_data_a),

    .comp_data_mask_i(comp_data_m_mask),
    .comp_data_index_o(comp_data_a_index)
);

always_ff @(posedge clk_i or negedge rst_n_i)
begin
    if (!rst_n_i) begin
        comp_done_p       <= 'b0;
        comp_data_m       <= 'b0;
        comp_data_m_index <= 'b0;
    end else begin
        comp_done_p       <= comp_init_p;
        comp_data_m       <= comp_init_p ? comp_data_a : comp_data_m;
        comp_data_m_index <= comp_init_p ? comp_data_a_index : comp_data_m_index;
    end
end

ame_num_approx #(
    .COMP_DATA_BITS(64)
) ame_num_approx (
    .clk_i(clk_i),
    .rst_n_i(rst_n_i),

    .comp_init_i(comp_done_p),
    .comp_done_o(),

    .comp_data_i(comp_data_m),
    .comp_data_o(comp_data_m_shift)
);

generate
    for (genvar i = 0; i < 6; i++) begin
        for (genvar j = 0; j < 7; j++) begin
            always_ff @(posedge clk_i) begin
                if (i[COMP_DATA_IDX_BITS-1:0] == comp_data_a_index) begin
                    comp_data_p[i][j][3] <= 'b1;
                    comp_data_p[i][j][1] <= 'b0;
                end else begin
                    comp_data_p[i][j][3] <= comp_data_a;
                    comp_data_p[i][j][1] <= comp_data_t[i][comp_loop_0_1];
                end

                comp_data_p[i][j][2] <= comp_data_t[i][j];
                comp_data_p[i][j][0] <= comp_data_t[comp_data_a_index][j];

                comp_data_n_shift[i][j] <= comp_data_m_shift - comp_data_s_shift[i][j];
            end

            ame_num_scale #(
                .COMP_DATA_BITS(64)
            ) ame_num_scale (
                .clk_i(clk_i),
                .rst_n_i(rst_n_i),

                .comp_init_i(comp_init_s[i][j]),
                .comp_done_o(),

                .comp_shift_o(comp_data_s_shift[i][j]),

                .comp_data_i(comp_data_p[i][j]),
                .comp_data_o(comp_data_s[i][j])
            );

            ame_num_compute #(
                .COMP_DATA_BITS(64)
            ) ame_num_compute (
                .clk_i(clk_i),
                .rst_n_i(rst_n_i),

                .comp_init_i(comp_init_c[i][j]),
                .comp_done_o(comp_done_c[i][j]),

                .comp_data_i(comp_data_s[i][j]),
                .comp_data_o(comp_data_c[i][j])
            );

            ame_num_normal #(
                .COMP_DATA_BITS(64)
            ) ame_num_normal (
                .clk_i(clk_i),
                .rst_n_i(rst_n_i),

                .comp_init_i(comp_done_c[i][j]),
                .comp_done_o(),

                .comp_shift_i(comp_data_n_shift[i][j]),

                .comp_data_i(comp_data_c[i][j]),
                .comp_data_o(comp_data_n[i][j])
            );
        end

        ame_num_divide #(
            .COMP_DATA_BITS(64)
        ) ame_num_divide (
            .clk_i(clk_i),
            .rst_n_i(rst_n_i),

            .comp_init_i(comp_init_d),
            .comp_done_o(comp_done_d[i]),

            .comp_data_i({comp_data_t[comp_data_m_index_mux[i]][i],
                         {comp_data_t[comp_data_m_index_mux[i]][6][COMP_DATA_BITS-COMP_DATA_FRAC_BITS-1:0], {COMP_DATA_FRAC_BITS{1'b0}}}}),
            .comp_data_o(comp_data_d[i])
        );

        assign comp_data_o[i] = comp_data_d[i];
    end
endgenerate

always_ff @(posedge clk_i or negedge rst_n_i)
begin
    if (!rst_n_i) begin
        ctl_sta <= IDLE;

        comp_done <= 'b0;

        comp_loop_0_1 <= 'b0;
        comp_loop_1_2 <= 'b0;
        comp_loop_2_3 <= 'b0;
        comp_loop_3_4 <= 'b0;

        comp_init_p <= 'b0;
        comp_init_s <= 'b0;
        comp_init_c <= 'b0;
        comp_init_d <= 'b0;

        comp_data_t <= 'b0;

        comp_data_m_mask      <= 'b0;
        comp_data_m_index_1_2 <= 'b0;
        comp_data_m_index_2_3 <= 'b0;
        comp_data_m_index_3_4 <= 'b0;

        comp_data_m_index_mux     <= 'b0;
        comp_data_m_index_mux_1_2 <= 'b0;
        comp_data_m_index_mux_2_3 <= 'b0;
        comp_data_m_index_mux_3_4 <= 'b0;
    end else begin
        case (ctl_sta)
            IDLE:
                ctl_sta <= comp_init_i ? PIVOT : IDLE;
            PIVOT:
                ctl_sta <= comp_data_zero ? IDLE : SCALE;
            SCALE:
                ctl_sta <= COMPUTE;
            COMPUTE:
                ctl_sta <= NORMAL;
            NORMAL:
                ctl_sta <= (comp_loop_3_4 == 'd5) ? DIVIDE : PIVOT;
            DIVIDE:
                ctl_sta <= comp_data_done ? IDLE : DIVIDE;
            default:
                ctl_sta <= IDLE;
        endcase

        case (ctl_sta)
            IDLE: begin
                comp_loop_0_1 <= affine_param6_i ? 'd0 : 'd2;

                comp_init_p <= comp_init_i;
                comp_init_c <= 'b0;
                comp_init_d <= 'b0;

                comp_data_t <= comp_init_i ? comp_data_i : 'b0;

                comp_data_m_mask      <= 'b0;
                comp_data_m_index_mux <= 'b0;
            end
            PIVOT: begin
                comp_loop_1_2 <= comp_loop_0_1;

                comp_init_p <= 'b0;
                for (int i = 0; i < 6; i++) begin
                    for (int j = 0; j < 7; j++) begin
                        if (i[COMP_DATA_IDX_BITS-1:0] == comp_data_a_index) begin
                            comp_init_s[i][j] <= 'b0;
                        end else begin
                            comp_init_s[i][j] <= 'b1;
                        end
                    end
                end
                comp_init_c <= 'b0;
                comp_init_d <= 'b0;

                comp_data_t <= comp_data_t;

                comp_data_m_mask      <= comp_data_m_mask;
                comp_data_m_index_mux <= comp_data_m_index_mux;
            end
            SCALE: begin
                comp_loop_2_3 <= comp_loop_1_2;

                comp_init_p <= 'b0;
                comp_init_s <= 'b0;
                for (int i = 0; i < 6; i++) begin
                    for (int j = 0; j < 7; j++) begin
                        if (i[COMP_DATA_IDX_BITS-1:0] == comp_data_m_index) begin
                            comp_init_c[i][j] <= 'b0;
                        end else begin
                            comp_init_c[i][j] <= 'b1;
                        end
                    end
                end
                comp_init_d <= 'b0;

                comp_data_t <= comp_data_t;

                comp_data_m_mask      <= comp_data_m_mask;
                comp_data_m_index_mux <= comp_data_m_index_mux;
            end
            COMPUTE: begin
                comp_loop_3_4 <= comp_loop_2_3;

                comp_init_p <= 'b0;
                comp_init_s <= 'b0;
                comp_init_c <= 'b0;
                comp_init_d <= 'b0;

                comp_data_t <= comp_data_t;

                case (comp_data_m_index)
                    'd0:
                        comp_data_m_mask <= comp_data_m_mask | 6'b00_0001;
                    'd1:
                        comp_data_m_mask <= comp_data_m_mask | 6'b00_0010;
                    'd2:
                        comp_data_m_mask <= comp_data_m_mask | 6'b00_0100;
                    'd3:
                        comp_data_m_mask <= comp_data_m_mask | 6'b00_1000;
                    'd4:
                        comp_data_m_mask <= comp_data_m_mask | 6'b01_0000;
                    'd5:
                        comp_data_m_mask <= comp_data_m_mask | 6'b10_0000;
                    default:
                        comp_data_m_mask <= comp_data_m_mask;
                endcase

                for (int i = 0; i < 6; i++) begin
                    if (comp_loop_2_3 == i[2:0]) begin
                        comp_data_m_index_mux[i] <= comp_data_m_index;
                    end else begin
                        comp_data_m_index_mux[i] <= comp_data_m_index_mux[i];
                    end
                end
            end
            NORMAL: begin
                comp_loop_0_1 <= (comp_loop_3_4 == 'd5) ? 'b0 : comp_loop_3_4 + 'b1;

                comp_init_p <= 'b1;
                comp_init_s <= 'b0;
                comp_init_c <= 'b0;
                comp_init_d <= (comp_loop_3_4 == 'd5) ? 'b1 : 'b0;

                comp_data_t <= comp_data_n;

                comp_data_m_mask      <= comp_data_m_mask;
                comp_data_m_index_mux <= comp_data_m_index_mux;
            end
            DIVIDE: begin
                comp_loop_0_1 <= 'b0;

                comp_init_p <= 'b0;
                comp_init_s <= 'b0;
                comp_init_c <= 'b0;
                comp_init_d <= 'b0;

                comp_data_t <= 'b0;

                comp_data_m_mask      <= comp_data_m_mask;
                comp_data_m_index_mux <= comp_data_m_index_mux;
            end
            default: begin
                comp_loop_0_1 <= 'b0;

                comp_init_p <= 'b0;
                comp_init_s <= 'b0;
                comp_init_c <= 'b0;
                comp_init_d <= 'b0;

                comp_data_t <= 'b0;

                comp_data_m_mask      <= 'b0;
                comp_data_m_index_mux <= 'b0;
            end
        endcase

        comp_done <= ((ctl_sta == PIVOT) & comp_data_zero) | ((ctl_sta == DIVIDE) & comp_data_done);
    end
end

endmodule
