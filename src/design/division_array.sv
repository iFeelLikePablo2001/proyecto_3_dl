// division_array.sv
// Arreglo combinacional que implementa la división de enteros sin signo

module division_array #(
    parameter int NA = 6,
    parameter int NB = 4
)(
    input  logic [NA-1:0] A,
    input  logic [NB-1:0] B,
    output logic [NA-1:0] Q,
    output logic [NB-1:0] R
);

    logic [NB:0] B_inv;
    assign B_inv = {1'b1, ~B};

    logic [NB-1:0] R_partial [0:NA];
    assign R_partial[0] = {NB{1'b0}};

    genvar row, j;
    generate
        for (row = 0; row < NA; row++) begin : gen_fila

            logic [NB:0]   R_ext;
            logic [NB+1:0] c;
            logic [NB:0]   D;

            assign R_ext = {R_partial[row], A[NA-1-row]};
            assign c[0]  = 1'b1;

            for (j = 0; j <= NB; j++) begin : gen_celda
                division_cell u_cell (
                    .r   (R_ext[j]),
                    .b   (B_inv[j]),
                    .cin (c[j]),
                    .d   (D[j]),
                    .cout(c[j+1])
                );
            end

            assign Q[NA-1-row]      = c[NB+1];
            assign R_partial[row+1] = c[NB+1] ? D[NB-1:0] : R_ext[NB-1:0];

        end
    endgenerate

    assign R = R_partial[NA];

endmodule
