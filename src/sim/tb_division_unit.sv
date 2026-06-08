`timescale 1ns/1ps

module tb_division_unit;

    localparam NA = 6;
    localparam NB = 4;

    logic clk;
    logic rst_n;
    logic valid;

    logic [NA-1:0] A;
    logic [NB-1:0] B;

    logic [NA-1:0] Q;
    logic [NB-1:0] R;
    logic done;

    division_unit #(
        .NA(NA),
        .NB(NB)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .valid(valid),
        .A(A),
        .B(B),
        .Q(Q),
        .R(R),
        .done(done)
    );

    // 27 MHz
    always #18.518 clk = ~clk;

    initial begin

        $dumpfile("tb_division_unit.vcd");
        $dumpvars(0, tb_division_unit);

        clk   = 0;
        rst_n = 0;
        valid = 0;
        A     = 0;
        B     = 0;

        // reset
        #100;
        rst_n = 1;

        // 12 / 3
        @(posedge clk);
        A = 12;
        B = 3;
        valid = 1;

        @(posedge clk);
        valid = 0;

        // esperar salida
        repeat(10) @(posedge clk);

        // 15 / 4
        A = 15;
        B = 4;
        valid = 1;

        @(posedge clk);
        valid = 0;

        repeat(10) @(posedge clk);

        $finish;

    end

endmodule