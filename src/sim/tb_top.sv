`timescale 1ns/1ps
// tb_top.sv - Banco de pruebas del top con teclado y display

module tb_top;

    logic clk;
    logic reset;
    logic [3:0] rows;
    logic [3:0] cols;
    logic [6:0] seg;
    logic [1:0] an;

    top dut (
        .clk  (clk),
        .reset(reset),
        .rows (rows),
        .cols (cols),
        .seg  (seg),
        .an   (an)
    );

    always #18.518 clk = ~clk;

    function automatic string kname(input logic [3:0] kc);
        case (kc)
            4'h0: return "'0'  digito";
            4'h1: return "'1'  digito";
            4'h2: return "'2'  digito";
            4'h3: return "'3'  digito";
            4'h4: return "'4'  digito";
            4'h5: return "'5'  digito";
            4'h6: return "'6'  digito";
            4'h7: return "'7'  digito";
            4'h8: return "'8'  digito";
            4'h9: return "'9'  digito";
            4'hA: return "'A'  separador (tecla A)";
            4'hB: return "'B'  ejecutar  (tecla B)";
            4'hC: return "'C'  borrar    (tecla C)";
            4'hD: return "'D'  toggle    (tecla D)";
            4'hE: return "'*'  borrar alt";
            4'hF: return "'#'  sin uso";
            default: return "???";
        endcase
    endfunction

    function automatic logic [3:0] kexpected(input int r, c);
        case ({r[1:0], c[1:0]})
            4'b0000: return 4'h1;   4'b0001: return 4'h2;
            4'b0010: return 4'h3;   4'b0011: return 4'hA;
            4'b0100: return 4'h4;   4'b0101: return 4'h5;
            4'b0110: return 4'h6;   4'b0111: return 4'hB;
            4'b1000: return 4'h7;   4'b1001: return 4'h8;
            4'b1010: return 4'h9;   4'b1011: return 4'hC;
            4'b1100: return 4'hE;   4'b1101: return 4'h0;
            4'b1110: return 4'hF;   4'b1111: return 4'hD;
            default: return 4'hF;
        endcase
    endfunction

    integer err1, err2;

    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);

        clk  = 0;
        rows = 4'b0000;
        err1 = 0;
        err2 = 0;

        reset = 0;
        #400;
        reset = 1;
        #400;

        $display("");
        $display("================================================================");
        $display("  PARTE 1: key_decoder  (fuerza row_detect / col_detect)");
        $display("================================================================");
        $display("  row | col | keycode |  Funcion                  |  Estado");
        $display("  ----|-----|---------|---------------------------|--------");

        for (int r = 0; r < 4; r++) begin
            for (int c = 0; c < 4; c++) begin
                logic [3:0] exp, got;
                exp = kexpected(r, c);

                force dut.row_detect = r[1:0];
                force dut.col_detect = c[1:0];
                #5;

                got = dut.keycode;

                if (got !== exp) err1++;
                if (got === exp)
                    $display("   %0d  |  %0d  |   0x%0h   |  %-25s|  OK",
                        r, c, got, kname(got));
                else
                    $display("   %0d  |  %0d  |   0x%0h   |  %-25s|  ERROR (esperado 0x%0h)",
                        r, c, got, kname(got), exp);
            end
        end

        release dut.row_detect;
        release dut.col_detect;

        $display("  ----------------------------------------------------------------");
        if (err1 == 0)
            $display("  >> PARTE 1 APROBADA: key_decoder correcto.");
        else
            $display("  >> PARTE 1 FALLO: %0d errores en key_decoder.", err1);

        $display("");
        $display("================================================================");
        $display("  PARTE 2: keypad_reader + key_decoder  (scan forzado)");
        $display("  (bypass de sync/debounce – igual que presionar tecla real)");
        $display("================================================================");
        $display("  row | col | keycode |  Funcion                  |  Estado");
        $display("  ----|-----|---------|---------------------------|--------");

        force dut.scan_enable = 1'b0;

        for (int r = 0; r < 4; r++) begin
            for (int c = 0; c < 4; c++) begin
                logic [3:0] exp, got;
                exp = kexpected(r, c);

                force dut.u_keypad.current_col = c[1:0];

                force dut.rows_clean = (4'b0001 << r);

                force dut.key_active = 1'b0;

                @(posedge clk);

                force dut.scan_enable = 1'b1;
                @(posedge clk);
                force dut.scan_enable = 1'b0;

                @(posedge clk);

                got = dut.keycode;

                if (got !== exp) err2++;
                if (got === exp)
                    $display("   %0d  |  %0d  |   0x%0h   |  %-25s|  OK",
                        r, c, got, kname(got));
                else
                    $display("   %0d  |  %0d  |   0x%0h   |  %-25s|  ERROR (esperado 0x%0h)",
                        r, c, got, kname(got), exp);

                force dut.rows_clean = 4'b0000;
                @(posedge clk);
                @(posedge clk);
            end
        end

        release dut.scan_enable;
        release dut.rows_clean;
        release dut.u_keypad.current_col;
        release dut.key_active;

        $display("  ----------------------------------------------------------------");
        if (err2 == 0)
            $display("  >> PARTE 2 APROBADA: escaneo correcto.");
        else
            $display("  >> PARTE 2 FALLO: %0d errores. Revisar keypad_reader.sv.", err2);

        $display("");
        $display("================================================================");
        $display("  TABLA DE REFERENCIA  –  Cableado físico esperado");
        $display("  (teclado 4x4 estándar: filas de arriba a abajo,");
        $display("   columnas de izquierda a derecha)");
        $display("================================================================");
        $display("  Tecla | Fila FPGA | Col FPGA | Pin fila | Pin col | keycode");
        $display("  ------|-----------|----------|----------|---------|---------");
        $display("    1   |  rows[0]  | cols[0]  |  pin 29  |  pin 25 |  0x1");
        $display("    2   |  rows[0]  | cols[1]  |  pin 29  |  pin 26 |  0x2");
        $display("    3   |  rows[0]  | cols[2]  |  pin 29  |  pin 27 |  0x3");
        $display("    A   |  rows[0]  | cols[3]  |  pin 29  |  pin 28 |  0xA (separador)");
        $display("    4   |  rows[1]  | cols[0]  |  pin 30  |  pin 25 |  0x4");
        $display("    5   |  rows[1]  | cols[1]  |  pin 30  |  pin 26 |  0x5");
        $display("    6   |  rows[1]  | cols[2]  |  pin 30  |  pin 27 |  0x6");
        $display("    B   |  rows[1]  | cols[3]  |  pin 30  |  pin 28 |  0xB (ejecutar)");
        $display("    7   |  rows[2]  | cols[0]  |  pin 33  |  pin 25 |  0x7");
        $display("    8   |  rows[2]  | cols[1]  |  pin 33  |  pin 26 |  0x8");
        $display("    9   |  rows[2]  | cols[2]  |  pin 33  |  pin 27 |  0x9");
        $display("    C   |  rows[2]  | cols[3]  |  pin 33  |  pin 28 |  0xC (borrar)");
        $display("    *   |  rows[3]  | cols[0]  |  pin 34  |  pin 25 |  0xE (borrar alt)");
        $display("    0   |  rows[3]  | cols[1]  |  pin 34  |  pin 26 |  0x0");
        $display("    #   |  rows[3]  | cols[2]  |  pin 34  |  pin 27 |  0xF (sin uso)");
        $display("    D   |  rows[3]  | cols[3]  |  pin 34  |  pin 28 |  0xD (toggle)");
        $display("================================================================");
        $display("  NOTA: cols = salidas del FPGA (pines 25-28), activo-ALTO.");
        $display("        rows = entradas del FPGA (pines 29-34), pull-DOWN interno.");
        $display("        NO conecte filas ni columnas a 3.3V ni GND externamente.");
        $display("================================================================");
        $display("");

        $finish;
    end

endmodule

