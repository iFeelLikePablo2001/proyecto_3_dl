`timescale 1ns/1ps

module tb_clock_enable;

logic clk;
logic reset;
logic enable;

clock_enable #(.MAX_COUNT(5)) DUT (
    .clk(clk),
    .reset(reset),
    .enable(enable)
);

always #5 clk = ~clk;

initial begin
    $dumpfile("tb_clock_enable.vcd");
    $dumpvars(0, tb_clock_enable);

    clk = 0;
    reset = 1;

    #20;
    reset = 0;

    #200;

    $finish;
end

endmodule