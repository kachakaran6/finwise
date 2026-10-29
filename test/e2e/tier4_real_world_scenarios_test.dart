import 'package:flutter_test/flutter_test.dart';
import 'package:finwise/data/storage.dart';
import 'package:finwise/domain/models/calc.dart';
import 'package:finwise/features/custom_studio/data/custom_calc_repository.dart';
import 'package:finwise/features/custom_studio/domain/models/custom_calc_definition.dart';
import 'package:finwise/features/custom_studio/domain/models/custom_input_def.dart';
import 'package:finwise/features/custom_studio/domain/models/custom_output_def.dart';
import 'package:finwise/features/custom_studio/runtime/custom_calculator_runtime.dart';

void main() {
  group('Tier 4: Real-World Application Scenarios E2E Suite', () {
    // =========================================================================
    // Scenario 1: Personal FIRE & Early Retirement Calculator
    // Exercising: F1, F4, F6, F7, F8, F9, F10, F11
    // =========================================================================
    test('Scenario 1: Personal FIRE & Early Retirement Calculator workflow', () async {
      final customRepo = CustomCalcRepository.inMemory();
      final scenarioRepo = ScenarioRepository.inMemory();

      // Step 1: Define FIRE calculator definition
      const fireCalc = CustomCalcDefinition(
        id: 'fire_retirement_calc',
        name: 'FIRE Retirement Target & Shortfall Planner',
        description: 'Calculates the target nest egg needed for Financial Independence and Retire Early (FIRE) using the 4% Safe Withdrawal Rule.',
        category: 'planning',
        iconKey: 'flame',
        inputs: [
          CustomInputDef(
            id: 'annual_expenses',
            label: 'Desired Annual Living Expenses',
            type: CustomInputType.currency,
            defaultValue: 60000.0,
            prefix: r'$',
          ),
          CustomInputDef(
            id: 'current_net_worth',
            label: 'Current Liquid Net Worth',
            type: CustomInputType.currency,
            defaultValue: 250000.0,
            prefix: r'$',
          ),
          CustomInputDef(
            id: 'annual_savings',
            label: 'Annual New Savings',
            type: CustomInputType.currency,
            defaultValue: 30000.0,
            prefix: r'$',
          ),
          CustomInputDef(
            id: 'swr_pct',
            label: 'Safe Withdrawal Rate (SWR) %',
            type: CustomInputType.percentage,
            defaultValue: 4.0,
            suffix: '%',
          ),
        ],
        outputs: [
          CustomOutputDef(
            id: 'fire_number',
            label: 'FIRE Target Net Worth',
            formula: 'round(annual_expenses / (swr_pct / 100), 2)',
            kind: CustomOutputKind.currency,
            isPrimary: true,
            formulaExplanation: 'Total portfolio needed so annual safe withdrawals fund all expenses.',
          ),
          CustomOutputDef(
            id: 'shortfall',
            label: 'Remaining Savings Needed',
            formula: 'max(0, fire_number - current_net_worth)',
            kind: CustomOutputKind.currency,
          ),
          CustomOutputDef(
            id: 'annual_passive_income',
            label: 'Annual Passive Income at Target',
            formula: 'fire_number * (swr_pct / 100)',
            kind: CustomOutputKind.currency,
          ),
        ],
      );

      // Verify definition validity and save
      expect(fireCalc.validate(), isEmpty);
      await customRepo.save(fireCalc);

      // Step 2: Execute with standard 4% rule ($60,000 expenses)
      // FIRE number = 60000 / 0.04 = 1,500,000
      // Shortfall = max(0, 1500000 - 250000) = 1,250,000
      // Annual passive income = 1500000 * 0.04 = 60,000
      final result1 = CustomCalculatorRuntime.compute(
        definition: fireCalc,
        rawInputs: {
          'annual_expenses': 60000.0,
          'current_net_worth': 250000.0,
          'annual_savings': 30000.0,
          'swr_pct': 4.0,
        },
      );

      expect(result1.hasErrors, isFalse);
      expect(result1.values['fire_number'], 1500000.0);
      expect(result1.primaryValue, 1500000.0);
      expect(result1.values['shortfall'], 1250000.0);
      expect(result1.values['annual_passive_income'], 60000.0);

      // Step 3: Reactive change — User already has $1,800,000 net worth (shortfall = 0)
      final result2 = CustomCalculatorRuntime.compute(
        definition: fireCalc,
        rawInputs: {
          'annual_expenses': 60000.0,
          'current_net_worth': 1800000.0,
          'annual_savings': 30000.0,
          'swr_pct': 4.0,
        },
      );
      expect(result2.values['shortfall'], 0.0);

      // Step 4: Persist Scenario Snapshot
      final now = DateTime.now().millisecondsSinceEpoch;
      final scenario = Scenario(
        id: 'scen_fire_2026',
        title: 'Lean FIRE 4% Target',
        calcId: 'custom_${fireCalc.id}',
        inputs: {'annual_expenses': 60000.0, 'current_net_worth': 250000.0, 'swr_pct': 4.0},
        snapshot: {
          'primary': {'l': 'FIRE Target Net Worth', 'v': 1500000.0, 'k': 'currency', 't': null},
          'rows': [
            {'l': 'Remaining Savings Needed', 'v': 1250000.0, 'k': 'currency', 't': null},
            {'l': 'Annual Passive Income at Target', 'v': 60000.0, 'k': 'currency', 't': null},
          ],
        },
        createdAt: now,
        updatedAt: now,
      );
      await scenarioRepo.upsert(scenario);

      final retrieved = await scenarioRepo.all();
      expect(retrieved.length, 1);
      expect(retrieved.first.calcId, 'custom_fire_retirement_calc');
      expect((retrieved.first.snapshot['primary'] as Map)['v'], 1500000.0);
    });

    // =========================================================================
    // Scenario 2: Freelancer Multi-Tier Tax & Net Income Estimator
    // Exercising: F1, F4, F5, F7, F8, F9, F10
    // =========================================================================
    test('Scenario 2: Freelancer Multi-Tier Tax & Net Income Estimator workflow', () {
      const taxCalc = CustomCalcDefinition(
        id: 'freelancer_tax_calc',
        name: 'Freelancer Multi-Tier Tax & Net Income Estimator',
        description: 'Calculates platform deductions, deductible business expenses, tax obligations, and take-home pay.',
        category: 'income',
        inputs: [
          CustomInputDef(
            id: 'gross_revenue',
            label: 'Annual Gross Invoicing',
            type: CustomInputType.currency,
            defaultValue: 120000.0,
          ),
          CustomInputDef(
            id: 'business_expenses',
            label: 'Deductible Operating Expenses',
            type: CustomInputType.currency,
            defaultValue: 20000.0,
          ),
          CustomInputDef(
            id: 'platform_fee_rate',
            label: 'Platform Marketplace Fee %',
            type: CustomInputType.percentage,
            defaultValue: 5.0,
          ),
          CustomInputDef(
            id: 'tax_rate',
            label: 'Effective Tax Rate %',
            type: CustomInputType.percentage,
            defaultValue: 25.0,
          ),
        ],
        outputs: [
          CustomOutputDef(
            id: 'platform_fees',
            label: 'Marketplace Fees',
            formula: 'gross_revenue * (platform_fee_rate / 100)',
            kind: CustomOutputKind.currency,
          ),
          CustomOutputDef(
            id: 'net_revenue',
            label: 'Taxable Business Profit',
            formula: 'gross_revenue - platform_fees - business_expenses',
            kind: CustomOutputKind.currency,
          ),
          CustomOutputDef(
            id: 'tax_amount',
            label: 'Estimated Income Tax',
            formula: 'net_revenue * (tax_rate / 100)',
            kind: CustomOutputKind.currency,
          ),
          CustomOutputDef(
            id: 'take_home_pay',
            label: 'Net Take-Home Pay',
            formula: 'net_revenue - tax_amount',
            kind: CustomOutputKind.currency,
            isPrimary: true,
          ),
          CustomOutputDef(
            id: 'effective_tax_pct',
            label: 'Effective Tax on Gross %',
            formula: 'round((tax_amount / gross_revenue) * 100, 2)',
            kind: CustomOutputKind.percentage,
            decimalPlaces: 2,
          ),
        ],
      );

      expect(taxCalc.validate(), isEmpty);

      // Invoicing: 120,000, Platform fee 5% = 6,000, Expenses = 20,000
      // Taxable profit: 120000 - 6000 - 20000 = 94,000
      // Tax (25%): 94000 * 0.25 = 23,500
      // Net take-home: 94000 - 23500 = 70,500
      // Effective tax % on gross: (23500 / 120000) * 100 = 19.58%
      final res = CustomCalculatorRuntime.compute(
        definition: taxCalc,
        rawInputs: {
          'gross_revenue': 120000.0,
          'business_expenses': 20000.0,
          'platform_fee_rate': 5.0,
          'tax_rate': 25.0,
        },
      );

      expect(res.hasErrors, isFalse);
      expect(res.values['platform_fees'], 6000.0);
      expect(res.values['net_revenue'], 94000.0);
      expect(res.values['tax_amount'], 23500.0);
      expect(res.values['take_home_pay'], 70500.0);
      expect(res.primaryValue, 70500.0);
      expect(res.values['effective_tax_pct'], 19.58);
    });

    // =========================================================================
    // Scenario 3: Commercial Real Estate Cap Rate & Cash-on-Cash Return
    // Exercising: F1, F4, F6, F7, F9, F10, F11
    // =========================================================================
    test('Scenario 3: Commercial Real Estate Cap Rate & Cash-on-Cash workflow', () async {
      final scenarioRepo = ScenarioRepository.inMemory();

      const creCalc = CustomCalcDefinition(
        id: 'cre_cap_rate_calc',
        name: 'Commercial Real Estate Cap Rate & Cash-on-Cash',
        description: 'Analyzes income-generating property yields, NOI, capitalization rate, and cash-on-cash equity return.',
        category: 'real_estate',
        inputs: [
          CustomInputDef(id: 'purchase_price', label: 'Property Acquisition Price', type: CustomInputType.currency, defaultValue: 1000000),
          CustomInputDef(id: 'gross_rental_income', label: 'Gross Annual Rental Income', type: CustomInputType.currency, defaultValue: 120000),
          CustomInputDef(id: 'operating_expenses', label: 'Annual Operating Expenses', type: CustomInputType.currency, defaultValue: 35000),
          CustomInputDef(id: 'down_payment_pct', label: 'Down Payment Equity %', type: CustomInputType.percentage, defaultValue: 25.0),
          CustomInputDef(id: 'annual_debt_service', label: 'Annual Mortgage Debt Service', type: CustomInputType.currency, defaultValue: 45000),
        ],
        outputs: [
          CustomOutputDef(
            id: 'noi',
            label: 'Net Operating Income (NOI)',
            formula: 'gross_rental_income - operating_expenses',
            kind: CustomOutputKind.currency,
          ),
          CustomOutputDef(
            id: 'cap_rate',
            label: 'Capitalization Rate (Cap Rate)',
            formula: 'round((noi / purchase_price) * 100, 2)',
            kind: CustomOutputKind.percentage,
            isPrimary: true,
          ),
          CustomOutputDef(
            id: 'initial_cash_invested',
            label: 'Initial Cash Invested',
            formula: 'purchase_price * (down_payment_pct / 100)',
            kind: CustomOutputKind.currency,
          ),
          CustomOutputDef(
            id: 'net_cash_flow',
            label: 'Annual Pre-Tax Cash Flow',
            formula: 'noi - annual_debt_service',
            kind: CustomOutputKind.currency,
          ),
          CustomOutputDef(
            id: 'cash_on_cash_return',
            label: 'Cash-on-Cash Return %',
            formula: 'round((net_cash_flow / initial_cash_invested) * 100, 2)',
            kind: CustomOutputKind.percentage,
          ),
        ],
      );

      expect(creCalc.validate(), isEmpty);

      // Purchase: 1,000,000, Gross: 120,000, Opex: 35,000, Down: 25%, Debt service: 45,000
      // NOI: 120000 - 35000 = 85,000
      // Cap rate: (85000 / 1000000) * 100 = 8.5%
      // Initial cash: 1000000 * 0.25 = 250,000
      // Pre-tax cash flow: 85000 - 45000 = 40,000
      // Cash-on-cash return: (40000 / 250000) * 100 = 16.0%
      final res = CustomCalculatorRuntime.compute(
        definition: creCalc,
        rawInputs: {
          'purchase_price': 1000000.0,
          'gross_rental_income': 120000.0,
          'operating_expenses': 35000.0,
          'down_payment_pct': 25.0,
          'annual_debt_service': 45000.0,
        },
      );

      expect(res.values['noi'], 85000.0);
      expect(res.values['cap_rate'], 8.5);
      expect(res.primaryValue, 8.5);
      expect(res.values['initial_cash_invested'], 250000.0);
      expect(res.values['net_cash_flow'], 40000.0);
      expect(res.values['cash_on_cash_return'], 16.0);

      // Persist scenario
      final scenario = Scenario(
        id: 'scen_cre_prime',
        title: 'Metro Prime Office Building',
        calcId: 'custom_${creCalc.id}',
        inputs: {'purchase_price': 1000000.0, 'noi': 85000.0},
        snapshot: {
          'primary': {'l': 'Cap Rate', 'v': 8.5, 'k': 'percentage', 't': null},
          'rows': [{'l': 'Cash-on-Cash', 'v': 16.0, 'k': 'percentage', 't': null}],
        },
        createdAt: 200,
        updatedAt: 200,
      );
      await scenarioRepo.upsert(scenario);
      expect((await scenarioRepo.all()).first.id, 'scen_cre_prime');
    });

    // =========================================================================
    // Scenario 4: Vehicle Loan vs Cash Investment Opportunity Cost
    // Exercising: F2, F4, F7, F8, F9, F10, F11
    // =========================================================================
    test('Scenario 4: Vehicle Loan vs Cash Investment Opportunity Cost workflow', () async {
      final repo = CustomCalcRepository.inMemory();

      const carCalc = CustomCalcDefinition(
        id: 'car_vs_invest_calc',
        name: 'Auto Loan vs Cash Opportunity Cost',
        description: 'Evaluates the opportunity cost of financing a car loan versus paying cash and investing the capital.',
        category: 'loans',
        inputs: [
          CustomInputDef(id: 'vehicle_price', label: 'Vehicle Price', type: CustomInputType.currency, defaultValue: 40000),
          CustomInputDef(id: 'down_payment', label: 'Down Payment', type: CustomInputType.currency, defaultValue: 5000),
          CustomInputDef(id: 'loan_rate_pct', label: 'Loan Annual Interest Rate %', type: CustomInputType.percentage, defaultValue: 6.0),
          CustomInputDef(id: 'tenure_years', label: 'Loan Term (Years)', type: CustomInputType.duration, defaultValue: 5),
          CustomInputDef(id: 'investment_return_pct', label: 'Expected Investment Return %', type: CustomInputType.percentage, defaultValue: 9.0),
        ],
        outputs: [
          CustomOutputDef(
            id: 'loan_principal',
            label: 'Financed Principal',
            formula: 'vehicle_price - down_payment',
            kind: CustomOutputKind.currency,
          ),
          CustomOutputDef(
            id: 'total_loan_interest',
            label: 'Total Loan Interest',
            formula: 'loan_principal * (loan_rate_pct / 100) * tenure_years',
            kind: CustomOutputKind.currency,
          ),
          CustomOutputDef(
            id: 'total_loan_paid',
            label: 'Total Cost of Financing',
            formula: 'loan_principal + total_loan_interest',
            kind: CustomOutputKind.currency,
          ),
          CustomOutputDef(
            id: 'invested_cash_future_value',
            label: 'Future Value of Cash if Invested',
            formula: 'round(vehicle_price * pow(1 + (investment_return_pct / 100), tenure_years), 2)',
            kind: CustomOutputKind.currency,
          ),
          CustomOutputDef(
            id: 'net_opportunity_gain',
            label: 'Net Investment Wealth Gain',
            formula: 'round(invested_cash_future_value - total_loan_paid, 2)',
            kind: CustomOutputKind.currency,
            isPrimary: true,
          ),
        ],
      );

      expect(carCalc.validate(), isEmpty);
      await repo.save(carCalc);

      // Principal: 40,000 - 5,000 = 35,000
      // Loan interest: 35000 * 0.06 * 5 = 10,500
      // Total loan paid: 35000 + 10500 = 45,500
      // Invested cash future value: 40000 * (1.09)^5 = 40000 * 1.53862395 = 61,544.96
      // Net opportunity gain: 61544.96 - 45500 = 16,044.96
      final res = CustomCalculatorRuntime.compute(
        definition: carCalc,
        rawInputs: {
          'vehicle_price': 40000.0,
          'down_payment': 5000.0,
          'loan_rate_pct': 6.0,
          'tenure_years': 5.0,
          'investment_return_pct': 9.0,
        },
      );

      expect(res.values['loan_principal'], 35000.0);
      expect(res.values['total_loan_interest'], 10500.0);
      expect(res.values['total_loan_paid'], 45500.0);
      expect(res.values['invested_cash_future_value'], closeTo(61544.96, 0.1));
      expect(res.values['net_opportunity_gain'], closeTo(16044.96, 0.1));

      // Duplicate calculator and modify parameters
      final duplicate = await repo.duplicate('car_vs_invest_calc');
      expect(duplicate.name, contains('(Copy)'));
    });

    // =========================================================================
    // Scenario 5: Crypto & Stock Portfolio Rebalancing Calculator
    // Exercising: F1, F4, F7, F8, F9, F10, F12
    // =========================================================================
    test('Scenario 5: Crypto & Stock Portfolio Rebalancing workflow', () {
      final repo = CustomCalcRepository.inMemory();

      const portfolioCalc = CustomCalcDefinition(
        id: 'portfolio_rebalance_calc',
        name: 'Asset Allocation & Portfolio Rebalancer',
        description: 'Computes target allocation values and necessary buy/sell rebalancing trades to align with target weights.',
        category: 'growth',
        inputs: [
          CustomInputDef(id: 'stock_value', label: 'Current Equities Value', type: CustomInputType.currency, defaultValue: 70000),
          CustomInputDef(id: 'crypto_value', label: 'Current Crypto Value', type: CustomInputType.currency, defaultValue: 30000),
          CustomInputDef(id: 'target_stock_pct', label: 'Target Equities %', type: CustomInputType.percentage, defaultValue: 60.0),
          CustomInputDef(id: 'target_crypto_pct', label: 'Target Crypto %', type: CustomInputType.percentage, defaultValue: 40.0),
        ],
        outputs: [
          CustomOutputDef(
            id: 'total_portfolio',
            label: 'Total Portfolio Value',
            formula: 'stock_value + crypto_value',
            kind: CustomOutputKind.currency,
          ),
          CustomOutputDef(
            id: 'target_stock_val',
            label: 'Desired Equities Allocation',
            formula: 'total_portfolio * (target_stock_pct / 100)',
            kind: CustomOutputKind.currency,
          ),
          CustomOutputDef(
            id: 'target_crypto_val',
            label: 'Desired Crypto Allocation',
            formula: 'total_portfolio * (target_crypto_pct / 100)',
            kind: CustomOutputKind.currency,
          ),
          CustomOutputDef(
            id: 'stock_rebalance_trade',
            label: 'Equities Rebalance (Sell if negative, Buy if positive)',
            formula: 'target_stock_val - stock_value',
            kind: CustomOutputKind.currency,
            isPrimary: true,
          ),
          CustomOutputDef(
            id: 'crypto_rebalance_trade',
            label: 'Crypto Rebalance (Sell if negative, Buy if positive)',
            formula: 'target_crypto_val - crypto_value',
            kind: CustomOutputKind.currency,
          ),
        ],
      );

      expect(portfolioCalc.validate(), isEmpty);

      // Total portfolio: 70,000 + 30,000 = 100,000
      // Target stock (60%): 60,000. Rebalance trade: 60000 - 70000 = -10,000 (Sell $10k)
      // Target crypto (40%): 40,000. Rebalance trade: 40000 - 30000 = +10,000 (Buy $10k)
      final res = CustomCalculatorRuntime.compute(
        definition: portfolioCalc,
        rawInputs: {
          'stock_value': 70000.0,
          'crypto_value': 30000.0,
          'target_stock_pct': 60.0,
          'target_crypto_pct': 40.0,
        },
      );

      expect(res.values['total_portfolio'], 100000.0);
      expect(res.values['target_stock_val'], 60000.0);
      expect(res.values['target_crypto_val'], 40000.0);
      expect(res.values['stock_rebalance_trade'], -10000.0);
      expect(res.values['crypto_rebalance_trade'], 10000.0);

      // Versioned JSON Export and Re-import check
      final jsonExport = repo.exportToJson(portfolioCalc);
      final imported = repo.importFromJson(jsonExport);
      expect(imported.validate(), isEmpty);

      final importedRes = CustomCalculatorRuntime.compute(
        definition: imported,
        rawInputs: {
          'stock_value': 70000.0,
          'crypto_value': 30000.0,
          'target_stock_pct': 60.0,
          'target_crypto_pct': 40.0,
        },
      );
      expect(importedRes.primaryValue, -10000.0);
    });

    // =========================================================================
    // Scenario 6: Currency-Localized Tuition Inflation Projection
    // Exercising: F2, F4, F5, F7, F8, F10, F12
    // =========================================================================
    test('Scenario 6: Currency-Localized Tuition Inflation Projection workflow', () {
      final repo = CustomCalcRepository.inMemory();

      const tuitionCalc = CustomCalcDefinition(
        id: 'tuition_inflation_calc',
        name: 'Higher Education Tuition Inflation Forecaster',
        description: 'Projects future college tuition costs taking compounding education inflation into account.',
        category: 'planning',
        inputs: [
          CustomInputDef(id: 'current_annual_tuition', label: 'Current Annual Tuition Cost', type: CustomInputType.currency, defaultValue: 25000),
          CustomInputDef(id: 'inflation_rate_pct', label: 'Expected College Inflation Rate %', type: CustomInputType.percentage, defaultValue: 5.0),
          CustomInputDef(id: 'years_until_college', label: 'Years Until Matriculation', type: CustomInputType.duration, defaultValue: 10),
          CustomInputDef(id: 'college_duration_years', label: 'Program Duration (Years)', type: CustomInputType.duration, defaultValue: 4),
        ],
        outputs: [
          CustomOutputDef(
            id: 'future_year1_tuition',
            label: 'Estimated Year 1 Tuition',
            formula: 'round(current_annual_tuition * pow(1 + (inflation_rate_pct / 100), years_until_college), 2)',
            kind: CustomOutputKind.currency,
          ),
          CustomOutputDef(
            id: 'total_estimated_tuition',
            label: 'Estimated 4-Year Tuition Total',
            formula: 'round(future_year1_tuition * college_duration_years, 2)',
            kind: CustomOutputKind.currency,
            isPrimary: true,
          ),
          CustomOutputDef(
            id: 'monthly_savings_needed',
            label: 'Required Monthly Savings (No Growth)',
            formula: 'round(total_estimated_tuition / (years_until_college * 12), 2)',
            kind: CustomOutputKind.currency,
          ),
        ],
      );

      expect(tuitionCalc.validate(), isEmpty);

      // Tuition: 25,000, Inflation: 5%, Years: 10, Duration: 4
      // Future year 1: 25000 * (1.05)^10 = 25000 * 1.6288946 = 40,722.37
      // 4-year total: 40722.37 * 4 = 162,889.48
      // Monthly savings needed: 162889.48 / (10 * 12) = 162889.48 / 120 = 1357.41
      final res = CustomCalculatorRuntime.compute(
        definition: tuitionCalc,
        rawInputs: {
          'current_annual_tuition': 25000.0,
          'inflation_rate_pct': 5.0,
          'years_until_college': 10.0,
          'college_duration_years': 4.0,
        },
      );

      expect(res.values['future_year1_tuition'], closeTo(40722.37, 0.05));
      expect(res.values['total_estimated_tuition'], closeTo(162889.48, 0.1));
      expect(res.values['monthly_savings_needed'], closeTo(1357.41, 0.1));

      final exportJson = repo.exportToJson(tuitionCalc);
      expect(exportJson, contains('finwise_calculator_export_version'));
      expect(exportJson, contains('tuition_inflation_calc'));
    });
  });
}
