# Digital2-Grupo8

# Control de Ascensor con PIC 16F887
**TP Final — Digital II | Grupo 8**

## Descripción general

Sistema de control de ascensor de 4 pisos implementado sobre un microcontrolador PIC 16F887. El movimiento de la cabina es simulado por un motor DC controlado por el PIC, mientras que 4 displays de 7 segmentos multiplexados indican el piso actual en todo momento. Un sensor infrarrojo MH-Series actúa como mecanismo de seguridad de puerta: si detecta una obstrucción durante el desplazamiento, el sistema detiene el motor de forma inmediata. El estado general del ascensor se señaliza mediante tres LEDs, y todos los eventos relevantes se reportan en tiempo real a través de comunicación UART hacia una PC.

## Estados del sistema

| Estado       | LED activo | Condición                                      |
|-------------|------------|------------------------------------------------|
| Inactivo    | 🔴 Rojo    | Sin solicitudes pendientes, ascensor detenido  |
| En movimiento | 🟡 Amarillo | Trasladándose hacia el piso de destino       |
| Piso alcanzado | 🟢 Verde  | Llegó al destino, puertas habilitadas         |

## Componentes utilizados

| Componente                  | Función en el sistema                                     |
|-----------------------------|-----------------------------------------------------------|
| PIC 16F887                  | Microcontrolador principal, gestiona toda la lógica       |
| Motor DC                    | Actuador que simula el movimiento de la cabina            |
| Sensor IR (MH-Sensor-Series)| Detección de obstrucción en puerta, seguridad del sistema |
| LEDs (rojo / amarillo / verde) | Señalización visual del estado del ascensor            |
| 4× Display 7 segmentos      | Indicación del piso actual (multiplexados por software)   |
| Módulo UART                 | Comunicación serie para monitoreo desde PC                |

## Funcionamiento

1. El usuario ingresa el piso de destino mediante la botonera.
2. El sistema enciende el LED amarillo e inicia el motor en la dirección correspondiente.
3. Durante el movimiento, el sensor infrarrojo monitorea la puerta de forma continua; ante cualquier obstrucción, el motor se detiene de inmediato.
4. Al alcanzar el piso solicitado, el motor se detiene y el LED verde confirma la llegada.
5. Cuando no hay solicitudes activas, el LED rojo indica que el sistema está en reposo.
6. El piso actual se refleja en todo momento en los displays de 7 segmentos.
7. Cada cambio de estado se transmite por UART para registro y monitoreo externo.