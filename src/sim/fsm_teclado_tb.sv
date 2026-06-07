`timescale 1ns/1ps   // unidad de tiempo / precisión

module fsm_teclado_tb;  // ← Este nombre va en TOP_TB del Makefile

    // ── Declaración de señales ────────────────────────────────────────
    logic        clk;
    logic        rst_n;
    logic        tecla_valida;
    logic [3:0]  tecla;
    logic        capturando_A;
    logic        capturando_B;
    logic        ejecutar_suma;

    // ── Instancia del módulo bajo prueba (DUT) ────────────────────────
    fsm_teclado dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .tecla_valida (tecla_valida),
        .tecla        (tecla),
        .capturando_A (capturando_A),
        .capturando_B (capturando_B),
        .ejecutar_suma(ejecutar_suma)
    );

    // ── Generador de reloj: periodo = 37ns ≈ 27 MHz ───────────────────
    initial clk = 0;
    always #18.5 clk = ~clk;   // medio periodo = 18.5 ns

    // ── Tarea auxiliar: simula presionar una tecla ────────────────────
    task presionar_tecla(input logic [3:0] valor);
        @(posedge clk);         // espera flanco de reloj
        tecla       = valor;
        tecla_valida = 1'b1;
        @(posedge clk);         // mantiene un ciclo
        tecla_valida = 1'b0;    // suelta la tecla
        repeat(3) @(posedge clk); // espera estabilización
    endtask

    // ── Bloque OBLIGATORIO para GTKWave ──────────────────────────────
    initial begin
        $dumpfile("fsm_teclado_tb.vcd");  // ← Este nombre va en VCD_FILE
        $dumpvars(0, fsm_teclado_tb);     // ← Nombre del módulo testbench
    end

    // ── Estímulos de prueba ───────────────────────────────────────────
    initial begin
        // 1. Inicialización
        rst_n        = 1'b0;
        tecla_valida = 1'b0;
        tecla        = 4'h0;
        repeat(5) @(posedge clk);   // mantiene reset 5 ciclos
        rst_n = 1'b1;
        repeat(2) @(posedge clk);

        // 2. Prueba: ingresar dígitos del número A (1, 2, 3)
        $display("--- Ingresando número A ---");
        presionar_tecla(4'd1);
        presionar_tecla(4'd2);
        presionar_tecla(4'd3);

        // 3. Tecla separadora 'A' (pasar a número B)
        $display("--- Separador: pasando a número B ---");
        presionar_tecla(4'hA);

        // 4. Ingresar dígitos del número B (4, 5, 6)
        $display("--- Ingresando número B ---");
        presionar_tecla(4'd4);
        presionar_tecla(4'd5);
        presionar_tecla(4'd6);

        // 5. Tecla 'B' para ejecutar suma
        $display("--- Ejecutar suma ---");
        presionar_tecla(4'hB);

        // 6. Verificación de salidas
        @(posedge clk);
        if (ejecutar_suma)
            $display("PASS: ejecutar_suma está activo");
        else
            $display("FAIL: ejecutar_suma debería estar activo");

        // 7. Tecla 'C' para reiniciar
        presionar_tecla(4'hC);
        @(posedge clk);
        if (!capturando_A && !capturando_B && !ejecutar_suma)
            $display("PASS: sistema regresó a IDLE");
        else
            $display("FAIL: sistema no regresó a IDLE");

        repeat(20) @(posedge clk);
        $display("--- Simulación terminada ---");
        $finish;   // termina la simulación
    end

endmodule
