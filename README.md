# Site do RemuneraMed

Site estático (HTML e CSS, sem build) publicado no GitHub Pages em https://remuneramed.com.br. Sem analytics e sem cookies.

## Lista de espera

O formulário está na seção `#lista-de-espera` de `index.html` e é tratado por `assets/lista-espera.js`. Ele grava cada inscrição, por `fetch`, na tabela `public.lista_espera` do projeto Supabase `remuneramed` (ref `pvfnkokgpkcqzdpzvkcg`, São Paulo), pela API REST. A chave usada no site é a chave pública (publishable); a proteção é a RLS do banco (o site só insere, não lê). O SQL da tabela fica em `docs/lista-espera-supabase/migration.sql`.

- Campos: nome, e-mail, especialidade, estado e cidade (obrigatórios). O celular com DDD só aparece, e aí é obrigatório, quando a pessoa marca a caixa do WhatsApp; sem ela, não é enviado. Desde o branch `conversao-2026-11-24`, depende da migration `supabase/migrations/20261124180000_lista_espera_campos_opcionais.sql` (telefone aceita NULL; CHECK sem WhatsApp, sem celular), que precisa ser aplicada no Supabase ANTES do merge do front. A especialidade vem da lista do CFM (Resolução 2.472/2026, 55 especialidades) mais "Sem especialidade", "Residente ou estudante" e "Outra" (texto opcional de até 80 caracteres). O valor gravado é o código de `/produto/melhorias-app/dados/especialidades-cfm-2472-ids.json`, igual ao do app, e o banco valida por CHECK (`docs/lista-espera-supabase/migration-02-especialidade.sql` e `migration-03-especialidade-codigos.sql`). Estado e cidade vêm de listas de seleção alimentadas por `assets/ibge-municipios.json`, gerado da API de localidades do IBGE (para atualizar, baixe `https://servicodados.ibge.gov.br/api/v1/localidades/municipios` de novo).
- O celular é gravado normalizado (`+55DDNXXXXXXXX`), só com o aceite do WhatsApp.
- UTM (`utm_source`, `utm_medium`, `utm_campaign`, `utm_content`, `utm_term`) lidos da URL, sem cookies.
- Duas caixas de aceite, ambas desmarcadas. A 1ª (e-mail e segmentação por especialidade, estado e cidade) é obrigatória e grava o texto em `texto_consentimento`. A 2ª (WhatsApp) é facultativa, grava `consentimento_whatsapp` (padrão false) e o texto em `texto_consentimento_whatsapp`. O texto gravado é o que a pessoa leu, sem as marcas "(obrigatório)" e "(facultativo)".
- Pedidos de acesso, correção e exclusão: prazo de 15 dias (LGPD art. 19), citado na política e no suporte. O procedimento interno fica na pasta de marketing (Conformidade), fora deste repositório.
- Campo escondido `site` (honeypot) descarta robôs.
- Retenção: até o lançamento mais 6 meses, ou até a pessoa pedir a exclusão (ver `privacidade.html`).
- Entrar na lista não reserva vaga na oferta de lançamento.
