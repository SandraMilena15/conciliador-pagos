# Perfil de fuentes – Conciliador de Pagos

Autora: Sandra Milena López · Datos de prueba del caso Treinta (Lab10)

## 1. Contexto y alcance
Treinta es una **plataforma** que procesa los pagos con tarjeta de sus comercios.
La venta del comercio queda registrada en la plataforma, y la **pasarela**
(el adquirente) es la que procesa y liquida el dinero.

Por eso la conciliación es de **dos vías: plataforma vs. pasarela**, vista desde Treinta.
No hay un archivo propio del comercio, porque la plataforma registra la venta en su nombre.

**Objetivo:** proteger a la plataforma de dos pérdidas:
1. Pagarle al comercio una venta que la pasarela nunca liquidó.
2. No pagarle al comercio una venta que la pasarela sí cobró.

## 2. Resumen de las fuentes
| | Plataforma (Treinta) | Pasarela |
|---|---|---|
| Qué representa | Registro de la venta por comercio | Transacción procesada y liquidada |
| Tabla de staging | `stg_plataforma` | `stg_pasarela` |
| Filas cargadas | 5.946 | 3.061 |
| Columnas | 23 | 28 |
| Granularidad | 1 fila = 1 transacción | 1 fila = 1 transacción |
| Llave | `acq_rrn` | `rrn` (Retrival Reference) |

Todas las columnas se cargan como **texto** en staging. La conversión de tipos
se hace después con SQL, para no perder datos en la carga.

## 3. Plataforma (Treinta)
| Campo | Formato encontrado | Problema | Tratamiento |
|---|---|---|---|
| `created_at` | `marzo 1, 2023, 11:59 PM` | Texto en español con AM/PM | Mapear el mes a número y convertir a timestamp |
| `amount`, `amt_*`, `net_amount_final` | `45.000` / `1.345,5` | Punto de miles y coma decimal | Quitar puntos y cambiar la coma por punto → numeric |
| `per_*` | `2,99%` | Porcentaje como texto | Quitar %, cambiar la coma por punto y dividir entre 100 |
| `acq_rrn` | 12 dígitos | Excel puede dañarlo (notación científica) | Mantener como texto y validar longitud = 12 |
| `acq_auth_code` | `R00988` | Alfanumérico | Mantener como texto |
| `terminal_id` | 4 dígitos | No coincide con la pasarela (8 dígitos) | No usar como llave |
| `card_schema` | `MASTERCARD DEBIT` | Distinto a la pasarela (`MasterCard`) | Normalizar la marca |
| `per_rteiva` | 15 % con monto 0 | Inconsistencia | Registrar como hallazgo y validar con el negocio |

**Regla de validación:** `net_amount_final = amount − amt_fee − amt_rtefte − amt_rteica − amt_rteiva` (cuadra en la muestra).

## 4. Pasarela
| Campo | Formato encontrado | Problema | Tratamiento |
|---|---|---|---|
| Encabezados | `Retefuente /Income Tax`, espacios, mayúsculas | No sirven como nombre de columna | Renombrar a snake_case antes de importar |
| `fecha_transaccion` + `hora` | `18/02/2023` + `23:59:11` | Fecha y hora en columnas separadas | `to_date(..., 'DD/MM/YYYY') + hora::time` |
| Montos | `$ 98.000,00`; `$ -` = 0 | Símbolo, separadores y guion como cero | Limpiar y convertir a numeric; el guion queda en 0 |
| `valor_franquicia` | 3 decimales | Precisión mayor que la de los demás montos | numeric sin redondear |
| `ciudad` | `PopayÃ‚Â¿n` | Codificación dañada | Reexportar en UTF-8 |
| `rrn` | 12 dígitos | Igual que en la plataforma | Texto, longitud = 12 |

**Regla de validación:** `total_deposito = valor_total − total_retenciones − tarifa_fija − tarifa_variable − valor_franquicia`
Ejemplo: 98.000 − 68 − 588 − 1.587,6 = 95.756,4 ✔

## 5. Hallazgos iniciales
- **Posible fraccionamiento o duplicado:** 5 compras idénticas de $98.000 en el terminal 21004823 en el mismo minuto.
- **Margen:** Treinta cobra 2,99 %, y la pasarela cuesta ≈ 0,6 % + $68 + ≈ 1,6 % de franquicia → hay que verificar el margen por transacción.
- **Retenciones:** el ReteICA varía entre 0,41 % y 0,42 %.
- **Plataforma:** 127 filas son copias exactas (error de exportación) → se depuran antes de cruzar.
- **Plataforma:** 54 ventas registradas dos veces, con el mismo RRN y el mismo `reference_id` a horas distintas → posible sobrepago de $2.467.455 COP (valor bruto; el neto se calcula en la etapa de cruce).
- **Pasarela:** 1 registro inválido (RRN = 0, fecha en formato MM/DD) → se excluye del cruce.
- **Periodo:** las fuentes cubren periodos distintos → la conciliación se limita a marzo de 2023.

## 6. Riesgos de los datos
- Excel puede dañar el RRN → importar desde CSV con la columna como texto.
- El CSV de Excel trae BOM y usa `;` como separador → guardar en UTF-8 sin BOM.
- Las ventas cerca de la medianoche generan diferencias por **corte de fecha**.
