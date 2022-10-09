/*
 * div_64b.sv
 *
 *  Created on: 2022-10-09 15:33
 *      Author: Jack Chen <redchenjs@live.com>
 */

`timescale 1 ns / 1 ps

module div_64b(
    input logic clk_i,
    input logic rst_n_i,

    input  logic init_i,
    output logic done_o,

    input logic [63:0] divided_i,
    input logic [63:0] divisor_i,

    output logic [63:0] quotient_o,
    output logic [63:0] remainder_o
);

always_comb begin
    if (rst_n_i) begin
        case (data_i) inside
            8'b1???_????:
                data_o = 8'b1000_0000;
            8'b01??_????:
                data_o = 8'b0100_0000;
            8'b001?_????:
                data_o = 8'b0010_0000;
            8'b0001_????:
                data_o = 8'b0001_0000;
            8'b0000_1???:
                data_o = 8'b0000_1000;
            8'b0000_01??:
                data_o = 8'b0000_0100;
            8'b0000_001?:
                data_o = 8'b0000_0010;
            8'b0000_0001:
                data_o = 8'b0000_0001;
            default:
                data_o = 8'b0000_0000;
        endcase
    end else begin
        data_o = 8'b0000_0000;
    end
end

endmodule
