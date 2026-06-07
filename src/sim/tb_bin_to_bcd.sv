`timescale 1ns/1ps

module tb_bin_to_bcd;

    localparam BIN_W    = 6;
    localparam N_DIGITS = 2;

    logic [BIN_W-1:0] bin_in;
    logic [N_DIGITS*4-1:0] bcd_out;

    // DUT
    bin_to_bcd #(
        .BIN_W(BIN_W),
        .N_DIGITS(N_DIGITS)
    ) dut (
        .bin_in(bin_in),
        .bcd_out(bcd_out)
    );

    initial begin

        // Crear archivo de ondas
        $dumpfile("bin_to_bcd.vcd");
        $dumpvars(0, tb_bin_to_bcd);

        // Caso 0
        bin_in = 0;
        #10;

        // Caso 1
        bin_in = 1;
        #10;

        // Caso 9
        bin_in = 9;
        #10;

        // Caso 10
        bin_in = 10;
        #10;

        // Caso 15
        bin_in = 15;
        #10;

        // Caso 31
        bin_in = 31;
        #10;

        // Caso 45
        bin_in = 45;
        #10;

        // Máximo valor para 6 bits
        bin_in = 63;
        #10;

        $finish;

    end

endmodule