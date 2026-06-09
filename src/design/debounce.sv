// debounce.sv - Filtro anti-rebote para entradas digitales
// Sincroniza la entrada con dos flip-flops y usa un contador de estabilidad para generar una salida limpia.


module debounce #(
    parameter LIMIT = 5
)(
    input logic clk,
    input logic reset,
    input logic noisy_in,
    output logic clean_out
);

logic previous;
logic [$clog2(LIMIT):0] counter;

always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        previous <= 0;
        counter <= 0;
        clean_out <= 0;
    end
    else begin

        if (noisy_in != previous) begin
            counter <= 0;
        end
        else begin
            counter <= counter + 1;
        end

        if (counter == LIMIT-1) begin
            clean_out <= noisy_in;
        end

        previous <= noisy_in;
    end
end

endmodule
