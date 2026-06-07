// bin_to_bcd.sv
// Conversor de número binario a representación BCD usando el algoritmo
// "Double Dabble" (shift-and-add-3). Totalmente combinacional.
//
// Algoritmo (BIN_W iteraciones):
//   1. Verificar cada dígito BCD: si el dígito >= 5, sumar 3.
//   2. Desplazar todo el registro (BCD + binario) un lugar a la izquierda.
//
// Parámetros:
//   BIN_W    = ancho del número binario de entrada
//   N_DIGITS = cantidad de dígitos BCD de salida (cada uno es 4 bits)
//
// Uso en el proyecto:
//   • Cociente (0..63):  bin_to_bcd #(.BIN_W(6), .N_DIGITS(2)) u_bcd_q (...)
//   • Residuo  (0..14):  bin_to_bcd #(.BIN_W(4), .N_DIGITS(2)) u_bcd_r (...)
//
// Ejemplo (BIN_W=6, N_DIGITS=2):
//   bin_in  = 6'd63  → bcd_out = 8'h63 (tens=6, units=3)
//   bin_in  = 6'd14  → bcd_out = 8'h14 (tens=1, units=4)
//
// bcd_out[N_DIGITS*4-1 : (N_DIGITS-1)*4] = dígito más significativo (decenas)
// bcd_out[3:0]                            = dígito menos significativo (unidades)

module bin_to_bcd #(
    parameter int BIN_W    = 6,   // bits del número binario de entrada
    parameter int N_DIGITS = 2    // dígitos BCD de salida
)(
    input  logic [BIN_W-1:0]      bin_in,
    output logic [N_DIGITS*4-1:0] bcd_out
);

    localparam int TOTAL_W = N_DIGITS * 4 + BIN_W; // ancho del registro de trabajo

    // Registro de trabajo: [BCD_N-1 ... BCD_0 | bin_in]
    logic [TOTAL_W-1:0] scratch;

    always_comb begin
        // Inicializar: dígitos BCD en 0, binario en los LSBs
        scratch = {{(N_DIGITS*4){1'b0}}, bin_in};

        // BIN_W iteraciones: verificar → sumar 3 si >= 5 → desplazar
        for (int i = 0; i < BIN_W; i++) begin

            // Verificar y ajustar cada dígito BCD (de unidades hacia arriba)
            for (int j = 0; j < N_DIGITS; j++) begin
                if (scratch[BIN_W + j*4 +: 4] >= 4'd5)
                    scratch[BIN_W + j*4 +: 4] =
                        scratch[BIN_W + j*4 +: 4] + 4'd3;
            end

            // Desplazamiento izquierda: el MSB del binario sube a BCD_units
            scratch = {scratch[TOTAL_W-2:0], 1'b0};
        end

        // Los dígitos BCD quedaron en los bits superiores del registro
        bcd_out = scratch[TOTAL_W-1 : BIN_W];
    end

endmodule