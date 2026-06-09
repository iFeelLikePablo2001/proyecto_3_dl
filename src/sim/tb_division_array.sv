`timescale 1ns/1ps

// tb_division_array.sv - Módulo tb_division_array

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

        A = 12;
        B = 3;
        #10;

        A = 15;
        B = 4;
        #10;

        A = 63;
        B = 7;
        #10;

        A = 20;
        B = 6;
        #10;

        A = 5;
        B = 8;
        #10;

        $finish;

    end

endmodule
