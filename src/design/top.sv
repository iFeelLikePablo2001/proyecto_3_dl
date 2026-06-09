// top.sv - Top-level del sistema de división entera
// Interconecta teclado, captura, control y display.
// Usa sincronizadores de doble FF para entradas asíncronas, debounce, FSM de registros y un divisor pipelínico.


module top (
    input  logic        clk,
    input  logic        reset,

    input  logic [3:0]  rows,
    output logic [3:0]  cols,

    output logic [6:0]  seg,
    output logic [1:0]  an
);


    logic rst_n;
    logic reset_i;
    assign rst_n   = reset;
    assign reset_i = ~reset;

    logic scan_enable;
    logic display_enable;

    logic [3:0] rows_sync;
    logic [3:0] rows_clean;

    logic [1:0] row_detect, col_detect_raw;
    logic       key_valid_raw;

    logic [1:0] col_detect;
    assign col_detect = col_detect_raw - 2'd1;

    logic [3:0] keycode;

    logic       key_active;
    logic       tecla_valida;

    logic capturando_A, capturando_B;
    logic valid_div, borrar, sel_display;
    logic done;

    logic [5:0] dividendo;
    logic [3:0] divisor;
    logic [9:0] dividendo_raw;
    logic [9:0] divisor_raw;

    logic [5:0] cociente;
    logic [3:0] residuo;

    logic [5:0] cociente_r;
    logic [3:0] residuo_r;

    logic [7:0] bcd_cociente;
    logic [7:0] bcd_residuo;

    logic [1:0] active_display;
    logic       disp_col;
    logic [7:0] bcd_sel;
    logic [3:0] digit;

    logic [3:0] cols_raw;

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

    genvar i;
    generate
        for (i = 0; i < 4; i++) begin : gen_filas
            sync u_sync (
                .clk      (clk),
                .async_in (rows[i]),
                .sync_out (rows_sync[i])
            );
            debounce #(.LIMIT(1000)) u_deb (
                .clk      (clk),
                .reset    (reset_i),
                .noisy_in (rows_sync[i]),
                .clean_out(rows_clean[i])
            );
        end
    endgenerate

    keypad_reader u_keypad (
        .clk        (clk),
        .reset      (reset_i),
        .scan_enable(scan_enable),
        .rows       (rows_clean),
        .cols       (cols_raw),
        .row_detect (row_detect),
        .col_detect (col_detect_raw),
        .key_valid  (key_valid_raw)
    );
    assign cols = ~cols_raw;

    key_decoder u_decoder (
        .key_row(row_detect),
        .key_col(col_detect),
        .keycode(keycode)
    );

    always_ff @(posedge clk or posedge reset_i) begin
        if (reset_i)
            key_active <= 1'b0;
        else if (rows_clean == 4'b0000)
            key_active <= 1'b0;
        else if (key_valid_raw)
            key_active <= 1'b1;
    end

    assign tecla_valida = key_valid_raw && !key_active;

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

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cociente_r <= '0;
            residuo_r  <= '0;
        end else if (done) begin
            cociente_r <= cociente;
            residuo_r  <= residuo;
        end
    end

    bin_to_bcd #(.BIN_W(6), .N_DIGITS(2)) u_bcd_q (
        .bin_in (cociente_r),
        .bcd_out(bcd_cociente)
    );

    bin_to_bcd #(.BIN_W(4), .N_DIGITS(2)) u_bcd_r (
        .bin_in (residuo_r),
        .bcd_out(bcd_residuo)
    );

    mux_display u_mux (
        .clk           (clk),
        .reset         (reset_i),
        .display_enable(display_enable),
        .active_display(active_display)
    );

    assign disp_col = active_display[0];

    assign bcd_sel = sel_display ? bcd_residuo : bcd_cociente;

    assign digit = disp_col ? bcd_sel[3:0] : bcd_sel[7:4];

    seven_seg_decoder u_seg (
        .number(digit),
        .seg   (seg)
    );

    assign an = disp_col ? 2'b01 : 2'b10;

endmodule
