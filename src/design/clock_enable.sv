// clock_enable.sv - Generador de habilitar periódico
// Cuenta ciclos de reloj con un registro y produce un pulso de enable a baja frecuencia.


module clock_enable #(
    parameter MAX_COUNT = 10
)(
    input logic clk,
    input logic reset,
    output logic enable
);

logic [$clog2(MAX_COUNT):0] counter;

always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        counter <= 0;
        enable <= 0;
    end
    else begin
        enable <= 0;
        counter <= counter + 1;

        if (counter == MAX_COUNT-1) begin
            counter <= 0;
            enable <= 1;
        end
    end
end

endmodule
