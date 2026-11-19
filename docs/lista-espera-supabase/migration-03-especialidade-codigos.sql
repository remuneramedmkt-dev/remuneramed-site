-- =====================================================================
-- 03: especialidade grava o CÓDIGO (igual ao do app), não o nome. Códigos de
-- produto/melhorias-app/dados/especialidades-cfm-2472-ids.json: 55 especialidades da Resolução
-- CFM 2.472/2026 + 'generalista' (rótulo visível "Sem especialidade") + 'residente-estudante' + 'outra'.
-- Aplicada em 19/11/2026 no projeto de produção (pvfnkokgpkcqzdpzvkcg) com a tabela VAZIA.
-- 'especialidade_outra' é opcional, até 80 caracteres, e só vale quando especialidade = 'outra'.
-- =====================================================================

alter table public.lista_espera drop constraint lista_espera_especialidade_val;
alter table public.lista_espera add constraint lista_espera_especialidade_val check (especialidade in (
    'acupuntura',
    'alergia-e-imunologia',
    'anestesiologia',
    'angiologia',
    'cardiologia',
    'cirurgia-cardiovascular',
    'cirurgia-da-mao',
    'cirurgia-de-cabeca-e-pescoco',
    'cirurgia-do-aparelho-digestivo',
    'cirurgia-geral',
    'cirurgia-oncologica',
    'cirurgia-pediatrica',
    'cirurgia-plastica',
    'cirurgia-toracica',
    'cirurgia-vascular',
    'clinica-medica',
    'coloproctologia',
    'dermatologia',
    'endocrinologia-e-metabologia',
    'endoscopia',
    'gastroenterologia',
    'genetica-medica',
    'geriatria',
    'ginecologia-e-obstetricia',
    'hematologia-e-hemoterapia',
    'homeopatia',
    'infectologia',
    'mastologia',
    'medicina-de-emergencia',
    'medicina-de-familia-e-comunidade',
    'medicina-do-trabalho',
    'medicina-do-trafego',
    'medicina-esportiva',
    'medicina-fisica-e-reabilitacao',
    'medicina-intensiva',
    'medicina-legal-e-pericia-medica',
    'medicina-nuclear',
    'medicina-preventiva-e-social',
    'nefrologia',
    'neurocirurgia',
    'neurologia',
    'nutrologia',
    'oftalmologia',
    'oncologia-clinica',
    'ortopedia-e-traumatologia',
    'otorrinolaringologia',
    'patologia',
    'patologia-clinica-medicina-laboratorial',
    'pediatria',
    'pneumologia',
    'psiquiatria',
    'radiologia-e-diagnostico-por-imagem',
    'radioterapia',
    'reumatologia',
    'urologia',
    'generalista',
    'residente-estudante',
    'outra'
  ));

alter table public.lista_espera add column especialidade_outra text;
alter table public.lista_espera add constraint lista_espera_especialidade_outra_val check (
  especialidade_outra is null
  or (especialidade = 'outra' and char_length(especialidade_outra) between 1 and 80));
grant insert (especialidade_outra) on public.lista_espera to anon;

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

-- ROLLBACK (volta ao estado da migration 02, que grava o nome; só com a tabela vazia ou convertendo os dados antes):
-- alter table public.lista_espera drop constraint lista_espera_especialidade_outra_val;
-- alter table public.lista_espera drop column especialidade_outra;
-- alter table public.lista_espera drop constraint lista_espera_especialidade_val;
-- e recriar a constraint lista_espera_especialidade_val com os nomes da migration 02;
-- recriar lista_espera_normalizar() sem a linha de especialidade_outra.
