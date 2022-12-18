/*
 * axi_h266enc.sv
 *
 *  Created on: 2022-07-16 22:00
 *      Author: Jack Chen <redchenjs@live.com>
 */

`timescale 1 ns / 1 ps

module axi_h266enc(
    input logic s_axi_aclk,
    input logic s_axi_aresetn,

    input  logic [31:0] s_axi_awaddr,
    input  logic        s_axi_awvalid,
    output logic        s_axi_awready,

    input  logic [63:0] s_axi_wdata,
    input  logic        s_axi_wvalid,
    output logic        s_axi_wready,

    output logic s_axi_bvalid,
    input  logic s_axi_bready,

    input  logic [31:0] s_axi_araddr,
    input  logic        s_axi_arvalid,
    output logic        s_axi_arready,

    output logic [63:0] s_axi_rdata,
    output logic        s_axi_rvalid,
    input  logic        s_axi_rready,

    input logic m_axi_aclk,
    input logic m_axi_aresetn,

    output logic [31:0] m_axi_awaddr,
    output logic  [7:0] m_axi_awlen,
    output logic  [2:0] m_axi_awsize,
    output logic  [1:0] m_axi_awburst,
    output logic        m_axi_awlock,
    output logic  [3:0] m_axi_awcache,
    output logic  [2:0] m_axi_awprot,
    output logic  [3:0] m_axi_awqos,
    output logic        m_axi_awvalid,
    input  logic        m_axi_awready,

    output logic [63:0] m_axi_wdata,
    output logic  [7:0] m_axi_wstrb,
    output logic        m_axi_wlast,
    output logic        m_axi_wvalid,
    input  logic        m_axi_wready,

    input  logic [1:0] m_axi_bresp,
    input  logic       m_axi_bvalid,
    output logic       m_axi_bready
);

logic [31:0] axi_awaddr_base;

logic [31:0] axi_awaddr;
logic        axi_awvalid;

logic [63:0] axi_wdata;
logic        axi_wvalid;

logic axi_bready;

assign s_axi_awready = s_axi_aresetn && s_axi_awvalid && (!s_axi_bvalid || s_axi_bready);
assign s_axi_wready  = s_axi_aresetn && s_axi_wvalid  && (!s_axi_bvalid || s_axi_bready);
assign s_axi_arready = s_axi_aresetn && s_axi_arvalid && (!s_axi_rvalid || s_axi_rready);

assign m_axi_awaddr  = axi_awaddr_base + axi_awaddr;
assign m_axi_awlen   = 0;
assign m_axi_awsize  = 3'h2;
assign m_axi_awburst = 2'h1;
assign m_axi_awlock  = 1'b0;
assign m_axi_awcache = 4'h2;
assign m_axi_awprot  = 3'h0;
assign m_axi_awqos   = 4'h0;
assign m_axi_awvalid = axi_awvalid;

assign m_axi_wdata  = axi_wdata;
assign m_axi_wstrb  = 8'hff;
assign m_axi_wlast  = axi_wvalid;
assign m_axi_wvalid = axi_wvalid;

assign m_axi_bready	= axi_bready;

parameter COMP_DATA_BITS = 64;
parameter COMP_DATA_IDX_BITS = 3;

logic comp_init_i;
logic comp_done_o;

logic affine_param6_i;

// 4 x 5 Integer Input              // 6 x 7 Integer Input
// --- --- --- --- --- --- | --     // --- --- --- --- --- --- | --
// --- --- --- --- --- --- | --     // A00 A01 A02 A03 A04 A05 | B0
// --- --- --- --- --- --- | --     // A10 A11 A12 A13 A14 A15 | B1
// --- --- A22 A23 A24 A25 | B2     // A20 A21 A22 A23 A24 A25 | B2
// --- --- A32 A33 A34 A35 | B3     // A30 A31 A32 A33 A34 A35 | B3
// --- --- A42 A43 A44 A45 | B4     // A40 A41 A42 A43 A44 A45 | B4
// --- --- A52 A53 A54 A55 | B5     // A50 A51 A52 A53 A54 A55 | B5
// --- --- --- --- --- --- | --     // --- --- --- --- --- --- | --
logic [5:0] [6:0] [COMP_DATA_BITS-1:0] comp_data_i;

// 4 Fixed Point Results            // 6 Fixed Point Results
// --- --- --- --- --- --- | --     // --- --- --- --- --- --- | --
//  --  --  X2  X3  X4  X5 | --     //  X0  X1  X2  X3  X4  X5 | --
// --- --- --- --- --- --- | --     // --- --- --- --- --- --- | --
logic [5:0] [COMP_DATA_BITS-1:0] comp_data_o;

always_ff @(posedge s_axi_aclk or negedge s_axi_aresetn)
begin
    if (!s_axi_aresetn) begin
        axi_awaddr_base <= 'b0;

        comp_init_i <= 'b0;
        comp_data_i <= 'b0;

        affine_param6_i <= 'b0;

        s_axi_bvalid <= 'b0;
        s_axi_rvalid <= 'b0;

        s_axi_rdata <= 'b0;
    end else begin
        comp_data_i <= 'b0;

        if (s_axi_awready) begin
            case (s_axi_awaddr[9:0]) inside
                10'h000:
                    axi_awaddr_base <= s_axi_wdata[31:0];
                10'h008:
                    {affine_param6_i, comp_init_i} <= s_axi_wdata[1:0];
                10'h2??:
                    if ((s_axi_awaddr[9:0]) < 42 * 8) begin
                        comp_data_i[s_axi_awaddr[9:0] / 7][s_axi_awaddr[9:0] % 7] <= s_axi_wdata;
                    end
            endcase
        end

        if (s_axi_arready) begin
            case (s_axi_araddr[9:0]) inside
                10'h000:
                    s_axi_rdata <= {32'b0, axi_awaddr_base};
                10'h008:
                    s_axi_rdata <= {62'b0, affine_param6_i, comp_init_i};
                10'h010:
                    s_axi_rdata <= comp_data_o[0];
                10'h018:
                    s_axi_rdata <= comp_data_o[1];
                10'h020:
                    s_axi_rdata <= comp_data_o[2];
                10'h028:
                    s_axi_rdata <= comp_data_o[3];
                10'h030:
                    s_axi_rdata <= comp_data_o[4];
                10'h038:
                    s_axi_rdata <= comp_data_o[5];
                10'h2??:
                    if ((s_axi_araddr[9:0]) < 42 * 8) begin
                        s_axi_rdata <= comp_data_i[s_axi_awaddr[9:0] / 7][s_axi_awaddr[9:0] % 7];
                    end else begin
                        s_axi_rdata <= 'b0;
                    end
                default:
                    s_axi_rdata <= 'b0;
            endcase
        end

        s_axi_bvalid <= (s_axi_bvalid & ~s_axi_bready) | s_axi_awready;
        s_axi_rvalid <= (s_axi_rvalid & ~s_axi_rready) | s_axi_arready;
    end
end

always_ff @(posedge s_axi_aclk or negedge s_axi_aresetn)
begin
    if (!s_axi_aresetn) begin
        axi_awaddr  <= 'b0;
        axi_awvalid <= 'b0;

        axi_wdata  <= 'b0;
        axi_wvalid <= 'b0;

        axi_bready <= 'b0;
    end else begin
        axi_awaddr  <= axi_awaddr;
        axi_awvalid <= axi_awvalid;

        axi_wdata  <= axi_wdata;
        axi_wvalid <= axi_wvalid;

        axi_bready <= (m_axi_bvalid & ~axi_bready);
    end
end

ame_equation_solver #(
    .COMP_DATA_BITS(COMP_DATA_BITS),
    .COMP_DATA_IDX_BITS(COMP_DATA_IDX_BITS)
) ame_equation_solver (
    .clk_i(s_axi_aclk),
    .rst_n_i(s_axi_aresetn),

    .comp_init_i(comp_init_i),
    .comp_done_o(comp_done_o),

    .affine_param6_i(affine_param6_i),

    .comp_data_i(comp_data_i),
    .comp_data_o(comp_data_o)
);

endmodule
