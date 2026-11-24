// Lista de espera do RemuneraMed: grava a inscrição na tabela public.lista_espera do Supabase
// (projeto remuneramed, São Paulo) pela API REST. A chave abaixo é a chave PÚBLICA (publishable):
// pode ficar no site. Quem protege os dados é a RLS do banco: o navegador só consegue inserir.
// Sem cookies, sem localStorage e sem sessionStorage.
const SUPABASE_URL = "https://pvfnkokgpkcqzdpzvkcg.supabase.co";
const SUPABASE_PUBLISHABLE_KEY = "sb_publishable_FhJZCIRBvEnLujGGCIbw9A_G6oTrPVM";
const ENDPOINT = SUPABASE_URL + "/rest/v1/lista_espera";
const LISTA_IBGE = "assets/ibge-municipios.json"; // IBGE, API de localidades (arquivo estático do site)
const PAGINA_OBRIGADO = "obrigado.html";
const TEMPO_LIMITE_MS = 15000;

const form = document.getElementById("lista-espera-form");
if (form) {
  const campo = (nome) => form.elements[nome];
  const status = document.getElementById("wl-status");
  const botao = document.getElementById("wl-enviar");
  const selUf = document.getElementById("wl-uf");
  const selCidade = document.getElementById("wl-cidade");
  let municipios = null;
  let listaIndisponivel = false;

  function mostrar(tipo, texto) {
    status.dataset.tipo = tipo;
    status.textContent = texto;
  }
  function marcarErro(el, texto) {
    el.setAttribute("aria-invalid", "true");
    mostrar("erro", texto);
    el.focus();
  }
  function limparErros() {
    for (const el of form.querySelectorAll("[aria-invalid]")) el.removeAttribute("aria-invalid");
    mostrar("", "");
  }

  // ---------- UTM (sem cookies): lê só location.search ----------
  const sanitizar = (v) => String(v || "").trim().toLowerCase().replace(/[^a-z0-9._-]/g, "").slice(0, 80);
  const parametros = new URLSearchParams(window.location.search);
  for (const nome of ["utm_source", "utm_medium", "utm_campaign", "utm_content", "utm_term"]) {
    const el = campo(nome);
    if (el) el.value = sanitizar(parametros.get(nome));
  }

  // ---------- Estado e cidade (lista do IBGE embutida no site) ----------
  function preencherUfs(dados) {
    for (const uf of dados.ufs) {
      const o = document.createElement("option");
      o.value = uf.sigla;
      o.textContent = uf.nome + " (" + uf.sigla + ")";
      selUf.append(o);
    }
  }
  function preencherCidades() {
    const uf = selUf.value;
    selCidade.replaceChildren();
    const primeira = document.createElement("option");
    primeira.value = "";
    if (!uf || !municipios || !municipios[uf]) {
      primeira.textContent = "Escolha o estado primeiro";
      selCidade.append(primeira);
      selCidade.disabled = true;
      return;
    }
    primeira.textContent = "Selecione a cidade";
    selCidade.append(primeira);
    for (const [codigo, nome] of municipios[uf]) {
      const o = document.createElement("option");
      o.value = String(codigo);
      o.textContent = nome;
      selCidade.append(o);
    }
    selCidade.disabled = false;
  }
  selUf.addEventListener("change", preencherCidades);

  // "Outra": mostra um campo de texto opcional (até 80 caracteres) para dizer qual.
  const selArea = campo("especialidade");
  const campoOutra = document.getElementById("wl-outra-campo");
  selArea.addEventListener("change", () => {
    const outra = selArea.value === "outra";
    campoOutra.hidden = !outra;
    if (!outra) campo("especialidade_outra").value = "";
  });

  fetch(LISTA_IBGE)
    .then((r) => { if (!r.ok) throw new Error("ibge"); return r.json(); })
    .then((dados) => { municipios = dados.municipios; preencherUfs(dados); })
    .catch(() => {
      // Estado e cidade são obrigatórios: sem a lista, o envio é bloqueado com aviso.
      selUf.disabled = true;
      selCidade.disabled = true;
      selUf.options[0].textContent = "Lista indisponível agora";
      listaIndisponivel = true;
    });

  // ---------- Telefone: máscara (DD) 9XXXX-XXXX e normalização +55DDNXXXXXXXX ----------
  const telefone = campo("telefone");
  function mascarar(digitos) {
    const d = digitos.slice(0, 11);
    if (d.length <= 2) return d.length ? "(" + d : "";
    if (d.length <= 7) return "(" + d.slice(0, 2) + ") " + d.slice(2);
    return "(" + d.slice(0, 2) + ") " + d.slice(2, 7) + "-" + d.slice(7);
  }
  function soDigitosNacionais(valor) {
    let d = String(valor).replace(/\D/g, "");
    // Colar "+55 62 99999-9999" ou "5562999999999": tira o 55 do país; tira 0 inicial do DDD.
    if (d.length > 11 && d.startsWith("55")) d = d.slice(2);
    if (d.length > 11 && d.startsWith("0")) d = d.slice(1);
    return d.slice(0, 11);
  }
  telefone.addEventListener("input", () => { telefone.value = mascarar(soDigitosNacionais(telefone.value)); });
  const celularValido = (d) => /^[1-9][1-9]9[0-9]{8}$/.test(d);

  // O celular só aparece (e só é obrigatório) quando a pessoa marca a caixa do WhatsApp.
  // Sem a caixa marcada, o campo é limpo e o celular não é enviado.
  const caixaWhatsapp = campo("consentimento_whatsapp");
  const campoTelefone = document.getElementById("wl-telefone-campo");
  function atualizarTelefone() {
    const marcado = caixaWhatsapp.checked === true;
    campoTelefone.hidden = !marcado;
    telefone.required = marcado;
    if (!marcado) { telefone.value = ""; telefone.removeAttribute("aria-invalid"); }
  }
  caixaWhatsapp.addEventListener("change", atualizarTelefone);
  atualizarTelefone();

  // ---------- Envio ----------
  const emailValido = (e) => /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(e);

  function montar() {
    const valor = (n) => campo(n).value.trim();
    // O texto gravado é exatamente o que a pessoa leu ao lado da caixa, sem o "(obrigatório)" e o "(facultativo)".
    const textoDe = (id) => {
      const copia = form.querySelector('label[for="' + id + '"]').cloneNode(true);
      for (const marca of copia.querySelectorAll(".req, .opt")) marca.remove();
      return copia.textContent.replace(/\s+/g, " ").trim().slice(0, 800);
    };
    const whatsapp = campo("consentimento_whatsapp").checked === true;
    const cidadeSel = selCidade.options[selCidade.selectedIndex];
    return {
      nome: valor("nome"),
      email: valor("email").toLowerCase(),
      telefone: whatsapp ? "+55" + soDigitosNacionais(telefone.value) : null,
      especialidade: campo("especialidade").value,
      especialidade_outra: campo("especialidade").value === "outra" ? (valor("especialidade_outra") || null) : null,
      uf: selUf.value,
      cidade: selCidade.value ? cidadeSel.textContent : "",
      codigo_ibge_municipio: selCidade.value ? Number(selCidade.value) : null,
      consentimento_lgpd: campo("consentimento").checked === true,
      texto_consentimento: textoDe("wl-consent"),
      consentimento_whatsapp: whatsapp,
      texto_consentimento_whatsapp: whatsapp ? textoDe("wl-consent-whatsapp") : null,
      origem: "site remuneramed.com.br, lista de espera",
      pagina: window.location.pathname.slice(0, 200),
      utm_source: valor("utm_source") || null,
      utm_medium: valor("utm_medium") || null,
      utm_campaign: valor("utm_campaign") || null,
      utm_content: valor("utm_content") || null,
      utm_term: valor("utm_term") || null,
    };
  }

  form.addEventListener("submit", async (evento) => {
    evento.preventDefault();
    limparErros();

    // Honeypot: robôs preenchem o campo escondido. Fingimos sucesso e não enviamos nada.
    if (campo("site").value) {
      window.location.assign(PAGINA_OBRIGADO);
      return;
    }

    const dados = montar();
    if (dados.nome.length < 2) return marcarErro(campo("nome"), "Informe seu nome.");
    if (!emailValido(dados.email) || dados.email.length > 160) return marcarErro(campo("email"), "Informe um e-mail válido, como nome@exemplo.com.");
    if (!dados.especialidade) return marcarErro(campo("especialidade"), "Escolha uma opção de especialidade.");
    if (listaIndisponivel) return mostrar("erro", "A lista de estados e cidades não carregou. Recarregue a página ou escreva para suporte@remuneramed.com.br.");
    if (!selUf.value) return marcarErro(selUf, "Escolha o estado.");
    if (!selCidade.value) return marcarErro(selCidade, "Escolha a cidade.");
    if (!dados.consentimento_lgpd) return marcarErro(campo("consentimento"), "Marque a primeira caixa de aceite (e-mail) para entrar na lista.");
    if (dados.consentimento_whatsapp && !celularValido(soDigitosNacionais(telefone.value))) return marcarErro(telefone, "Para receber pelo WhatsApp, informe um celular com DDD, como (62) 99999-9999. Se não quiser, desmarque a caixa do WhatsApp.");

    botao.disabled = true;
    mostrar("ok", "Enviando…");
    const controle = new AbortController();
    const relogio = setTimeout(() => controle.abort(), TEMPO_LIMITE_MS);
    try {
      const resposta = await fetch(ENDPOINT, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          apikey: SUPABASE_PUBLISHABLE_KEY,
          Prefer: "return=minimal",
        },
        body: JSON.stringify(dados),
        signal: controle.signal,
      });
      // 201 = gravado. 409 = e-mail já estava na lista: mesma resposta, para não revelar quem está cadastrado.
      if (resposta.status === 201 || resposta.status === 409) {
        window.location.assign(PAGINA_OBRIGADO);
        return;
      }
      throw new Error("status " + resposta.status);
    } catch (erro) {
      mostrar("erro", "Não foi possível enviar agora. Tente de novo em instantes ou escreva para suporte@remuneramed.com.br.");
      botao.disabled = false;
    } finally {
      clearTimeout(relogio);
    }
  });

  botao.disabled = false; // o botão só liga quando o JavaScript carrega
}
