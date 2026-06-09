`timescale 1ns/1ps

// tb_fsm_teclado.sv - Módulo tb_fsm_teclado

module tb_fsm_teclado;

    logic clk;
    logic rst_n;

    logic tecla_valida;
    logic [3:0] tecla;
    logic done;

    logic capturando_A;
    logic capturando_B;
    logic valid;
    logic borrar;
    logic sel_display;

    fsm_teclado dut (
        .clk(clk),
        .rst_n(rst_n),
        .tecla_valida(tecla_valida),
        .tecla(tecla),
        .done(done),
        .capturando_A(capturando_A),
        .capturando_B(capturando_B),
        .valid(valid),
        .borrar(borrar),
        .sel_display(sel_display)
    );

    always #18.518 clk = ~clk;

    initial begin

        $dumpfile("tb_fsm_teclado.vcd");
        $dumpvars(0, tb_fsm_teclado);

        clk = 0;
        rst_n = 0;
        tecla_valida = 0;
        tecla = 0;
        done = 0;

        #20;
        rst_n = 1;

        @(posedge clk);
        tecla = 4'hA;
        tecla_valida = 1;

        @(posedge clk);
        tecla_valida = 0;

        @(posedge clk);
        tecla = 4'hB;
        tecla_valida = 1;

        @(posedge clk);
        tecla_valida = 0;

        #30;
        done = 1;

        @(posedge clk);
        done = 0;

        @(posedge clk);
        tecla = 4'hD;
        tecla_valida = 1;

        @(posedge clk);
        tecla_valida = 0;

        @(posedge clk);
        tecla = 4'hC;
        tecla_valida = 1;

        @(posedge clk);
        tecla_valida = 0;

        #30;
        $finish;

    end

endmodule
