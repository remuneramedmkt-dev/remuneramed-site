-- =====================================================================
-- 04: consentimento do WhatsApp separado e facultativo (LGPD art. 8º; política do WhatsApp Business).
-- Aplicada em 19/11/2026 no projeto de produção (pvfnkokgpkcqzdpzvkcg), com a tabela vazia.
-- consentimento_lgpd continua obrigatório (e-mail + segmentação por especialidade, estado e cidade).
-- consentimento_whatsapp: default false; se true, o texto aceito vai em texto_consentimento_whatsapp
-- (20 a 800 caracteres); se false, o texto fica nulo.
-- =====================================================================

alter table public.lista_espera add column consentimento_whatsapp boolean not null default false;
alter table public.lista_espera add column texto_consentimento_whatsapp text;
alter table public.lista_espera add constraint lista_espera_whatsapp_val check (
  (consentimento_whatsapp is true and char_length(texto_consentimento_whatsapp) between 20 and 800)
  or (consentimento_whatsapp is false and texto_consentimento_whatsapp is null));
grant insert (consentimento_whatsapp, texto_consentimento_whatsapp) on public.lista_espera to anon;

comment on column public.lista_espera.consentimento_lgpd is
  'Consentimento obrigatorio: contato por e-mail sobre o lancamento e uso de especialidade, estado e cidade para segmentar o aviso. O texto aceito fica em texto_consentimento.';
comment on column public.lista_espera.consentimento_whatsapp is
  'Consentimento facultativo e separado para contato por WhatsApp. Default false. O texto aceito fica em texto_consentimento_whatsapp (so quando true).';

create or replace function public.lista_espera_normalizar()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.nome  := btrim(new.nome);
  new.email := lower(btrim(new.email));
  new.especialidade := btrim(new.especialidade);
  new.especialidade_outra := nullif(btrim(new.especialidade_outra), '');
  new.cidade       := btrim(new.cidade);
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

-- ROLLBACK (desfaz a migration 04):
-- alter table public.lista_espera drop constraint lista_espera_whatsapp_val;
-- alter table public.lista_espera drop column texto_consentimento_whatsapp;
-- alter table public.lista_espera drop column consentimento_whatsapp;   -- o grant de INSERT some junto com a coluna
-- comment on column public.lista_espera.consentimento_lgpd is null;
-- e recriar lista_espera_normalizar() sem a linha de texto_consentimento_whatsapp (ver migration-03).
