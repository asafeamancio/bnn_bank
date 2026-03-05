-- controladores, funcoes para verificacoes complexas

function transferMoney(fromAccountNumber, toAccountNumber, amount, description)
    local amount = tonumber(amount)
    if not amount or amount <= 0 then return false, "Valor inválido." end --test
    local sourceAcc = accountsCache[fromAccountNumber]
    local targetAcc = accountsCache[toAccountNumber]

    if not sourceAcc or not targetAcc then return false, "Conta inexistente." end

    local sourceBank = banksCache[sourceAcc.bankID]
    local targetBank = banksCache[targetAcc.bankID]

    local fee = sourceBank:getTransactionFee(targetAcc.bankID)
    local totalDeduction = amount + fee

    if sourceAcc.balance < totalDeduction then 
        return false, ("Saldo insuficiente. Valor: R$%.2f + Taxa: R$%.2f"):format(amount, fee) 
    end

    if not sourceBank:hasWallet("commercial") then
        return false, "Erro: Esse banco é apenas para investimentos."
    end

    sourceAcc.balance = sourceAcc.balance - totalDeduction
    targetAcc.balance = targetAcc.balance + amount
    
    sourceBank.reserveBalance = sourceBank.reserveBalance + fee
    
    if sourceAcc.bankID ~= targetAcc.bankID then
        sourceBank.reserveBalance = sourceBank.reserveBalance - amount
        targetBank.reserveBalance = targetBank.reserveBalance + amount
        targetBank.isDirty = true
    end

    sourceAcc.isDirty = true
    targetAcc.isDirty = true
    sourceBank.isDirty = true

    dbExec(db, "INSERT INTO bank_transactions (origin_account, destiny_account, amount, tax, type, description) VALUES (?, ?, ?, ?, 'transfer', ?)",
        fromAccountNumber, toAccountNumber, amount, fee, description or "Transferência")

    return true, ("Transferência de R$%.2f realizada (Taxa: R$%.2f)"):format(amount, fee)
end

-- sis credit limit
function onPlayerReceiveSalary(accountNumber, amount)
    local acc = accountsCache[accountNumber]
    if acc then
        acc:updateScore(3)
    end
end

function processInstallmentPayment(installmentObj)
    local acc = accountsCache[installmentObj.account_number]
    if installmentObj:isOverdue() then
        acc:updateScore(-50) -- atraso
    else
        acc:updateScore(5) -- pontual
    end
end