-- =========================================================
-- Conciliador de Pagos (caso Treinta) · Tablas de staging
-- Todo se carga como texto, tal como llega en el archivo.
-- La limpieza (montos, fechas, llaves) se hace después, con SQL.
-- =========================================================

-- 1. Pasarela (archivo del adquirente / procesador de pagos)
--    Los nombres de columna son los del archivo, renombrados a snake_case.
create table stg_pasarela (
  fecha_transaccion   text,  -- Transaction date (dd/mm/aaaa)
  hora                text,  -- Time (hh:mm:ss)
  fecha_liquidacion   text,  -- Posting date (dd/mm/aaaa)
  slip                text,  -- Slip
  estado              text,  -- Status
  reverso             text,  -- Reversal
  origen              text,  -- Tran Source
  clase               text,  -- Class
  tipo                text,  -- Type
  marca_tarjeta       text,  -- Card brand
  ciudad              text,  -- City
  pais                text,  -- Country
  merchant_no         text,  -- Merchant no.
  rrn                 text,  -- Retrival Reference  (LLAVE DE CRUCE)
  codigo_autorizacion text,  -- Auth. code
  terminal_id         text,  -- Terminal ID
  valor_compra        text,  -- Tran Amount Gr/Valor compra
  iva                 text,  -- IVA
  imp_consumo         text,  -- IMP CONSUMO
  valor_total         text,  -- VALOR TOTAL
  retefuente          text,  -- Retefuente /Income Tax
  reteica             text,  -- ReteICA /Municipal Tax
  reteiva             text,  -- ReteIVA/VAT tax
  total_retenciones   text,  -- TOTAL RETENCIONES
  tarifa_fija         text,  -- Tarifa fija
  tarifa_variable     text,  -- Tarifa Variable
  valor_franquicia    text,  -- Valor cobrado por la franquicia
  total_deposito      text,  -- TOTAL EN DEPOSITO
  cargado_en          timestamptz not null default now()
);

-- 2. Plataforma (registro de Treinta)
--    Se conservan los nombres originales, que ya vienen en snake_case.
create table stg_plataforma (
  store_id                   text,
  user_id                    text,
  terminal_id                text,
  created_at                 text,  -- "marzo 1, 2023, 11:59 PM"
  treinta_transaction_id     text,
  reference_id               text,
  card_schema                text,
  acq_rrn                    text,  -- (LLAVE DE CRUCE con stg_pasarela.rrn)
  acq_auth_code              text,
  installments_quantity      text,
  acq_gateway_response_text  text,
  amount                     text,
  amt_iva                    text,
  per_iva                    text,
  amt_fee                    text,
  per_fee                    text,
  amt_rtefte                 text,
  per_rtefte                 text,
  amt_rteica                 text,
  per_rteica                 text,
  amt_rteiva                 text,
  per_rteiva                 text,
  net_amount_final           text,
  cargado_en                 timestamptz not null default now()
);

-- 3. Alcance: conciliación de dos vías (plataforma vs. pasarela).
--    La plataforma registra la venta en nombre del comercio; no hay archivo del comercio.

-- 4. Seguridad
alter table stg_pasarela   enable row level security;
alter table stg_plataforma enable row level security;
