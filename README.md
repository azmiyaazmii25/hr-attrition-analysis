
## HR Attrition Analysis (SQL)

**A SQL case study analyzing why employees leave, which departments are most affected, and what it costs the business — using MySQL, joins, CTEs, and window functions.**

---

## 1. The Business Problem

The People/HR team wants to know:
> "Attrition feels higher than last year. Which departments are losing people fastest, how long do people stay before leaving, and is pay the reason they're leaving?"

This is a common real-world analyst task — a stakeholder has a vague concern, and the job is to turn it into specific, decision-ready numbers.

## 2. The Data

A simulated but realistic HR dataset with three tables:

| Table | Description |
|---|---|
| `departments` | 6 departments across 3 office locations |
| `employees` | 50 employees — job title, hire date, termination date (NULL if still active), salary, manager, gender |
| `performance_reviews` | Multiple performance ratings (1–5) per employee over time |

See [`sql/schema.sql`](sql/schema.sql) for table structure and [`sql/seed_data.sql`](sql/seed_data.sql) for the data.

## 3. Approach

Queries are organized in [`sql/queries.sql`](sql/queries.sql) from beginner to advanced, so the file itself doubles as a learning path:

1. **Basic filtering** — `WHERE`, `ORDER BY`
2. **Aggregation** — `GROUP BY`, headcount and average salary breakdowns
3. **Joins** — department joins, a self-join for the manager hierarchy, LEFT JOIN to find departments with zero attrition
4. **Core business metrics** — overall and department-level attrition rate, average tenure of leavers, salary comparison (leavers vs. stayers)
5. **CTEs** — same attrition logic rewritten cleanly, plus a query that isolates only above-average-attrition departments
6. **Window functions** — `RANK()` for salary ranking within department, `LAG()` to track whether performance ratings dropped before someone left, a running headcount total, and a pay-equity check by gender

## 4. Key Findings

**Overall attrition rate: 20%** (10 of 50 employees have left).

**Attrition is heavily concentrated in two departments:**

| Department | Headcount | Leavers | Attrition Rate |
|---|---|---|---|
| Engineering | 16 | 5 | **31.3%** |
| Sales | 10 | 3 | **30.0%** |
| Marketing | 5 | 1 | 20.0% |
| Customer Support | 8 | 1 | 12.5% |
| HR | 5 | 0 | 0% |
| Finance | 6 | 0 | 0% |

**Tenure before leaving varies sharply by department:**
- Sales employees who leave do so **very early — around 13 months** on average.
- Engineering employees leave later, **around 35 months**.
- Marketing and Support leavers stay much longer (69–83 months) before exiting.

→ This tells two *different* stories requiring two *different* fixes: Sales looks like an early-tenure/onboarding problem, while Engineering looks like a mid-career retention problem.

**Salary is NOT the primary driver.** Counter to the initial assumption, employees who left actually earned *more* on average (₹9.86L) than those who stayed (₹9.03L). This is an important finding — it means a blanket pay raise likely won't fix attrition, and the real driver is probably something else (role fit, management, growth opportunities, work culture).

**Performance ratings trend downward before departure** for several employees (visible via the `LAG()` query) — suggesting disengagement is detectable *before* someone resigns, which is actionable for early intervention.

**Pay equity check:** at the aggregate level, average salary is roughly comparable between genders (₹9.09L for women vs. ₹9.00L for men), though this should be checked per job title, not just overall, since aggregate averages can mask role-level gaps.

## 5. Recommendations

1. **Fix Sales onboarding, not Sales pay.** With average tenure of leavers at just 13 months, this looks like a ramp-up/expectation-setting problem, not a compensation problem. Recommend reviewing the first 90-day experience.
2. **Investigate Engineering culture/growth paths** separately — longer tenure before leaving suggests burnout or lack of career progression rather than a bad hire/onboarding fit.
3. **Build a lightweight early-warning signal** using performance rating trends (the `LAG()` query) — a declining rating over two consecutive reviews could trigger a retention conversation before resignation.
4. **Don't lead with a pay raise** as the retention fix — the data doesn't support pay as the primary driver here. Redirect budget toward manager training or career-pathing instead.

---

## How to Run This Yourself

```bash
mysql -u root -p < sql/schema.sql
mysql -u root -p hr_attrition < sql/seed_data.sql
mysql -u root -p hr_attrition < sql/queries.sql
```

Or paste each file into MySQL Workbench / any MySQL client and run section by section.

## Tools Used
- MySQL 8.0 (window functions, CTEs)
- Python (data generation for realistic seed data — see `generate_data.py`)

## What This Project Demonstrates
- Translating a vague business question into specific metrics
- Joins (inner, left, self-join)
- CTEs for readable, layered logic
- Window functions (`RANK`, `LAG`, running totals) — often the differentiator in SQL interview rounds
- Drawing a business recommendation from data, not just reporting numbers
---

## Author
**Azmiya** — [GitHub](https://github.com/azmiyaazmii25)
