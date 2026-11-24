-- =====================================================================
-- 05: lista de espera com formulário curto (rascunho de 24/11/2026, NÃO APLICADA).
--
-- O que muda:
--   * Obrigatórios passam a ser só nome, e-mail e o aceite do e-mail
--     (consentimento_lgpd + texto_consentimento), que já eram NOT NULL e continuam.
--   * telefone, especialidade, uf, cidade e codigo_ibge_municipio deixam de ser NOT NULL.
--   * O celular passa a ser obrigatório só quando consentimento_whatsapp = true.
--   * O front deixa de enviar o celular sem o aceite do WhatsApp (minimização, LGPD
--     art. 6º, III). Não há CHECK para isso no banco (ver o motivo mais abaixo).
--   * Cidade e código IBGE andam juntos, e cidade exige estado (o CHECK
--     lista_espera_ibge_uf não pega o caso de uf nulo com código preenchido).
--
-- Continuam valendo, sem mudança (todos aceitam NULL por serem CHECK):
--   lista_espera_tel_fmt, lista_espera_especialidade_val, lista_espera_especialidade_outra_val,
--   lista_espera_uf_val, lista_espera_cidade_tam, lista_espera_ibge_uf, lista_espera_whatsapp_val,
--   a política de RLS "anon pode inserir inscricao com consentimento" e os gatilhos
--   z_ignorar_duplicado e z_limite.
--
-- Projeto: remuneramed (pvfnkokgpkcqzdpzvkcg, São Paulo). Schema conferido por leitura em
-- 24/11/2026 (última migration aplicada: 20261119231352 lista_espera_whatsapp_check_nulo).
--
-- ORDEM DE PUBLICAÇÃO: aplicar esta migration ANTES do merge do front (branch
-- conversao-2026-11-24). O front novo envia NULL nesses campos e falharia com o banco atual.
-- O front atual continua funcionando depois desta migration (ele sempre manda tudo preenchido).
-- Depende de: revisão da Conformidade e autorização do Gabriel.
-- =====================================================================

alter table public.lista_espera
  alter column telefone drop not null,
  alter column especialidade drop not null,
  alter column uf drop not null,
  alter column cidade drop not null,
  alter column codigo_ibge_municipio drop not null;

-- Celular obrigatório quando marcar o WhatsApp.
alter table public.lista_espera
  add constraint lista_espera_tel_se_whatsapp
  check (consentimento_whatsapp is false or telefone is not null);

-- Sem WhatsApp, sem celular: o front novo não envia o celular quando a caixa do WhatsApp
-- está desmarcada. De propósito, NÃO há CHECK para isso no banco: as inscrições antigas
-- guardaram o celular pelo formulário anterior, e um CHECK (mesmo NOT VALID) seria
-- reavaliado em qualquer UPDATE dessas linhas (testado em Postgres 17 local), travando
-- correções e pedidos de titulares. Se a Conformidade quiser a regra no banco, primeiro
-- decidir o que fazer com o celular das linhas antigas sem WhatsApp.

-- Cidade e código IBGE juntos; cidade exige estado.
alter table public.lista_espera
  add constraint lista_espera_cidade_coerente
  check ((cidade is null) = (codigo_ibge_municipio is null)
         and (codigo_ibge_municipio is null or uf is not null));

-- Normalização: texto vazio vira NULL nos campos que ficaram opcionais.
create or replace function public.lista_espera_normalizar()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.nome  := btrim(new.nome);
  new.email := lower(btrim(new.email));
  new.telefone      := nullif(btrim(new.telefone), '');
  new.especialidade := nullif(btrim(new.especialidade), '');
  new.especialidade_outra := nullif(btrim(new.especialidade_outra), '');
  new.uf           := nullif(btrim(new.uf), '');
  new.cidade       := nullif(btrim(new.cidade), '');
  new.texto_consentimento_whatsapp := nullif(btrim(new.texto_consentimento_whatsapp), '');
  new.origem       := nullif(btrim(new.origem), '');
  new.pagina       := nullif(btrim(new.pagina), '');
  new.utm_source   := nullif(btrim(new.utm_source), '');
  new.utm_medium   := nullif(btrim(new.utm_medium), '');
  new.utm_campaign := nullif(btrim(new.utm_campaign), '');
  new.utm_content  := nullif(btrim(new.utm_content), '');
  new.utm_term     := nullif(btrim(new.utm_term), '');
  new.user_agent   := nullif(btrim(new.user_agent), '');
  return new;
end;
$$;

comment on column public.lista_espera.telefone is 'Celular +55DDNXXXXXXXX. Obrigatório só com consentimento_whatsapp = true (desde a migration 20261124180000).';
comment on column public.lista_espera.especialidade is 'Código da especialidade (lista do app). Opcional desde a migration 20261124180000.';

-- ROLLBACK (só funciona se nenhuma linha tiver NULL nesses campos; antes, apague ou complete essas linhas):
-- alter table public.lista_espera drop constraint lista_espera_cidade_coerente;
-- alter table public.lista_espera drop constraint lista_espera_tel_se_whatsapp;
-- alter table public.lista_espera
--   alter column telefone set not null, alter column especialidade set not null,
--   alter column uf set not null, alter column cidade set not null,
--   alter column codigo_ibge_municipio set not null;
-- e recriar lista_espera_normalizar() como em 20261119231352 (especialidade e cidade só com btrim, sem nullif;
-- telefone e uf sem normalização).
