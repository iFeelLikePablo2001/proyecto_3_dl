`timescale 1ns/1ps

module suma_tb;

    // ── Señales ───────────────────────────────────────────────────────
    logic        clk;
    logic        rst_n;
    logic        ejecutar;
    logic [9:0]  numero_a;
    logic [9:0]  numero_b;
    logic [10:0] resultado;

    // ── Instancia del módulo bajo prueba ──────────────────────────────
    suma dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .ejecutar  (ejecutar),
        .numero_a  (numero_a),
        .numero_b  (numero_b),
        .resultado (resultado)
    );

    // ── Reloj 27 MHz ──────────────────────────────────────────────────
    initial clk = 0;
    always #18.5 clk = ~clk;

    // ── Obligatorio para GTKWave ──────────────────────────────────────
    initial begin
        $dumpfile("suma_tb.vcd");
        $dumpvars(0, suma_tb);
    end

    // ── Estímulos ─────────────────────────────────────────────────────
    initial begin
        // Reset inicial
        rst_n    = 1'b0;
        ejecutar = 1'b0;
        numero_a = 10'd0;
        numero_b = 10'd0;
        repeat(5) @(posedge clk);
        rst_n = 1'b1;
        repeat(2) @(posedge clk);

        // Prueba 1: 123 + 456 = 579
        numero_a = 10'd123;
        numero_b = 10'd456;
        ejecutar = 1'b1;
        @(posedge clk);
        ejecutar = 1'b0;
        @(posedge clk);
        if (resultado == 11'd579)
            $display("PASS: 123 + 456 = %0d", resultado);
        else
            $display("FAIL: esperado 579, obtenido %0d", resultado);

        repeat(3) @(posedge clk);

        // Prueba 2: 999 + 999 = 1998 (caso máximo)
        numero_a = 10'd999;
        numero_b = 10'd999;
        ejecutar = 1'b1;
        @(posedge clk);
        ejecutar = 1'b0;
        @(posedge clk);
        if (resultado == 11'd1998)
            $display("PASS: 999 + 999 = %0d", resultado);
        else
            $display("FAIL: esperado 1998, obtenido %0d", resultado);

        repeat(3) @(posedge clk);

        // Prueba 3: 0 + 0 = 0 (caso mínimo)
        numero_a = 10'd0;
        numero_b = 10'd0;
        ejecutar = 1'b1;
        @(posedge clk);
        ejecutar = 1'b0;
        @(posedge clk);
        if (resultado == 11'd0)
            $display("PASS: 0 + 0 = %0d", resultado);
        else
            $display("FAIL: esperado 0, obtenido %0d", resultado);

        repeat(5) @(posedge clk);
        $display("--- Simulación terminada ---");
        $finish;
    end

endmodule