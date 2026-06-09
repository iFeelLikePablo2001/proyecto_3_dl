// division_cell.sv - Celda de resta en complemento a dos
// Es un sumador completo que realiza R_ext - B con ~B + cin=1 y propaga el carry para decidir el bit de cociente.


module division_cell (
    input  logic r,
    input  logic b,
    input  logic cin,
    output logic d,
    output logic cout
);
    assign {cout, d} = r + b + cin;

endmodule
