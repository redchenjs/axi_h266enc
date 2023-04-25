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
    output logic comp_load_o,
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
    input logic                            [7:0] comp_data_index_i,

    // 4 Fixed Point Results            // 6 Fixed Point Results
    // --- --- --- --- --- --- | --     // --- --- --- --- --- --- | --
    //  --  --  X2  X3  X4  X5 | --     //  X0  X1  X2  X3  X4  X5 | --
    // --- --- --- --- --- --- | --     // --- --- --- --- --- --- | --
    output logic [5:0] [COMP_DATA_BITS-1:0] comp_data_o,
    output logic                      [7:0] comp_data_index_o
);

// Stage 0 / 5 Registers
logic                            [7:0] comp_data_index_0_1;

logic                                  comp_pipe_0_1;
logic                            [2:0] comp_loop_0_1;
logic [5:0]                            comp_data_m_mask_0_1;
logic [5:0]   [COMP_DATA_IDX_BITS-1:0] comp_data_m_index_mux_0_1;
logic [5:0] [6:0] [COMP_DATA_BITS-1:0] comp_data_t_0_1;
logic                                  comp_init_p_0_1;
logic             [COMP_DATA_BITS-1:0] comp_data_a_1;
logic         [COMP_DATA_IDX_BITS-1:0] comp_data_a_index_1;

logic                                  comp_init_d_4_5;

assign comp_load_o = ~comp_pipe_2_3;

// Stage: 1 / Output Register: 1 - 2
logic                                  [7:0] comp_data_index_1_2;

logic                                        comp_pipe_1_2;
logic                                  [2:0] comp_loop_1_2;
logic                   [COMP_DATA_BITS-1:0] comp_data_m_1_2;
logic [5:0]                                  comp_data_m_mask_1_2;
logic               [COMP_DATA_IDX_BITS-1:0] comp_data_m_index_1_2;
logic [5:0]         [COMP_DATA_IDX_BITS-1:0] comp_data_m_index_mux_1_2;
logic                                        comp_done_p_1_2;
logic [5:0] [6:0] [3:0] [COMP_DATA_BITS-1:0] comp_data_p_1_2;
logic [5:0] [6:0]                            comp_init_s_1_2;

ame_num_compare #(
    .COMP_DATA_BITS(64),
    .COMP_DATA_IDX_BITS(3)
) ame_num_compare (
    .clk_i(clk_i),
    .rst_n_i(rst_n_i),

    .comp_init_i(comp_init_p_0_1),
    .comp_done_o(),

    .comp_data_i({
        comp_data_t_0_1[5][comp_loop_0_1],
        comp_data_t_0_1[4][comp_loop_0_1],
        comp_data_t_0_1[3][comp_loop_0_1],
        comp_data_t_0_1[2][comp_loop_0_1],
        comp_data_t_0_1[1][comp_loop_0_1],
        comp_data_t_0_1[0][comp_loop_0_1]
    }),
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
        comp_data_index_1_2 <= 'b0;

        comp_pipe_1_2 <= 'b0;
        comp_loop_1_2 <= 'b0;

        comp_done_p_1_2 <= 'b0;
        comp_init_s_1_2 <= 'b0;

        comp_data_m_1_2 <= 'b0;
        comp_data_m_mask_1_2 <= 'b0;

        comp_data_m_index_1_2 <= 'b0;
        comp_data_m_index_mux_1_2 <= 'b0;
    end else begin
        comp_data_index_1_2 <= comp_pipe_0_1 ? comp_data_index_0_1 : 'b0;

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
logic                                    [7:0] comp_data_index_2_3;

logic                                          comp_pipe_2_3;
logic                                    [2:0] comp_loop_2_3;
logic             [$clog2(COMP_DATA_BITS)-1:0] comp_data_m_shift_2_3;
logic [5:0]                                    comp_data_m_mask_2_3;
logic                 [COMP_DATA_IDX_BITS-1:0] comp_data_m_index_2_3;
logic [5:0]           [COMP_DATA_IDX_BITS-1:0] comp_data_m_index_mux_2_3;
logic [5:0] [6:0] [$clog2(COMP_DATA_BITS)-1:0] comp_data_s_shift_2_3;
logic [5:0] [6:0] [3:0]   [COMP_DATA_BITS-1:0] comp_data_s_2_3;
logic [5:0] [6:0]                              comp_init_c_2_3;

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
        comp_data_index_2_3 <= 'b0;

        comp_pipe_2_3 <= 'b0;
        comp_loop_2_3 <= 'b0;

        comp_init_c_2_3 <= 'b0;

        comp_data_m_mask_2_3 <= 'b0;
        comp_data_m_index_2_3 <= 'b0;
        comp_data_m_index_mux_2_3 <= 'b0;
    end else begin
        comp_data_index_2_3 <= comp_data_index_1_2;

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
logic                                    [7:0] comp_data_index_3_4;

logic                                          comp_pipe_3_4;
logic                                    [2:0] comp_loop_3_4;
logic [5:0]                                    comp_data_m_mask_3_4;
logic [5:0]           [COMP_DATA_IDX_BITS-1:0] comp_data_m_index_mux_3_4;
logic [5:0] [6:0] [$clog2(COMP_DATA_BITS)-1:0] comp_data_n_shift_3_4;
logic [5:0] [6:0]                              comp_done_c_3_4;
logic [5:0] [6:0]         [COMP_DATA_BITS-1:0] comp_data_c_3_4;
logic [5:0] [6:0]         [COMP_DATA_BITS-1:0] comp_data_n_4;

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
        comp_data_index_3_4 <= 'b0;

        comp_pipe_3_4 <= 'b0;
        comp_loop_3_4 <= 'b0;

        comp_data_m_mask_3_4 <= 'b0;
        comp_data_m_index_mux_3_4 <= 'b0;
    end else begin
        comp_data_index_3_4 <= comp_data_index_2_3;

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

// Stage: 4 / Output Register: 1 / 5
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
        comp_data_index_0_1 <= 'b0;

        comp_pipe_0_1 <= 'b0;
        comp_loop_0_1 <= 'b0;

        comp_init_p_0_1 <= 'b0;
        comp_data_t_0_1 <= 'b0;

        comp_data_m_mask_0_1 <= 'b0;
        comp_data_m_index_mux_0_1 <= 'b0;

        comp_init_d_4_5 <= 'b0;
    end else begin
        if (comp_init_i) begin
            comp_data_index_0_1 <= comp_data_index_i;

            comp_pipe_0_1 <= 'b1;
            comp_loop_0_1 <= affine_param6_i ? 'd0 : 'd2;

            comp_init_p_0_1 <= 'b1;
            comp_data_t_0_1 <= comp_data_i;

            comp_data_m_mask_0_1 <= 'b0;
            comp_data_m_index_mux_0_1 <= 'b0;

            comp_init_d_4_5 <= 'b0;
        end else begin
            comp_data_index_0_1 <= comp_data_index_3_4;

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

// Division Input FIFO
parameter FIFO_I_WIDTH_D_I = COMP_DATA_BITS * 6 * 2 + 8;
parameter FIFO_I_DEPTH_D_I = 8;
parameter FIFO_O_WIDTH_D_I = COMP_DATA_BITS * 6 * 2 + 8;
parameter FIFO_O_DEPTH_D_I = 8;

typedef enum logic [1:0] {
    IDLE   = 'd0,
    DATA_A = 'd1,
    DATA_B = 'd2
} state_t;

state_t ctl_sta_d_i;
state_t ctl_sta_d_o;

logic [1:0]       comp_init_d;
logic [1:0] [5:0] comp_done_d;

logic [1:0] [7:0] comp_data_index_d_i;

logic                              fifo_wr_en_d_i;
logic       [FIFO_I_WIDTH_D_I-1:0] fifo_wr_data_d_i;
logic                              fifo_wr_full_d_i;
logic [$clog2(FIFO_I_DEPTH_D_I):0] fifo_wr_free_d_i;

logic                              fifo_rd_en_d_i;
logic       [FIFO_O_WIDTH_D_I-1:0] fifo_rd_data_d_i;
logic                              fifo_rd_empty_d_i;
logic [$clog2(FIFO_O_DEPTH_D_I):0] fifo_rd_avail_d_i;

assign fifo_wr_en_d_i   = comp_init_d_4_5;
assign fifo_wr_data_d_i = {
    comp_data_index_0_1,
    comp_data_t_0_1[comp_data_m_index_mux_0_1[5]][5], {comp_data_t_0_1[comp_data_m_index_mux_0_1[5]][6][COMP_DATA_BITS-COMP_DATA_FRAC_BITS-1:0], {COMP_DATA_FRAC_BITS{1'b0}}},
    comp_data_t_0_1[comp_data_m_index_mux_0_1[4]][4], {comp_data_t_0_1[comp_data_m_index_mux_0_1[4]][6][COMP_DATA_BITS-COMP_DATA_FRAC_BITS-1:0], {COMP_DATA_FRAC_BITS{1'b0}}},
    comp_data_t_0_1[comp_data_m_index_mux_0_1[3]][3], {comp_data_t_0_1[comp_data_m_index_mux_0_1[3]][6][COMP_DATA_BITS-COMP_DATA_FRAC_BITS-1:0], {COMP_DATA_FRAC_BITS{1'b0}}},
    comp_data_t_0_1[comp_data_m_index_mux_0_1[2]][2], {comp_data_t_0_1[comp_data_m_index_mux_0_1[2]][6][COMP_DATA_BITS-COMP_DATA_FRAC_BITS-1:0], {COMP_DATA_FRAC_BITS{1'b0}}},
    comp_data_t_0_1[comp_data_m_index_mux_0_1[1]][1], {comp_data_t_0_1[comp_data_m_index_mux_0_1[1]][6][COMP_DATA_BITS-COMP_DATA_FRAC_BITS-1:0], {COMP_DATA_FRAC_BITS{1'b0}}},
    comp_data_t_0_1[comp_data_m_index_mux_0_1[0]][0], {comp_data_t_0_1[comp_data_m_index_mux_0_1[0]][6][COMP_DATA_BITS-COMP_DATA_FRAC_BITS-1:0], {COMP_DATA_FRAC_BITS{1'b0}}}
};

fifo #(
    .I_WIDTH(FIFO_I_WIDTH_D_I),
    .I_DEPTH(FIFO_I_DEPTH_D_I),
    .O_WIDTH(FIFO_O_WIDTH_D_I),
    .O_DEPTH(FIFO_O_DEPTH_D_I)
) fifo_d_i (
    .clk_i(clk_i),
    .rst_n_i(rst_n_i),

    .wr_en_i(fifo_wr_en_d_i),
    .wr_data_i(fifo_wr_data_d_i),
    .wr_full_o(fifo_wr_full_d_i),
    .wr_free_o(fifo_wr_free_d_i),

    .rd_en_i(fifo_rd_en_d_i),
    .rd_data_o(fifo_rd_data_d_i),
    .rd_empty_o(fifo_rd_empty_d_i),
    .rd_avail_o(fifo_rd_avail_d_i)
);

always_ff @(posedge clk_i or negedge rst_n_i)
begin
    if (!rst_n_i) begin
        ctl_sta_d_i <= IDLE;

        comp_init_d <= 'b0;

        fifo_rd_en_d_i <= 'b0;

        comp_data_index_d_i <= 'b0;
    end else begin
        if (!fifo_rd_empty_d_i & (ctl_sta_d_i == IDLE)) begin
            case ({&comp_done_d[1], &comp_done_d[0]}) inside
                2'b10: begin
                    ctl_sta_d_i <= DATA_B;

                    fifo_rd_en_d_i <= (fifo_rd_avail_d_i >= 'd1) ? 'b1 : 'b0;
                end
                2'b?1: begin
                    ctl_sta_d_i <= DATA_A;

                    fifo_rd_en_d_i <= (fifo_rd_avail_d_i >= 'd1) ? 'b1 : 'b0;
                end
                2'b00: begin
                    ctl_sta_d_i <= IDLE;

                    fifo_rd_en_d_i <= 'b0;
                end
            endcase
        end

        case (ctl_sta_d_i)
            DATA_B: begin
                case ({comp_init_d, fifo_rd_en_d_i})
                    3'b001: begin
                        ctl_sta_d_i <= DATA_B;

                        comp_init_d[1] <= fifo_rd_en_d_i;
                        comp_init_d[0] <= 'b0;

                        fifo_rd_en_d_i <= 'b0;
                    end
                    default: begin
                        ctl_sta_d_i <= IDLE;

                        comp_init_d[1] <= 'b0;
                        comp_init_d[0] <= 'b0;

                        fifo_rd_en_d_i <= 'b0;
                    end
                endcase
            end
            DATA_A: begin
                case ({comp_init_d, fifo_rd_en_d_i})
                    3'b001: begin
                        ctl_sta_d_i <= DATA_A;

                        comp_init_d[1] <= 'b0;
                        comp_init_d[0] <= fifo_rd_en_d_i;

                        fifo_rd_en_d_i <= 'b0;
                    end
                    default: begin
                        ctl_sta_d_i <= IDLE;

                        comp_init_d[1] <= 'b0;
                        comp_init_d[0] <= 'b0;

                        fifo_rd_en_d_i <= 'b0;
                    end
                endcase
            end
        endcase

        for (int k = 0; k < 2; k++) begin
            if (comp_init_d[k]) begin
                comp_data_index_d_i[k] <= fifo_rd_data_d_i[FIFO_O_WIDTH_D_I - 1 : FIFO_O_WIDTH_D_I - 8];
            end
        end
    end
end

// Stage: 5 / Division
logic [5:0] [1:0] [COMP_DATA_BITS-1:0] comp_data_d_i;
logic [1:0] [5:0] [COMP_DATA_BITS-1:0] comp_data_d_t;
logic [1:0] [5:0] [COMP_DATA_BITS-1:0] comp_data_d_o;

generate
    for (genvar k = 0; k < 2; k++) begin
        for (genvar i = 0; i < 6; i++) begin
            assign comp_data_d_i[i] = fifo_rd_data_d_i[COMP_DATA_BITS * 2 * (i + 1) - 1 : COMP_DATA_BITS * 2 * i];

            ame_num_divide #(
                .COMP_DATA_BITS(COMP_DATA_BITS)
            ) ame_num_divide (
                .clk_i(clk_i),
                .rst_n_i(rst_n_i),

                .comp_init_i(comp_init_d[k]),
                .comp_done_o(comp_done_d[k][i]),

                .comp_data_i(comp_data_d_i[i]),
                .comp_data_o(comp_data_d_t[k][i])
            );
        end
    end
endgenerate

// Division Output FIFO
parameter FIFO_I_WIDTH_D_O = COMP_DATA_BITS * 6 + 8;
parameter FIFO_I_DEPTH_D_O = 8;
parameter FIFO_O_WIDTH_D_O = COMP_DATA_BITS * 6 + 8;
parameter FIFO_O_DEPTH_D_O = 8;

logic [1:0]       comp_done_t;
logic [1:0] [7:0] comp_data_index_d_o;

logic [1:0]                              fifo_wr_en_d_c;
logic [1:0]                              fifo_wr_en_d_o;
logic [1:0]       [FIFO_I_WIDTH_D_O-1:0] fifo_wr_data_d_o;
logic [1:0]                              fifo_wr_full_d_o;
logic [1:0] [$clog2(FIFO_I_DEPTH_D_O):0] fifo_wr_free_d_o;

logic [1:0]                              fifo_rd_en_d_o;
logic [1:0]       [FIFO_O_WIDTH_D_O-1:0] fifo_rd_data_d_o;
logic [1:0]                              fifo_rd_empty_d_o;
logic [1:0] [$clog2(FIFO_O_DEPTH_D_O):0] fifo_rd_avail_d_o;

generate
    for (genvar k = 0; k < 2; k++) begin
        assign fifo_wr_data_d_o[k] = {
            comp_data_index_d_i[k],
            comp_data_d_t[k][5], comp_data_d_t[k][4],
            comp_data_d_t[k][3], comp_data_d_t[k][2],
            comp_data_d_t[k][1], comp_data_d_t[k][0]
        };

        fifo #(
            .I_WIDTH(FIFO_I_WIDTH_D_O),
            .I_DEPTH(FIFO_I_DEPTH_D_O),
            .O_WIDTH(FIFO_O_WIDTH_D_O),
            .O_DEPTH(FIFO_O_DEPTH_D_O)
        ) fifo_d_o (
            .clk_i(clk_i),
            .rst_n_i(rst_n_i),

            .wr_en_i(fifo_wr_en_d_o[k]),
            .wr_data_i(fifo_wr_data_d_o[k]),
            .wr_full_o(fifo_wr_full_d_o[k]),
            .wr_free_o(fifo_wr_free_d_o[k]),

            .rd_en_i(fifo_rd_en_d_o[k]),
            .rd_data_o(fifo_rd_data_d_o[k]),
            .rd_empty_o(fifo_rd_empty_d_o[k]),
            .rd_avail_o(fifo_rd_avail_d_o[k])
        );

        for (genvar i = 0; i < 6; i++) begin
            assign comp_data_d_o[k][i] = fifo_rd_data_d_o[k][COMP_DATA_BITS * (i + 1) - 1 : COMP_DATA_BITS * i];
        end

        assign comp_data_index_d_o[k] = fifo_rd_data_d_o[k][FIFO_O_WIDTH_D_O - 1 : FIFO_O_WIDTH_D_O - 8];
    end
endgenerate

always_ff @(posedge clk_i or negedge rst_n_i)
begin
    if (!rst_n_i) begin
        ctl_sta_d_o <= IDLE;

        comp_done_o <= 'b0;

        comp_data_o <= 'b0;
        comp_done_t <= 'b0;
        comp_data_index_o <= 'b0;

        fifo_wr_en_d_c <= 'b0;
        fifo_wr_en_d_o <= 'b0;

        fifo_rd_en_d_o <= 'b0;
    end else begin
        for (int k = 0; k < 2; k++) begin
            fifo_wr_en_d_c[k] <= ~(|comp_done_d[k]) ? 'b1 : fifo_wr_en_d_o[k] ? 'b0 : fifo_wr_en_d_c[k];
            fifo_wr_en_d_o[k] <= ~fifo_wr_en_d_o[k] & fifo_wr_en_d_c[k] & &comp_done_d[k];
        end

        comp_done_t <= fifo_rd_en_d_o;
        comp_done_o <= |comp_done_t;

        for (int i = 0; i < 6; i++) begin
            comp_data_o[i] <= comp_done_t[1] ? comp_data_d_o[1][i] : comp_data_d_o[0][i];
        end

        comp_data_index_o <= comp_done_t[1] ? comp_data_index_d_o[1] : comp_data_index_d_o[0];

        if (!fifo_rd_empty_d_o[0]) begin
            fifo_rd_en_d_o[1] <= 'b0;
            fifo_rd_en_d_o[0] <= !fifo_rd_en_d_o[0];
        end else begin
            if (!fifo_rd_empty_d_o[1]) begin
                fifo_rd_en_d_o[1] <= !fifo_rd_en_d_o[1];
                fifo_rd_en_d_o[0] <= 'b0;
            end else begin
                fifo_rd_en_d_o <= 'b0;
            end
        end
    end
end

endmodule
