-- =====================================================================
-- 02: especialidade obrigatória e validada (Resolução CFM nº 2.472/2026, 55 especialidades)
-- mais a opção 'Sem especialidade (generalista)'. Aplicada em 19/11/2026 no projeto de produção
-- remuneramed (pvfnkokgpkcqzdpzvkcg), com a tabela vazia. Sem tabela de referência: o front usa a
-- lista estática do index.html, e o CHECK impede valor fora da lista, mesmo via API.
-- Se o CFM publicar nova lista: trocar a constraint (drop e add) e as opções do index.html.
-- =====================================================================

alter table public.lista_espera rename column especialidade_ou_area to especialidade;
alter table public.lista_espera drop constraint lista_espera_area_tam;
alter table public.lista_espera alter column especialidade set not null;
alter table public.lista_espera add constraint lista_espera_especialidade_val check (especialidade in (
    'Sem especialidade (generalista)',
    'Acupuntura',
    'Alergia e imunologia',
    'Anestesiologia',
    'Angiologia',
    'Cardiologia',
    'Cirurgia cardiovascular',
    'Cirurgia da mão',
    'Cirurgia de cabeça e pescoço',
    'Cirurgia do aparelho digestivo',
    'Cirurgia geral',
    'Cirurgia oncológica',
    'Cirurgia pediátrica',
    'Cirurgia plástica',
    'Cirurgia torácica',
    'Cirurgia vascular',
    'Clínica médica',
    'Coloproctologia',
    'Dermatologia',
    'Endocrinologia e metabologia',
    'Endoscopia',
    'Gastroenterologia',
    'Genética médica',
    'Geriatria',
    'Ginecologia e obstetrícia',
    'Hematologia e hemoterapia',
    'Homeopatia',
    'Infectologia',
    'Mastologia',
    'Medicina de emergência',
    'Medicina de família e comunidade',
    'Medicina do trabalho',
    'Medicina do tráfego',
    'Medicina esportiva',
    'Medicina física e reabilitação',
    'Medicina intensiva',
    'Medicina legal e perícia médica',
    'Medicina nuclear',
    'Medicina preventiva e social',
    'Nefrologia',
    'Neurocirurgia',
    'Neurologia',
    'Nutrologia',
    'Oftalmologia',
    'Oncologia clínica',
    'Ortopedia e traumatologia',
    'Otorrinolaringologia',
    'Patologia',
    'Patologia clínica/medicina laboratorial',
    'Pediatria',
    'Pneumologia',
    'Psiquiatria',
    'Radiologia e diagnóstico por imagem',
    'Radioterapia',
    'Reumatologia',
    'Urologia'
  ));

create or replace function public.lista_espera_normalizar()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.nome  := btrim(new.nome);
  new.email := lower(btrim(new.email));
  new.especialidade := btrim(new.especialidade);
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

-- ROLLBACK (desfaz a migration 02):
-- alter table public.lista_espera drop constraint lista_espera_especialidade_val;
-- alter table public.lista_espera alter column especialidade drop not null;
-- alter table public.lista_espera rename column especialidade to especialidade_ou_area;
-- alter table public.lista_espera add constraint lista_espera_area_tam check (especialidade_ou_area is null or char_length(especialidade_ou_area) <= 120);
-- e recriar lista_espera_normalizar() com: new.especialidade_ou_area := nullif(btrim(new.especialidade_ou_area), '');
