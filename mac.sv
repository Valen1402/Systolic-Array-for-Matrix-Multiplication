/////////////////////////////////////////////////////////////////////
//
// Title: mac.sv
// Student: Minh Quang Nguyen 20190723
//
/////////////////////////////////////////////////////////////////////

`timescale 1 ns / 1 ps

module mac #(
  parameter IFMAP_BITWIDTH   = 16,
  parameter W_BITWIDTH   = 8,
  parameter OFMAP_BITWIDTH   = 32
)
(
  input  logic                                             clk,
  input  logic                                             rstn,

  input  logic                                             I_en,
  output logic                                             I_ready,
  input  logic [IFMAP_BITWIDTH-1:0]                        I_in,
  output logic [IFMAP_BITWIDTH-1:0]                        I_out,

  input  logic                                             W_en,
  output logic                                             W_ready,
  input  logic [W_BITWIDTH-1:0]                            W_in,
  output logic [W_BITWIDTH-1:0]                            W_out,

  input  logic [OFMAP_BITWIDTH-1:0]                        P_in,
  output logic [OFMAP_BITWIDTH-1:0]                        P_out
);

  always_ff @( posedge clk) begin

    if (!rstn) begin
      I_out       <= 0;
      I_ready     <= 0;
      W_out       <= 0;
      W_ready     <= 0;
      P_out       <= 0;

    end else begin
      if (W_en) begin
        W_out     <= W_in;
        W_ready   <= 1;
      end else begin
        W_ready   <= 0;
      end

      if (I_en) begin
        I_out     <= I_in;
        I_ready   <= 1;
        P_out     <= P_in + {{24{W_out[W_BITWIDTH-1]}}, W_out[W_BITWIDTH-1:0]} * {{16{I_in[IFMAP_BITWIDTH-1]}}, I_in[IFMAP_BITWIDTH-1:0]};

      end else begin
        I_ready   <= 0;
      end
    end
  end

endmodule
