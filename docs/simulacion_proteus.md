# Guía de Simulación en Proteus — Control de Temperatura Pava Eléctrica

Guía paso a paso para montar y simular el proyecto (firmware `TP Final/Pava.asm`) en Proteus 8 (ISIS). Incluye lista de componentes, conexiones pin por pin y cómo cargar el `.hex` y probar por el terminal virtual.

> **Importante:** Proteus simula toda la lógica (recepción del setpoint, ADC, multiplexado de displays, control del relé con histéresis y la UART), pero **no simula la realimentación térmica**: al encender el relé, el LM35 no sube de temperatura solo. Para probar el lazo se mueve a mano el valor del LM35.

---

## 1. Compilar el `.hex`

El firmware está en ensamblador, así que se compila con **MPASM**:

1. Abrir **MPLAB X IDE** (o MPLAB IDE v8.92) y crear un proyecto para el **PIC16F887** usando el toolchain **mpasm**.
2. Agregar `Pava.asm` como *Source File*.
3. Compilar (*Build* / F11). Se genera `Pava.hex` en la carpeta de salida del proyecto.

> El archivo `Pava.asm` ya define la palabra de configuración (`__CONFIG`) con oscilador interno, WDT off, etc., por lo que el `.hex` queda autocontenido.

---

## 2. Lista de Componentes (Pick Devices `P`)

| Componente | Palabra clave en Proteus | Cant. |
|---|---|---|
| Microcontrolador | `PIC16F887` | 1 |
| Sensor de temperatura | `LM35` | 1 |
| Display 7 seg cátodo común | `7SEG-COM-CATHODE` (o un `7SEG-MPX4-CC`) | 4 (o 1) |
| Transistor NPN (barrido displays) | `2N2222` o `BC547` | 4 |
| Optoacoplador | `PC817` | 1 |
| Transistor NPN (driver relé) | `BC547` | 1 |
| Relé | `RELAY` (o un módulo relé) | 1 |
| Diodo de protección (flyback) | `1N4148` / `1N4007` | 1 |
| Carga (resistencia de la pava) | `LAMP` | 1 |
| Resistencias 330 Ω (segmentos) | `RES` | 7 |
| Resistencias 1 kΩ (bases transistores) | `RES` | 5 |
| Resistencia 10 kΩ (pull-up MCLR) | `RES` | 1 |
| Terminal virtual (instrumento UART) | *Virtual Terminal* | 1 |
| Fuente / GND | `POWER` (+5V) y `GROUND` | — |

> Si preferís simplificar el hardware real, podés reemplazar el bloque **PC817 + transistor + relé** por un **módulo relé optoacoplado** (entrada por nivel alto, ya que el firmware activa RB0 en alto).

---

## 3. Configurar el PIC16F887

1. Doble clic sobre el PIC → *Edit Properties*.
2. **Program File:** seleccionar `Pava.hex`.
3. **Processor Clock Frequency:** `4 MHz` (coincide con el oscilador interno configurado en el firmware; Proteus usa este valor para la temporización).
4. Conectar:
   - **VDD** (pines 11 y 32) → **+5 V**
   - **VSS** (pines 12 y 31) → **GND**
   - **MCLR/RE3** (pin 1) → **+5 V** a través de una resistencia de **10 kΩ** (el firmware usa `MCLRE_ON`).

---

## 4. Conexiones pin por pin

### Sensor LM35 → ADC
| LM35 | PIC |
|---|---|
| Vout | **RA0 / AN0** (pin 2) |
| +Vs | +5 V |
| GND | GND |

### Displays de 7 segmentos (cátodo común)
Los **segmentos a–g** se conectan en paralelo a los 4 displays, cada línea con una resistencia de **330 Ω**:

| Segmento | PIC (PORTD) |
|---|---|
| a | RD0 |
| b | RD1 |
| c | RD2 |
| d | RD3 |
| e | RD4 |
| f | RD5 |
| g | RD6 |

La **habilitación de cada dígito** se hace con un transistor NPN en el cátodo común (RCx en alto → transistor conduce → cátodo a GND → dígito encendido). Base con resistencia de **1 kΩ**:

| Habilitación | PIC | Muestra |
|---|---|---|
| Dígito 1 → Q1 | RC0 (pin 15) | Temperatura (dígito) |
| Dígito 2 → Q2 | RC1 (pin 16) | Temperatura (dígito) |
| Dígito 3 → Q3 | RC2 (pin 17) | Setpoint (dígito) |
| Dígito 4 → Q4 | RC3 (pin 18) | Setpoint (dígito) |

> RC0–RC1 muestran la **temperatura** medida y RC2–RC3 el **setpoint**. Si algún par de dígitos aparece con decena/unidad invertidas, intercambiá físicamente esos dos displays (el firmware ya hace una corrección de orden).

### Relé con aislamiento (RB0)
`RB0 (pin 33)` → R 1 kΩ → **LED del PC817** → (lado de salida) transistor BC547 → bobina del **relé** → +5 V, con el **diodo flyback** en antiparalelo sobre la bobina. Los contactos del relé conmutan la **carga (LAMP)** que representa la resistencia de la pava.

> Si usás un módulo relé optoacoplado: `RB0` → IN del módulo, VCC → +5 V, GND → GND.

### UART → Terminal Virtual
| PIC | Terminal Virtual |
|---|---|
| RC6 / TX (pin 25) | **RXD** |
| RC7 / RX (pin 26) | **TXD** |
| GND | GND |

Configurar el terminal: **9600 baudios, 8 bits de datos, sin paridad, 1 bit de stop** (8N1).

---

## 5. Simular y probar

1. Pulsar **Play** (▶) para iniciar la simulación.
2. En el terminal virtual debería aparecer el mensaje de arranque: **`LISTO`**.
3. **Fijar el setpoint:** escribir en el terminal `U70` y presionar **Enter**. Los displays RC2–RC3 mostrarán `70`.
4. Cada ~1 segundo el terminal imprime el estado:
   ```
   S=70;T=25;R=0
   ```
   donde `S` = setpoint, `T` = temperatura, `R` = estado del relé (0/1).
5. **Probar el control:** mover el valor del **LM35** (clic en las flechas del componente durante la simulación):
   - Con temperatura **por debajo de `setpoint − 5`** → el relé se activa (`R=1`) y la lámpara enciende.
   - Al alcanzar o superar el **setpoint** → el relé se apaga (`R=0`) y la lámpara se apaga.
   - Entre ambos valores se mantiene el último estado (**histéresis**).

---

## 6. Problemas frecuentes

- **Los displays se ven tenues o "fantasma":** es normal en multiplexado; subí la velocidad de animación de Proteus o verificá las resistencias de segmento (330 Ω).
- **El terminal no muestra nada:** revisá que RC6→RXD y RC7→TXD (no invertidos) y que el baud rate sea 9600 8N1.
- **La temperatura mostrada no coincide con el LM35:** la conversión a °C del firmware (`≈ ADC×1,9`) es aproximada. Con LM35 (10 mV/°C) y Vref = 5 V conviene recalcular/calibrar la fórmula de `CALC_TEMP`.
- **El relé no conmuta:** confirmá que el setpoint ya fue cargado (sin `Uxx` recibido, el relé queda apagado por seguridad) y que RB0 llega al optoacoplador/módulo.
