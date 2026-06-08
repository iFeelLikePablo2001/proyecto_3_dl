// ============================================================
// ESTRUCTURA (Figura 2 del enunciado, Harris & Harris §5.2.7)
//
//  valid ──► [Reg entrada: A, B]
//                  │
//            [Fila 0 – 5 FA combinacional]
//                  │
//            ══[REG pipeline 0]══          ← registro entre fila 0 y 1
//                  │
//            [Fila 1 – 5 FA combinacional]
//                  │
//            ══[REG pipeline 1]══          ← registro entre fila 1 y 2
//                  │
//                 ...
//                  │
//            [Fila 5 – 5 FA combinacional]
//                  │
//            ══[REG pipeline 5]══   ──► done, Q, R
//
// Latencia    : NA = 6 ciclos de reloj
// Ruta crítica: NB+1 = 5 full adders (una sola fila)
// Frecuencia  : 27 MHz  ✓
//
// Por qué esto es distinto a la FSM (versión anterior):
//   - FSM       : 1 fila reutilizada en 6 ciclos (un solo conjunto de FAs)
//   - Pipeline  : 6 filas físicas distintas, una por ciclo, con FF entre ellas
//   - Ambas dan la misma latencia (6 ciclos) y frecuencia, pero el pipeline
//     muestra la segmentación explícita que describe el enunciado.
//
// Señales de pipeline (índice k = 0..NA):
//   r_p[k]  : residuo parcial de NB bits   — salida de la fila k-1
//   q_p[k]  : cociente acumulado de NA bits — salida de la fila k-1
//   a_p[k]  : dividendo desplazado          — MSB = bit a procesar en fila k
//   b_p[k]  : divisor propagado             — reduce ruta crítica al evitar
//              fanout desde la entrada original hasta cada fila
//   v_p[k]  : bandera valid                 — fluye junto con los datos
// ============================================================

module division_unit #(
    parameter int NA = 6,   // bits del dividendo  (máx: 2^NA−1 = 63)
    parameter int NB = 4    // bits del divisor    (máx: 2^NB−1 = 15)
)(
    input  logic          clk,
    input  logic          rst_n,   // reset activo-bajo
    input  logic          valid,   // pulso 1 ciclo: inicia la división
    input  logic [NA-1:0] A,       // dividendo
    input  logic [NB-1:0] B,       // divisor
    output logic [NA-1:0] Q,       // cociente  (estable cuando done = 1)
    output logic [NB-1:0] R,       // residuo   (estable cuando done = 1)
    output logic          done     // pulso 1 ciclo: resultado listo
);

    // ── Registros de pipeline ────────────────────────────────────────
    // r_p, q_p : rango [1:NA]  → escritos por las filas 0..NA-1
    // a_p, b_p : rango [0:NA]  → a_p[0]/b_p[0] = registro de entrada
    // v_p      : rango [0:NA]  → v_p[0] = registro de entrada, v_p[NA] = done
    logic [NB-1:0] r_p [1:NA];
    logic [NA-1:0] q_p [1:NA];
    logic [NA-1:0] a_p [0:NA];
    logic [NB-1:0] b_p [0:NA];
    logic          v_p [0:NA];

    // ── Registro de entrada ──────────────────────────────────────────
    // Captura A y B en el ciclo en que valid = 1.
    // v_p[0] propaga la bandera "dato válido" a través del pipeline.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_p[0] <= '0;
            b_p[0] <= '0;
            v_p[0] <= 1'b0;
        end else begin
            v_p[0] <= valid;
            if (valid) begin
                a_p[0] <= A;
                b_p[0] <= B;
            end
        end
    end

    // ── NA etapas de pipeline ────────────────────────────────────────
    // Cada etapa implementa UNA fila del arreglo de la Figura 2:
    //   1. Computa r_ext = {residuo_previo, bit_dividendo}  (NB+1 bits)
    //   2. Calcula D = r_ext - B via complemento a dos      (NB+2 bits)
    //   3. Determina Q_bit = carry_out (1 → D≥0, 0 → D<0)
    //   4. Registra el nuevo residuo, cociente y contexto
    genvar k;
    generate
        for (k = 0; k < NA; k++) begin : gen_fila

            // ── Señales de entrada de esta etapa ──────────────────────
            // r_prev y q_prev son los valores que entran a esta fila:
            //   • Fila 0 (k=0): residuo y cociente iniciales = 0
            //   • Filas 1..NA-1: provenientes del registro de pipeline k
            // Usar generate-if garantiza que el índice nunca esté fuera de rango.
            logic [NB-1:0] r_prev;
            logic [NA-1:0] q_prev;

            if (k == 0) begin : g_entrada_primera
                assign r_prev = {NB{1'b0}};   // Fila 0: residuo inicial = 0
                assign q_prev = {NA{1'b0}};   // Fila 0: cociente inicial = 0
            end else begin : g_entrada_resto
                assign r_prev = r_p[k];        // Desde el REG de la fila anterior
                assign q_prev = q_p[k];
            end

            // ── Cómputo combinacional de la fila k ────────────────────
            // r_ext = {residuo_previo[NB-1:0], bit_k_del_dividendo}
            // El MSB de a_p[k] es siempre el próximo bit a procesar
            // (se va desplazando izquierda en cada etapa).
            logic [NB:0]   r_ext;   // residuo extendido (NB+1 bits)
            logic [NB+1:0] sub;     // resultado de la resta (NB+2 bits)
            logic          q_bit;   // bit del cociente de esta fila

            assign r_ext = {r_prev, a_p[k][NA-1]};

            // D = r_ext − B  →  r_ext + ~{0,B} + 1  (complemento a dos)
            // sub[NB+1] = carry_out:
            //   1 → D ≥ 0 → Q_bit = 1, nuevo residuo = D[NB-1:0]
            //   0 → D < 0 → Q_bit = 0, nuevo residuo = r_ext[NB-1:0]
            assign sub   = {1'b0, r_ext}
                         + {1'b0, {1'b1, ~b_p[k]}}
                         + {{(NB+1){1'b0}}, 1'b1};
            assign q_bit = sub[NB+1];

            // ── Registro de pipeline entre fila k y fila k+1 ─────────
            // Este es el "REG" que se muestra en el diagrama de bloques.
            // Captura en el flanco de reloj y presenta los datos a la
            // siguiente fila combinacional en el ciclo siguiente.
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    r_p[k+1] <= '0;
                    q_p[k+1] <= '0;
                    a_p[k+1] <= '0;
                    b_p[k+1] <= '0;
                    v_p[k+1] <= 1'b0;
                end else begin
                    // Nuevo residuo parcial
                    r_p[k+1] <= q_bit ? sub[NB-1:0] : r_ext[NB-1:0];

                    // Cociente acumulado: desplazamiento izquierda, q_bit en LSB.
                    // q_prev[NA-2:0] = bits previos; q_bit = bit de esta fila.
                    // Para k=0: q_prev = 0 → q_p[1] = {5'b0, q_bit}
                    // Para k=5: q_p[6] = {Q[5],Q[4],...,Q[0]} = cociente final
                    q_p[k+1] <= {q_prev[NA-2:0], q_bit};

                    // Dividendo desplazado para la siguiente fila:
                    // el bit ya procesado sale por MSB, un 0 entra por LSB.
                    a_p[k+1] <= {a_p[k][NA-2:0], 1'b0};

                    // Divisor y bandera valid se propagan sin modificación
                    b_p[k+1] <= b_p[k];
                    v_p[k+1] <= v_p[k];
                end
            end

        end
    endgenerate

    // ── Salidas ───────────────────────────────────────────────────────
    // Después de NA ciclos desde valid=1, los datos llegan a la etapa final.
    // done = v_p[NA] es un pulso de 1 ciclo de ancho.
    // Q y R son válidos mientras done permanezca alto (1 ciclo) y no cambian
    // hasta que comience la siguiente operación.
    assign Q    = q_p[NA];
    assign R    = r_p[NA];
    assign done = v_p[NA];

endmodule