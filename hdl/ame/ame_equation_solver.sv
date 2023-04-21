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

logic comp_done;

logic                                          comp_pipe_0_1;
logic                                    [2:0] comp_loop_0_1;
logic [5:0]                                    comp_data_m_mask_0_1;
logic [5:0]           [COMP_DATA_IDX_BITS-1:0] comp_data_m_index_mux_0_1;
logic [5:0] [6:0]         [COMP_DATA_BITS-1:0] comp_data_t_0_1;
logic                                          comp_init_p_0_1;
logic                     [COMP_DATA_BITS-1:0] comp_data_a_1;
logic                 [COMP_DATA_IDX_BITS-1:0] comp_data_a_index_1;

logic                                          comp_pipe_1_2;
logic                                    [2:0] comp_loop_1_2;
logic                     [COMP_DATA_BITS-1:0] comp_data_m_1_2;
logic [5:0]                                    comp_data_m_mask_1_2;
logic                 [COMP_DATA_IDX_BITS-1:0] comp_data_m_index_1_2;
logic [5:0]           [COMP_DATA_IDX_BITS-1:0] comp_data_m_index_mux_1_2;
logic                                          comp_done_p_1_2;
logic [5:0] [6:0] [3:0]   [COMP_DATA_BITS-1:0] comp_data_p_1_2;
logic [5:0] [6:0]                              comp_init_s_1_2;

logic                                          comp_pipe_2_3;
logic                                    [2:0] comp_loop_2_3;
logic             [$clog2(COMP_DATA_BITS)-1:0] comp_data_m_shift_2_3;
logic [5:0]                                    comp_data_m_mask_2_3;
logic                 [COMP_DATA_IDX_BITS-1:0] comp_data_m_index_2_3;
logic [5:0]           [COMP_DATA_IDX_BITS-1:0] comp_data_m_index_mux_2_3;
logic [5:0] [6:0] [$clog2(COMP_DATA_BITS)-1:0] comp_data_s_shift_2_3;
logic [5:0] [6:0] [3:0]   [COMP_DATA_BITS-1:0] comp_data_s_2_3;
logic [5:0] [6:0]                              comp_init_c_2_3;

logic                                          comp_pipe_3_4;
logic                                    [2:0] comp_loop_3_4;
logic [5:0]                                    comp_data_m_mask_3_4;
logic [5:0]           [COMP_DATA_IDX_BITS-1:0] comp_data_m_index_mux_3_4;
logic [5:0] [6:0] [$clog2(COMP_DATA_BITS)-1:0] comp_data_n_shift_3_4;
logic [5:0] [6:0]                              comp_done_c_3_4;
logic [5:0] [6:0]         [COMP_DATA_BITS-1:0] comp_data_c_3_4;

logic [5:0] [6:0]         [COMP_DATA_BITS-1:0] comp_data_n_4;

logic                                          comp_init_d_4_5;
logic [5:0]                                    comp_done_d_5;
logic [5:0]               [COMP_DATA_BITS-1:0] comp_data_d_5;

wire comp_data_zero = ~|comp_data_a_1;
wire comp_data_done =  &comp_done_d_5 & ~comp_init_d_4_5;

assign comp_done_o = comp_done;

// Stage: 1 / Output Register: 1 - 2
ame_num_compare #(
    .COMP_DATA_BITS(64),
    .COMP_DATA_IDX_BITS(3)
) ame_num_compare (
    .clk_i(clk_i),
    .rst_n_i(rst_n_i),

    .comp_init_i(comp_init_p_0_1),
    .comp_done_o(),

    .comp_data_i({ comp_data_t_0_1[5][comp_loop_0_1],
                   comp_data_t_0_1[4][comp_loop_0_1],
                   comp_data_t_0_1[3][comp_loop_0_1],
                   comp_data_t_0_1[2][comp_loop_0_1],
                   comp_data_t_0_1[1][comp_loop_0_1],
                   comp_data_t_0_1[0][comp_loop_0_1] }),
    .comp_data_o(comp_data_a_1),

    .comp_data_mask_i(comp_data_m_mask_0_1),
    .comp_data_index_o(comp_data_a_index_1)
);

generate
    for (genvar i = 0; i < 6; i++) begin
        for (genvar j = 0; j < 7; j++) begin
            always_ff @(posedge clk_i) begin
                if (i[COMP_DATA_IDX_BITS-1:0] == comp_data_a_index_1) begin
                    comp_data_p_1_2[i][j][3] <= 'b1;
                    comp_data_p_1_2[i][j][1] <= 'b0;
                end else begin
                    comp_data_p_1_2[i][j][3] <= comp_data_a_1;
                    comp_data_p_1_2[i][j][1] <= comp_data_t_0_1[i][comp_loop_0_1];
                end

                comp_data_p_1_2[i][j][2] <= comp_data_t_0_1[i][j];
                comp_data_p_1_2[i][j][0] <= comp_data_t_0_1[comp_data_a_index_1][j];
            end
        end
    end
endgenerate

always_ff @(posedge clk_i or negedge rst_n_i)
begin
    if (!rst_n_i) begin
        comp_pipe_1_2 <= 'b0;
        comp_loop_1_2 <= 'b0;

        comp_done_p_1_2 <= 'b0;
        comp_init_s_1_2 <= 'b0;

        comp_data_m_1_2 <= 'b0;
        comp_data_m_mask_1_2 <= 'b0;

        comp_data_m_index_1_2 <= 'b0;
        comp_data_m_index_mux_1_2 <= 'b0;
    end else begin
        comp_pipe_1_2 <= comp_pipe_0_1;
        comp_loop_1_2 <= comp_loop_0_1;

        comp_done_p_1_2 <= comp_init_p_0_1;
        for (int i = 0; i < 6; i++) begin
            for (int j = 0; j < 7; j++) begin
                if (i[COMP_DATA_IDX_BITS-1:0] == comp_data_a_index_1) begin
                    comp_init_s_1_2[i][j] <= 'b0;
                end else begin
                    comp_init_s_1_2[i][j] <= 'b1;
                end
            end
        end

        comp_data_m_1_2      <= comp_data_a_1;
        comp_data_m_mask_1_2 <= comp_data_m_mask_0_1;

        comp_data_m_index_1_2     <= comp_data_a_index_1;
        comp_data_m_index_mux_1_2 <= comp_data_m_index_mux_0_1;
    end
end


// Stage: 2 / Output Register: 2 - 3
ame_num_approx #(
    .COMP_DATA_BITS(64)
) ame_num_approx (
    .clk_i(clk_i),
    .rst_n_i(rst_n_i),

    .comp_init_i(comp_done_p_1_2),
    .comp_done_o(),

    .comp_data_i(comp_data_m_1_2),
    .comp_data_o(comp_data_m_shift_2_3)
);

generate
    for (genvar i = 0; i < 6; i++) begin
        for (genvar j = 0; j < 7; j++) begin
            ame_num_scale #(
                .COMP_DATA_BITS(64)
            ) ame_num_scale (
                .clk_i(clk_i),
                .rst_n_i(rst_n_i),

                .comp_init_i(comp_init_s_1_2[i][j]),
                .comp_done_o(),

                .comp_shift_o(comp_data_s_shift_2_3[i][j]),

                .comp_data_i(comp_data_p_1_2[i][j]),
                .comp_data_o(comp_data_s_2_3[i][j])
            );
        end
    end
endgenerate

always_ff @(posedge clk_i or negedge rst_n_i)
begin
    if (!rst_n_i) begin
        comp_pipe_2_3 <= 'b0;
        comp_loop_2_3 <= 'b0;

        comp_init_c_2_3 <= 'b0;

        comp_data_m_mask_2_3 <= 'b0;
        comp_data_m_index_2_3 <= 'b0;
        comp_data_m_index_mux_2_3 <= 'b0;
    end else begin
        comp_pipe_2_3 <= comp_pipe_1_2;
        comp_loop_2_3 <= comp_loop_1_2;

        for (int i = 0; i < 6; i++) begin
            for (int j = 0; j < 7; j++) begin
                if (i[COMP_DATA_IDX_BITS-1:0] == comp_data_m_index_1_2) begin
                    comp_init_c_2_3[i][j] <= 'b0;
                end else begin
                    comp_init_c_2_3[i][j] <= 'b1;
                end
            end
        end

        comp_data_m_mask_2_3 <= comp_data_m_mask_1_2;

        comp_data_m_index_2_3     <= comp_data_m_index_1_2;
        comp_data_m_index_mux_2_3 <= comp_data_m_index_mux_1_2;
    end
end

// Stage: 3 / Output Register: 3 - 4
generate
    for (genvar i = 0; i < 6; i++) begin
        for (genvar j = 0; j < 7; j++) begin
            always_ff @(posedge clk_i) begin
                comp_data_n_shift_3_4[i][j] <= comp_data_m_shift_2_3 - comp_data_s_shift_2_3[i][j];
            end

            ame_num_compute #(
                .COMP_DATA_BITS(64)
            ) ame_num_compute (
                .clk_i(clk_i),
                .rst_n_i(rst_n_i),

                .comp_init_i(comp_init_c_2_3[i][j]),
                .comp_done_o(comp_done_c_3_4[i][j]),

                .comp_data_i(comp_data_s_2_3[i][j]),
                .comp_data_o(comp_data_c_3_4[i][j])
            );
        end
    end
endgenerate

always_ff @(posedge clk_i or negedge rst_n_i)
begin
    if (!rst_n_i) begin
        comp_pipe_3_4 <= 'b0;
        comp_loop_3_4 <= 'b0;

        comp_data_m_mask_3_4 <= 'b0;
        comp_data_m_index_mux_3_4 <= 'b0;
    end else begin
        comp_pipe_3_4 <= comp_pipe_2_3;
        comp_loop_3_4 <= comp_loop_2_3;

        case (comp_data_m_index_2_3)
            'd0:
                comp_data_m_mask_3_4 <= comp_data_m_mask_2_3 | 6'b00_0001;
            'd1:
                comp_data_m_mask_3_4 <= comp_data_m_mask_2_3 | 6'b00_0010;
            'd2:
                comp_data_m_mask_3_4 <= comp_data_m_mask_2_3 | 6'b00_0100;
            'd3:
                comp_data_m_mask_3_4 <= comp_data_m_mask_2_3 | 6'b00_1000;
            'd4:
                comp_data_m_mask_3_4 <= comp_data_m_mask_2_3 | 6'b01_0000;
            'd5:
                comp_data_m_mask_3_4 <= comp_data_m_mask_2_3 | 6'b10_0000;
            default:
                comp_data_m_mask_3_4 <= comp_data_m_mask_2_3;
        endcase

        for (int i = 0; i < 6; i++) begin
            if (comp_loop_2_3 == i[2:0]) begin
                comp_data_m_index_mux_3_4[i] <= comp_data_m_index_2_3;
            end else begin
                comp_data_m_index_mux_3_4[i] <= comp_data_m_index_mux_2_3[i];
            end
        end
    end
end

// Stage: 4 / Output Register: None
generate
    for (genvar i = 0; i < 6; i++) begin
        for (genvar j = 0; j < 7; j++) begin
            ame_num_normal #(
                .COMP_DATA_BITS(64)
            ) ame_num_normal (
                .clk_i(clk_i),
                .rst_n_i(rst_n_i),

                .comp_init_i(comp_done_c_3_4[i][j]),
                .comp_done_o(),

                .comp_shift_i(comp_data_n_shift_3_4[i][j]),

                .comp_data_i(comp_data_c_3_4[i][j]),
                .comp_data_o(comp_data_n_4[i][j])
            );
        end
    end
endgenerate

always_ff @(posedge clk_i or negedge rst_n_i)
begin
    if (!rst_n_i) begin
        comp_pipe_0_1 <= 'b0;
        comp_loop_0_1 <= 'b0;

        comp_init_p_0_1 <= 'b0;
        comp_data_t_0_1 <= 'b0;

        comp_data_m_mask_0_1 <= 'b0;
        comp_data_m_index_mux_0_1 <= 'b0;

        comp_init_d_4_5 <= 'b0;
    end else begin
        if (comp_init_i) begin
            comp_pipe_0_1 <= 'b1;
            comp_loop_0_1 <= affine_param6_i ? 'd0 : 'd2;

            comp_init_p_0_1 <= 'b1;
            comp_data_t_0_1 <= comp_data_i;

            comp_data_m_mask_0_1 <= 'b0;
            comp_data_m_index_mux_0_1 <= 'b0;

            comp_init_d_4_5 <= 'b0;
        end else begin
            comp_pipe_0_1 <= (comp_loop_3_4 == 'd5) ? 'b0 : comp_pipe_3_4;
            comp_loop_0_1 <= (comp_loop_3_4 == 'd5) ? 'b0 : comp_loop_3_4 + comp_pipe_3_4;

            comp_init_p_0_1 <= (comp_loop_3_4 == 'd5) ? 'b0 : comp_pipe_3_4;
            comp_data_t_0_1 <= comp_data_n_4;

            comp_data_m_mask_0_1 <= comp_data_m_mask_3_4;
            comp_data_m_index_mux_0_1 <= comp_data_m_index_mux_3_4;

            comp_init_d_4_5 <= (comp_loop_3_4 == 'd5) ? comp_pipe_3_4 : 'b0;
        end
    end
end

// Stage: 5 / Output Register: 5
generate
    for (genvar i = 0; i < 6; i++) begin
        ame_num_divide #(
            .COMP_DATA_BITS(64)
        ) ame_num_divide (
            .clk_i(clk_i),
            .rst_n_i(rst_n_i),

            .comp_init_i(comp_init_d_4_5),
            .comp_done_o(comp_done_d_5[i]),

            .comp_data_i({comp_data_t_0_1[comp_data_m_index_mux_0_1[i]][i],
                         {comp_data_t_0_1[comp_data_m_index_mux_0_1[i]][6][COMP_DATA_BITS-COMP_DATA_FRAC_BITS-1:0], {COMP_DATA_FRAC_BITS{1'b0}}}}),
            .comp_data_o(comp_data_d_5[i])
        );

        assign comp_data_o[i] = comp_data_d_5[i];
    end
endgenerate

endmodule
