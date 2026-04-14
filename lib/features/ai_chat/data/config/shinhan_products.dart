/// Shinhan Bank Vietnam product catalog for AI recommendations
/// Used by the Financial Coach to suggest relevant banking products
/// based on user spending patterns.
class ShinhanProducts {
  /// Product catalog injected into AI context for recommendation engine
  static const String catalog = '''
SHINHAN PRODUCT CATALOG (recommend when spending patterns match):

1. Shinhan Cashback Credit Card
   - Benefit: 5% cashback on dining, 3% on shopping, 1% on everything else
   - Annual fee: 0 VND (first year), 500,000 VND after
   - Best for: Users with high dining/shopping spend (>3M VND/month)
   - Action: apply_credit_card

2. Shinhan Premium Savings Account
   - Interest: 5.5% annual (6-month term), 6.0% (12-month term)
   - Minimum deposit: 1,000,000 VND
   - Best for: Users with idle balance >5M VND in current account
   - Action: open_savings_account

3. Shinhan FX Multi-Currency Card
   - Benefit: 0% FX markup, free international ATM withdrawals (5x/month)
   - Annual fee: 300,000 VND
   - Best for: Users with frequent international/USD transactions
   - Action: apply_credit_card

4. Shinhan Personal Loan
   - Rate: From 7.9% annual, terms 12-60 months
   - Amount: 20M - 500M VND
   - Best for: Users paying high credit card interest or needing consolidation
   - Action: apply_loan

5. Shinhan Life Insurance
   - Coverage: Health + Life combined, from 500,000 VND/month
   - Best for: Users with no insurance-related transactions
   - Action: (informational only — link to advisor)

6. Shinhan Auto-Save (Round-Up)
   - Rounds up every transaction to nearest 10,000 VND, saves the difference
   - Best for: Users who want to save passively without thinking
   - Action: transfer_to_savings
''';

  /// Recommendation rules (injected into system prompt when spending data is available)
  static const String recommendationRules = '''
PRODUCT RECOMMENDATION RULES (only suggest when pattern is clear):
- Dining + Shopping > 3M/month → Shinhan Cashback Credit Card (5% back = saves ~150k+/month)
- Current account balance > 5M idle → Shinhan Premium Savings (5.5% = ~22.9k/month per 5M)
- International/USD transactions frequent → Shinhan FX Card (0% markup saves 2-3% per transaction)
- Credit card interest payments visible → Shinhan Personal Loan (consolidate at 7.9% vs 20%+ card rate)
- No insurance category in transactions → Mention Shinhan Life Insurance (once, not repeatedly)
- Many small transactions → Shinhan Auto-Save round-up feature

IMPORTANT: Maximum 1 product suggestion per conversation turn. Don't overwhelm the user.
''';
}
