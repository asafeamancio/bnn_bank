
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

### Tipos de Contas
Tipos de Contas | Função Principal | Diferencial | 
:------: | :------: | :------: | 
Corrente | Movimentações Diárias, Taxa Mensal | Permite Cartão Credito/Debito Baseado Score | 
Poupança | Reserva Emergência, Rendimentos Diários | Juros Baseados BC | 
Salário | Rencebimento dos Salários, Taxa Mensal Baixa | Débitos Cobrados Direto | 
Conjunta |  |  | 
Empresarial | Permite Automações, Notas Fiscais, Boletos | Taxa Mensal Alta, Capital Inicial Alto | 

---
# GitHub Copy/Paste
> git init
> git add README.md
> git commit -m "first commit"
> git branch -M main
> git remote add origin https://github.com/asafeamancio/bnn_bank.git
> git push -u origin main
>
> ### GitHub Clonando repositórios e realizando commits
> git clone 
> git add .
> git config --global user.name "Seu Nome"
> git config --global user.email "seuemail@exemplo.com"
> git checkout -b nome-da-sua-tarefa
> git status
> git add . or git add nome_arquivo
> git commit -m "o que foi feito"
> git push -u origin nome-da-sua-tarefa
> 

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
