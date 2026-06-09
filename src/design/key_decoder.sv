// key_decoder.sv - Decodificador de fila/columna a código de tecla
// Convierte la posición detectada en el teclado matricial a un código de tecla usando lógica combinacional.


module key_decoder (
    input  logic [1:0] key_row,
    input  logic [1:0] key_col,
    output logic [3:0] keycode
);

    always_comb begin
        unique case ({key_row, key_col})
        4'b0000: keycode = 4'h1;
        4'b0001: keycode = 4'h2;
        4'b0010: keycode = 4'h3;
        4'b0011: keycode = 4'hA;

        4'b0100: keycode = 4'h4;
        4'b0101: keycode = 4'h5;
        4'b0110: keycode = 4'h6;
        4'b0111: keycode = 4'hB;

        4'b1000: keycode = 4'h7;
        4'b1001: keycode = 4'h8;
        4'b1010: keycode = 4'h9;
        4'b1011: keycode = 4'hC;

        4'b1100: keycode = 4'hE;
        4'b1101: keycode = 4'h0;
        4'b1110: keycode = 4'hF;
        4'b1111: keycode = 4'hD;

        default: keycode = 4'hF;
    endcase
    end

endmodule
