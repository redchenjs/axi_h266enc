/*
 * ame_pri_8b.sv
 *
 *  Created on: 2022-08-31 22:55
 *      Author: Jack Chen <redchenjs@live.com>
 */

`timescale 1 ns / 1 ps

module ame_pri_8b (
    input logic rst_n_i,

    input  logic carry_i,
    output logic carry_o,

    input  logic [7:0] data_i,
    output logic [7:0] data_o
);

always_comb begin
    if (rst_n_i) begin
        case (data_i + {7'b0, carry_i}) inside
            9'b1_????_????: // BIT 8 CARRY OUT
                {carry_o, data_o} = 9'b1_1000_0000;
            9'b0_11??_????: // BIT 7 UPPER HALF
                {carry_o, data_o} = 9'b1_1000_0000;
            9'b0_10??_????: // BIT 7 LOWER HALF
                {carry_o, data_o} = 9'b0_1000_0000;
            9'b0_011?_????: // BIT 6 UPPER HALF
                {carry_o, data_o} = 9'b0_1000_0000;
            9'b0_010?_????: // BIT 6 LOWER HALF
                {carry_o, data_o} = 9'b0_0100_0000;
            9'b0_0011_????: // BIT 5 UPPER HALF
                {carry_o, data_o} = 9'b0_0100_0000;
            9'b0_0010_????: // BIT 5 LOWER HALF
                {carry_o, data_o} = 9'b0_0010_0000;
            9'b0_0001_1???: // BIT 4 UPPER HALF
                {carry_o, data_o} = 9'b0_0010_0000;
            9'b0_0001_0???: // BIT 4 LOWER HALF
                {carry_o, data_o} = 9'b0_0001_0000;
            9'b0_0000_11??: // BIT 3 UPPER HALF
                {carry_o, data_o} = 9'b0_0001_0000;
            9'b0_0000_10??: // BIT 3 LOWER HALF
                {carry_o, data_o} = 9'b0_0000_1000;
            9'b0_0000_011?: // BIT 2 UPPER HALF
                {carry_o, data_o} = 9'b0_0000_1000;
            9'b0_0000_010?: // BIT 2 LOWER HALF
                {carry_o, data_o} = 9'b0_0000_0100;
            9'b0_0000_0011: // BIT 1 UPPER HALF
                {carry_o, data_o} = 9'b0_0000_0100;
            9'b0_0000_0010: // BIT 1 LOWER HALF
                {carry_o, data_o} = 9'b0_0000_0010;
            9'b0_0000_0001: // BIT 0 UPPER HALF
                {carry_o, data_o} = 9'b0_0000_0001;
            default:
                {carry_o, data_o} = 9'b0_0000_0000;
        endcase
    end else begin
        {carry_o, data_o} = 9'b0_0000_0000;
    end
end

endmodule
