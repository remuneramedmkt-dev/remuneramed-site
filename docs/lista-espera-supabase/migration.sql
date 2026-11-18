-- =====================================================================
-- RASCUNHO: NÃO APLICADO. Só roda depois da aprovação do Gabriel.
-- Projeto Supabase: remuneramed (ref pvfnkokgpkcqzdpzvkcg, sa-east-1, São Paulo)
-- Tabela da lista de espera do site remuneramed.com.br
-- Substitui o FormSubmit. Quem escreve é o navegador (papel anon) via
-- POST /rest/v1/lista_espera; ninguém além do dono do projeto lê.
-- =====================================================================

create table public.lista_espera (
  id                       uuid        primary key default gen_random_uuid(),
  created_at               timestamptz not null default now(),

  -- dados da pessoa
  nome                     text        not null,
  email                    text        not null,
  telefone                 text        not null,   -- só dígitos normalizados: +55DDNXXXXXXXX
  especialidade_ou_area    text,
  uf                       char(2),                -- lista do IBGE
  cidade                   text,                   -- nome oficial do município (IBGE)
  codigo_ibge_municipio    integer,                -- 7 dígitos (IBGE)

  -- consentimento (LGPD, art. 7º, I): a data e a hora são o created_at
  consentimento_lgpd       boolean     not null,
  texto_consentimento      text        not null,

  -- origem do cadastro (UTM lido da URL, sem cookies)
  origem                   text,
  pagina                   text,
  utm_source               text,
  utm_medium               text,
  utm_campaign             text,
  utm_content              text,
  utm_term                 text,
  user_agent               text,                   -- opcional; o site NÃO envia por padrão

  -- e-mail é sempre gravado em minúsculas e sem espaços (trigger abaixo),
  -- então a unicidade abaixo vale sem diferenciar maiúsculas
  constraint lista_espera_email_unico unique (email),

  constraint lista_espera_nome_tam   check (char_length(btrim(nome)) between 2 and 120),
  constraint lista_espera_email_tam  check (char_length(email) between 6 and 160),
  constraint lista_espera_email_fmt  check (email ~ '^[a-z0-9._%+''-]+@[a-z0-9-]+(\.[a-z0-9-]+)*\.[a-z]{2,}$'),
  -- celular brasileiro: +55, DDD de 2 dígitos (11 a 99, sem zero), 9 e mais 8 dígitos
  constraint lista_espera_tel_fmt    check (telefone ~ '^\+55[1-9][1-9]9[0-9]{8}$'),
  constraint lista_espera_area_tam   check (especialidade_ou_area is null or char_length(especialidade_ou_area) <= 120),
  constraint lista_espera_uf_val     check (uf is null or uf in (
    'AC','AL','AM','AP','BA','CE','DF','ES','GO','MA','MG','MS','MT','PA','PB','PE','PI','PR',
    'RJ','RN','RO','RR','RS','SC','SE','SP','TO')),
  constraint lista_espera_cidade_tam check (cidade is null or char_length(cidade) between 2 and 120),
  -- UF, cidade e código do município vêm juntos ou não vêm
  constraint lista_espera_local_junto check (
    (uf is null and cidade is null and codigo_ibge_municipio is null)
    or (uf is not null and cidade is not null and codigo_ibge_municipio is not null)),
  -- os 2 primeiros dígitos do código do município são o código IBGE da UF
  constraint lista_espera_ibge_uf check (
    codigo_ibge_municipio is null or (
      codigo_ibge_municipio between 1100000 and 5399999
      and (codigo_ibge_municipio / 100000) = case uf
        when 'RO' then 11 when 'AC' then 12 when 'AM' then 13 when 'RR' then 14 when 'PA' then 15
        when 'AP' then 16 when 'TO' then 17 when 'MA' then 21 when 'PI' then 22 when 'CE' then 23
        when 'RN' then 24 when 'PB' then 25 when 'PE' then 26 when 'AL' then 27 when 'SE' then 28
        when 'BA' then 29 when 'MG' then 31 when 'ES' then 32 when 'RJ' then 33 when 'SP' then 35
        when 'PR' then 41 when 'SC' then 42 when 'RS' then 43 when 'MS' then 50 when 'MT' then 51
        when 'GO' then 52 when 'DF' then 53 end)),
  constraint lista_espera_consent    check (consentimento_lgpd is true),
  constraint lista_espera_texto_tam  check (char_length(texto_consentimento) between 20 and 800),
  constraint lista_espera_origem_tam check (origem is null or char_length(origem) <= 120),
  constraint lista_espera_pagina_tam check (pagina is null or char_length(pagina) <= 200),
  constraint lista_espera_utm_tam    check (
    coalesce(char_length(utm_source), 0)   <= 80 and coalesce(char_length(utm_medium), 0) <= 80 and
    coalesce(char_length(utm_campaign), 0) <= 80 and coalesce(char_length(utm_content), 0) <= 80 and
    coalesce(char_length(utm_term), 0)     <= 80),
  constraint lista_espera_ua_tam     check (user_agent is null or char_length(user_agent) <= 300)
);

comment on table public.lista_espera is
  'Lista de espera do site remuneramed.com.br. Dados pessoais (LGPD): só o dono do projeto lê. Retenção: lançamento do app + 6 meses, ou até a pessoa pedir exclusão.';

-- Normaliza antes de gravar: e-mail em minúsculas e sem espaços, textos sem espaços nas pontas,
-- campos vazios viram NULL. SECURITY INVOKER (padrão): não amplia permissão de ninguém.
create function public.lista_espera_normalizar()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.nome  := btrim(new.nome);
  new.email := lower(btrim(new.email));
  new.especialidade_ou_area := nullif(btrim(new.especialidade_ou_area), '');
  new.cidade       := nullif(btrim(new.cidade), '');
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

create trigger lista_espera_normalizar
  before insert on public.lista_espera
  for each row execute function public.lista_espera_normalizar();

-- A função do trigger não precisa ser chamável pela API
revoke all on function public.lista_espera_normalizar() from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- Segurança: RLS ligado e anon só insere
-- ---------------------------------------------------------------------
alter table public.lista_espera enable row level security;

-- O Supabase concede tudo por padrão em tabelas novas; tira tudo e devolve só INSERT em colunas fixas.
revoke all on table public.lista_espera from anon, authenticated;
grant insert (nome, email, telefone, especialidade_ou_area, uf, cidade, codigo_ibge_municipio,
              consentimento_lgpd, texto_consentimento, origem, pagina,
              utm_source, utm_medium, utm_campaign, utm_content, utm_term, user_agent)
  on public.lista_espera to anon;
-- Sem SELECT, UPDATE ou DELETE para anon e authenticated. id e created_at são gerados pelo banco.
-- service_role (e o painel do Supabase) continuam com acesso total e ignoram a RLS.

create policy "anon pode inserir inscricao com consentimento"
  on public.lista_espera
  for insert
  to anon
  with check (
    consentimento_lgpd is true
    and char_length(nome) between 2 and 120
    and char_length(email) between 6 and 160
    and char_length(texto_consentimento) between 20 and 800
  );
-- Sem política de SELECT/UPDATE/DELETE: com RLS ligado, isso significa "negado".

-- ---------------------------------------------------------------------
-- LIMITE DE ABUSO (OPCIONAL, fica comentado)
-- Um teto global de inscrições por minuto protege a tabela de inundação, mas um
-- atacante também pode travar inscrições legítimas ao bater o teto. Só ative se
-- houver ataque. Alternativas melhores no LEIA-ME (Cloudflare, Edge Function).
-- ---------------------------------------------------------------------
-- create function public.lista_espera_limite()
-- returns trigger language plpgsql security definer set search_path = '' as $$
-- begin
--   if (select count(*) from public.lista_espera where created_at > now() - interval '1 minute') >= 30 then
--     raise exception 'limite de inscricoes por minuto' using errcode = 'P0001';
--   end if;
--   return new;
-- end $$;
-- revoke all on function public.lista_espera_limite() from public, anon, authenticated;
-- create trigger lista_espera_limite before insert on public.lista_espera
--   for each row execute function public.lista_espera_limite();
