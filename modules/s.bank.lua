Bank = {}
Bank.__index = Bank

function Bank.new(data)
    local self = setmetatable({}, Bank)

    self.id             = data.id
    self.name           = data.name
    self.ownerID        = data.owner_id
    self.type           = data.type
    self.status         = data.status or "active"
    self.reserveBalance = tonumber(data.reserve_balance) or 0
    self.compulsoryRate = tonumber(data.compulsory_rate) or 10
    self.isDirty        = false

    local parsedWallets = type(data.wallets) == "string" and fromJSON(data.wallets) or data.wallets or {}

    local licenseType = parsedWallets.license_type or "commercial"

    local defaultEnabled = BankConfig.LicenseTemplates[licenseType]
        or BankConfig.LicenseTemplates["commercial"]

    self.wallets = {
        license_type = licenseType,
        enabled      = (parsedWallets.enabled and next(parsedWallets.enabled))
                        and parsedWallets.enabled
                        or defaultEnabled,
        fees         = parsedWallets.fees  or {},
        loans        = parsedWallets.loans or {}
    }

    setmetatable(self.wallets.fees,  BankConfig.FeeMetatable)
    setmetatable(self.wallets.loans, BankConfig.LoanMetatable)

    return self
end

--[[
FACTORY — cria banco no MySQL e injeta no cache
obrigatórios em `data`:
name         (string)
owner_id     (number)  — 0 para banco do sistema
opcionais:
type "private" | "public"
license_type chave BankConfig.LicenseTemplates
reserve_balance number 0
compulsory_rate number 0–100 10
callback function(success, bankObj|errorMsg)
Retorno imediato: true, "processando" | false, "motivo"
--]]

function Bank.create(data)

    if type(data.name) ~= "string" or #data.name == 0 then
        return false, "Nome do banco é obrigatório."
    end

    if #data.name > 64 then
        return false, "Nome do banco não pode ultrapassar 64 caracteres."
    end

    local bankType = data.type or "private"
    if bankType ~= "private" and bankType ~= "public" then
        return false, "Tipo inválido. Use 'private' ou 'public'."
    end

    if not data.owner_id then
        return false, "owner_id é obrigatório (use 0 para banco do sistema)."
    end

    local licenseType = data.license_type or "commercial"
    if not BankConfig.LicenseTemplates[licenseType] then
        return false, "Licença inválida: '" .. tostring(licenseType) .. "'."
    end

    local bankStatus = data.status or "active"
    if bankStatus ~= "active" and bankType ~= "intervened" and bankType ~= "closed" then
        return false, "Status inválido. Use 'active' ou 'intervened' ou 'closed'."
    end


    local reserveBalance = tonumber(data.reserve_balance) or 0
    if reserveBalance < 0 then
        return false, "reserve_balance não pode ser negativo."
    end

    local compulsoryRate = tonumber(data.compulsory_rate) or 10
    if compulsoryRate < 0 or compulsoryRate > 100 then
        return false, "compulsory_rate deve estar entre 0 e 100."
    end

    -- JSON > db
    local wallets = {
        license_type = licenseType,
        enabled      = BankConfig.LicenseTemplates[licenseType],
        fees         = {},
        loans        = {}
    }

    -- assinc
    dbQuery(function(qh)
        local numRows, newID = dbPoll(qh, 0)

        if not newID or newID <= 0 then
            outputDebugString("[BNN] Bank.create: INSERT falhou para '" .. data.name .. "'.", 1)
            if data.callback then data.callback(false, "Erro interno ao salvar no banco de dados.") end
            return
        end

        local newBankData = {
            id              = newID,
            name            = data.name,
            owner_id        = data.owner_id,
            type            = bankType,
            status          = bankStatus,
            reserve_balance = reserveBalance,
            compulsory_rate = compulsoryRate,
            wallets         = toJSON(wallets)
        }

        local newBank       = Bank.new(newBankData)
        banksCache[newID]   = newBank

        outputDebugString(("[BNN] Banco '%s' criado | ID: %d | Licença: %s | Status: '%s' "):format(
            data.name, newID, licenseType, bankStatus))

        if data.callback then data.callback(true, newBank) end

    end, db,
    "INSERT INTO bank_institutions (name, type, owner_id, reserve_balance, compulsory_rate, wallets, status) VALUES (?, ?, ?, ?, ?, ?, ?)",
    data.name, bankType, data.owner_id, reserveBalance, compulsoryRate, toJSON(wallets), bankStatus)

    return true, "Processando criação de banco..."
end

function Bank:save()
    if not self.isDirty then return end

    dbExec(db,
        "UPDATE bank_institutions SET reserve_balance = ?, wallets = ?, status = ? WHERE id = ?",
        self.reserveBalance, toJSON(self.wallets), self.status, self.id)

    self.isDirty = false
end

-- gets
function Bank:getLicenseType()
    return self.wallets.license_type
end

function Bank:hasWallet(walletType)
    return self.wallets.enabled[walletType] == true
end

function Bank:getTransactionFee(targetBankID)
    if self.id == targetBankID then
        return self.wallets.fees.internal
    else
        return self.wallets.fees.external
    end
end

function Bank:getLoanConfig(loanType)
    return self.wallets.loans[loanType]
end

function Bank:canOperate()
    return self.status ~= "intervened"
end

function Bank:depositReserve(amount)
    local amount = tonumber(amount)
    if not amount or amount <= 0 then return false, "Valor inválido." end

    self.reserveBalance = self.reserveBalance + amount
    self.isDirty        = true
    return true
end

function Bank:withdrawReserve(amount)
    local amount = tonumber(amount)
    if not amount or amount <= 0 then return false, "Valor inválido." end

    local minimumRequired = self.reserveBalance * (self.compulsoryRate / 100)
    if (self.reserveBalance - amount) < minimumRequired then
        return false, ("Reserva insuficiente. Mínimo compulsório: R$%.2f"):format(minimumRequired)
    end

    self.reserveBalance = self.reserveBalance - amount
    self.isDirty        = true
    return true
end

function Bank:updateLoanSetting(loanType, key, value)
    if not BankConfig.DefaultLoans[loanType] then return false end

    if type(rawget(self.wallets.loans, loanType)) ~= "table" then
        rawset(self.wallets.loans, loanType, {})
    end

    self.wallets.loans[loanType][key] = value
    self.isDirty = true
    return true
end

-- todas as contas deste banco que pertencem ao jogador
function Bank:getAccountsByPlayer(playerID)
    local result = {}
    for _, acc in pairs(accountsCache) do
        if acc.bankID == self.id and acc.playerID == playerID then
            result[#result + 1] = acc
        end
    end
    return result
end