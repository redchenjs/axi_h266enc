/*
 * enc_8b.sv
 *
 *  Created on: 2022-10-09 16:46
 *      Author: Jack Chen <redchenjs@live.com>
 */

`timescale 1 ns / 1 ps

module enc_8b(
    input logic rst_n_i,

    input  logic [7:0] data_i,
    output logic [2:0] data_o
);

always_comb begin
    if (rst_n_i) begin
        case (data_i) inside
            8'b1000_0000:
                data_o = 3'b111;
            8'b0100_0000:
                data_o = 3'b110;
            8'b0010_0000:
                data_o = 3'b101;
            8'b0001_0000:
                data_o = 3'b100;
            8'b0000_1000:
                data_o = 3'b011;
            8'b0000_0100:
                data_o = 3'b010;
            8'b0000_0010:
                data_o = 3'b001;
            8'b0000_0001:
                data_o = 3'b000;
            default:
                data_o = 3'b000;
        endcase
    end else begin
        data_o = 3'b000;
    end
end

endmodule
