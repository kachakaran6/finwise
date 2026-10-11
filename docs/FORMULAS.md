# Formula Reference

This document is the authoritative derivation reference for every formula used in
the calculator engine (`lib/domain/calculations/finance.dart`).
It exists so that formula correctness can be verified independently of the code.

---

## Conventions

| Symbol | Meaning |
|---|---|
| P | Principal / present value (lump sum) |
| FV | Future value |
| C | Periodic contribution / payment |
| r | Annual interest / return rate as a **decimal** (e.g. 0.10 for 10%) |
| r% | Annual rate as a **percentage** (passed in by the UI, converted to r internally) |
| k | Number of periods per year (compounding or contribution frequency) |
| i | Periodic rate = r/k (nominal) or (1+r)^(1/k) − 1 (effective) |
| n | Total number of periods |
| t | Time in years |
| m | Compounding frequency per year |
| f | Annual inflation rate (decimal) |

All rates received from UI fields are annual percentages. The engine converts them to
decimal before use: `r = annualPct / 100`. Periodic rate functions live in `periodicRate()`.

---

## Rate conventions

### Nominal periodic rate

```
i = r / k
```

This is the simpler and most common convention. A 12% annual rate gives a 1%
monthly rate. Used by default.

### Effective annual rate → periodic rate

```
i = (1 + r)^(1/k) − 1
```

This produces a periodic rate that, when compounded k times, equals the effective
annual rate exactly. A 12% effective annual rate gives a monthly rate of
`(1.12)^(1/12) − 1 ≈ 0.9489%`.

Both conventions are selectable in calculators C03, C04, C05, C10, C11.

---

## C01 — Compound interest

**Formula**

```
A = P × (1 + r/m)^(m × t)
```

**Zero-rate branch**

```
If r = 0: A = P
```

**Derived values**

- Interest earned: `A − P`
- Effective annual rate: `(1 + r/m)^m − 1`

**Implementation**: `compoundValue(principal, annualPct, years, m)` in `finance.dart`.

**Yearly schedule**: value at each integer year y is `compoundValue(P, r%, y, m)`.
Opening balance at year y is the value at year y−1. Interest in year y is the
difference between closing and opening values.

---

## C02 — Simple interest

**Formula**

```
I = P × r × t
A = P + I
```

Interest is earned only on the original principal. It does not compound.
Annual interest = `P × r × 1` = `P × r`.

**Implementation**: `simpleInterest(p, annualPct, years)`.

---

## C03 — Recurring investment (ordinary annuity / annuity due)

**End-of-period (ordinary annuity)**

```
FV = C × ((1 + i)^n − 1) / i
```

Each contribution C earns interest for the remaining periods after it is made.
Contribution 1 earns interest for n−1 periods; contribution n earns nothing.

**Beginning-of-period (annuity due)**

```
FV_due = FV × (1 + i)
```

Each contribution earns one extra period of interest because it is made at the start.

**Zero-rate branch**

```
If i ≈ 0: FV = C × n
```

**Parameters**: contribution frequency k (weekly = 52, monthly = 12, quarterly = 4,
half-yearly = 2, yearly = 1); n = `years × k` periods.

**Implementation**: `annuityFv(c, i, n, begin:)`.

---

## C04 — Step-up recurring investment

Contribution in period p (0-indexed):

```
C(p) = C_initial × (1 + s)^floor(p / k)
```

where s is the annual step-up rate (decimal) and k is periods per year.
Year 1 (periods 0 to k−1) uses C_initial. Year 2 uses `C_initial × (1 + s)`, etc.

**Simulation**: the `project()` function iterates period by period:

```
end-of-period:   balance(p+1) = balance(p) × (1 + i) + C(p)
begin-of-period: balance(p+1) = (balance(p) + C(p)) × (1 + i)
```

**Check**: at s = 0, C04 must equal C03.

**Implementation**: `_stepUp()` in `catalog.dart` calling `project()`.

---

## C05 — Goal contribution (inverse of C03)

Given a target FV, solve C03 for C:

**End-of-period**

```
C = FV × i / ((1 + i)^n − 1)
```

**Beginning-of-period**

```
C = FV × i / ((1 + i)^n − 1) / (1 + i)
   = FV × i / ((1 + i)^(n+1) − (1 + i))    [simplified form]
```

**Zero-rate branch**

```
If i ≈ 0: C = FV / n
```

**Round-trip invariant**: `annuityFv(goalContribution(FV, i, n, begin), i, n, begin) ≈ FV` to within 1e-6.

**Implementation**: `goalContribution(fv, i, n, begin:)`.

---

## C06 — Goal lump sum / present value

Discount a future value back to today:

```
PV = FV / (1 + i)^n
```

where n = m × t (compounding periods) and i = r / m.

**Zero-rate branch**

```
If i ≈ 0: PV = FV
```

**Growth equation**: investing PV at rate r with m-period compounding for t years
produces exactly FV (i.e. C01 and C06 are inverses of each other).

**Implementation**: `presentValue(fv, i, n)` where n is the total number of compounding periods.

---

## C07 — CAGR (Compound Annual Growth Rate)

```
CAGR = (V1 / V0)^(1/t) − 1
```

**Constraints**:
- V0 > 0 (CalcException if ≤ 0)
- V1 ≥ 0 (V1 = 0 gives CAGR = −100%)
- t > 0 (CalcException if ≤ 0)

CAGR uses only the start and end values; it says nothing about the path in between
(distributions, drawdowns, volatility). This is stated in the Notes tab.

**Implementation**: `cagr(v0, v1, t)`.

---

## C08 — Absolute return

```
Gain = V1 + Distributions − Costs − V0
Return% = Gain / V0 × 100
```

This is the **total** (not annualised) return. Use C07 (CAGR) to compare across
different time periods.

**Constraint**: V0 > 0 (CalcException if ≤ 0).

**Implementation**: `_absReturn()` in `catalog.dart`.

---

## C09 — Inflation and real return

### Future cost

```
FutureCost = Cost_today × (1 + f)^t
```

### Purchasing power

```
PurchasingPower = FutureMoney / (1 + f)^t
```

Expressed in today's currency. A given amount of money will buy less over time.

### Real return (Fisher equation)

```
Real = (1 + Nominal) / (1 + Inflation) − 1
```

The approximation `Nominal − Inflation` is shown alongside for comparison only.
The exact Fisher equation is used for the primary result.

**Constraint**: Inflation > −100% (CalcException if f ≤ −1).

**Implementation**: `_inflation()` in `catalog.dart`.

---

## C10 — EMI (Equated Monthly Instalment)

Monthly payment to fully amortize principal P over n months at monthly rate i:

```
EMI = P × i × (1 + i)^n / ((1 + i)^n − 1)
```

**Zero-rate branch**

```
If i ≈ 0: EMI = P / n
```

Interest share and principal share change each month; the formula gives the fixed
payment that satisfies both the lender's interest requirement and the full repayment
in exactly n payments.

**Implementation**: `emi(p, i, n)`.

---

## C11 — Amortization schedule

Each month j (1 to n):

```
Interest_j   = Opening_j × i          (rounded to 2 dp)
Principal_j  = Payment_j − Interest_j
Closing_j    = Opening_j − Principal_j
Opening_{j+1} = Closing_j
```

The standard payment is `round2(emi(P, i, n))`. For the final period, the payment
is set to exactly `round2(Opening + Interest)` to close the residual, which may
differ slightly from the standard payment due to accumulated rounding.

Closing balances below 1e-6 are clamped to zero to eliminate floating-point noise.

**Invariant**: sum of all `Principal_j` ≈ P (within 0.005). `Closing_n` = 0.

**Implementation**: `amortize(principal, i, n)`.

---

## C12 — Savings goal

**Step 1 — Project existing savings**

```
existing(n) = current × (1 + i)^n          (if growth = 'grow')
existing(n) = current                        (if growth = 'flat')
```

where `i = annual_rate / 1200` (nominal monthly rate).

**Step 2 — Remaining target**

```
remaining = max(0, target − existing(n))
```

**Step 3 — Monthly contribution**

```
monthly = goalContribution(remaining, i, n)    (C05 with end-of-period)
```

If remaining = 0, no new contributions are needed.

**No-growth mode** (rate = 0): `monthly = remaining / n`.

**Implementation**: `_savingsGoal()` in `catalog.dart`.

---

## C13 — Percentage utilities

| Mode | Formula |
|---|---|
| `of` | part = value × percentage / 100 |
| `change` | change% = (new − old) / old × 100 (old ≠ 0) |
| `points` | points = new_rate − old_rate |
| `add` | result = amount × (1 + p/100) |
| `remove` | result = amount × (1 − p/100) |
| `undo_add` | original = amount / (1 + p/100) |
| `undo_remove` | original = amount / (1 − p/100) |

Percentage points are the arithmetic difference between two rates.
Percentage change is the relative change from the original value.
These two are explicitly kept separate (FR-02, FR-03).

---

## C14 — Investment comparison

Two independent scenarios A and B run over the same horizon with the same model
(monthly compounding at month end):

```
balance_A(p+1) = balance_A(p) × (1 + rA/1200) + contribA
balance_B(p+1) = balance_B(p) × (1 + rB/1200) + contribB
```

Primary result: `balance_B(n) − balance_A(n)`.

Both scenarios use the same n (months = common_years × 12), but may have different
starting balances, monthly contributions, and annual return rates.

**Assumption shown to user**: higher assumed returns do not imply equal risk.

---

## Numerical stability notes

| Issue | Mitigation |
|---|---|
| Division by `i` when i ≈ 0 | All annuity formulas check `i.abs() < 1e-9` and use a zero-rate branch |
| Accumulated rounding in loan schedules | Interest and payment rounded to 2 dp each period; final payment clears residual |
| Closing balance noise | Values below 1e-6 are clamped to 0 in `amortize()` |
| CAGR with V0 near zero | CalcException raised before the division |
| Inflation at −100% | CalcException raised before division by (1 + f) |
