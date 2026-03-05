Loan = {}
Loan.__index = Loan

function Loan.new(data)
    local self = setmetatable({}, Loan)
    
    self.id               = data.id
    self.borrowerAccount  = data.borrower_account
    self.bankID           = data.bank_id

    self.totalAmount      = tonumber(data.total_amount)
    self.installmentsQty  = tonumber(data.installments_qty)
    self.interestRate     = tonumber(data.interest_rate)
    
    self.loanType         = data.loan_type
    self.status           = data.status or 'active' -- 'active', 'paid', 'defaulted'
    self.isDirty          = false

    return self
end

function Loan:save()
    if self.isDirty then
        dbExec(db, "UPDATE bank_loans SET status = ?, total_amount = ? WHERE id = ?", 
            self.status, self.totalAmount, self.id)
        self.isDirty = false
    end
end



function calculateLoanTerms(accountNumber, requestedAmount)
    local acc = accountsCache[accountNumber]
    if not acc then return false, "Conta não encontrada." end

    local maxMultiplier = acc.score / 100 --Score 500 = 5x o saldo
    -- local test = self.totalAmount - acc.balance
    local maxAllowed = acc.balance * maxMultiplier
    
    if requestedAmount > maxAllowed then
        return false, ("Crédito Negado: Seu limite máximo para este score é R$%.2f"):format(maxAllowed)
    end

    local baseRate = 0.05 -- 5% 
    local riskPremium = (1000 - acc.score) / 1000 * 0.25 -- max +25% de juros
    local finalRate = baseRate + riskPremium

    return true, {
        rate = finalRate,
        maxAmount = maxAllowed,
        installments = acc.score > 700 and 24 or 12 -- Score alto parcela em mais vezes
    }
end

function approveAndCreateLoan(accountNumber, amount, installments)
    local canLoan, terms = calculateLoanTerms(accountNumber, amount)
    if not canLoan then return false, terms end

    local acc = accountsCache[accountNumber]
    local bank = banksCache[acc.bankID]

    -- liquidez do banco = 2-% na reserva
    local requiredReserve = amount * 0.20
    if bank.reserveBalance < requiredReserve then
        return false, "O banco não possui reserva de liquidez para aprovar este crédito no momento."
    end

    -- Juros Compostos
    local totalToPay = amount * (1 + terms.rate)
    local installmentValue = totalToPay / installments

    dbQuery(function(qh)
        local res, _, id = dbPoll(qh, 0)
        
        for i = 1, installments do
            --local dueDate = getTimestampPlusDays(i * 30) -- para datas
            local dueDate = os.time()
            dbExec(db, "INSERT INTO bank_installments (loan_id, account_number, amount, due_date) VALUES (?, ?, ?, FROM_UNIXTIME(?))", 
                id, accountNumber, installmentValue, dueDate)
        end

        acc.balance = acc.balance + amount
        bank.reserveBalance = bank.reserveBalance - amount
        acc.isDirty = true
        bank.isDirty = true
        
        outputDebugString("[BNN] Empréstimo ID " .. id .. " criado para conta " .. accountNumber)
    end, db, "INSERT INTO bank_loans (borrower_account, bank_id, total_amount, installments_qty, interest_rate, status) VALUES (?, ?, ?, ?, ?, 'active')",
    accountNumber, acc.bankID, totalToPay, installments, terms.rate)

    return true, "Empréstimo aprovado! Valor creditado em sua conta."
end



function Loan:settle() --computar deletar (func liquidar emprestimo)
    self.status = 'paid'
    self.isDirty = true
    --  bônus de Credit Score 
end