/*
 * pri_8b.sv
 *
 *  Created on: 2022-08-31 22:55
 *      Author: Jack Chen <redchenjs@live.com>
 */

`timescale 1 ns / 1 ps

module pri_8b (
    input logic rst_n_i,

    input  logic [7:0] data_i,
    output logic [7:0] data_o
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
