`timescale 1ns/1ps

module tb_top;

    logic clk;
    logic reset;

    logic [3:0] rows;
    logic [3:0] cols;

    logic [6:0] seg;
    logic [1:0] an;

    top dut (
        .clk(clk),
        .reset(reset),
        .rows(rows),
        .cols(cols),
        .seg(seg),
        .an(an)
    );

    // 27 MHz
    always #18.518 clk = ~clk;

    initial begin

        $dumpfile("tb_top.vcd");
        $dumpvars(0,tb_top);

        clk   = 0;
        reset = 1;
        rows  = 4'b0000;

        #200;
        reset = 0;

        //----------------------------------
        // Prueba 1: 12 / 3 = 4 R0
        //----------------------------------

        force dut.dividendo = 6'd12;
        force dut.divisor   = 4'd3;

        force dut.valid_div = 1'b1;
        @(posedge clk);
        force dut.valid_div = 1'b0;

        repeat(10) @(posedge clk);

        //----------------------------------
        // Prueba 2: 15 / 4 = 3 R3
        //----------------------------------

        force dut.dividendo = 6'd15;
        force dut.divisor   = 4'd4;

        force dut.valid_div = 1'b1;
        @(posedge clk);
        force dut.valid_div = 1'b0;

        repeat(10) @(posedge clk);

        release dut.dividendo;
        release dut.divisor;
        release dut.valid_div;

        #1000;

        $finish;

    end

endmodule