/////////////////////////////////////////////////////////////////////
//
// Title: mac.sv
// Student: Minh Quang Nguyen 20190723
//
/////////////////////////////////////////////////////////////////////


`timescale 1 ns / 1 ps

module MacArray
#(
    parameter MAC_ROW                                                   = 16,
    parameter MAC_COL                                                   = 16,
    parameter IFMAP_BITWIDTH                                            = 16,
    parameter W_BITWIDTH                                                = 8,
    parameter OFMAP_BITWIDTH                                            = 32
)
(
    input  logic                                                        clk,
    input  logic                                                        rstn,

    input  logic                                                        w_prefetch_in,
    input  logic                                                        w_enable_in,
    input  logic [MAC_COL-1:0][W_BITWIDTH-1:0]                          w_data_in,

    input  logic                                                        ifmap_start_in,
    input  logic [MAC_ROW-1:0]                                          ifmap_enable_in,
    input  logic [MAC_ROW-1:0][IFMAP_BITWIDTH-1:0]                      ifmap_data_in,

    output logic [MAC_COL-1:0]                                          ofmap_valid_out,
    output logic [MAC_COL-1:0][OFMAP_BITWIDTH-1:0]                      ofmap_data_out
);

    /////// LOCAL REGISTERS  ///////
    logic [MAC_COL-1:0][MAC_ROW-1:0]                                    mac_I_en;
    logic [MAC_COL-1:0][MAC_ROW-1:0]                                    mac_I_ready;
    logic [MAC_COL-1:0][MAC_ROW-1:0][IFMAP_BITWIDTH-1:0]                mac_I_in;
    logic [MAC_COL-1:0][MAC_ROW-1:0][IFMAP_BITWIDTH-1:0]                mac_I_out;

    logic [MAC_COL-1:0][MAC_ROW-1:0]                                    mac_W_en;
    logic [MAC_COL-1:0][MAC_ROW-1:0]                                    mac_W_ready;
    logic [MAC_COL-1:0][MAC_ROW-1:0][W_BITWIDTH-1:0]                    mac_W_in;
    logic [MAC_COL-1:0][MAC_ROW-1:0][W_BITWIDTH-1:0]                    mac_W_out;

    logic [MAC_COL-1:0][MAC_ROW-1:0][OFMAP_BITWIDTH-1:0]                mac_P_in;
    logic [MAC_COL-1:0][MAC_ROW-1:0][OFMAP_BITWIDTH-1:0]                mac_P_out;
    logic                                                               bias; // ignore in this project, set to 0

    /////// GENERATE THE (MAC_COL x MAC_ROW) MAC ARRAY  ///////
    genvar i, j;
    generate
        for (i = 0; i< MAC_COL; i = i+1) begin
            for (j=0; j< MAC_ROW; j = j+1) begin
                mac #(.IFMAP_BITWIDTH(IFMAP_BITWIDTH), .W_BITWIDTH(W_BITWIDTH), .OFMAP_BITWIDTH(OFMAP_BITWIDTH))
                mac_i_j ( .clk(clk), .rstn(rstn), .I_en(mac_I_en[i][j]),
                    .I_ready(mac_I_ready[i][j]), .I_in(mac_I_in[i][j]), .I_out(mac_I_out[i][j]),
                    .W_en(mac_W_en[i][j]), .W_ready(mac_W_ready[i][j]), .W_in(mac_W_in[i][j]),
                    .W_out(mac_W_out[i][j]), .P_in(mac_P_in[i][j]), .P_out(mac_P_out[i][j]));
            end
        end
    endgenerate

    /////// COMBINATIONAL LOGIC ///////
    integer r, c;
    always_comb begin
        for (r = 0; r < MAC_ROW; r = r+1) begin
            for (c = 0; c < MAC_COL; c = c+1) begin

                if (c == 0) begin
                    mac_I_en[c][r] = ifmap_enable_in[r];
                    mac_I_in[c][r] = ifmap_data_in[r];
                end else begin
                    mac_I_en[c][r] = mac_I_ready[c-1][r];
                    mac_I_in[c][r] = mac_I_out[c-1][r];
                end

                if (r == 0) begin
                    mac_W_en[c][r] = w_enable_in;
                    mac_W_in[c][r] = w_data_in[c];
                    mac_P_in[c][r] = bias;
                end else begin
                    mac_W_en[c][r] = w_enable_in & mac_W_ready[c][r-1];
                    mac_W_in[c][r] = mac_W_out[c][r-1];
                    mac_P_in[c][r] = mac_P_out[c][r-1];
                end
            end
        end

        for (c = 0; c < MAC_COL; c = c+1) begin
            ofmap_valid_out[c] = mac_I_ready[c][MAC_ROW-1];
            ofmap_data_out[c] = mac_P_out[c][MAC_ROW-1];
        end

    end

    /////// SEQUENCIAL LOGIC ///////
    integer a, b;
    always_ff @(posedge clk) begin
        if (!rstn) begin
            bias                    <= 0;
            ofmap_valid_out         <= 0;

            for (a = 0; a < MAC_COL; a = a+1) begin
                mac_I_en[a]         <= 0;
                mac_I_ready[a]      <= 0;
                mac_W_en[a]         <= 0;
                mac_W_ready[a]      <= 0;
                ofmap_data_out      <= 0;

                for (b = 0; b < MAC_ROW; b = c+1) begin
                    mac_I_in[a][b]  <= 0;
                    mac_I_out[a][b] <= 0;
                    mac_W_in[a][b]  <= 0;
                    mac_W_out[a][b] <= 0;
                    mac_P_in[a][b]  <= 0;
                    mac_P_out[a][b] <= 0;
                end
            end
        
        end else begin

        // for naive printout debug //
        //$display("mac_I_en: %h, ifmap_enable_in: %h, mac_I_ready: %h", mac_I_en[0], ifmap_enable_in, mac_I_ready[0]);
        //$display("mac_I_in: %h, mac_I_out: %h, ifmap_data_in = %h", mac_I_in[0], mac_I_out[0], ifmap_data_in);
        //$display("mac_W_en: %h, w_enable_in: %h, mac_W_ready: %h", mac_W_en[0], w_enable_in, mac_W_ready[0]);
        //$display("mac_W_in: %h, mac_W_out: %h, W_data_in = %h", mac_W_in[0], mac_W_out[0], w_data_in[0]);
        //$display("mac_P_in: %h, mac_P_out: %h", mac_P_in[0], mac_P_out[0]);
        end
    end

endmodule
