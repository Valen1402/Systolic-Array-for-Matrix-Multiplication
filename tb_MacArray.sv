/////////////////////////////////////////////////////////////////////
//
// Title: MacArray.sv
// Author: Jung-hoon Kim
//
/////////////////////////////////////////////////////////////////////

`timescale 1 ns / 1 ps

//`define DEBUG

module tb_MacArray;

    parameter MAC_ROW                               = 16;
    parameter MAC_COL                               = 16;


    parameter IFMAP_BITWIDTH                        = 16;
    `ifdef DEBUG
    parameter IFMAP_NUM                             = 10;
    `else
    parameter IFMAP_NUM                             = 1024;
    `endif

    parameter W_BITWIDTH                            = 8;
    parameter W_WIDTH                               = 16;
    parameter W_HEIGHT                              = 16;

    parameter OFMAP_BITWIDTH                        = 32;
    `ifdef DEBUG
    parameter OFMAP_NUM                             = 10;
    `else
    parameter OFMAP_NUM                             = 1024;
    `endif

    const time CLK_PERIOD                           = 10ns;
    const time CLK_HALF_PERIOD                      = CLK_PERIOD / 2;
    const int  RESET_WAIT_CYCLES                    = 10;

    int                                             error;
    int                                             cal_data_num[MAC_COL-1:0];

/////////////////////////////////////////////////////////////////////

    logic                                           clk;
    logic                                           rstn;
    logic [MAC_COL-1:0]                             cal_done; // column done

    logic                                           w_prefetch_in;
    logic                                           w_enable_in;
    logic [W_BITWIDTH-1:0]                          w_data[MAC_COL-1:0][MAC_ROW-1:0];
    logic [MAC_COL-1:0][W_BITWIDTH-1:0]             w_data_in;

    logic                                           ifmap_start_in;
    logic [MAC_ROW-1:0]                             ifmap_enable_in;
    logic [IFMAP_BITWIDTH-1:0]                      ifmap_data[MAC_ROW-1:0][IFMAP_NUM-1:0];
    logic [MAC_ROW-1:0][IFMAP_BITWIDTH-1:0]         ifmap_data_in;

    logic [MAC_COL-1:0]                             ofmap_valid_out;
    logic [OFMAP_BITWIDTH-1:0]                      ofmap_data[MAC_COL-1:0][OFMAP_NUM-1:0];
    logic [MAC_COL-1:0][OFMAP_BITWIDTH-1:0]         ofmap_data_out;
    logic [OFMAP_BITWIDTH-1:0]                      ref_ofmap_data[MAC_COL-1:0];

/////////////////////////////////////////////////////////////////////
// Function

    function [15:0] decimal_to_ascii (input [31:0] num_in);
        logic [7:0]                                 num_10;
        logic [7:0]                                 num_1;

        num_10                                      = num_in / 10;
        num_1                                       = num_in % 10;

        num_10                                      = "0" + num_10;
        num_1                                       = "0" + num_1;

        decimal_to_ascii                            = {num_10, num_1};
    endfunction

/////////////////////////////////////////////////////////////////////
// Task

    task automatic w_prefetch;
    begin

        $display("Prefetch Start");
        w_enable_in                                 = 1'b1;

        for (int r = 0; r < MAC_ROW; r++) begin: ROW_W_PREFETCH
            for (int c = 0; c < MAC_COL; c++) begin: COL_W_PREFETCH
                w_data_in[c]                        = w_data[c][MAC_ROW-1-r];
            end
            @(posedge clk);
        end

        w_enable_in                                 = 1'b0;
    end
    endtask

    task automatic ifmap_feed;
    begin

        $display("ifmap feeding Start");

        for (int r = 0; r < MAC_ROW; r++) begin: ROW_IF_FEED
            automatic int auto_r = r;

            fork
                begin
                    row_ifmap_feed(auto_r);
                end
            join_none
        end
    end
    endtask

    task automatic row_ifmap_feed(int row_index);
    begin
        repeat(row_index) @(posedge clk);
        ifmap_enable_in[row_index]                  = 1'b1;

        for (int n = 0; n < IFMAP_NUM; n++) begin: IF_FEED
            ifmap_data_in[row_index]                = ifmap_data[row_index][n];
            @(posedge clk);
        end

        ifmap_enable_in[row_index]                  = 1'b0;
    end
    endtask

    task automatic err_check;
    begin

        $display("Error Check Start");

        for (int c = 0; c < MAC_COL; c++) begin: COL_CHECK
            automatic int auto_c = c;
            cal_data_num[c]                         = 0;

            fork
                cal_err_check(auto_c);
            join_none
        end

        wait fork;

        $display("Error Count Result: %0d", error);
        if (error== 0) $display("Successfully Completed");
        else $display("Successfully Failed");
        #20;

        $stop;
    end
    endtask

    task automatic cal_err_check(int cal_index);
    begin
        while (!cal_done[cal_index]) begin

            if (ofmap_valid_out[cal_index]) begin
                if (ref_ofmap_data[cal_index] != ofmap_data_out[cal_index]) error++;
                cal_data_num[cal_index]++;
            end

            cal_done[cal_index]                     = cal_data_num[cal_index] == OFMAP_NUM;

            @(posedge clk);
        end
    end    
    endtask

/////////////////////////////////////////////////////////////////////
// Test

    initial begin
        clk                                         = 1'b0;
        fork
            forever #CLK_HALF_PERIOD clk            = ~clk;
        join
    end

    initial begin
        cal_done                                    = {MAC_COL{1'b0}};
        w_enable_in                                 = 1'b0;
        ifmap_enable_in                             = {MAC_ROW{1'b0}};
    end

    initial begin
        rstn                                        = 1'b0;
        w_prefetch_in                               = 1'b0;
        ifmap_start_in                              = 1'b0;
        repeat(RESET_WAIT_CYCLES) @(posedge clk);
        rstn                                        = 1'b1;

        repeat(2) @(posedge clk);

        w_prefetch_in                               = 1'b1;
        @(posedge clk)
        w_prefetch_in                               = 1'b0;

        w_prefetch();

        ifmap_start_in                              = 1'b1;
        @(posedge clk)
        ifmap_start_in                              = 1'b0;

        ifmap_feed();

        while(|ofmap_valid_out) @(posedge clk);
        err_check();
    end

    genvar i;
    generate
        for (i = 0; i < MAC_COL; i++) begin : loop_of_ref
            assign ref_ofmap_data[i]                = ofmap_data[i][cal_data_num[i]];
        end
    endgenerate

/////////////////////////////////////////////////////////////////////
// Data read

    genvar j, k;
    generate
        for (j = 0; j < MAC_COL; j++) begin : loop_w_of
            `ifdef DEBUG
            localparam W_FILE_NAME                  = {"/home/members/yi/quang/ee426 assign 1/data/", "debug_weight", decimal_to_ascii(j), ".hex"};
            localparam OFMAP_FILE_NAME              = {"/home/members/yi/quang/ee426 assign 1/data/", "debug_ofmap", decimal_to_ascii(j), ".hex"};
            `else
            localparam W_FILE_NAME                  = {"/home/members/yi/quang/ee426 assign 1/data/", "weight", decimal_to_ascii(j), ".hex"};
            localparam OFMAP_FILE_NAME              = {"/home/members/yi/quang/ee426 assign 1/data/", "ofmap", decimal_to_ascii(j), ".hex"};
            `endif

            initial begin
                $readmemh(W_FILE_NAME, w_data[j]);
                $readmemh(OFMAP_FILE_NAME, ofmap_data[j]);
            end
        end

        for (k = 0; k < MAC_ROW; k++) begin : loop_if
            `ifdef DEBUG
            localparam IFMAP_FILE_NAME = {"/home/members/yi/quang/ee426 assign 1/data/", "debug_ifmap", decimal_to_ascii(k), ".hex"};
            `else
            localparam IFMAP_FILE_NAME = {"/home/members/yi/quang/ee426 assign 1/data/", "ifmap", decimal_to_ascii(k), ".hex"};
            `endif

            initial begin
                $readmemh(IFMAP_FILE_NAME, ifmap_data[k]);
            end
        end
    endgenerate

/////////////////////////////////////////////////////////////////////
// ********** User Logic **********

    MacArray
    #(
        .MAC_ROW                                    ( MAC_ROW         ),
        .MAC_COL                                    ( MAC_COL         ),
        .IFMAP_BITWIDTH                             ( IFMAP_BITWIDTH  ),
        .W_BITWIDTH                                 ( W_BITWIDTH      ),
        .OFMAP_BITWIDTH                             ( OFMAP_BITWIDTH  )

    )
    DUT
    (
        .clk                                        ( clk             ),
        .rstn                                       ( rstn            ),

        .w_prefetch_in                              ( w_prefetch_in   ),
        .w_enable_in                                ( w_enable_in     ),
        .w_data_in                                  ( w_data_in       ),

        .ifmap_start_in                             ( ifmap_start_in  ),
        .ifmap_enable_in                            ( ifmap_enable_in ),
        .ifmap_data_in                              ( ifmap_data_in   ),

        .ofmap_valid_out                            ( ofmap_valid_out ),
        .ofmap_data_out                             ( ofmap_data_out  )
    );

endmodule
