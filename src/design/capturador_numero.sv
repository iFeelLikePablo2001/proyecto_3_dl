module capturador_numero (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        habilitado,    // viene de capturando_A o capturando_B
    input  logic        tecla_valida,
    input  logic [3:0]  tecla,
    output logic [9:0]  numero_bcd,    // número completo (máx 999 = 10 bits)
    output logic        listo          // ya se ingresaron 3 dígitos
);

    logic [3:0] digito [0:2]; // arreglo: digito[0]=unidades, [1]=decenas, [2]=centenas
    logic [1:0] idx;           // índice de dígito actual
    localparam MAX_DIGITOS = 3;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            idx        <= 2'd0;
            listo      <= 1'b0;
            digito[0]  <= 4'd0;
            digito[1]  <= 4'd0;
            digito[2]  <= 4'd0;
        end
        else if (habilitado && tecla_valida && tecla <= 4'd9) begin
            // Desplazamiento estilo calculadora:
            // el nuevo dígito entra por la derecha, los anteriores suben
            digito[2] <= digito[1];
            digito[1] <= digito[0];
            digito[0] <= tecla;

            if (idx < MAX_DIGITOS - 1)
                idx <= idx + 1;
            else
                listo <= 1'b1; // ya tenemos 3 dígitos
        end
    end

    // Reconstruye el valor decimal a partir de los dígitos BCD
    assign numero_bcd = (digito[2] * 10'd100)
                      + (digito[1] * 10'd10)
                      + (digito[0]);

endmodule