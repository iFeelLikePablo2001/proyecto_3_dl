`timescale 1ns/1ps

module tb_division_array;

    localparam NA = 6;
    localparam NB = 4;

    logic [NA-1:0] A;
    logic [NB-1:0] B;

    logic [NA-1:0] Q;
    logic [NB-1:0] R;

    division_array #(
        .NA(NA),
        .NB(NB)
    ) dut (
        .A(A),
        .B(B),
        .Q(Q),
        .R(R)
    );

    initial begin

        $dumpfile("division_array.vcd");
        $dumpvars(0, tb_division_array);

        // 12 / 3
        A = 12;
        B = 3;
        #10;

        // 15 / 4
        A = 15;
        B = 4;
        #10;

        // 63 / 7
        A = 63;
        B = 7;
        #10;

        // 20 / 6
        A = 20;
        B = 6;
        #10;

        // dividendo menor que divisor
        A = 5;
        B = 8;
        #10;

        $finish;

    end

endmodule