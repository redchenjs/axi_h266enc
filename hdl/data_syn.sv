/*
 * data_syn.sv
 *
 *  Created on: 2021-06-09 16:38
 *      Author: Jack Chen <redchenjs@live.com>
 */

module data_syn(
    input logic clk_i,
    input logic rst_n_i,

    input logic data_i,

    output logic data_o
);

logic data_a, data_b;

assign data_o = data_b;

always_ff @(posedge clk_i or negedge rst_n_i)
begin
    if (!rst_n_i) begin
        data_a <= 1'b0;
        data_b <= 1'b0;
    end else begin
        data_a <= data_i;
        data_b <= data_a;
    end
end

endmodule
