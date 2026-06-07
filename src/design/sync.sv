// sync.sv
// Sincronizador de señal asíncrona usando doble flip-flop.
// Alinea async_in al dominio de reloj clk para reducir riesgos de metastabilidad.
module sync (
    input logic clk,
    input logic async_in,
    output logic sync_out
);

logic ff1, ff2;

always_ff @(posedge clk) begin
    ff1 <= async_in;
    ff2 <= ff1;
end

assign sync_out = ff2;

endmodule