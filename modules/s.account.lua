Account = {}
Account.__index = Account

--[[
GERADOR DE NÚMERO DE CONTA
Formato: BBB.SSSS-D
BBB  = 3 dígitos
SSSS = 4 dígitos
D    = verificador (igual cpf)
--]]

local function generateAccountNumber(bankID)
    local seq = 1
    for _, acc in pairs(accountsCache) do
        if acc.bankID == bankID then seq = seq + 1 end
    end

    local bankStr = string.format("%03d", bankID)
    local seqStr  = string.format("%04d", seq)
    local raw     = bankStr .. seqStr

    local sum = 0
    for i = 1, #raw do
        sum = sum + tonumber(raw:sub(i, i))
    end

    return bankStr .. "." .. seqStr .. "-" .. (sum % 9)
end

function Account.new(data)
    local self = setmetatable({}, Account)

    self.accountNumber = data.account_number
    self.bankID        = data.bank_id
    self.playerID      = data.player_id

    self.balance       = tonumber(data.balance)      or 0
    self.limit         = tonumber(data.credit_limit) or 0
    self.score         = tonumber(data.credit_score) or 500

    self.type          = data.type
    self.status        = data.status or "active"
    self.isDirty       = false

    return self
end

--[[
obrigatórios em `data`:
bank_id    (number)
player_id  (number)

opcionais:
type "corrente" | "poupanca" | "salario"
initial_balance  number 0
callback function(success, accountObj|errorMsg)
Retorno imediato: true, "processando" | false, "erro"
--]]

local VALID_ACC_TYPES = { corrente = true, poupanca = true, salario = true , investimento = true, empresarial = true}

function Account.create(data)

    if not data.bank_id then
        return false, "bank_id é obrigatório."
    end

    if not data.player_id then
        return false, "player_id é obrigatório."
    end

    local bank = banksCache[data.bank_id]
    if not bank then
        return false, "Banco ID " .. tostring(data.bank_id) .. " não encontrado no sistema."
    end

    if not bank:canOperate() then
        return false, "Banco está sob intervenção e não pode abrir novas contas."
    end

    if not bank:hasWallet("commercial") then
        return false, "Este banco não possui carteira comercial. Não aceita contas de depósito."
    end

    local accType = data.type or "corrente"
    if not VALID_ACC_TYPES[accType] then
        return false, "Tipo de conta inválido. Use 'corrente', 'poupanca' ou 'salario'."
    end

    -- Bloq duplicidade
    for _, acc in pairs(accountsCache) do
        if acc.playerID == data.player_id
        and acc.bankID  == data.bank_id
        and acc.type    == accType then
            return false, ("Jogador já possui uma conta '%s' neste banco (%s).")
                :format(accType, acc.accountNumber)
        end
    end

    local initialBalance = tonumber(data.initial_balance) or 0
    if initialBalance < 0 then
        return false, "Saldo inicial não pode ser negativo."
    end

    local accountNumber = generateAccountNumber(data.bank_id)

    dbQuery(function(qh)
        local _, numRows, _ = dbPoll(qh, 0)

        if not numRows or numRows <= 0 then
            outputDebugString("[BNN] Account.create: INSERT falhou para player " .. tostring(data.player_id), 1) -- debug
            if data.callback then data.callback(false, "Erro interno ao salvar no banco de dados.") end
            return
        end

        local newAccData = {
            account_number = accountNumber,
            bank_id        = data.bank_id,
            player_id      = data.player_id,
            balance        = initialBalance,
            credit_limit   = 0,
            credit_score   = 500,
            type           = accType,
            status         = "active"
        }

        local newAcc               = Account.new(newAccData)
        accountsCache[accountNumber] = newAcc

        outputDebugString(("[BNN] Conta '%s' criada | Banco: %d | Player: %d | Tipo: %s"):format(
            accountNumber, data.bank_id, data.player_id, accType)) -- debug

        if data.callback then data.callback(true, newAcc) end

    end, db,
    "INSERT INTO bank_accounts (account_number, bank_id, player_id, balance, type, status) VALUES (?, ?, ?, ?, ?, 'active')",
    accountNumber, data.bank_id, data.player_id, initialBalance, accType)

    return true, "Processando criação de conta..."
end

function Account:save()
    if not self.isDirty then return end

    dbExec(db,
        "UPDATE bank_accounts SET balance = ?, credit_limit = ?, credit_score = ?, status = ? WHERE account_number = ?",
        self.balance, self.limit, self.score, self.status, self.accountNumber)

    self.isDirty = false
end

function Account:deposit(amount)
    local amount = tonumber(amount)
    if not amount or amount <= 0 then
        return false, "Valor de depósito inválido."
    end
    if self.status == "frozen" then
        return false, "Conta bloqueada. Operação não permitida."
    end

    self.balance = self.balance + amount
    self.isDirty = true

    self:logTransaction("deposit", amount, 0, nil)
    return true
end

function Account:withdraw(amount)
    local amount = tonumber(amount)
    if not amount or amount <= 0 then
        return false, "Valor de saque inválido."
    end
    if self.status == "frozen" then
        return false, "Conta bloqueada. Operação não permitida."
    end

    -- disponível = balance + limite (negativo ate o limite)
    local available = self.balance + self.limit
    if amount > available then
        return false, ("Saldo insuficiente. Disponível: R$%.2f (inclui limite de R$%.2f)")
            :format(available, self.limit)
    end

    self.balance = self.balance - amount
    self.isDirty = true

    self:logTransaction("withdrawal", amount, 0, nil)
    return true
end

function Account:sendMoneyTo(targetNumber, amount, desc)
    return transferMoney(self.accountNumber, targetNumber, amount, desc)
end


--  log transactions type: "deposit" | "withdrawal" | "transfer" | "fee" | "loan"
function Account:logTransaction(txType, amount, fee, counterpartNumber)
    transactionBuffer[#transactionBuffer + 1] = {
        origin    = self.accountNumber,
        destiny   = counterpartNumber or self.accountNumber,
        amount    = amount,
        fee       = fee,
        txType    = txType,
        timestamp = os.time()
    }

    -- Flush antecipado se o volume estiver alto
    if #transactionBuffer >= TX_BATCH_LIMIT then
        flushTransactionBuffer()
    end
end

function Account:freeze()
    if self.status == "frozen" then return false, "Conta já está bloqueada." end
    self.status  = "frozen"
    self.isDirty = true
    return true
end

function Account:unfreeze()
    if self.status ~= "frozen" then return false, "Conta não está bloqueada." end
    self.status  = "active"
    self.isDirty = true
    return true
end

local MIN_SCORE = 0
local MAX_SCORE = 1000

function math.clamp(val, lower, upper)
    if lower > upper then lower, upper = upper, lower end
    return math.max(lower, math.min(upper, val))
end

function Account:updateScore(delta)
    local oldScore = self.score
    self.score = math.clamp(self.score + delta, MIN_SCORE, MAX_SCORE)

    if oldScore ~= self.score then
        self.isDirty = true
    end
end

function Account:getCreditRisk()
    if self.score >= 800 then return "Excelente"
    elseif self.score >= 600 then return "Bom"
    elseif self.score >= 400 then return "Médio"
    else return "Alto Risco"
    end
end

function Account:calculateNewLimit()
    self.limit   = self.score * 2
    self.isDirty = true
end

function Account:getPlayer()
    for _, player in ipairs(getElementsByType("player")) do
        if getElementData(player, "dbid") == self.playerID then
            return player
        end
    end
    return nil
end