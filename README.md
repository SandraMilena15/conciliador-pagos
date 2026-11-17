# Conciliador de Pagos – Treinta

Conciliación de dos vías entre la plataforma (Treinta) y la pasarela de pagos:
detecta ventas no liquidadas, cobros no registrados, diferencias de monto,
duplicados y cortes de fecha, y mide el margen por transacción.

> Estado: en construcción. Datos de prueba de un caso práctico (Lab10).

## Documentación
- [Perfil de fuentes](docs/perfil_fuentes.md): formatos, calidad y reglas de validación
- [Llaves de cruce](docs/llaves_cruce.md): RRN, niveles de cruce y tipos de diferencia

## Avance
- [x] Perfilamiento de fuentes y carga a staging en Supabase (5.946 + 3.061 filas)
- [ ] Limpieza y tipado con SQL
- [ ] Motor de cruce y clasificación de diferencias
- [ ] Dashboard y agente de consulta

## Hallazgos principales
- 54 ventas registradas dos veces en la plataforma, por $2.467.455 COP (valor bruto) en posibles sobrepagos.
- 127 filas duplicadas por error de exportación, depuradas antes del cruce.

## Autora
Sandra Milena López · [LinkedIn](https://linkedin.com/in/smilenalopezpuentes)
