// keypad_reader.sv
// Lee un teclado matricial 4x4 mediante escaneo de columnas.
// Cada ciclo habilita una columna distinta, busca la fila activa y cuando
// detecta una tecla presionada produce un pulso key_valid con la fila/columna.
module keypad_reader (
    input logic clk,
    input logic reset,
    input logic scan_enable,
    input logic [3:0] rows,

    output logic [3:0] cols,
    output logic [1:0] row_detect,
    output logic [1:0] col_detect,
    output logic key_valid
);

logic [1:0] current_col;

always_ff @(posedge clk or posedge reset) begin

    if (reset) begin
        current_col <= 0;
        cols <= 4'b1110;
        key_valid <= 0;
    end
    else begin

        key_valid <= 0;

        if (scan_enable) begin

            current_col <= current_col + 1;

            case(current_col)
                2'd0: cols <= 4'b1110;
                2'd1: cols <= 4'b1101;
                2'd2: cols <= 4'b1011;
                2'd3: cols <= 4'b0111;
            endcase

            if (rows != 4'b0000) begin

                key_valid <= 1;
                col_detect <= current_col;

                case(rows)
                    4'b0001: row_detect <= 0;
                    4'b0010: row_detect <= 1;
                    4'b0100: row_detect <= 2;
                    4'b1000: row_detect <= 3;
                endcase

            end
        end
    end
end

endmodule