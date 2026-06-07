// division_cell.sv
// Celda fundamental del divisor en arreglo (Figura 3 del enunciado).
//
// Implementa un sumador completo (full adder) de 1 bit.
// En el contexto del divisor:
//   r   = bit del residuo parcial extendido R_ext
//   b   = bit de ~B_ext (complemento del divisor extendido a NB+1 bits)
//   cin = acarreo de la celda anterior (cin=1 en la celda LSB de cada fila)
//
// La cadena de acarreos de NB+1 celdas calcula R_ext + ~{0,B} + 1,
// es decir, la resta R_ext - B en complemento a dos.
// El acarreo de salida de la celda MSB (cout final de la fila) indica:
//   cout = 1  →  R_ext >= B  →  Q_i = 1, residuo nuevo = D = resultado
//   cout = 0  →  R_ext  < B  →  Q_i = 0, residuo nuevo = R_ext (sin cambio)

module division_cell (
    input  logic r,     // bit del residuo parcial
    input  logic b,     // bit de ~B (complementado) o 1'b1 para la ext. MSB
    input  logic cin,   // acarreo de entrada
    output logic d,     // bit del resultado de la resta
    output logic cout   // acarreo de salida
);
    assign {cout, d} = r + b + cin;

endmodule