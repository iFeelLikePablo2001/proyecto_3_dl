// division_array.sv
// Arreglo combinacional que implementa la división de enteros sin signo
// según la Figura 2 del enunciado (Harris & Harris, sección 5.2.7).
//
// Estructura: NA filas × (NB+1) celdas por fila.
//   - Cada fila procesa un bit del dividendo (de MSB a LSB).
//   - Cada celda es una instancia de division_cell (full adder).
//   - La cadena de acarreo por fila calcula R_ext - B en complemento a dos.
//   - El acarreo de salida de cada fila determina el bit del cociente Q_i
//     y selecciona el nuevo residuo parcial.
//
// Parámetros:
//   NA = bits del dividendo (default 6, max 63)
//   NB = bits del divisor   (default 4, max 15)
//
// NOTA: Este bloque es totalmente combinacional. Para cumplir 27 MHz se
// recomienda agregar registros de pipeline entre filas (ver division_unit.sv).

module division_array #(
    parameter int NA = 6,  // bits del dividendo
    parameter int NB = 4   // bits del divisor
)(
    input  logic [NA-1:0] A,  // dividendo (sin signo)
    input  logic [NB-1:0] B,  // divisor   (sin signo)
    output logic [NA-1:0] Q,  // cociente
    output logic [NB-1:0] R   // residuo
);

    // ─── Complemento de {0, B} = {1, ~B} ────────────────────────────
    // Usado en todas las filas como término fijo de la resta.
    // B_inv[NB:0] = ~{1'b0, B[NB-1:0]} = {1'b1, ~B[NB-1:0]}
    logic [NB:0] B_inv;
    assign B_inv = {1'b1, ~B};

    // ─── Residuos parciales entre filas ──────────────────────────────
    // R_partial[0]   = 0 (residuo inicial)
    // R_partial[k+1] = salida de la fila k
    logic [NB-1:0] R_partial [0:NA];
    assign R_partial[0] = {NB{1'b0}};

    // ─── Generación de filas ──────────────────────────────────────────
    genvar row, j;
    generate
        for (row = 0; row < NA; row++) begin : gen_fila

            // R_ext: residuo de la fila anterior extendido con el bit A[NA-1-row]
            // {R_partial[row][NB-1:0], A[NA-1-row]} → NB+1 bits
            logic [NB:0]   R_ext;
            logic [NB+1:0] c;      // cadena de acarreos: c[0]=1 (cin), c[NB+1]=carry_out
            logic [NB:0]   D;      // resultado de la resta (NB+1 bits)

            assign R_ext = {R_partial[row], A[NA-1-row]};
            assign c[0]  = 1'b1;   // cin=1 para complemento a dos

            // Instanciación de NB+1 celdas full adder por fila
            for (j = 0; j <= NB; j++) begin : gen_celda
                division_cell u_cell (
                    .r   (R_ext[j]),
                    .b   (B_inv[j]),   // ~B[j] para j<NB; 1'b1 (= ~0) para j=NB
                    .cin (c[j]),
                    .d   (D[j]),
                    .cout(c[j+1])
                );
            end

            // c[NB+1]: acarreo final de la fila
            //   1 → R_ext >= B → Q_i = 1, residuo = D[NB-1:0]
            //   0 → R_ext  < B → Q_i = 0, residuo = R_ext[NB-1:0]
            assign Q[NA-1-row]      = c[NB+1];
            assign R_partial[row+1] = c[NB+1] ? D[NB-1:0] : R_ext[NB-1:0];

        end
    endgenerate

    assign R = R_partial[NA];

endmodule