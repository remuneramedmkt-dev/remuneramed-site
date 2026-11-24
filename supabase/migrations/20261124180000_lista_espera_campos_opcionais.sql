-- =====================================================================
-- 05: lista de espera, celular só com o aceite do WhatsApp (rascunho de 24/11/2026, NÃO APLICADA).
--
-- Decisão do Gabriel de 24/11/2026, 18h13 (relatada pela Conformidade): especialidade, estado e
-- cidade continuam OBRIGATÓRIOS; o celular passa a ser pedido só para quem marca o WhatsApp.
-- Esta migration faz só duas coisas:
--   1. telefone aceita NULL (drop not null);
--   2. CHECK lista_espera_sem_whatsapp_sem_tel: sem o aceite do WhatsApp, o banco não guarda
--      celular (minimização, LGPD art. 6º, III), pedido da Conformidade em 24/11/2026
--      (REVISAO-2026-11-24-conversao-site.md).
-- Nada mais muda: especialidade, uf, cidade e codigo_ibge_municipio seguem NOT NULL; as CHECKs,
-- a RLS e os gatilhos atuais (inclusive lista_espera_normalizar) ficam como estão.
-- Observação: não há CHECK obrigando o celular quando consentimento_whatsapp = true; isso é
-- garantido só pelo front (assets/lista-espera.js). A lista_espera_tel_fmt continua validando
-- o formato quando o celular vem preenchido.
--
-- Projeto: remuneramed (pvfnkokgpkcqzdpzvkcg, São Paulo). Schema conferido por leitura em
-- 24/11/2026 (última migration aplicada: 20261119231352 lista_espera_whatsapp_check_nulo).
-- A tabela tinha 0 linhas em 24/11/2026 (select count(*) só de leitura). Se entrarem linhas
-- antes de aplicar, conferir antes:
--   select count(*) from public.lista_espera
--   where consentimento_whatsapp is false and telefone is not null;
-- Se der mais que zero, a CHECK falha ao ser criada; o que fazer com esses celulares
-- (tratamento de dados) precisa de decisão do Gabriel.
--
-- ORDEM DE PUBLICAÇÃO: aplicar esta migration ANTES do merge do front (branch
-- conversao-2026-11-24). O front novo envia telefone NULL sem WhatsApp e falharia com o banco atual.
-- Inscrições COM WhatsApp continuam funcionando com o front atual depois desta migration; sem
-- WhatsApp, o front atual (que sempre manda o celular) passaria a ser recusado pela CHECK, então
-- o merge deve vir logo depois da aplicação.
-- Depende de: revisão final da Conformidade e autorização expressa do Gabriel.
-- =====================================================================

alter table public.lista_espera
  alter column telefone drop not null;

alter table public.lista_espera
  add constraint lista_espera_sem_whatsapp_sem_tel
  check (consentimento_whatsapp is true or telefone is null);

comment on column public.lista_espera.telefone is 'Celular +55DDNXXXXXXXX. Só com consentimento_whatsapp = true (desde a migration 20261124180000).';

-- ROLLBACK (só funciona se nenhuma linha tiver telefone NULL; antes, decida com o Gabriel o que fazer com essas linhas):
-- alter table public.lista_espera drop constraint lista_espera_sem_whatsapp_sem_tel;
-- alter table public.lista_espera alter column telefone set not null;
-- comment on column public.lista_espera.telefone is null;
