// capturador_numero.sv - Módulo capturador_numero

module capturador_numero (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        habilitado,
    input  logic        tecla_valida,
    input  logic        borrar,
    input  logic [3:0]  tecla,
    output logic [9:0]  numero_bcd,
    output logic        listo

);

    logic [3:0] digito [0:2];
    logic [1:0] idx;
    localparam MAX_DIGITOS = 2;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            idx        <= 2'd0;
            listo      <= 1'b0;
            digito[0]  <= 4'd0;
            digito[1]  <= 4'd0;
            digito[2]  <= 4'd0;
        end
        else if (habilitado && tecla_valida && tecla <= 4'd9) begin
            digito[2] <= digito[1];
            digito[1] <= digito[0];
            digito[0] <= tecla;

            if (idx < MAX_DIGITOS - 1)
                idx <= idx + 1;
            else
                listo <= 1'b1;
        end
        else if (borrar) begin
         idx       <= 2'd0;
            listo     <= 1'b0;
            digito[0] <= 4'd0;
            digito[1] <= 4'd0;
        end
    end

    assign numero_bcd = (digito[2] * 10'd100)
                      + (digito[1] * 10'd10)
                      + (digito[0]);

endmodule
