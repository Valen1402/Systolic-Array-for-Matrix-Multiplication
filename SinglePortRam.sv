module SinglePortRam
#(
    parameter RAM_WIDTH                     = 32,
    parameter RAM_ADDR_BITS                 = 10,
    parameter INIT_FILE_NAME                = ""
)
(
    input  logic                            clk,
    input  logic                            we_in,
    input  logic [RAM_ADDR_BITS-1:0]        addr_in,
    input  logic [RAM_WIDTH-1:0]            wdata_in,
    output logic [RAM_WIDTH-1:0]            rdata_out
);

    logic [RAM_WIDTH-1:0]                   mem[(2**RAM_ADDR_BITS)-1:0];
    

    initial begin
        if (INIT_FILE_NAME != "") begin
            $readmemh(INIT_FILE_NAME, mem);
        end
    end

    always @(posedge clk) begin
        if(we_in) begin
            mem[addr_in]                    <= wdata_in;
        end
        else begin
            rdata_out                       <= mem[addr_in];
        end
    end

endmodule