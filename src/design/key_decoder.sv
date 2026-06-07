// key_decoder.sv
// Convierte la posición de fila/columna detectada en el valor de la tecla.
// Mapea cada combinación de row/col a un valor numérico o a códigos especiales
// como A y B para funciones de control.
module key_decoder (
    input  logic [1:0] key_row,
    input  logic [1:0] key_col,
    output logic [3:0] keycode
);

    always_comb begin
        unique case ({key_row, key_col})
        // Fila 0: 1, 2, 3, A
        4'b0000: keycode = 4'h1;
        4'b0001: keycode = 4'h2;
        4'b0010: keycode = 4'h3;
        4'b0011: keycode = 4'hA;

        // Fila 1: 4, 5, 6, B
        4'b0100: keycode = 4'h4;
        4'b0101: keycode = 4'h5;
        4'b0110: keycode = 4'h6;
        4'b0111: keycode = 4'hB;

        // Fila 2: 7, 8, 9, C
        4'b1000: keycode = 4'h7;
        4'b1001: keycode = 4'h8;
        4'b1010: keycode = 4'h9;
        4'b1011: keycode = 4'hC;

        // Fila 3: *, 0, #, D
        4'b1100: keycode = 4'hX; // * → no tiene representación hex directa
        4'b1101: keycode = 4'h0;
        4'b1110: keycode = 4'hX; // # → ídem
        4'b1111: keycode = 4'hD;

        default: keycode = 4'hF;
    endcase
    end

endmodule