-- =====================================================================
-- 20261124180000: lista de espera, celular só com o aceite do WhatsApp (e obrigatório com ele).
-- RASCUNHO, NÃO APLICADA. Aplicar só com autorização expressa do Gabriel, ANTES do merge do PR #3.
--
-- Decisão do Gabriel de 24/11/2026, 18h13: especialidade, estado e cidade seguem obrigatórios;
-- celular só para quem marca o WhatsApp. Revisão da Conformidade (SQL final da seção
-- "Revisão final e0e1bd8"): REVISAO-2026-11-24-conversao-site.md.
-- Nada mais muda: especialidade, uf, cidade e codigo_ibge_municipio seguem NOT NULL; as CHECKs,
-- a RLS e os gatilhos atuais (inclusive lista_espera_normalizar) ficam como estão.
-- Como consentimento_whatsapp é NOT NULL, as duas CHECKs juntas fazem valer
-- "celular se, e somente se, houver opt-in do WhatsApp". Ficam separadas para que cada erro
-- diga o que falhou.
--
-- Pré-checagem (deve dar 0 nas duas; a tabela tinha 0 linhas em 24/11/2026). Versão completa,
-- só leitura, em PRECHECK.sql (pasta de prints da conversão):
--   select count(*) from public.lista_espera where consentimento_whatsapp is false and telefone is not null;
--   select count(*) from public.lista_espera where consentimento_whatsapp is true and telefone is null;
--
-- Sem begin/commit explícitos: o apply_migration do Supabase (e o CLI) já roda o arquivo numa
-- transação. Para aplicar pelo psql, use psql -1 (uma transação só).
--
-- ORDEM: pré-checagem -> aplicar -> merge do front logo em seguida. Depois desta migration, o
-- front atual (que sempre manda o celular) tem as inscrições SEM WhatsApp recusadas.
-- =====================================================================

alter table public.lista_espera
  alter column telefone drop not null;

-- Sem aceite do WhatsApp, sem celular (minimização, LGPD art. 6º, III).
alter table public.lista_espera
  add constraint lista_espera_sem_whatsapp_sem_tel
  check (consentimento_whatsapp is true or telefone is null);

-- Com aceite do WhatsApp, celular obrigatório (o opt-in sem número não tem utilidade).
alter table public.lista_espera
  add constraint lista_espera_tel_se_whatsapp
  check (consentimento_whatsapp is not true or telefone is not null);

comment on column public.lista_espera.telefone is
  'Celular +55DDNXXXXXXXX. Presente se e somente se consentimento_whatsapp = true (desde a migration 20261124180000).';

-- ROLLBACK (só se nenhuma linha tiver telefone NULL; antes, decidir com o Gabriel o que fazer com essas linhas):
-- alter table public.lista_espera drop constraint lista_espera_tel_se_whatsapp;
-- alter table public.lista_espera drop constraint lista_espera_sem_whatsapp_sem_tel;
-- alter table public.lista_espera alter column telefone set not null;
-- comment on column public.lista_espera.telefone is null;
