// top.sv
// Módulo de nivel superior para el Proyecto 3: División de Enteros.
// Interconecta todos los subsistemas de la TangNano 9K.
//
// Flujo de datos:
//   rows/cols → [sync] → [debounce] → keypad_reader → key_decoder
//            → [new_key_detect] → fsm_teclado
//                                → capturador_A  → division_unit
//                                → capturador_B  →      ↓
//                                                  → bin_to_bcd ×2
//                                                  → seven_seg_decoder
//                                                  → mux_display → an/seg
//
// Reset físico (pin 3): activo-alto (reset).
// Módulos con rst_n activo-bajo reciben (~reset).
//
// IMPORTANTE: capturador_numero.sv debe estar modificado para aceptar:
//   - Parámetros MAX_DIGITOS y OUT_WIDTH
//   - Puerto de entrada: borrar
//   - Salida: numero_bin [OUT_WIDTH-1:0] en lugar de numero_bcd [9:0]

module top (
    input  logic        clk,       // 27 MHz (pin 52)
    input  logic        reset,     // reset activo-alto (pin 3)

    // Teclado matricial 4×4
    input  logic [3:0]  rows,      // filas (entradas, con pull-down en PCB)
    output logic [3:0]  cols,      // columnas (salidas de escaneo)

    // Display de 7 segmentos (2 dígitos físicos)
    output logic [6:0]  seg,       // segmentos (activo-bajo en TangNano)
    output logic [1:0]  an         // ánodos (activo-bajo: 0 = enciende)
);

    // ─────────────────────────────────────────────────────────────────
    // 0. Señales internas
    // ─────────────────────────────────────────────────────────────────
    logic rst_n;
    assign rst_n = ~reset;         // activo-bajo para los módulos que lo usan

    // Señales de escaneo/refresco
    logic scan_enable;             // habilita un paso del escaneo del teclado
    logic display_enable;          // avanza el multiplexor de display

    // Filas sincronizadas y con anti-rebote
    logic [3:0] rows_sync;
    logic [3:0] rows_clean;

    // Salidas del keypad_reader
    logic [1:0] row_detect, col_detect;
    logic       key_valid_raw;

    // Salida del key_decoder
    logic [3:0] keycode;

    // Detección de tecla nueva (one-shot)
    logic       key_active;
    logic       tecla_valida;      // pulso limpio: 1 sola vez por pulsación

    // Salidas del fsm_teclado
    logic capturando_A, capturando_B;
    logic valid_div, borrar, sel_display;
    logic done;

    // Salidas de los capturadores
    logic [5:0] dividendo;         // 6 bits, máx 63
    logic [3:0] divisor;           // 4 bits, máx 15
    logic [9:0] dividendo_raw;     // salida cruda del capturador (10 bits BCD)
    logic [9:0] divisor_raw;       // salida cruda del capturador (10 bits BCD)

    // Salidas del division_unit (cableadas directamente desde los registros del pipeline)
    logic [5:0] cociente;
    logic [3:0] residuo;

    // Latches de salida: capturan cociente y residuo cuando done=1 y los mantienen
    // estables hasta la próxima operación.
    // NECESARIO con el pipeline: tras done, los registros q_p[NA]/r_p[NA] se
    // sobreescriben en el siguiente ciclo con la burbuja inválida que sigue al dato.
    // Sin estos latches el display mostraría basura a partir del segundo ciclo.
    logic [5:0] cociente_r;
    logic [3:0] residuo_r;

    // BCD del cociente y del residuo
    logic [7:0] bcd_cociente;      // [7:4]=decenas, [3:0]=unidades
    logic [7:0] bcd_residuo;

    // Display mux
    logic [1:0] active_display;
    logic       disp_col;          // bit 0 del active_display para 2 pantallas
    logic [7:0] bcd_sel;           // BCD seleccionado (cociente o residuo)
    logic [3:0] digit;             // dígito BCD a mostrar en esta ranura

    // ─────────────────────────────────────────────────────────────────
    // 1. Generadores de habilitar (clock enables)
    // ─────────────────────────────────────────────────────────────────
    // scan_enable  ≈ 1 kHz  → período de escaneo del teclado
    // display_enable ≈ 2 kHz → avanza entre los 2 displays físicos
    clock_enable #(.MAX_COUNT(27_000)) u_scan_ce (
        .clk   (clk),
        .reset (reset),
        .enable(scan_enable)
    );

    clock_enable #(.MAX_COUNT(13_500)) u_disp_ce (
        .clk   (clk),
        .reset (reset),
        .enable(display_enable)
    );

    // ─────────────────────────────────────────────────────────────────
    // 2. Sincronización y anti-rebote de las filas del teclado
    // ─────────────────────────────────────────────────────────────────
    genvar i;
    generate
        for (i = 0; i < 4; i++) begin : gen_filas
            // Sincronizador de doble FF (evita metaestabilidad)
            sync u_sync (
                .clk      (clk),
                .async_in (rows[i]),
                .sync_out (rows_sync[i])
            );
            // Anti-rebote (~37 µs a 27 MHz con LIMIT=1000)
            debounce #(.LIMIT(1000)) u_deb (
                .clk      (clk),
                .reset    (reset),
                .noisy_in (rows_sync[i]),
                .clean_out(rows_clean[i])
            );
        end
    endgenerate

    // ─────────────────────────────────────────────────────────────────
    // 3. Lector de teclado matricial 4×4
    // ─────────────────────────────────────────────────────────────────
    keypad_reader u_keypad (
        .clk        (clk),
        .reset      (reset),
        .scan_enable(scan_enable),
        .rows       (rows_clean),
        .cols       (cols),
        .row_detect (row_detect),
        .col_detect (col_detect),
        .key_valid  (key_valid_raw)
    );

    // ─────────────────────────────────────────────────────────────────
    // 4. Decodificador de posición fila/columna → código de tecla
    // ─────────────────────────────────────────────────────────────────
    key_decoder u_decoder (
        .key_row(row_detect),
        .key_col(col_detect),
        .keycode(keycode)
    );

    // ─────────────────────────────────────────────────────────────────
    // 5. Detección de tecla nueva (one-shot por pulsación)
    //
    // key_valid_raw se dispara cada scan_enable mientras la tecla esté
    // presionada. key_active se activa en el primer pulso y se limpia
    // al soltar (rows_clean == 0). tecla_valida es alto solo en el
    // primer ciclo de cada pulsación distinta.
    // ─────────────────────────────────────────────────────────────────
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            key_active <= 1'b0;
        else if (rows_clean == 4'b0000)
            key_active <= 1'b0;    // tecla liberada: permitir siguiente pulsación
        else if (key_valid_raw)
            key_active <= 1'b1;    // primera detección de esta pulsación
    end

    assign tecla_valida = key_valid_raw && !key_active;

    // ─────────────────────────────────────────────────────────────────
    // 6. FSM de control del teclado
    // ─────────────────────────────────────────────────────────────────
    fsm_teclado u_fsm (
        .clk          (clk),
        .rst_n        (rst_n),
        .tecla_valida (tecla_valida),
        .tecla        (keycode),
        .done         (done),
        .capturando_A (capturando_A),
        .capturando_B (capturando_B),
        .valid        (valid_div),
        .borrar       (borrar),
        .sel_display  (sel_display)
    );

    // ─────────────────────────────────────────────────────────────────
    // 7. Capturadores de dígitos decimales
    //    (requiere capturador_numero.sv modificado con MAX_DIGITOS,
    //     OUT_WIDTH y puerto borrar)
    // ─────────────────────────────────────────────────────────────────

    // Dividendo A: máx 63 → 6 bits
    capturador_numero u_capA (
        .clk         (clk),
        .rst_n       (rst_n),
        .habilitado  (capturando_A),
        .tecla_valida(tecla_valida),
        .tecla       (keycode),
        .borrar      (borrar),
        .numero_bcd  (dividendo_raw),
        .listo       ()
    );
    assign dividendo = dividendo_raw[5:0];

    // Divisor B: máx 15 → 4 bits
    capturador_numero u_capB (
        .clk         (clk),
        .rst_n       (rst_n),
        .habilitado  (capturando_B),
        .tecla_valida(tecla_valida),
        .tecla       (keycode),
        .borrar      (borrar),
        .numero_bcd  (divisor_raw),
        .listo       ()
    );
    assign divisor = divisor_raw[3:0];

    // ─────────────────────────────────────────────────────────────────
    // 8. Unidad de división de enteros
    // ─────────────────────────────────────────────────────────────────
    division_unit #(
        .NA(6),
        .NB(4)
    ) u_div (
        .clk  (clk),
        .rst_n(rst_n),
        .valid(valid_div),
        .A    (dividendo),
        .B    (divisor),
        .Q    (cociente),
        .R    (residuo),
        .done (done)
    );

    // ─────────────────────────────────────────────────────────────────
    // 9. Latch de salida del divisor
    // Captura Q y R en el ciclo en que done=1 y los retiene estables.
    // Timing: done=v_p[NA] es una salida registrada del pipeline; cociente
    // y residuo son también registrados (q_p[NA], r_p[NA]). Todos se leen
    // ANTES del flanco activo, por lo que el latch captura los valores
    // correctos del mismo ciclo en que done=1 aparece.
    // ─────────────────────────────────────────────────────────────────
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cociente_r <= '0;
            residuo_r  <= '0;
        end else if (done) begin
            cociente_r <= cociente;
            residuo_r  <= residuo;
        end
    end

    // ─────────────────────────────────────────────────────────────────
    // 10. Conversores binario → BCD (para display)
    // Usan cociente_r / residuo_r (latched, estables) — NO las salidas
    // directas del pipeline que se sobreescriben tras done.
    // ─────────────────────────────────────────────────────────────────
    bin_to_bcd #(.BIN_W(6), .N_DIGITS(2)) u_bcd_q (
        .bin_in (cociente_r),
        .bcd_out(bcd_cociente)
    );

    bin_to_bcd #(.BIN_W(4), .N_DIGITS(2)) u_bcd_r (
        .bin_in (residuo_r),
        .bcd_out(bcd_residuo)
    );

    // ─────────────────────────────────────────────────────────────────
    // 11. Multiplexor de display: avanza entre los 2 ánodos físicos
    // ─────────────────────────────────────────────────────────────────
    mux_display u_mux (
        .clk           (clk),
        .reset         (reset),
        .display_enable(display_enable),
        .active_display(active_display)
    );

    // Solo se usan los 2 displays físicos → usar bit 0 del contador
    assign disp_col = active_display[0];

    // ─────────────────────────────────────────────────────────────────
    // 11. Selección de qué mostrar: cociente o residuo
    //     sel_display = 0 → cociente, 1 → residuo
    // ─────────────────────────────────────────────────────────────────
    assign bcd_sel = sel_display ? bcd_residuo : bcd_cociente;

    // bcd_sel[7:4] = dígito de decenas
    // bcd_sel[3:0] = dígito de unidades
    // disp_col=0 → display izquierdo (decenas)
    // disp_col=1 → display derecho  (unidades)
    assign digit = disp_col ? bcd_sel[3:0] : bcd_sel[7:4];

    // ─────────────────────────────────────────────────────────────────
    // 12. Decodificador BCD → 7 segmentos
    // ─────────────────────────────────────────────────────────────────
    seven_seg_decoder u_seg (
        .number(digit),
        .seg   (seg)
    );

    // ─────────────────────────────────────────────────────────────────
    // 13. Control de ánodos (activo-bajo: 0 enciende el display)
    //     Solo un display activo a la vez.
    // ─────────────────────────────────────────────────────────────────
    // disp_col=0 → an = 2'b10 (activa an[0], display izquierdo)
    // disp_col=1 → an = 2'b01 (activa an[1], display derecho)
    assign an = disp_col ? 2'b01 : 2'b10;

endmodule