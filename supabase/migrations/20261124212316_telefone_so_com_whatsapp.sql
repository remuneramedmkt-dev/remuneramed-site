-- =====================================================================
-- 20261124212316 telefone_so_com_whatsapp: lista de espera, celular só com o aceite do WhatsApp
-- (e obrigatório com ele).
-- APLICADA no Supabase (projeto pvfnkokgpkcqzdpzvkcg) em 24/11/2026, às 18h23 (horário de Brasília),
-- pela Conformidade, com autorização do Gabriel. Versão e nome conferidos em
-- supabase_migrations.schema_migrations; os comandos abaixo são os mesmos registrados lá.
--
-- Decisão do Gabriel de 24/11/2026, 18h13: especialidade, estado e cidade seguem obrigatórios;
-- celular só para quem marca o WhatsApp. SQL final da revisão da Conformidade
-- (REVISAO-2026-11-24-conversao-site.md, seção "Revisão final e0e1bd8").
-- Nada mais muda: especialidade, uf, cidade e codigo_ibge_municipio seguem NOT NULL; as demais
-- CHECKs, a RLS e os gatilhos ficam como estavam.
-- Como consentimento_whatsapp é NOT NULL, as duas CHECKs juntas fazem valer
-- "celular se, e somente se, houver opt-in do WhatsApp".
--
-- Definições no banco (pg_get_constraintdef, conferidas em 24/11/2026):
--   lista_espera_sem_whatsapp_sem_tel: CHECK (((consentimento_whatsapp IS TRUE) OR (telefone IS NULL)))
--   lista_espera_tel_se_whatsapp:      CHECK (((consentimento_whatsapp IS NOT TRUE) OR (telefone IS NOT NULL)))
-- =====================================================================

alter table public.lista_espera alter column telefone drop not null;
alter table public.lista_espera add constraint lista_espera_sem_whatsapp_sem_tel check (consentimento_whatsapp is true or telefone is null);
alter table public.lista_espera add constraint lista_espera_tel_se_whatsapp check (consentimento_whatsapp is not true or telefone is not null);
comment on column public.lista_espera.telefone is 'Celular +55DDNXXXXXXXX. Presente se e somente se consentimento_whatsapp = true (desde 24/11/2026).';

-- ROLLBACK (só se nenhuma linha tiver telefone NULL; antes, decidir com o Gabriel o que fazer com essas linhas):
-- alter table public.lista_espera drop constraint lista_espera_tel_se_whatsapp;
-- alter table public.lista_espera drop constraint lista_espera_sem_whatsapp_sem_tel;
-- alter table public.lista_espera alter column telefone set not null;
-- comment on column public.lista_espera.telefone is null;
