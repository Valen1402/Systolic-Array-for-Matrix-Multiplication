/////////////////////////////////////////////////////////////////////
//
// Title: tb_MemoryController.sv
//
/////////////////////////////////////////////////////////////////////

`timescale 1 ns / 1 ps

module tb_MemoryController;

    // size parameter
    localparam WEIGHT_ROW                           = 64;
    localparam WEIGHT_COL                           = 288;
    localparam INPUT_ROW                            = 288;
    localparam INPUT_COL                            = 196;
    localparam OUTPUT_ROW                           = 64;
    localparam OUTPUT_COL                           = 196;
    localparam MAC_ROW                              = 16;
    localparam MAC_COL                              = 16;
    localparam W_BITWIDTH                           = 8;
    localparam INPUT_BITWIDTH                       = 16;
    localparam OUTPUT_BITWIDTH                      = 32;
    localparam W_ADDR_BIT                           = 11;
    localparam INPUT_ADDR_BIT                       = 12;
    localparam OUTPUT_ADDR_BIT                      = 10;
    // number parameter
    localparam WEIGHT_DATA_NUM                      = (WEIGHT_ROW * WEIGHT_COL)/MAC_COL;
    localparam INPUT_REF_DATA_NUM                   = (INPUT_ROW * INPUT_COL * 4)/MAC_ROW;
    localparam OUTPUT_DATA_NUM                      = (OUTPUT_ROW * OUTPUT_COL)/MAC_COL;

    int                                             weight_error;
    int                                             input_error;
    int                                             output_error;


    const time CLK_PERIOD                           = 10ns;
    const time CLK_HALF_PERIOD                      = CLK_PERIOD / 2;
    const int  RESET_WAIT_CYCLES                    = 10;

    logic                                           clk;
    logic                                           rstn;

    logic                                           start;

    logic                                           output_ready;

    logic                                           w_prefetch;
    logic [W_ADDR_BIT-1:0]                          w_addr;
    logic                                           w_read_en;

    logic                                           input_start;
    logic [INPUT_ADDR_BIT-1:0]                      input_addr;
    logic                                           input_read_en;

    logic                                           mac_done;

    logic [OUTPUT_ADDR_BIT-1:0]                     output_addr;
    logic                                           output_write_en;
    logic                                           output_write_done;

    logic                                           w_valid;
    logic [W_BITWIDTH*MAC_COL-1:0]                  w_data;
    logic [W_BITWIDTH*MAC_COL-1:0]                  w_data_ref_init[WEIGHT_DATA_NUM-1:0];
    logic [W_BITWIDTH*MAC_COL-1:0]                  w_data_ref;
    logic [$clog2(WEIGHT_DATA_NUM)-1:0]             w_data_ref_cnt;

    logic                                           input_valid;
    logic [INPUT_BITWIDTH*MAC_ROW-1:0]              input_data;
    logic [INPUT_BITWIDTH*MAC_ROW-1:0]              input_data_ref_init[INPUT_REF_DATA_NUM-1:0];
    logic [INPUT_BITWIDTH*MAC_ROW-1:0]              input_data_ref;
    logic [$clog2(INPUT_REF_DATA_NUM)-1:0]          input_data_ref_cnt;

    logic                                            output_valid;
    logic [OUTPUT_BITWIDTH*MAC_COL-1:0]              output_data_init[OUTPUT_DATA_NUM-1:0];
    logic [OUTPUT_BITWIDTH*MAC_COL-1:0]              output_data;
    logic [OUTPUT_BITWIDTH*MAC_COL-1:0]              output_data_delay;
    logic [OUTPUT_BITWIDTH*MAC_COL-1:0]              output_data_ref_init[OUTPUT_DATA_NUM-1:0];
    logic [OUTPUT_BITWIDTH*MAC_COL-1:0]              output_data_ref;
    logic [$clog2(OUTPUT_DATA_NUM)-1:0]              output_data_ref_cnt;

    initial begin
        clk                                         = 1'b0;
        fork
            forever #CLK_HALF_PERIOD clk            = ~clk;
        join
    end

    initial begin
        rstn                                        = 1'b0;
        start                                       = 1'b0;
        output_ready                                 = 1'b0;
        repeat(RESET_WAIT_CYCLES) @(posedge clk);
        rstn                                        = 1'b1;
        repeat(2) @(posedge clk);
        start                                       = 1'b1;
        @(posedge clk);
        start                                       = 1'b0;
        wait(mac_done);
        @(posedge clk);
        output_ready                                 = 1'b1;
        repeat((OUTPUT_ROW*OUTPUT_COL)/MAC_COL)@(posedge clk);
        output_ready                                 = 1'b0;
        @(posedge clk);

        if ((weight_error + input_error + output_error) == 0) begin
            $display("Sucessfully finish!!");
            $display("total error: 0");
        end
        else begin
            $display("Simulation failed...");
            $display("weight error: %d", weight_error);
            $display("input error: %d", input_error);
            $display("output error: %d", output_error);
        end

        $stop;
    end
/************************************************************
    Data Read
************************************************************/
    initial begin
        $display("Loading text file.");
        $readmemh("F:/KAIST 9th term/EE426 AI Silicon System/Project/Project 2/data/weight_systolic.hex", w_data_ref_init);
        $readmemh("F:/KAIST 9th term/EE426 AI Silicon System/Project/Project 2/data/input_systolic.hex", input_data_ref_init);
        $readmemh("F:/KAIST 9th term/EE426 AI Silicon System/Project/Project 2/data/.hex", output_data_init);
        $readmemh("F:/KAIST 9th term/EE426 AI Silicon System/Project/Project 2/data/output_systolic.hex", output_data_ref_init);
    end

/************************************************************
    Error count
************************************************************/
    always @(posedge clk) begin
        if (~rstn) begin
            w_valid                                     <= '0;
            w_data_ref_cnt                              <= '0;
        end
        else begin
            w_valid                                     <= w_read_en;
            if (w_valid) begin
                w_data_ref_cnt                          <= w_data_ref_cnt + 'd1;
            end
        end
    end

    always @(posedge clk) begin
        if (~rstn) begin
            input_valid                                 <= '0;
            input_data_ref_cnt                          <= '0;
        end
        else begin
            input_valid                                 <= input_read_en;
            if (input_valid) begin
                input_data_ref_cnt                      <= input_data_ref_cnt + 'd1;
            end
        end
    end

    always @(posedge clk) begin
        if (~rstn) begin
            output_valid                                 <= '0;
            output_data_ref_cnt                          <= '0;
            output_data_delay                            <= '0;
        end
        else begin
            output_valid                                 <= output_write_en;
            output_data_delay                            <= output_data;
            if (output_valid) begin
                output_data_ref_cnt                      <= output_data_ref_cnt + 'd1;
            end
        end
    end

    assign output_data                                   = output_data_init[output_addr];

    assign w_data_ref                                   = w_data_ref_init[w_data_ref_cnt];
    assign input_data_ref                               = input_data_ref_init[input_data_ref_cnt];
    assign output_data_ref                               = output_data_ref_init[output_data_ref_cnt];

    always @(*) begin
        if (w_valid) begin
            if (w_data_ref != w_data) begin
                weight_error++;
            end
        end
    end

    always @(*) begin
        if (input_valid) begin
            if (input_data_ref != input_data) begin
                input_error++;
            end
        end
    end


    always @(*) begin
        if (output_valid) begin
            if (output_data_ref != output_data_delay) begin
                output_error++;
            end
        end
    end

/************************************************************
    User Logic
************************************************************/
    MemoryController
    #(
        // logic parameter
        .MAC_ROW                                        (MAC_ROW          ),
        .MAC_COL                                        (MAC_COL          ),
        .W_BITWIDTH                                     (W_BITWIDTH       ),
        .INPUT_BITWIDTH                                 (INPUT_BITWIDTH   ),
        .OUTPUT_BITWIDTH                                (OUTPUT_BITWIDTH   ),
        .W_ADDR_BIT                                     (W_ADDR_BIT       ),
        .INPUT_ADDR_BIT                                 (INPUT_ADDR_BIT   ),
        .OUTPUT_ADDR_BIT                                (OUTPUT_ADDR_BIT   ),
        // operation parameter
        .WEIGHT_ROW                                     (WEIGHT_ROW     ),
        .WEIGHT_COL                                     (WEIGHT_COL    ),
        .INPUT_ROW                                      (INPUT_ROW      ),
        .INPUT_COL                                      (INPUT_COL     ),
        .OUTPUT_ROW                                     (OUTPUT_ROW      ),
        .OUTPUT_COL                                     (OUTPUT_COL     )
    )
    DUT
    (
        .clk                                            (clk),
        .rstn                                           (rstn),
        .start_in                                       (start),
        .output_ready_in                                (output_ready),
        .w_prefetch_out                                 (w_prefetch),
        .w_addr_out                                     (w_addr),
        .w_read_en_out                                  (w_read_en),
        .input_start_out                                (input_start),
        .input_addr_out                                 (input_addr),
        .input_read_en_out                              (input_read_en),
        .mac_done_out                                   (mac_done),
        .output_addr_out                                (output_addr),
        .output_write_en_out                            (output_write_en),
        .output_write_done_out                          (output_write_done)
    );

/************************************************************
    Memory
************************************************************/
    SinglePortRam
    #(
        .RAM_WIDTH                                      (W_BITWIDTH*MAC_COL),
        .RAM_ADDR_BITS                                  (W_ADDR_BIT),
        .INIT_FILE_NAME                                 ("F:/KAIST 9th term/EE426 AI Silicon System/Project/Project 2/data/weight_normal.hex")
    )
    weightRamInst
    (
        .clk                                            (clk),
        .we_in                                          (1'b0),         //only read
        .addr_in                                        (w_addr),
        .wdata_in                                       ({(W_BITWIDTH*MAC_COL){1'b0}}),
        .rdata_out                                      (w_data)
    );

    SinglePortRam
    #(
        .RAM_WIDTH                                      (INPUT_BITWIDTH*MAC_ROW),
        .RAM_ADDR_BITS                                  (INPUT_ADDR_BIT),
        .INIT_FILE_NAME                                 ("F:/KAIST 9th term/EE426 AI Silicon System/Project/Project 2/data/input_normal.hex")
    )
    inputRamInst
    (
        .clk                                            (clk),
        .we_in                                          (1'b0),         //only read
        .addr_in                                        (input_addr),
        .wdata_in                                       ({(INPUT_BITWIDTH*MAC_ROW){1'b0}}),
        .rdata_out                                      (input_data)
    );

    SinglePortRam
    #(
        .RAM_WIDTH                                      (OUTPUT_BITWIDTH*MAC_COL),
        .RAM_ADDR_BITS                                  (OUTPUT_ADDR_BIT)
    )
    outputRamInst
    (
        .clk                                            (clk),
        .we_in                                          (output_write_en),
        .addr_in                                        (output_addr),
        .wdata_in                                       (output_data),
        .rdata_out                                      (/*unused*/)    // no read
    );
    
endmodule