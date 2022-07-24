/*
 * fifo_async.sv
 *
 *  Created on: 2022-04-07 20:52
 *      Author: Jack Chen <redchenjs@live.com>
 */

module fifo_async #(
    parameter WIDTH = 8,
    parameter DEPTH = 12,
    parameter ABITS = 4
) (
    input  logic             in_clk,
    input  logic             in_resetn,
    input  logic             in_enable,
    input  logic [WIDTH-1:0] in_data,
    output logic [ABITS-1:0] in_free,

    input  logic             out_clk,
    input  logic             out_resetn,
    input  logic             out_enable,
    output logic [WIDTH-1:0] out_data,
    output logic [ABITS-1:0] out_avail
);

logic [WIDTH-1:0] fifo [0:DEPTH-1];
logic [ABITS-1:0] in_ptr, in_ptr_gray;
logic [ABITS-1:0] out_ptr, out_ptr_gray;

logic [ABITS-1:0] out_ptr_for_in_clk, in_ptr_for_out_clk;
logic [ABITS-1:0] sync_in_ptr_0, sync_out_ptr_0;
logic [ABITS-1:0] sync_in_ptr_1, sync_out_ptr_1;
logic [ABITS-1:0] sync_in_ptr_2, sync_out_ptr_2;

function [ABITS-1:0] bin2gray(input [ABITS-1:0] in);
    begin
        logic [ABITS:0] temp = in;
        for (integer i = 0; i < ABITS; i++) begin
            bin2gray[i] = ^temp[i +: 2];
        end
    end
endfunction

function [ABITS-1:0] gray2bin(input [ABITS-1:0] in);
    begin
        for (integer i = 0; i < ABITS; i++) begin
            gray2bin[i] = ^(in >> i);
        end
    end
endfunction

always_ff @(posedge in_clk) begin
    if (!in_resetn) begin
        in_ptr      <= 0;
        in_ptr_gray <= 0;
    end else begin
        if (in_enable) begin
            fifo[in_ptr] <= in_data;
            in_ptr       <= in_ptr + 1'b1;
            in_ptr_gray  <= bin2gray(in_ptr + 1'b1);
        end
    end

    sync_out_ptr_0 <= out_ptr_gray;
    sync_out_ptr_1 <= sync_out_ptr_0;
    sync_out_ptr_2 <= sync_out_ptr_1;
    out_ptr_for_in_clk <= gray2bin(sync_out_ptr_2);

    in_free <= DEPTH - in_ptr + out_ptr_for_in_clk - 1;
end

always_ff @(posedge out_clk) begin
    if (!out_resetn) begin
        out_ptr      <= 0;
        out_ptr_gray <= 0;
    end else begin
        if (out_enable) begin
            out_ptr      <= out_ptr + 1'b1;
            out_ptr_gray <= bin2gray(out_ptr + 1'b1);
            out_data     <= fifo[out_ptr + 1'b1];
        end else begin
            out_data <= fifo[out_ptr];
        end
    end

    sync_in_ptr_0 <= in_ptr_gray;
    sync_in_ptr_1 <= sync_in_ptr_0;
    sync_in_ptr_2 <= sync_in_ptr_1;
    in_ptr_for_out_clk <= gray2bin(sync_in_ptr_2);

    out_avail <= in_ptr_for_out_clk - out_ptr;
end

endmodule
