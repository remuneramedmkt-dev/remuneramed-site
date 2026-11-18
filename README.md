# Site do RemuneraMed

Site estático (HTML e CSS, sem build) publicado no GitHub Pages em https://remuneramed.com.br. Sem analytics e sem cookies.

## Lista de espera

O formulário está na seção `#lista-de-espera` de `index.html`. Ele envia os dados por POST para o **FormSubmit** (https://formsubmit.co), que encaminha cada inscrição por e-mail para remuneramed.mkt@gmail.com. Não há backend próprio e não há conta a criar.

### Ativação (obrigatória, uma vez)

O FormSubmit só começa a entregar depois que o dono do e-mail confirma o endereço:

1. Abra https://remuneramed.com.br (ou o endereço do GitHub Pages) e envie o formulário uma vez com dados de teste, marcando o consentimento.
2. Na caixa de remuneramed.mkt@gmail.com, abra o e-mail do FormSubmit (confira também o spam) e clique em **Activate Form**.
3. Envie outro teste e confirme que o e-mail de inscrição chega e que a página `obrigado.html` abre.

Se quiser esconder o endereço no HTML, o próprio FormSubmit manda, depois da ativação, um código aleatório para colocar no lugar do e-mail no atributo `action`.

### Como trocar pelo serviço definitivo

Só o atributo `action` e os campos ocultos que começam com `_` são específicos do FormSubmit.

- **Formspree** (exige conta gratuita): crie um formulário, copie o endereço `https://formspree.io/f/SEU_ID`, troque o `action`, apague os campos ocultos `_captcha`, `_template`, `_subject`, `_next` e o `_honey` (use `_gotcha` no lugar dele) e defina o redirecionamento no painel deles.
- **Google Forms**: crie o formulário na conta suporte@remuneramed.com.br, com os mesmos campos e a caixa de consentimento obrigatória, e troque o botão do site por um link para ele (ou use o endereço `formResponse` com os campos `entry.XXXX`).
- **Provisório sem terceiros (mailto)**: troque `action` por `mailto:suporte@remuneramed.com.br` e acrescente `enctype="text/plain"`. Abre o programa de e-mail da pessoa, então funciona pior no celular.

Ao trocar de serviço, atualize também a seção "Lista de espera do lançamento" de `privacidade.html` (operador do formulário) e a nota abaixo do botão em `index.html`.

### Regras da lista

- Campos: nome e e-mail obrigatórios; especialidade ou área e cidade/UF opcionais.
- Caixa de consentimento obrigatória e desmarcada. O texto aceito segue junto de cada inscrição (campo `texto_do_consentimento`).
- Retenção: até o lançamento mais 6 meses, ou até a pessoa pedir a exclusão (ver `privacidade.html`).
- Entrar na lista não reserva vaga na oferta de lançamento.
