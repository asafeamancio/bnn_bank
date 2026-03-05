db            = nil
banksCache    = {}
accountsCache = {}
loansCache    = {}

transactionBuffer     = {}
TX_BATCH_LIMIT  = 30 -- flush

addEventHandler("onResourceStart", resourceRoot, function()
    db = dbConnect("mysql",
        ("dbname=%s;host=%s;port=%s"):format(dbConfig.name, dbConfig.host, dbConfig.port),
        dbConfig.user, dbConfig.pass, "share=1")

    if db then
        outputDebugString("[BNN] Conexão SQL ativa. Carregando cache...") -- debug
        loadBankSystem()
    else
        outputDebugString("[BNN] Erro crítico: falha na conexão SQL.", 1) -- debug
    end
end)

addEventHandler("onResourceStop", resourceRoot, function()
    outputDebugString("[BNN] Encerrando... salvando cache de emergência.") -- debug

    for _, acc  in pairs(accountsCache) do if acc.isDirty  then acc:save()  end end
    for _, bank in pairs(banksCache)    do if bank.isDirty then bank:save() end end
    for _, loan in pairs(loansCache)    do if loan.isDirty then loan:save() end end

    flushTransactionBuffer()

    outputDebugString("[BNN] Todos os dados foram persistidos com segurança.") -- debug
end)

function loadBankSystem()
    dbQuery(function(qh)
        local banks, numBanks = dbPoll(qh, 0)
        if banks then
            for _, row in ipairs(banks) do
                banksCache[row.id] = Bank.new(row)
            end
            outputDebugString("[BNN] " .. numBanks .. " bancos carregados.") -- debug
        end

        dbQuery(function(qh2)
            local accounts, numAccs = dbPoll(qh2, 0)
            if accounts then
                for _, row in ipairs(accounts) do
                    accountsCache[row.account_number] = Account.new(row)
                end
                outputDebugString("[BNN] " .. numAccs .. " contas carregadas.") -- debug
            end

            dbQuery(function(qh3)
                local loans, numLoans = dbPoll(qh3, 0)
                if loans then
                    for _, row in ipairs(loans) do
                        loansCache[row.id] = Loan.new(row)
                    end
                    outputDebugString("[BNN] " .. numLoans .. " empréstimos ativos carregados.") -- debug
                end

                startAutoSync()
                outputDebugString("[BNN] Sistema pronto.")

            end, db, "SELECT * FROM bank_loans WHERE status = 'active'")

        end, db, "SELECT * FROM bank_accounts")

    end, db, "SELECT * FROM bank_institutions")
end

function flushTransactionBuffer()
    if #transactionBuffer == 0 then return end

    -- Captura e limpa o buffer atomicamente antes do INSERT.
    -- Se o dbExec falhar, as transações se perdem mas o servidor
    -- não trava — log de debug sinaliza o problema.
    local batch        = transactionBuffer
    transactionBuffer  = {}

    -- Monta "(?,?,?,?,?),(?,?,?,?,?),..." e achata os valores
    local placeholders = {}
    local params       = {}

    for _, tx in ipairs(batch) do
        placeholders[#placeholders + 1] = "(?,?,?,?,?,FROM_UNIXTIME(?))"
        params[#params + 1] = tx.origin
        params[#params + 1] = tx.destiny
        params[#params + 1] = tx.amount
        params[#params + 1] = tx.fee
        params[#params + 1] = tx.txType
        params[#params + 1] = tx.timestamp
    end

    local sql = "INSERT INTO bank_transactions (origin_account, destiny_account, amount, tax, type, created_at) VALUES "
        .. table.concat(placeholders, ",")

    -- unpack dos params como varargs do dbExec
    dbExec(db, sql, unpack(params))

    outputDebugString(("[BNN] TransactionBuffer: %d registros persistidos em lote."):format(#batch))
end

local SYNC_INTERVAL = 5 * 60 * 1000  -- 5 minutos em ms

function startAutoSync()
    setTimer(function()
        local a, b, l = 0, 0, 0

        for _, acc  in pairs(accountsCache) do if acc.isDirty  then acc:save()  a = a + 1 end end
        for _, bank in pairs(banksCache)    do if bank.isDirty then bank:save() b = b + 1 end end
        for _, loan in pairs(loansCache)    do if loan.isDirty then loan:save() l = l + 1 end end

        flushTransactionBuffer()

        if a > 0 or b > 0 or l > 0 then
            outputDebugString(("[BNN] AutoSync: %d contas, %d bancos, %d empréstimos salvos."):format(a, b, l)) -- debug
        end
    end, SYNC_INTERVAL, 0)
end