// division_cell.sv
// Celda fundamental del divisor en arreglo (Figura 3 del enunciado).

module division_cell (
    input  logic r,
    input  logic b,
    input  logic cin,
    output logic d,
    output logic cout
);
    assign {cout, d} = r + b + cin;

endmodule
