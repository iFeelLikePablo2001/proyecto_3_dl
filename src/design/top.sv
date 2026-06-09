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
// Reset físico (pin 3): activo-BAJO.
//   - Sin presionar botón : pin = HIGH → sistema corriendo
//   - Botón presionado    : pin = LOW  → reset activo
//
// rst_n   = reset tal cual (activo-bajo para módulos que lo esperan así)
// reset_i = ~reset         (activo-alto para módulos que esperan reset=1)

module top (
    input  logic        clk,       // 27 MHz (pin 52)
    input  logic        reset,     // reset físico activo-bajo (pin 3)

    // Teclado matricial 4×4
    input  logic [3:0]  rows,      // filas (entradas, pull-down interno)
    output logic [3:0]  cols,      // columnas (salidas de escaneo, activo-alto)

    // Display de 7 segmentos (2 dígitos físicos)
    output logic [6:0]  seg,       // segmentos (activo-bajo en TangNano)
    output logic [1:0]  an         // ánodos (activo-bajo: 0 = enciende)
);

    // ─────────────────────────────────────────────────────────────────
    // 0. Señales internas
    // ─────────────────────────────────────────────────────────────────

    // El pin físico de reset (pin 3) es activo-BAJO:
    //   - Reposo (sin presionar botón): pin = HIGH  → no reset
    //   - Botón presionado:             pin = LOW   → reset activo
    // rst_n   = señal activo-bajo  para módulos que la esperan así  (= reset tal cual)
    // reset_i = señal activo-alto para módulos que esperan reset=1  (= ~reset)
    logic rst_n;
    logic reset_i;
    assign rst_n   = reset;   // pin es activo-bajo → HIGH en reposo = sin reset
    assign reset_i = ~reset;  // activo-alto interno → HIGH cuando botón presionado

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
    logic [9:0] dividendo_raw;     // salida cruda del capturador (10 bits)
    logic [9:0] divisor_raw;       // salida cruda del capturador (10 bits)

    // Salidas del division_unit
    logic [5:0] cociente;
    logic [3:0] residuo;

    // Latches de salida: capturan cociente y residuo cuando done=1
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

    // Columnas del teclado: keypad_reader genera patrón activo-bajo (una col en 0,
    // el resto en 1). Para que las filas (con pull-down interno) suban al detectar
    // una tecla, se necesita señal activo-alto en el pin físico → invertir.
    logic [3:0] cols_raw;          // salida interna de keypad_reader (activo-bajo)

    // ─────────────────────────────────────────────────────────────────
    // 1. Generadores de habilitar (clock enables)
    // ─────────────────────────────────────────────────────────────────
    // scan_enable  ≈ 1 kHz  → período de escaneo del teclado
    // display_enable ≈ 2 kHz → avanza entre los 2 displays físicos
    clock_enable #(.MAX_COUNT(27_000)) u_scan_ce (
        .clk   (clk),
        .reset (reset_i),
        .enable(scan_enable)
    );

    clock_enable #(.MAX_COUNT(13_500)) u_disp_ce (
        .clk   (clk),
        .reset (reset_i),
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
                .reset    (reset_i),
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
        .reset      (reset_i),
        .scan_enable(scan_enable),
        .rows       (rows_clean),
        .cols       (cols_raw),     // patrón activo-bajo interno
        .row_detect (row_detect),
        .col_detect (col_detect),
        .key_valid  (key_valid_raw)
    );
    // Invertir: pin físico activo-alto → columna activa en HIGH
    // tecla presionada conecta fila con columna HIGH → fila sube → detectado
    assign cols = ~cols_raw;

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
    // ─────────────────────────────────────────────────────────────────
    always_ff @(posedge clk or posedge reset_i) begin
        if (reset_i)
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
    // 11. Multiplexor de display
    // ─────────────────────────────────────────────────────────────────
    mux_display u_mux (
        .clk           (clk),
        .reset         (reset_i),
        .display_enable(display_enable),
        .active_display(active_display)
    );

    assign disp_col = active_display[0];

    // ─────────────────────────────────────────────────────────────────
    // 12. Selección cociente / residuo y decodificación de dígito
    // ─────────────────────────────────────────────────────────────────
    assign bcd_sel = sel_display ? bcd_residuo : bcd_cociente;

    // bcd_sel[7:4] = decenas, bcd_sel[3:0] = unidades
    // disp_col=0 → display izquierdo (decenas)
    // disp_col=1 → display derecho  (unidades)
    assign digit = disp_col ? bcd_sel[3:0] : bcd_sel[7:4];

    // ─────────────────────────────────────────────────────────────────
    // 13. Decodificador BCD → 7 segmentos
    // ─────────────────────────────────────────────────────────────────
    seven_seg_decoder u_seg (
        .number(digit),
        .seg   (seg)
    );

    // ─────────────────────────────────────────────────────────────────
    // 14. Control de ánodos (activo-bajo)
    // disp_col=0 → an = 2'b10 (activa an[0], display izquierdo)
    // disp_col=1 → an = 2'b01 (activa an[1], display derecho)
    // ─────────────────────────────────────────────────────────────────
    assign an = disp_col ? 2'b01 : 2'b10;

endmodule
