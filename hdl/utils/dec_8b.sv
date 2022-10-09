/*
 * dec_8b.sv
 *
 *  Created on: 2022-10-09 18:44
 *      Author: Jack Chen <redchenjs@live.com>
 */

`timescale 1 ns / 1 ps

module dec_8b(
    input logic rst_n_i,

    input  logic [2:0] data_i,
    output logic [7:0] data_o
);

always_comb begin
    if (rst_n_i) begin
        case (data_i) inside
            3'b111:
                data_o = 8'b1000_0000;
            3'b110:
                data_o = 8'b0100_0000;
            3'b101:
                data_o = 8'b0010_0000;
            3'b100:
                data_o = 8'b0001_0000;
            3'b011:
                data_o = 8'b0000_1000;
            3'b010:
                data_o = 8'b0000_0100;
            3'b001:
                data_o = 8'b0000_0010;
            3'b000:
                data_o = 8'b0000_0001;
            default:
                data_o = 8'b0000_0000;
        endcase
    end else begin
        data_o = 8'b0000_0000;
    end
end

endmodule
