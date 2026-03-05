BankConfig = {}

-- defaultTax
BankConfig.DefaultFees = {
    internal = 0.0,    
    external = 15.00,
    maintenance = 25.00,
    atm_withdrawal = 5.00
}

BankConfig.LicenseTemplates = {
    commercial = { 
        commercial = true,
        investment = false,
        payment = false,
        loans = true
    },
    payment_institution = { -- IP 
        commercial = false,
        investment = false,
        payment = true,
        loans = false
    },
    multiple = {
        commercial = true,
        investment = true,
        payment = true,
        loans = true
    }
}

BankConfig.DefaultLoans = {

    personal = {
        label = "Pessoal", category = "PF",
        amortization = "PRICE", interestRate = 0.05,
        maxInstallments = 24, downPaymentRequired = 0.0,
        collateralType = "none", blockSale = false 
    },

    payroll = {
        label = "Consignado", category = "PF", 
        amortization = "PRICE", interestRate = 0.02,
        maxInstallments = 48, downPaymentRequired = 0.0,
        collateralType = "salary", blockSale = false 
    },
    
    vehicle = { label = "Financiamento de Veículo", category = "PF_PJ",
    amortization = "PRICE", interestRate = 0.025,
    maxInstallments = 48, downPaymentRequired = 0.10,
    collateralType = "vehicle", blockSale = true
    },
    
    real_estate = { label = "Financiamento Imobiliário", category = "PF_PJ",
    amortization = "SAC", interestRate = 0.008,
    maxInstallments = 120, downPaymentRequired = 0.20,
    collateralType = "property", blockSale = true 
    },
    
    working_capital = { label = "Capital de Giro", category = "PJ",
    amortization = "PRICE", interestRate = 0.035,
    maxInstallments = 36, downPaymentRequired = 0.0,
    collateralType = "company_assets", blockSale = false 
    }
}

BankConfig.LoanMetatable = {
    __index = function(table, key) return BankConfig.DefaultLoans[key] end
}

BankConfig.FeeMetatable = {
    __index = function(table, key) return BankConfig.DefaultFees[key] end
}