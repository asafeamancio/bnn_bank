
local function printHeader(player, text)
    outputChatBox("=== " .. text .. " ===", player, 255, 200, 0)
end

local function printOK(player, text)
    outputChatBox("[OK] " .. text, player, 0, 255, 0)
end

local function printERR(player, text)
    outputChatBox("[ERRO] " .. text, player, 255, 60, 60)
end

local function printINFO(player, text)
    outputChatBox("  " .. text, player, 180, 180, 255)
end

addCommandHandler("bnnajuda", function(player)
    printHeader(player, "BNN BANK - Comandos de Teste")
    printINFO(player, "/bnncriarBanco  [nome] [licença] [reserva]")
    printINFO(player, "/bnncriarConta  [bankID] [tipo]")
    printINFO(player, "/bnncache                — mostra cache atual")
    printINFO(player, "/bnndepositar  [conta] [valor]")
    printINFO(player, "/bnnsacar      [conta] [valor]")
    printINFO(player, "/bnntransferir [origem] [destino] [valor]")
    printINFO(player, "/bnnemprestimo [conta] [valor] [parcelas]")
    printINFO(player, "/bnnscore      [conta]")
    printINFO(player, "/bnnatraso     [conta]")
    printINFO(player, "/bnnbloquear   [conta]")
    printINFO(player, "/bnndesbloquear [conta]")
    printINFO(player, "/bnnforcesync           — força save manual")
end)

addCommandHandler("bnncriarBanco", function(player, cmd, nome, licenca, reserva)
    if not nome then
        return printERR(player, "Uso: /bnncriarBanco [nome] [licença] [reserva]")
    end

    local pID = getElementData(player, "dbid") or 1

    local ok, msg = Bank.create({
        name            = nome,
        type            = "private",
        license_type    = licenca or "commercial",
        owner_id        = pID,
        reserve_balance = tonumber(reserva) or 0,

        callback = function(success, result)
            if success then
                printOK(player, ("Banco '%s' criado! ID: %d | Licença: %s | Reserva: R$%.2f")
                    :format(result.name, result.id, result:getLicenseType(), result.reserveBalance))
            else
                printERR(player, "Falha ao criar banco: " .. tostring(result))
            end
        end
    })

    if not ok then
        printERR(player, msg)
    else
        printINFO(player, "Solicitação enviada, aguardando confirmação do banco...")
    end
end)

addCommandHandler("bnncriarConta", function(player, cmd, bankIDStr, tipo)
    local bankID = tonumber(bankIDStr)
    if not bankID then
        return printERR(player, "Uso: /bnncriarConta [bankID] [tipo]")
    end

    local pID = getElementData(player, "dbid") or 1

    local ok, msg = Account.create({
        bank_id   = bankID,
        player_id = pID,
        type      = tipo or "corrente",

        callback = function(success, result)
            if success then
                printOK(player, ("Conta criada! Número: %s | Banco: %d | Tipo: %s")
                    :format(result.accountNumber, result.bankID, result.type))
            else
                printERR(player, "Falha ao criar conta: " .. tostring(result))
            end
        end
    })

    if not ok then
        printERR(player, msg)
    else
        printINFO(player, "Solicitação enviada, aguardando confirmação do banco...")
    end
end)

addCommandHandler("bnncache", function(player)
    printHeader(player, "Cache - Bancos")
    local countB = 0
    for id, bank in pairs(banksCache) do
        countB = countB + 1
        printINFO(player, ("[%d] %s | Reserva: R$%.2f | Status: %s | Dirty: %s")
            :format(id, bank.name, bank.reserveBalance, bank.status, tostring(bank.isDirty)))
    end
    if countB == 0 then printINFO(player, "(nenhum banco em cache)") end

    printHeader(player, "Cache - Contas")
    local countA = 0
    for num, acc in pairs(accountsCache) do
        countA = countA + 1
        printINFO(player, ("[%s] Player: %d | Saldo: R$%.2f | Score: %d | Status: %s | Dirty: %s")
            :format(num, acc.playerID, acc.balance, acc.score, acc.status, tostring(acc.isDirty)))
    end
    if countA == 0 then printINFO(player, "(nenhuma conta em cache)") end
end)

addCommandHandler("bnndepositar", function(player, cmd, numConta, valorStr)
    local valor = tonumber(valorStr)
    if not numConta or not valor then
        return printERR(player, "Uso: /bnndepositar [conta] [valor]")
    end

    local acc = accountsCache[numConta]
    if not acc then
        return printERR(player, "Conta '" .. numConta .. "' não encontrada no cache.")
    end

    local ok, msg = acc:deposit(valor)
    if ok then
        printOK(player, ("Depósito de R$%.2f realizado. Novo saldo: R$%.2f"):format(valor, acc.balance))
    else
        printERR(player, msg)
    end
end)

addCommandHandler("bnnsacar", function(player, cmd, numConta, valorStr)
    local valor = tonumber(valorStr)
    if not numConta or not valor then
        return printERR(player, "Uso: /bnnsacar [conta] [valor]")
    end

    local acc = accountsCache[numConta]
    if not acc then
        return printERR(player, "Conta '" .. numConta .. "' não encontrada no cache.")
    end

    local ok, msg = acc:withdraw(valor)
    if ok then
        printOK(player, ("Saque de R$%.2f realizado. Novo saldo: R$%.2f"):format(valor, acc.balance))
    else
        printERR(player, msg)
    end
end)

addCommandHandler("bnntransferir", function(player, cmd, origem, destino, valorStr)
    local valor = tonumber(valorStr)
    if not origem or not destino or not valor then
        return printERR(player, "Uso: /bnntransferir [conta_origem] [conta_destino] [valor]")
    end

    local success, message = transferMoney(origem, destino, valor, "Teste via comando")
    if success then
        printOK(player, message)
    else
        printERR(player, message)
    end
end)

addCommandHandler("bnnemprestimo", function(player, cmd, numConta, valorStr, parcelasStr)
    local valor    = tonumber(valorStr)
    local parcelas = tonumber(parcelasStr) or 12

    if not numConta or not valor then
        return printERR(player, "Uso: /bnnemprestimo [conta] [valor] [parcelas]")
    end

    local success, message = approveAndCreateLoan(numConta, valor, parcelas)
    if success then
        printOK(player, message)
    else
        printERR(player, message)
    end
end)

addCommandHandler("bnnscore", function(player, cmd, numConta)
    if not numConta then
        return printERR(player, "Uso: /bnnscore [conta]")
    end

    local acc = accountsCache[numConta]
    if not acc then
        return printERR(player, "Conta '" .. numConta .. "' não encontrada no cache.")
    end

    printOK(player, ("Conta %s | Score: %d | Classificação: %s | Limite: R$%.2f")
        :format(numConta, acc.score, acc:getCreditRisk(), acc.limit))
end)

addCommandHandler("bnnatraso", function(player, cmd, numConta)
    local acc = accountsCache[numConta]
    if not acc then
        return printERR(player, "Conta '" .. tostring(numConta) .. "' não encontrada no cache.")
    end

    acc:updateScore(-30)
    printERR(player, ("Atraso simulado em %s. Score agora: %d (%s)")
        :format(numConta, acc.score, acc:getCreditRisk()))
end)

addCommandHandler("bnnbloquear", function(player, cmd, numConta)
    local acc = accountsCache[numConta]
    if not acc then return printERR(player, "Conta não encontrada.") end

    local ok, msg = acc:freeze()
    if ok then printOK(player, "Conta " .. numConta .. " bloqueada.")
    else printERR(player, msg) end
end)

addCommandHandler("bnndesbloquear", function(player, cmd, numConta)
    local acc = accountsCache[numConta]
    if not acc then return printERR(player, "Conta não encontrada.") end

    local ok, msg = acc:unfreeze()
    if ok then printOK(player, "Conta " .. numConta .. " desbloqueada.")
    else printERR(player, msg) end
end)

addCommandHandler("bnnforcesync", function(player)
    local a, b, l = 0, 0, 0

    for _, acc  in pairs(accountsCache) do if acc.isDirty  then acc:save()  a = a + 1 end end
    for _, bank in pairs(banksCache)    do if bank.isDirty then bank:save() b = b + 1 end end
    for _, loan in pairs(loansCache)    do if loan.isDirty then loan:save() l = l + 1 end end

    printOK(player, ("Sync manual: %d contas, %d bancos, %d empréstimos salvos."):format(a, b, l))
end)