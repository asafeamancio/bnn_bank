
---

## Ecossistema Bancario
> Ao invez de apenas um banco que imprime dinheiro infinitamente, esse sistema dita regras para como funciona um banco, contas, tipos de banco e normas para criação de contas desse banco.
> Não somos um banco, somos a criação de bancos.









---
### Tipos de Bancos
- Banco Privado
Empresa privada pode ser aberta por qualquer pessoa, podendo fazer qualquer tipo de negociação dentro da lei, e respondendo diretamente ás normas do BC, como reajustes de juros e auditorias 
- Banco Central
O Banco Central é responsável pela impressao de dinheiro, ajustes de impostos.
### Tipos de Bancos
Carteiras | Funçao | Diferencial
:------: | :------: | :------: | 
Comercial | Capta Deposito á vista | ATMs Espalhados, Salario


#### Carteira Comercial
O comum conhecido, captação de depósitos à vista e oferecer contas correntes de livre movimentação.
Empréstimos de curto prazo, cheque especial, capital de giro para empresas de jogadores e desconto de duplicatas.
#### Instituição de Pagamento (IP)
Pessoa juridica com autorização do BC para gerenciar fluxos de dinheiro dos usuários, mas com limitações. Pode abrir contas para clientes, aportes, transferencias e saques, emitir moeda eletronica, emitir cartões de credito (pós-pago, utilizando reserva de investidores) e débito. Atuar como "Adquirente" para aceitar pagamentos em estabelecimentos (Criar maquininhas), receber salarios via portabilidade, saindo de uma conta-salário diretamente para elas.
#### Carteira de Investimento
Foca em operações de médio e longo prazo e no financiamento do setor produtivo, Eles não oferecem contas correntes movimentáveis por cheque ou cartão de débito.
Esse sistema não serve para você comprar um café na esquina, serve para você congelar seu dinheiro por 1 mês e trocar por rendimentos.
##### Atividades Privativas e Corporate Finance
carteira habilita a instituição a atuar em Underwriting, fusões e aquisições (M&A) e administração de fundos de terceiros. Abrir um capital inicial (IPO) ou emitir dívida para expandir
#### Carteira de Desenvolvimento: A Exceção Estatal
Apenas a Caixa ECOFE é licenciada para isso, usada para investir no desenvolvimendo e financiar projetos de infraestrutura com taxas subsidiadas ou prazos alongados que o mercado privado não suportaria.
#### Carteira de Crédito Imobiliário
Ela permite a emissão de Letras de Crédito Imobiliário LCI e a captação de Depósitos de Poupança (65% dos depósitos destinados ao financiamento habit.)
Usada para viabilizar a compra de casas, usa dinheiro dos iniciantes guardados em poupança (com taxa baixa) para financiar jogadores antigos a comprarem mansões (com altas taxas).
#### Carteira de Crédito, Financiamento e Investimento CFI
Sociedades de Crédito, Financiamento e Investimento, focada no crédito direto ao consumidor, seja financiamento de veiculos ou crediario de lojas
Taxas mais altas compensando a inadimplência, emprestimos rapidos para jogadores com baixo score.
#### Carteira de Arrendamento Mercantil
Leasing é uma operação híbrida entre aluguel e financiamento, a instituição adquire um bem e o arrenda ao cliente por um prazo determinado, com opção de compra ao final. O banco mantem a propriedade jurídica do bem (o jogar apenas a posse), a recuperação de um veículo em caso de inadimplência é legalmente mais ágil do que em um financiamento cia CFC (onde o bem esta no nome do devedor, apenas alienado).
Bancos usarão essa carteira para oferecer veículos de luxo com entradas menores, mas com cláusulas de retomada imediata, caso atrase o pagamento, criando novas dinamicas.

#### Sociedade de Empréstimo entre Pessoas (LOCK)
A SEP é a plataforma de Peer-to-Peer Lending. Ela conecta o investidor (Jogador A) ao tomador (Jogador B). A empresa apenas analisa os riscos, cria taxas de acordo e coloca em uma vitrine para outros jogadores investirem no tomador (Jogador B) e apos os pagamentos, as parcelas são pagas ao investidor e parte fica com a instituição intermediária.
#### Mercado de Câmbio e a Distinção de Entidades (LOCK EM DESENVOLVIMENTO)





---
### Rascunhos

Coluna |	Tipo |	Descrição | 
:------: | :------: | :------: | 
id	| INT (PK)	| ID único do banco no ecossistema. |
name  |	VARCHAR	| Nome da instituição (Ex: Maze Bank).
type	| ENUM	| 'central', 'commercial', 'investment', 'credit_union'. 
owner_id	| INT	| ID do jogador dono (ou 0 para sistema).
reserves	| DECIMAL	| Capital total que o banco possui para honrar saques.
settings	| JSON	| Regras dinâmicas (taxas, limites, cores da UI).
status	| ENUM	| 'organic', 'ai_managed', 'intervened'.

Coluna	|Tipo	|Descrição|
:------: | :------: | :------: | 
acc_id	|INT (PK)	|Número da conta (ex: 10001).
bank_id	|INT (FK)	|ID do banco ao qual esta conta pertence.
player_id	|INT	|Identificador do dono da conta.
balance	|DECIMAL	|Saldo atual disponível para uso.
acc_type	|VARCHAR	|Tipo de conta ('corrente', 'poupanca', 'salario').
created_at	|TIMESTAMP	|Data e hora de abertura da conta.

Coluna	|Tipo	|Descrição
:------: | :------: | :------: | 
id|	INT (PK)|	ID único da transação.
origin_acc|	INT|	Conta de origem dos fundos.
dest_acc|	INT|	Conta de destino dos fundos.
amount|	DECIMAL|	Valor bruto transferido.
tax_applied|	DECIMAL|	Valor da taxa retida pelo banco (lucro da operação).
created_at|	TIMESTAMP|	Registro temporal da movimentação.


| Coluna | Tipo | Motivo |
| :--- | :--- | :--- |
| `document_number` | VARCHAR(14) | Vinculação com CPF/CNPJ do Cartório. |
| `daily_limit` | DECIMAL | Proteção contra drenagem de reserva. |
| `status` | ENUM('active', 'frozen') | Permite bloqueio judicial pela Polícia. |


| Coluna | Tipo | Descrição |
| :--- | :--- | :--- |
| `loan_id` | INT (PK) | Controle de dívidas ativas. |
| `total_debt` | DECIMAL | Valor total com juros compostos. |
| `next_installment` | TIMESTAMP | Próxima data de cobrança automática. |

---
# GitHub Copy/Paste
1. git init
2. git add README.md
3. git commit -m "first commit"
4. git branch -M main
5. git remote add origin https://github.com/asafeamancio/bnn_bank.git
6. git push -u origin main

### GitHub Clonando repositórios e realizando commits
1. git clone 
2. git add .
3. git config --global user.name "Seu Nome"
4. git config --global user.email "seuemail@exemplo.com"
5. git checkout -b nome-da-sua-tarefa
6. git status
7. git add . or git add nome_arquivo
8. git commit -m "o que foi feito"
9. git push -u origin nome-da-sua-tarefa



#### Sistema WolfStreet (Taxa de Juros Dinâmica Baseada em Risco)
Emprestimos P2P
Empresa A - Solicita Emprestimo no Banco SothWalk ( $ 1.000.000,00 e pagará 30% ao ano)
Banco atraves de seus gerencias anunciam o emprestimo para possiveis investidores
Gerente A - Consegue um grande cliente $ 700.000,00 (70% da divida)
- Assumiu muito risco sendo recomepnsado com 26% de juros dessa divida
- Lucro: $ 182.000,00
Gerente B - Consegue uma empresa para investir $ 250.000,00 (25% da divida)
- Risco médio sendo recompensado por 17.2% dos juros
- Lucro: $ 43.000,00
Gerente B - Consegue um novo investidor porem um cliente comum do banco $ 50.000,00 (5% da divida)
- Cliente correu um risco muito baixo
- Taxa de juros que ele vai receber é bem menor 9% 
- Lucro: $ 4.5000,00
  
Incentivando jogadores a fazer um alto investimento atraves de um alto risco. O banco ja consegue reduzir a inflação e custear sua empresa com o dinheiro que sobrou desse emprestimo.
Empresa A vai pagar ao banco $ 300.000,00 em juros do emprestimo que vai ser repartido aos investidores, porem a parte deles são de $ 230.000,00 e o banco fica com $ 70.000,00 para custear esse sistema e recomensar seus gerentes com 

TaxaFinal = TaxaMax * (Investimento/Total)Elevado a TaxaRiscoBanco

Esse calculo exponencial mede o comprometimento do jogador com o investimento que ele vai fazer, não é apenas sobre o quanto de dinheiro voce tem, e sim sobre o quanto de divida voce pretende assumir. Pouco risco, pouco retorno, alto risco, altas parcelas. 