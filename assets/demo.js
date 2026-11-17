const examples = {
  plantao: {
    title: "Plantões de outubro",
    detail: "4 plantões de R$ 1.200,00 com pagamento em novembro.",
    amounts: [
      ["Valor previsto", "R$ 4.800,00"],
      ["Valor recebido", "R$ 3.600,00"],
      ["Saldo a receber", "R$ 1.200,00"],
    ],
    note: "O saldo de outubro continua em aberto até o próximo crédito.",
  },
  convenio: {
    title: "Repasse de outubro",
    detail: "12 procedimentos de R$ 350,00 conforme a tabela do convênio.",
    amounts: [
      ["Valor previsto", "R$ 4.200,00"],
      ["Valor recebido", "R$ 3.850,00"],
      ["Glosa a conferir", "R$ 350,00"],
    ],
    note: "Repasse em 20 de novembro para a produção de outubro.",
  },
  consultorio: {
    title: "Semana de consultório",
    detail: "8 consultas particulares de R$ 450,00 com pagamentos em datas diferentes.",
    amounts: [
      ["Valor previsto", "R$ 3.600,00"],
      ["Valor recebido", "R$ 2.700,00"],
      ["Saldo a receber", "R$ 900,00"],
    ],
    note: "Duas consultas ainda aguardam pagamento.",
  },
  vinculos: {
    title: "Renda dos vínculos",
    detail: "Um salário CLT e dois plantões via PJ com datas de pagamento diferentes.",
    amounts: [
      ["Salário em 6 nov.", "R$ 9.400,00"],
      ["Plantões em 25 nov.", "R$ 3.600,00"],
      ["Total previsto no mês", "R$ 13.000,00"],
    ],
    note: "As datas da folha e do repasse definem quando a renda entra no caixa.",
  },
};

const result = document.querySelector("#demo-resultado");
const buttons = document.querySelectorAll("[data-example]");

for (const button of buttons) {
  button.addEventListener("click", () => {
    const example = examples[button.dataset.example];
    if (!example) return;

    for (const option of buttons) {
      option.setAttribute("aria-pressed", String(option === button));
    }
    result.querySelector("h3").textContent = example.title;
    result.querySelector(".demo-detail").textContent = example.detail;
    result.querySelector(".demo-note").textContent = example.note;

    const amounts = example.amounts.map(([label, value]) => {
      const row = document.createElement("div");
      const term = document.createElement("dt");
      const definition = document.createElement("dd");
      term.textContent = label;
      definition.textContent = value;
      row.append(term, definition);
      return row;
    });
    result.querySelector("dl").replaceChildren(...amounts);
  });
}
