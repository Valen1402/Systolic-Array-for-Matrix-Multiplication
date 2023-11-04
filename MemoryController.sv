/////////////////////////////////////////////////////////////////////
//
// Title: MemoryController.sv
//
/////////////////////////////////////////////////////////////////////

`timescale 1 ns / 1 ps

module MemoryController
#(
    // logic parameter
    parameter MAC_ROW                                           = 16,
    parameter MAC_COL                                           = 16,
    parameter W_BITWIDTH                                        = 8,
    parameter INPUT_BITWIDTH                                    = 16,
    parameter OUTPUT_BITWIDTH                                   = 32,
    parameter W_ADDR_BIT                                        = 11,
    parameter INPUT_ADDR_BIT                                    = 12,
    parameter OUTPUT_ADDR_BIT                                   = 10,
    // operation parameter
    parameter WEIGHT_ROW                                        = 64,
    parameter WEIGHT_COL                                        = 288,
    parameter INPUT_ROW                                         = 288,
    parameter INPUT_COL                                         = 196,
    parameter OUTPUT_ROW                                        = 64,
    parameter OUTPUT_COL                                        = 196
)
(
    input  logic                                                clk,
    input  logic                                                rstn,

    input  logic                                                start_in,

    input  logic                                                output_ready_in,

    output logic                                                w_prefetch_out,
    output logic [W_ADDR_BIT-1:0]                               w_addr_out,
    output logic                                                w_read_en_out,

    output logic                                                input_start_out,
    output logic [INPUT_ADDR_BIT-1:0]                           input_addr_out,
    output logic                                                input_read_en_out,

    output logic                                                mac_done_out,

    output logic [OUTPUT_ADDR_BIT-1:0]                          output_addr_out,
    output logic                                                output_write_en_out,
    output logic                                                output_write_done_out
);
    // counter for cycles in each weight prefetch (1-> 16)
    logic [3:0]                                                 w_cycle_count;
    // counter for weight tiling batches of the whole weight (1 -> 4)
    logic [1:0]                                                 w_tiling_count1;
    logic [5:0]                                                 w_tiling_count2;


    // counter for cycles in each input fetch (1-> 196)
    logic [7:0]                                                 input_cycle_count;
    // counter for how many time an input tiling is used (1-> 4)
    logic [1:0]                                                 input_tiling_count1;
    // counter for input tiling batches of the whole input (1-> 18)
    logic [5:0]                                                 input_tiling_count2;
    
    logic                                                       weight_prefetching;
    logic                                                       input_fetching;
    logic                                                       outputting;
    logic                                                       last_cycle;

    //always_comb begin
    //end

    always_ff @ (posedge clk) begin
        if (!rstn) begin
            w_prefetch_out          <= 0;
            w_addr_out              <= 0;
            w_read_en_out           <= 0;
            input_start_out         <= 0;
            input_addr_out          <= 0;
            input_read_en_out       <= 0;
            mac_done_out            <= 0;
            output_addr_out         <= 0;
            output_write_en_out     <= 0;
            output_write_done_out   <= 0;

            w_cycle_count           <= 0;
            w_tiling_count1         <= 0;
            w_tiling_count2         <= 0;
            input_cycle_count       <= 0;
            input_tiling_count1     <= 0;
            input_tiling_count2     <= 0;

            weight_prefetching      <= 0;
            input_fetching          <= 0;

        end else if (start_in) begin
            weight_prefetching      <= 1;
            w_prefetch_out          <= 1;
            w_addr_out              <= 0;
            w_read_en_out           <= 1;
            w_cycle_count           <= 0; // or 1, need to check
            w_tiling_count1         <= 0;

            input_fetching          <= 0;
            input_cycle_count       <= 0;
            input_tiling_count1     <= 0;
            input_tiling_count2     <= 0;
            last_cycle              <= 0;



        end else if (weight_prefetching) begin
            // start new weight prefetch
            w_prefetch_out          <= 0;
            w_cycle_count           <= w_cycle_count + 1;

            if (w_cycle_count != 4'hf) begin // or 4'he, need to check
                w_addr_out          <= w_addr_out + 4;
                w_read_en_out       <= 1;

            // end weight prefetching, start input fetching
            end else begin
                w_read_en_out       <= 0;
                w_tiling_count1     <= w_tiling_count1+ 1;
                weight_prefetching  <= 0;
                input_start_out     <= 1;
                input_fetching      <= 1;
                input_cycle_count   <= 0;
                input_tiling_count1 <= input_tiling_count1 + 1;
                input_read_en_out   <= 1;

                // change input tiling
                if (input_tiling_count1 == 3) begin
                    w_tiling_count2         <= w_tiling_count2 + 1;
                    
                    input_addr_out          <= input_tiling_count2;
                    input_tiling_count2     <= input_tiling_count2 + 1;

                    // last input tiling
                    if (input_tiling_count2 == 17) begin
                        last_cycle          <= 1;
                    end

                end else begin
                    input_addr_out  <= input_tiling_count2;
                end
            end

        end else if (input_fetching) begin
            input_start_out         <= 0;
            input_cycle_count       <= input_cycle_count + 1;

            if (input_cycle_count != 195) begin
                input_addr_out      <= input_addr_out + 18;

            end else begin
                input_read_en_out   <= 0;
                input_fetching      <= 0;
                if (!last_cycle) begin
                    weight_prefetching  <= 1;
                    w_prefetch_out      <= 1;
                    w_read_en_out       <= 1;

                    w_addr_out          <= w_tiling_count2 * 64 + w_tiling_count1;

                end else begin
                    mac_done_out        <= 1;
                    outputting          <= 1;
                    output_addr_out     <= 0;
                end
            end

        end else if (outputting) begin
            
        end
    end


endmodule
