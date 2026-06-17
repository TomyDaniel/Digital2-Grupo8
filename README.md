# Control de Temperatura para Pava Eléctrica

> **Asignatura:** Electrónica Digital II — Universidad Nacional de Córdoba
> **Integrantes:**
> * Kulichevsky, Lucia
> * Torossi, Abril
> * Daniel, Tomas
>
> **Profesor:** Blasco, Marcos
> **Grupo:** 8

---

## 🚀 1. Descripción General del Proyecto

Sistema embebido de control de temperatura para una pava eléctrica, implementado sobre un microcontrolador **PIC16F887**. El usuario fija un **umbral de temperatura** enviándolo por **UART** desde la PC. El sistema mide de forma continua la temperatura del agua con un **sensor analógico** y, mediante un **optoacoplador**, comanda un **relé** que habilita la resistencia calefactora de la pava. El control es por **histéresis**: el relé enciende cuando la temperatura cae por debajo del umbral y se apaga al alcanzarlo, evitando conmutaciones constantes.

La información se presenta en **4 displays de 7 segmentos multiplexados** y, en paralelo, se transmite el estado completo por **UART** hacia el monitor serie de una PC una vez por segundo, con el formato `S=<setpoint>;T=<temperatura>;R=<estado_relé>`. El sistema está pensado como un control on/off con histéresis para calentamiento de agua con apagado automático.

### 🎯 Alcances del Proyecto (¿Qué hace y qué NO hace el sistema?)

* **El sistema SÍ es capaz de:** medir la temperatura en tiempo real mediante el ADC interno; recibir y fijar el umbral por comando UART; controlar la resistencia a través de un relé comandado por optoacoplador, con lógica de histéresis; mostrar simultáneamente temperatura y setpoint en 4 displays de 7 segmentos; y reportar el estado por UART cada ~1 segundo. Ademas incluye una interfaz grafica dedicada para el monitoreo.
* **El sistema NO incluye:** carga del umbral por teclado físico; control de temperatura por algoritmo PID; almacenamiento local de datos; conectividad inalámbrica.

### ⏩ Posibles Etapas Siguientes

* Agregar un teclado matricial para configurar el setpoint de forma local, sin depender de la PC.
* Implementar un control PID para mantener la temperatura estable en lugar del control on/off por histéresis.
* Migrar el circuito de protoboard a un PCB con aislamiento reforzado entre la etapa de potencia y la etapa de control de baja tensión.

---

## 📐 2. Arquitectura del Sistema: Hardware y Software

### 🔌 Hardware & Interconexión

* **Diagrama de Bloques:**

  ![Diagrama de Bloques del Sistema](hardware/diagrama_bloques.png)
* **Esquemático del Circuito:** 

  ![Esquematico en proteus](docs/img/EsquematicoProteus.png)
* **Asignación de pines:**

  | Pin            | Función                                              |
  |----------------|------------------------------------------------------|
  | RA0 / AN0      | Entrada analógica del sensor de temperatura          |
  | RB0            | Salida al optoacoplador → relé (activo en alto)      |
  | PORTD (RD0–RD6)| Segmentos de los displays (cátodo común)             |
  | RC0, RC1       | Habilitación displays de **temperatura** (decena/unidad) |
  | RC2, RC3       | Habilitación displays de **setpoint** (decena/unidad)|
  | RC6 / RC7      | UART TX / RX (9600 baudios)                          |

* **Descripción del Circuito y Consideraciones de Diseño:**
  * **Acondicionamiento del sensor:** la tensión del sensor de temperatura ingresa por AN0; se digitaliza con el ADC y se convierte a °C por software.
  * **Aislamiento de potencia:** el optoacoplador separa galvánicamente la salida RB0 del PIC del circuito del relé, protegiendo la lógica de la etapa de red.
  * **Protección inductiva:** diodo de marcha libre en la bobina del relé para suprimir picos de tensión al desconectar.
  * **Multiplexado de displays:** los 4 displays comparten las líneas de segmento y se habilitan secuencialmente desde RC0–RC3, reduciendo el número de pines.

  > **Nota:** el sensor utilizado es el **LM35** (10 mV/°C). La conversión a °C en `CALC_TEMP` es una aproximación (≈ ADC×1,9) que conviene calibrar contra una referencia.

### 💻 Arquitectura de Software (Firmware)

* **Descripción:** el lazo principal (`MAIN`) ejecuta cíclicamente: recepción UART → lectura del ADC → cálculo de temperatura → actualización de displays → control del relé, y envía el estado por UART cuando se cumple el período de ~1 s. El refresco multiplexado de los 4 displays y la temporización del envío UART se gestionan en la **ISR del Timer0**.

---

## ⚡ 3. Especificaciones Eléctricas, Alimentación y Entorno

### 🔌 Parámetros de Alimentación y Consumo

* **Tensión de operación del sistema:** 5 V
* **Método de alimentación:** Alimentación por USB desde la Notebook. La etapa de potencia se alimenta de forma independiente y aislada mediante el optoacoplador.


### 📌 Electrónica Digital II — PIC16F887

* **Herramientas de Software:** MPLAB X IDE, ensamblador **MPASM**.
* **Configuración de Bits:**
  * *Oscilador:* `INTRC` — oscilador **interno a 4 MHz**, configurado vía `OSCCON`
  * *Watchdog Timer (WDT):* `OFF`
  * *Power-up Timer (PWRTE):* `ON`
  * *Master Clear (MCLRE):* `ON`
  * *Brown-out Reset (BOREN):* `ON`
  * *Low Voltage Programming (LVP):* `OFF`
  * *Protección de código (CP / CPD):* `OFF`
* **Periféricos Internos Utilizados:**
  * **ADC** — canal AN0, Vref = Vdd, reloj Fosc/8, justificación izquierda.
  * **EUSART** — UART asíncrona a **9600 baudios**, TX en RC6 y RX en RC7.
  * **Timer0** — base de tiempo para el multiplexado de displays y la temporización del envío UART.
* **Gestión de Interrupciones:** el PIC16F887 dispone de un único vector de interrupción. En este diseño **solo se habilita la interrupción del Timer0** (`GIE` + `T0IE`), que en la ISR atiende el refresco constante de los displays y lleva el contador para el envío periódico por UART. La **recepción UART se resuelve por *polling*** dentro del lazo principal, ya que la llegada de un comando de setpoint no es crítica en el tiempo y no justifica una interrupción adicional; esto mantiene la ISR corta y determinística.

---

## 🔄 4. Proceso de Integración y Desarrollo

* **Etapa 1 (Validación inicial):** configuración del oscilador interno y de los puertos; verificación de reloj e interrupción de Timer0.
* **Etapa 2 (Interfaz visual):** implementación del multiplexado de los 4 displays de 7 segmentos con Timer0.
* **Etapa 3 (Adquisición y comunicación):** puesta en marcha del ADC para la lectura del sensor y del EUSART para recibir el setpoint y enviar el estado.
* **Etapa 4 (Sistema completo):** integración de la lógica de control con histéresis, comando del relé vía optoacoplador, calibración del sensor y pruebas de estrés del sistema completo.

---

## 📊 5. Ensayos, Pruebas y Resultados

* **Evidencia Fotográfica y Gráficos:**
![Prototipo](<docs/img/Prototipo en protoboard .jpeg>)
![Setup](docs/img/Setup.jpeg)
  ![Interfaz gráfica](<docs/img/Interfaz gráfica.jpeg>)
---

## 📂 6. Estructura del Repositorio

El repositorio debe mantener la siguiente estructura limpia (recuerden configurar el `.gitignore` para no subir carpetas temporales como `dist/`, `build/`, ni archivos intermedios `.cof` / `.hex`):

```text
├── firmware/          # Código fuente del proyecto
│   └── src/           # Archivos de código 
├── hardware/          # Archivos de diseño, esquemáticos y BOM
├── docs/              # Datasheets clave, imágenes del README, diagramas
└── README.md          # Este archivo de presentación
```

> **Nota:** el firmware del proyecto se encuentra en `firmware/src/Pava.asm`. En `TP's Clases/` están los ejercicios de cursado.
