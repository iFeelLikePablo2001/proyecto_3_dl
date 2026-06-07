module tb_sync;

logic clk;
logic async_in;
logic sync_out;

sync DUT (
    .clk(clk),
    .async_in(async_in),
    .sync_out(sync_out)
);

always #5 clk = ~clk;

initial begin
    $dumpfile("tb_sync.vcd");
    $dumpvars(0, tb_sync);
    
    clk = 0;
    async_in = 0;

    #17 async_in = 1;
    #23 async_in = 0;
    #40 async_in = 1;

    #100;

    $finish;
end

endmodule