// fsm_teclado.sv
// Máquina de estados que controla el flujo de captura de datos y la
// activación del divisor de enteros.
//
// Teclas:
//   0-9  → dígito decimal
//   0xA  → separador: fin de dividendo, inicio de divisor
//   0xB  → ejecutar división
//   0xC  → borrar / reiniciar
//   0xD  → alternar despliegue cociente / residuo
//   0xE  → (*) funciona igual que borrar

module fsm_teclado (
    input  logic        clk,
    input  logic        rst_n,         // reset activo-bajo
    input  logic        tecla_valida,  // pulso de 1 ciclo por tecla nueva
    input  logic [3:0]  tecla,         // código de la tecla (de key_decoder)
    input  logic        done,          // del division_unit: resultado listo

    output logic        capturando_A,  // habilita el capturador del dividendo
    output logic        capturando_B,  // habilita el capturador del divisor
    output logic        valid,         // pulso de 1 ciclo que arranca el divisor
    output logic        borrar,        // pulso de 1 ciclo que limpia los capturadores
    output logic        sel_display    // 0 = mostrar cociente, 1 = mostrar residuo
);

    // ─── Constantes de teclas ─────────────────────────────────────────
    localparam logic [3:0] KEY_SEP  = 4'hA; // separador dividendo → divisor
    localparam logic [3:0] KEY_EXEC = 4'hB; // ejecutar división
    localparam logic [3:0] KEY_CLR  = 4'hC; // borrar
    localparam logic [3:0] KEY_TOG  = 4'hD; // toggle display
    localparam logic [3:0] KEY_STAR = 4'hE; // (*) también borra

    // ─── Definición de estados ────────────────────────────────────────
    typedef enum logic [1:0] {
        CAP_A   = 2'd0,  // ingresando dígitos del dividendo
        CAP_B   = 2'd1,  // ingresando dígitos del divisor
        DIVIDIR = 2'd2,  // esperando que el divisor termine
        LISTO   = 2'd3   // resultado disponible en pantalla
    } state_t;

    state_t state, next_state;

    // ─── Señal interna de borrado (combinacional) ─────────────────────
    logic key_clr;
    assign key_clr = tecla_valida && (tecla == KEY_CLR || tecla == KEY_STAR);

    // ─── Registro de estado ───────────────────────────────────────────
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= CAP_A;
        else        state <= next_state;
    end

    // ─── Lógica de próximo estado ─────────────────────────────────────
    always_comb begin
        next_state = state;
        unique case (state)

            CAP_A: begin
                if (key_clr)                              next_state = CAP_A;
                else if (tecla_valida && tecla == KEY_SEP) next_state = CAP_B;
            end

            CAP_B: begin
                if (key_clr)                               next_state = CAP_A;
                else if (tecla_valida && tecla == KEY_EXEC) next_state = DIVIDIR;
            end

            DIVIDIR: begin
                if (key_clr) next_state = CAP_A;
                else if (done) next_state = LISTO;
            end

            LISTO: begin
                if (key_clr) next_state = CAP_A;
            end

        endcase
    end

    // ─── Salidas Moore / Mealy ────────────────────────────────────────

    // Habilitaciones de capturador (Moore: dependen solo del estado)
    assign capturando_A = (state == CAP_A);
    assign capturando_B = (state == CAP_B);

    // valid: pulso Mealy de 1 ciclo al presionar B en CAP_B
    assign valid = (state == CAP_B) && tecla_valida && (tecla == KEY_EXEC);

    // borrar: pulso de 1 ciclo al presionar C o * en cualquier estado
    assign borrar = key_clr;

    // ─── Toggle de display (registro independiente) ───────────────────
    // Funciona en cualquier estado; se reinicia con rst_n
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sel_display <= 1'b0;
        else if (tecla_valida && tecla == KEY_TOG)
            sel_display <= ~sel_display;
    end

endmodule