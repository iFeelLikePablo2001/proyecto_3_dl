// fsm_teclado.sv - Máquina de estados para captura de datos y control de división

module fsm_teclado (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        tecla_valida,
    input  logic [3:0]  tecla,
    input  logic        done,

    output logic        capturando_A,
    output logic        capturando_B,
    output logic        valid,
    output logic        borrar,
    output logic        sel_display
);

    localparam logic [3:0] KEY_SEP  = 4'hA;
    localparam logic [3:0] KEY_EXEC = 4'hB;
    localparam logic [3:0] KEY_CLR  = 4'hC;
    localparam logic [3:0] KEY_TOG  = 4'hD;
    localparam logic [3:0] KEY_STAR = 4'hE;

    typedef enum logic [1:0] {
        CAP_A   = 2'd0,
        CAP_B   = 2'd1,
        DIVIDIR = 2'd2,
        LISTO   = 2'd3
    } state_t;

    state_t state, next_state;

    logic key_clr;
    assign key_clr = tecla_valida && (tecla == KEY_CLR || tecla == KEY_STAR);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= CAP_A;
        else        state <= next_state;
    end

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


    assign capturando_A = (state == CAP_A);
    assign capturando_B = (state == CAP_B);

    assign valid = (state == CAP_B) && tecla_valida && (tecla == KEY_EXEC);

    assign borrar = key_clr;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sel_display <= 1'b0;
        else if (tecla_valida && tecla == KEY_TOG)
            sel_display <= ~sel_display;
    end

endmodule
