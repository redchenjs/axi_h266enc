/*
 * ame_equal_coeff.sv
 *
 *  Created on: 2022-07-18 11:38
 *      Author: Jack Chen <redchenjs@live.com>
 */

`timescale 1 ns / 1 ps

module ame_equal_coeff #(
    parameter LINE_DATA_BITS = 7,
    parameter COMP_DATA_BITS = 8
) (
    input logic clk_i,
    input logic rst_n_i,

    input  logic comp_init_i,
    output logic comp_done_o,

    // 6 Pixel Buffer Input
    // Horizontal Sobel Filter: Use Veritcal Memory
    // Vertical Sobel Filter: Use Horizontal Memory
    input logic [5:0] [LINE_DATA_BITS-1:0] line_data_i,

    // 4 x 4 = 16 Results
    output logic [3:0] [3:0] [COMP_DATA_BITS-1:0] comp_data_o
);

typedef enum logic [2:0] {
    IDLE   = 3'b000,
    COMP_1 = 3'b001,
    COMP_2 = 3'b010,
    COMP_3 = 3'b011,
    COMP_4 = 3'b100,
    COMP_5 = 3'b101,
    COMP_6 = 3'b110
} state_t;

state_t ctl_sta;

logic [5:0] [1:0] [COMP_DATA_BITS-1:0] line_data;
logic [3:0] [3:0] [COMP_DATA_BITS-1:0] comp_data;

typedef enum logic {
    DATA_1 = 1'b0,
    DATA_2 = 1'b1
} comp_data_t;

generate
    for (genvar i = 0; i < 6; i++) begin: comp_block
        assign line_data[i][DATA_1] = line_data_i[i];
        assign line_data[i][DATA_2] = line_data_i[i] << 1;
    end
endgenerate

logic comp_done;

assign comp_done_o = comp_done;
assign comp_data_o = comp_data;

always_ff @(posedge clk_i or negedge rst_n_i)
begin
    if (!rst_n_i) begin
        ctl_sta <= IDLE;

        comp_done <= 'b0;
        comp_data <= 'b0;
    end else begin
        case (ctl_sta)
            IDLE:
                ctl_sta <= comp_init_i ? COMP_1 : ctl_sta;
            COMP_1:
                ctl_sta <= COMP_2;
            COMP_2:
                ctl_sta <= COMP_3;
            COMP_3:
                ctl_sta <= COMP_4;
            COMP_4:
                ctl_sta <= COMP_5;
            COMP_5:
                ctl_sta <= COMP_6;
            COMP_6:
                ctl_sta <= comp_init_i ? COMP_1 : IDLE;
            default:
                ctl_sta <= IDLE;
        endcase

        comp_done <= (ctl_sta == COMP_6);

        case (ctl_sta)
            IDLE:
                comp_data <= 'b0;
            COMP_1: begin
                comp_data[0][0] <= - line_data[0][DATA_1] - line_data[1][DATA_2] - line_data[2][DATA_1];
                comp_data[1][0] <= - line_data[1][DATA_1] - line_data[2][DATA_2] - line_data[3][DATA_1];
                comp_data[2][0] <= - line_data[2][DATA_1] - line_data[3][DATA_2] - line_data[4][DATA_1];
                comp_data[3][0] <= - line_data[3][DATA_1] - line_data[4][DATA_2] - line_data[5][DATA_1];
            end
            COMP_2: begin
                comp_data[0][1] <= - line_data[0][DATA_1] - line_data[1][DATA_2] - line_data[2][DATA_1];
                comp_data[1][1] <= - line_data[1][DATA_1] - line_data[2][DATA_2] - line_data[3][DATA_1];
                comp_data[2][1] <= - line_data[2][DATA_1] - line_data[3][DATA_2] - line_data[4][DATA_1];
                comp_data[3][1] <= - line_data[3][DATA_1] - line_data[4][DATA_2] - line_data[5][DATA_1];
            end
            COMP_3: begin
                comp_data[0][0] <= comp_data[0][0] + line_data[0][DATA_1] + line_data[1][DATA_2] + line_data[2][DATA_1];
                comp_data[1][0] <= comp_data[1][0] + line_data[1][DATA_1] + line_data[2][DATA_2] + line_data[3][DATA_1];
                comp_data[2][0] <= comp_data[2][0] + line_data[2][DATA_1] + line_data[3][DATA_2] + line_data[4][DATA_1];
                comp_data[3][0] <= comp_data[3][0] + line_data[3][DATA_1] + line_data[4][DATA_2] + line_data[5][DATA_1];

                comp_data[0][2] <= - line_data[0][DATA_1] - line_data[1][DATA_2] - line_data[2][DATA_1];
                comp_data[1][2] <= - line_data[1][DATA_1] - line_data[2][DATA_2] - line_data[3][DATA_1];
                comp_data[2][2] <= - line_data[2][DATA_1] - line_data[3][DATA_2] - line_data[4][DATA_1];
                comp_data[3][2] <= - line_data[3][DATA_1] - line_data[4][DATA_2] - line_data[5][DATA_1];
            end
            COMP_4: begin
                comp_data[0][1] <= comp_data[0][1] + line_data[0][DATA_1] + line_data[1][DATA_2] + line_data[2][DATA_1];
                comp_data[1][1] <= comp_data[1][1] + line_data[1][DATA_1] + line_data[2][DATA_2] + line_data[3][DATA_1];
                comp_data[2][1] <= comp_data[2][1] + line_data[2][DATA_1] + line_data[3][DATA_2] + line_data[4][DATA_1];
                comp_data[3][1] <= comp_data[3][1] + line_data[3][DATA_1] + line_data[4][DATA_2] + line_data[5][DATA_1];

                comp_data[0][3] <= - line_data[0][DATA_1] - line_data[1][DATA_2] - line_data[2][DATA_1];
                comp_data[1][3] <= - line_data[1][DATA_1] - line_data[2][DATA_2] - line_data[3][DATA_1];
                comp_data[2][3] <= - line_data[2][DATA_1] - line_data[3][DATA_2] - line_data[4][DATA_1];
                comp_data[3][3] <= - line_data[3][DATA_1] - line_data[4][DATA_2] - line_data[5][DATA_1];
            end
            COMP_5: begin
                comp_data[0][2] <= comp_data[0][2] + line_data[0][DATA_1] + line_data[1][DATA_2] + line_data[2][DATA_1];
                comp_data[1][2] <= comp_data[1][2] + line_data[1][DATA_1] + line_data[2][DATA_2] + line_data[3][DATA_1];
                comp_data[2][2] <= comp_data[2][2] + line_data[2][DATA_1] + line_data[3][DATA_2] + line_data[4][DATA_1];
                comp_data[3][2] <= comp_data[3][2] + line_data[3][DATA_1] + line_data[4][DATA_2] + line_data[5][DATA_1];
            end
            COMP_6: begin
                comp_data[0][3] <= comp_data[0][3] + line_data[0][DATA_1] + line_data[1][DATA_2] + line_data[2][DATA_1];
                comp_data[1][3] <= comp_data[1][3] + line_data[1][DATA_1] + line_data[2][DATA_2] + line_data[3][DATA_1];
                comp_data[2][3] <= comp_data[2][3] + line_data[2][DATA_1] + line_data[3][DATA_2] + line_data[4][DATA_1];
                comp_data[3][3] <= comp_data[3][3] + line_data[3][DATA_1] + line_data[4][DATA_2] + line_data[5][DATA_1];
            end
            default:
                comp_data <= 'b0;
        endcase
    end
end

endmodule
