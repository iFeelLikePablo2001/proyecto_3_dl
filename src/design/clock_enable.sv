// clock_enable.sv
// Generador de enable periódico: cuenta ciclos de reloj y produce un pulso
// de salida cuando el contador alcanza MAX_COUNT-1.
// Se usa para crear una señal de barrido o temporización más lenta a partir
// del reloj principal.
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