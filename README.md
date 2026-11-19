# Site do RemuneraMed

Site estático (HTML e CSS, sem build) publicado no GitHub Pages em https://remuneramed.com.br. Sem analytics e sem cookies.

## Lista de espera

O formulário está na seção `#lista-de-espera` de `index.html` e é tratado por `assets/lista-espera.js`. Ele grava cada inscrição, por `fetch`, na tabela `public.lista_espera` do projeto Supabase `remuneramed` (ref `pvfnkokgpkcqzdpzvkcg`, São Paulo), pela API REST. A chave usada no site é a chave pública (publishable); a proteção é a RLS do banco (o site só insere, não lê). O SQL da tabela fica em `docs/lista-espera-supabase/migration.sql`.

- Campos: nome, e-mail, celular com DDD, especialidade, estado e cidade (todos obrigatórios). A especialidade vem da lista do CFM (Resolução 2.472/2026, 55 especialidades) mais a opção "Sem especialidade (generalista)", escrita direto no `index.html` e validada no banco por CHECK (`docs/lista-espera-supabase/migration-02-especialidade.sql`). Estado e cidade vêm de listas de seleção alimentadas por `assets/ibge-municipios.json`, gerado da API de localidades do IBGE (para atualizar, baixe `https://servicodados.ibge.gov.br/api/v1/localidades/municipios` de novo).
- O celular é gravado normalizado (`+55DDNXXXXXXXX`).
- UTM (`utm_source`, `utm_medium`, `utm_campaign`, `utm_content`, `utm_term`) lidos da URL, sem cookies.
- Caixa de consentimento obrigatória e desmarcada; o texto exato que a pessoa leu é gravado em `texto_consentimento`.
- Campo escondido `site` (honeypot) descarta robôs.
- Retenção: até o lançamento mais 6 meses, ou até a pessoa pedir a exclusão (ver `privacidade.html`).
- Entrar na lista não reserva vaga na oferta de lançamento.
