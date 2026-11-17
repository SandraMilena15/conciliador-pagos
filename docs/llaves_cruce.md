# Llaves de cruce – Conciliador de Pagos

Conciliación de dos vías: **plataforma (`stg_plataforma`) vs. pasarela (`stg_pasarela`)**.

## 1. Llave principal: RRN
El **RRN** (*Retrieval Reference Number*) es el número único de 12 dígitos que
la red de pagos asigna a cada transacción con tarjeta. Funciona como la cédula
de la transacción y existe en las dos fuentes:

| Fuente | Columna |
|---|---|
| Plataforma | `acq_rrn` |
| Pasarela | `rrn` (en el archivo original: *Retrival Reference*) |

**Validación del RRN:** sus primeros 6 dígitos son la hora de la transacción (HHMMSS).
Ejemplo: `235911325701` → 23:59:11, que coincide con `11:59 PM` en `created_at`.

## 2. Cruce por niveles
| Nivel | Regla | Uso |
|---|---|---|
| 1 | `acq_rrn = rrn` | Cruce exacto |
| 1b | Nivel 1 + `acq_auth_code = codigo_autorizacion` | Confirma que el nivel 1 es correcto |
| 2 | Monto + fecha y hora (± 5 min) + marca normalizada | Filas sin RRN o sin cruce exacto |
| Sin cruce | Ninguna regla aplica | Se clasifica como diferencia |

**Campos que NO sirven como llave:** `terminal_id` (4 dígitos vs. 8) y la marca sin normalizar.

## 3. Clasificación de diferencias
| Tipo | Regla | Riesgo para la plataforma |
|---|---|---|
| Falta en pasarela | Está en la plataforma pero no en la pasarela | Pagarle al comercio lo que no se recibió |
| Falta en plataforma | Está en la pasarela pero no en la plataforma | El comercio no recibe su plata → reclamo |
| Diferencia de monto | Mismo RRN, monto distinto | Pérdida o sobrepago |
| Duplicado | RRN repetido en una fuente | Pago doble |
| Corte de fecha | Mismo RRN, el día cambia cerca de la medianoche | Falso descuadre (no es un error real) |
| Reverso | La pasarela marca reverso | La venta no debe pagarse |

## 4. Supuestos y pendientes
- La tolerancia de ± 5 min del nivel 2 es un supuesto; se ajusta después de ver los datos.
- Falta validar con el negocio la inconsistencia de `per_rteiva`.
- Las muestras de prueba pueden no traslaparse en fechas; el porcentaje de cruce se mide después de la carga completa.
