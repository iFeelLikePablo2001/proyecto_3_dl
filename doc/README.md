# Informe: Proyecto 3

Integrantes:
- Kevin Mora Sobalvarro.
- Pablo Cabrera Montealegre.

## Descripción General

### Funcionamiento del Sistema Completo

El sistema implementa un divisor de números enteros sin signo con capacidad de operación en rango de hasta 63÷15 (dividendo de 6 bits, divisor de 4 bits). El diseño utiliza una arquitectura jerárquica con los siguientes bloques principales:

#### **Subsistemas Principales:**

1. **Subsistema de Entrada (Teclado):** 
   - Teclado matricial 4×4 
   - Sincronización de señales asíncronas mediante doble flip-flop
   - Eliminación de rebotes (debounce) para cada línea
   - Escaneo periódico de filas y detección de columnas activas
   - Mapeo de teclas a códigos hexadecimales (0-F)

2. **Subsistema de Captura de Números:**
   - Captura del dividendo (entrada A, máximo 63)
   - Captura del divisor (entrada B, máximo 15)
   - FSM que gestiona los estados: esperando dividendo, esperando divisor, división en proceso

3. **Subsistema de Cálculo (División Entera):**
   - Divisor combinacional puro
   - Divisor secuencial con pipeline (N² ciclos de reloj para N bits)
   - Implementa el algoritmo de división por resta iterativa
   - Salidas: cociente (Q) y residuo (R)

4. **Subsistema de Conversión (Binario a BCD):**
   - Convierte valores binarios a representación BCD
   - Soporta conversión de dividendo, divisor, cociente y residuo
   - Permite visualización en display de 7 segmentos

5. **Subsistema de Visualización (Display):**
   - Display de 2 dígitos de 7 segmentos
   - Multiplexado por tiempo a 100 kHz aproximadamente
   - Muestra selectivamente: dividendo, divisor, cociente o residuo

## Diagramas de Bloques

### Diagrama de Bloques General del Sistema

```
┌─────────────────────────────────────────────────────────────────────┐
│                          SISTEMA DIVISOR DE ENTEROS                 │
└─────────────────────────────────────────────────────────────────────┘

  Teclado 4×4                                                Display 7-seg
      │                                                           ▲
      │                                                           │
      ▼                                                           │
┌─────────────────┐     ┌────────────────────┐     ┌──────────────────┐
│  SINCRONIZADOR  │────▶│  DEBOUNCE & SCAN   │────▶│  CAPTURADOR     │
│  (Doble FF)     │     │  (4 filas × LIMIT) │     │  NÚMEROS A & B   │
└─────────────────┘     └────────────────────┘     └──────────────────┘
                               ▲                            │
                               │                            ▼
                        ┌──────────────┐     ┌──────────────────────┐
                        │  KEYPAD      │     │  FSM TECLADO         │
                        │  READER      │─────│  (control flujo)     │
                        │  (Escaneo)   │     └──────────────────────┘
                        └──────────────┘            │
                                                    ▼
                                        ┌──────────────────────┐
                                        │  DIVISION UNIT       │
                                        │  (pipelínica)        │
                                        │  NA=6, NB=4          │
                                        └──────────────────────┘
                                                    │
                                                    ▼
                                        ┌──────────────────────┐
                                        │  BIN TO BCD (×4)     │
                                        │  (Dividendo, Divisor,│
                                        │   Cociente, Residuo) │
                                        └──────────────────────┘
                                                    │
                                                    ▼
                                        ┌──────────────────────┐
                                        │  MUX DISPLAY &       │
                                        │  7-SEG DECODER       │
                                        │  (Multiplexado)      │
                                        └──────────────────────┘
```

### Conexion de Subsistemas

**Senales:**

1. **Entrada:** El usuario presiona teclas del teclado matricial
2. **Sincronización:** Cada fila se sincroniza con doble flip-flops en serie y se aplica debounce
3. **Detección:** El lector de teclado escanea columnas y detecta pulsaciones
4. **Decodificación:** Se mapea (fila, columna) a código hexadecimal
5. **Captura:** La FSM distribuye códigos entre capturadores de dividendo/divisor
6. **Cálculo:** Una vez ingresados ambos números, se ejecuta la división
7. **Conversión:** Cociente, residuo, dividendo y divisor se convierten a BCD
8. **Visualización:** El display alterna entre mostrar los valores

**Señales de Control:**
- `scan_enable`: Habilita escaneo del teclado
- `display_enable`: Habilita multiplexación del display
- `valid`: Indica cuando los números ingresados son válidos
- `done`: Señal que indica fin de la división
- `sel_display`: Selecciona si mostrar cociente (0) o residuo (1)

---

## FSMs disenadas

### FSM del Teclado 


```
┌──────────────────────────────────────────────────────────────┐
│                   Estados y Transiciones                      │
└──────────────────────────────────────────────────────────────┘

        Reset
         │
         ▼
    ┌─────────────────────────────────────────┐
    │  ESPERANDO_DIVIDENDO                    │
    │  • capturando_A = 1                     │
    │  • capturando_B = 0                     │
    │  • Espera entrada A válida o tecla A    │
    └─────────────────────────────────────────┘
         │
         │ Tecla A presionada
         ▼
    ┌─────────────────────────────────────────┐
    │  ESPERANDO_DIVISOR                      │
    │  • capturando_A = 0                     │
    │  • capturando_B = 1                     │
    │  • Espera entrada B válida o tecla B    │
    └─────────────────────────────────────────┘
         │
         │ Tecla B presionada
         ▼
    ┌─────────────────────────────────────────┐
    │  DIVISION_EN_PROCESO                    │
    │  • capturando_A = 0                     │
    │  • capturando_B = 0                     │
    │  • valid = 1 (inicia división)          │
    │  • Espera señal 'done'                  │
    └─────────────────────────────────────────┘
         │
         │ done = 1
         ▼
    ┌─────────────────────────────────────────┐
    │  RESULTADO_LISTO                        │
    │  • valid = 0                            │
    │  • Resultado disponible en display      │
    │  • Espera tecla D (toggle) o C (borrar) │
    └─────────────────────────────────────────┘
         │
         │ Tecla D: toggle (muestra Q/R)
         │ Tecla C: borrar (vuelve a ESPERANDO_DIVIDENDO)
         │
         └──────────────────────┐
                                ▼
                 (Vuelve a ESPERANDO_DIVIDENDO)
```

**Tabla de estados:**

| Estado Actual | Entrada | Salida (capturando_A, capturando_B, valid) | Próximo Estado |
|---|---|---|---|
| ESPERANDO_DIVIDENDO | Tecla 0-9, *, # | (1, 0, 0) | ESPERANDO_DIVIDENDO |
| ESPERANDO_DIVIDENDO | Tecla A | (0, 1, 0) | ESPERANDO_DIVISOR |
| ESPERANDO_DIVIDENDO | Tecla C | (1, 0, 0) | ESPERANDO_DIVIDENDO |
| ESPERANDO_DIVISOR | Tecla 0-9, *, # | (0, 1, 0) | ESPERANDO_DIVISOR |
| ESPERANDO_DIVISOR | Tecla B | (0, 0, 1) | DIVISION_EN_PROCESO |
| ESPERANDO_DIVISOR | Tecla C | (1, 0, 0) | ESPERANDO_DIVIDENDO |
| DIVISION_EN_PROCESO | done=1 | (0, 0, 0) | RESULTADO_LISTO |
| RESULTADO_LISTO | Tecla D | (0, 0, 0) | RESULTADO_LISTO (toggle display) |
| RESULTADO_LISTO | Tecla C | (1, 0, 0) | ESPERANDO_DIVIDENDO |

---

## Análisis de Simulaciones

LAS IMAGENES WV ESPERADAS SE PUEDE ENCONTRAR EN LA CARPETA IMG CON EL DEBIDO NOMBRE DEL MODULO

### 1. Simulación: `tb_division_array.sv`

**Descripción:**
La división computa el resultado en un solo ciclo combinacional.

**Resultados WV**

| Entrada A | Entrada B | Cociente Esperado | Residuo Esperado | Estado |
|---|---|---|---|---|
| 12 | 3 | 4 | 0 | ✓ OK |
| 15 | 4 | 3 | 3 | ✓ OK |
| 63 | 7 | 9 | 0 | ✓ OK |
| 20 | 6 | 3 | 2 | ✓ OK |
| 5 | 8 | 0 | 5 | ✓ OK |

**Análisis:**
- La lógica combinacional computa correctamente cociente y residuo
- El caso especial donde B > A se maneja correctamente (Q=0, R=A)
- El arreglo proporciona resultado instantáneo

### 2. Simulación: `tb_division_unit.sv`

**Descripción:**
La división secuencial implementa el algoritmo iterativo con pipeline, trabajando con una operacion cada cilo CLK

**Resultados WV**

| Entrada A | Entrada B | Cociente Esperado | Residuo Esperado | Estado |
|---|---|---|---|---|
| 12 | 3 | 4 | 0 | ✓ OK |
| 15 | 4 | 3 | 3 | ✓ OK |


**Análisis:**
- El modulo permanece inactivo (IDLE) hasta que recibe rst_n=1
- Da una senal valid=1 cuando se reciben correctamente el dividendo y divisor
- El pipeline ejecuta una accion por flanco de reloj
- La señal done cambia a 1 por un ciclo del clk al completarse la división

### 3. Simulación: `tb_bin_to_bcd.sv`

**Descripción:**
Validar conversión de binario a BCD.

**Resultados WV**

| Entrada Binaria | Valor Decimal | BCD Esperado | Estado |
|---|---|---|---|
| 0 | 0 | 0x00 | ✓ OK |
| 1 | 1 | 0x01 | ✓ OK |
| 9 | 9 | 0x09 | ✓ OK |
| 10 | 10 | 0x10 | ✓ OK |
| 15 | 15 | 0x15 | ✓ OK |
| 31 | 31 | 0x31 | ✓ OK |
| 45 | 45 | 0x45 | ✓ OK |


**Análisis:**
- La conversión es correcta para todo el rango de entrada
- Soporta todos los casos límite del rango (0 y 63)

### 4. Simulación: `tb_clock_enable.sv`

**Descripción:**
Genera pulsos periódicos a partir del reloj principal para controlar escaneo del teclado y multiplexación del display.

**Análisis WV:**
- Inicia conteo cuando reset=0
- El generador cuenta hasta MAX_COUNT ciclos de reloj (en este caso 5 entonces cuenta de 0 a 4)
- Genera un pulso de duración 1 ciclo cada MAX_COUNT ciclos

### 5. Simulación: `tb_debounce.sv`

**Descripción:**
Filtra las oscilaciones (rebotes) causadas por contactos mecánicos del teclado mediante contador.


**Análisis WV:**
- Inicia el contador de LIMIT=4 cuando reset=0
- noisy_in recibe pulsos pero como el debounce requiere LIMIT=4 ciclos consecutivos del mismo nivel antes de cambiar salida clean_out=0
- noisy_in recibe una senal por mas de LIMIT ciclos por lo que en ese momento clean_out=1

### 6. Simulación: `tb_sync.sv`

**Descripción:**
Sincroniza señales asíncronas a dominio de reloj del FPGA, minimizando riesgo de metaestabilidad.

**Análisis WV:**
- Dos flip-flops en cadena inician con valores indefinidos
- El primer flanco de reloj activa ff1 y le da valor de 0
- Cuando async_in=1 ff1=1 un ciclo despues de que cambie la senal
- Otro ciclo despues de que cambia ff1 a 1 entonces ff2=1
- sync_out = ff2

### 7. Simulación: `tb_keypad_reader.sv`

**Descripción:**
Implementa escaneo multiplexado de teclado 4×4 y detección de pulsaciones.

**Análisis de WV:**
- Inicia funcionamiento con reset=0
- scan_enable=1 cuando se cambia de columna
- Si hay una fila donde se presiona una tecla, key_valid=1 y se captura la direccion de la fila y columna con row_detect y col_detect

### 8. Simulación: `tb_fsm_teclado.sv`

**Descripción:**
Implementa la máquina de estados que controla el flujo de entrada dividendo → divisor → ejecución → visualización.

**Análisis:**
- Inicia con rst_n=1
- Captura ambos numeros
- Cambia de estado 01,10,11,00 segun la tecla A,B,C,D
- Genera un pulso done=1 cuando la operacion esta completa

### 9. Simulación: `tb_top.sv` - INTEGRACIÓN COMPLETA

**Descripción:**
Prueba de integración que valida:

**Análisis WV:**
- En la simulacion salen muchas senales por lo que elegimos enfocarnos en las que demuestran el funcionamiento
- En el primer pulso de done tras colocarnos encima se observa que se hizo la operacion 59/8 con resultado de 7 de cociente y 3 de residuo que es correcto

## Análisis de Recursos FPGA

### Estimación de Consumo de Recursos

**Nota:** Los valores son estimados mediante síntesis de Vivado. 

| Subsistema | Componentes | LUTs | FF | BRAM | Observaciones |
|---|---|---|---|---|---|
| **Sincronizadores** | sync (×4 filas) | 8 | 8 | 0 | Doble FF por entrada |
| **Debounce** | debounce (×4) | 40 | 40 | 0 | Contador LIMIT=1000 |
| **Clock Enable** | clock_enable (×2) | 30 | 30 | 0 | Contadores de escaneo/display |
| **Keypad Reader** | keypad_reader | 60 | 25 | 0 | Control de escaneo |
| **Key Decoder** | key_decoder | 10 | 0 | 0 | Lógica combinacional |
| **FSM Teclado** | fsm_teclado | 40 | 12 | 0 | 5 estados principales |
| **Capturadores** | capturador_numero (×2) | 100 | 60 | 0 | Registros para A y B |
| **Division Array** | division_array | 150 | 0 | 0 | Combinacional puro |
| **Division Unit** | division_unit | 300 | 120 | 0 | Pipeline 36-40 ciclos |
| **Bin to BCD** | bin_to_bcd (×4) | 200 | 0 | 0 | Conversión combinacional |
| **Mux Display** | mux_display | 30 | 20 | 0 | Multiplexador 2:1 |
| **7-Seg Decoder** | seven_seg_decoder | 20 | 0 | 0 | Tabla de decodificación |
| **Top Level** | interconexiones | 50 | 50 | 0 | Ruteamiento y lógica de control |
| **TOTAL ESTIMADO** | **~38 módulos** | **~1,038** | **~365** | **0** | **Utilización ≈ 2-3% de Tang Nano 9K** |

### Consumo de Potencia Teórico

**Parámetros:**
- Voltaje: 3.3V (del header FPGA)
- Frecuencia: 27 MHz (clk default FPGA)
- Capacitancia dinámica estimada: ~50 pF
- Factor de actividad: ~0.3

**Fórmula:** P = C × V² × f × α

- **Potencia Dinámica:** P_dyn ≈ 50pF × (3.3V)² × 27MHz × 0.3 ≈ **150 mW**
- **Potencia de Reposo:** P_static ≈ **50 mW** 
- **Potencia Total Estimada:** ~200 mW


## Velocidades de Reloj

### Análisis de Rutas Críticas

**Requerimiento del Proyecto:** Mínimo 27 MHz

**Estimación de Velocidades Máximas:**

| Ruta Crítica | Componentes | Retardo Estimado | Margen de Seguridad |
|---|---|---|---|
| **1. Teclado → Keycode** | sync → debounce → keypad → decoder | ~800 ns | TIMING POSITIVO |
| **2. Keycode → FSM** | keycode → fsm_teclado | ~400 ns | TIMING POSITIVO |
| **3. Entrada → División** | capturadores → division_unit → registros | ~1200 ns | TIMING POSITIVO |
| **4. BCD → Display** | bin_to_bcd → 7seg_decoder → mux | ~600 ns | TIMING POSITIVO |
| **5. Display Multiplexador** | contador → selector → salidas | ~500 ns | TIMING POSITIVO |

**Frecuencia Máxima Estimada:** **50-60 MHz** 


## Problemas y Soluciones

### 1. **Problema: Entrada del Teclado**

No se reconocian bien las entradas del teclado presuntamente por mal debounce y sync.

**Soluciones Implementadas:**

1. **Sincronización con Doble Flip-Flop:**
   - Reduce probabilidad de metaestabilidad
   - Latencia: 2 ciclos de reloj

2. **Debounce:**
   - Contador requiere LIMIT ciclos consecutivos del mismo nivel
   - Filtra completamente rebotes

3. **key_valid:**
   - FSM detecta flanco positivo de `key_valid`
   - Ignora pulsaciones adicionales hasta liberación de tecla

### 2. **Problema: Latencia de División Secuencial**

Retardo al presionar las teclas

**Soluciones Consideradas:**

1. **Pipeline:**
   - Insertar registros en múltiples puntos de división
   - Permitir  múltiples divisiones simultáneamente

2. **Display Interactivo:**
   - Mostrar operandos mientras se procesa division
   - Usuario ve entrada inmediata aunque división esté en proceso


### 3. **Problema: Proyecto Físico parcialmente funcional**

Se logro cumplir parcialmente con lo solicitado. Solo algunas teclas se veian bien en el display pero si ocurria una division ya que por ejemplo al dividir 3/3 daba 1 con residuo 0.
