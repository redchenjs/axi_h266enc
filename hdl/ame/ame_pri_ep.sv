/*
 * ame_pri_ep.sv
 *
 *  Created on: 2022-08-31 22:55
 *      Author: Jack Chen <redchenjs@live.com>
 */

`timescale 1 ns / 1 ps

module ame_pri_ep (
    input logic rst_n_i,

    input logic [1:0] carry_i,

    input  logic [7:0] data_i,
    output logic [7:0] data_o
);

always_comb begin
    if (rst_n_i) begin
        case ({data_i, carry_i}) inside
            10'b10??_????_??: // BIT 7 UPPER HALF
                data_o = 8'b1000_0000;
            10'b011?_????_??: // BIT 7 LOWER HALF
                data_o = 8'b1000_0000;
            10'b010?_????_??: // BIT 6 UPPER HALF
                data_o = 8'b0100_0000;
            10'b0011_????_??: // BIT 6 LOWER HALF
                data_o = 8'b0100_0000;
            10'b0010_????_??: // BIT 5 UPPER HALF
                data_o = 8'b0010_0000;
            10'b0001_1???_??: // BIT 5 LOWER HALF
                data_o = 8'b0010_0000;
            10'b0001_0???_??: // BIT 4 UPPER HALF
                data_o = 8'b0001_0000;
            10'b0000_11??_??: // BIT 4 LOWER HALF
                data_o = 8'b0001_0000;
            10'b0000_10??_??: // BIT 3 UPPER HALF
                data_o = 8'b0000_1000;
            10'b0000_011?_??: // BIT 3 LOWER HALF
                data_o = 8'b0000_1000;
            10'b0000_010?_??: // BIT 2 UPPER HALF
                data_o = 8'b0000_0100;
            10'b0000_0011_??: // BIT 2 LOWER HALF
                data_o = 8'b0000_0100;
            10'b0000_0010_??: // BIT 1 UPPER HALF
                data_o = 8'b0000_0010;
            10'b0000_0001_1?: // BIT 1 LOWER HALF
                data_o = 8'b0000_0010;
            10'b0000_0001_0?: // BIT 0 UPPER HALF
                data_o = 8'b0000_0001;
            10'b0000_0000_11: // BIT 0 LOWER HALF
                data_o = 8'b0000_0001;
            default:
                data_o = 8'b0000_0000;
        endcase
    end else begin
        data_o = 8'b0000_0000;
    end
end

endmodule
