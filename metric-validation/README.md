# Marketplace Metrics: Logistics Impact on Retention & Sentiment
**Quantitative UX Research | SQL & R Integration | Statistical Modeling**

## Project Overview
This project investigates the relationship between shipping performance and customer behavior on Olist, the largest e-commerce marketplace in Brazil. By integrating a PostgreSQL relational database with advanced statistical modeling in R, I quantified the exact marginal impact of delivery delays on review scores and long-term customer retention.

**The Bottom Line:** While delivery speed is statistically significant, it only explains 7% of the variance in customer satisfaction, suggesting that expectation management and product quality are more critical levers for ROI than blanket logistics acceleration.

---

## Technical Stack
*   **Database:** PostgreSQL (Schema design, DDL/DML, Window Functions)
*   **Languages:** R (tidyverse, DBI, RPostgreSQL)
*   **Statistics:** Logistic Regression, Fisher’s Exact Test, Kruskal-Wallis, Spearman Rank Correlation
*   **Visualization:** ggplot2

---

## Database Architecture
The analysis is built on a relational star schema centered on the `orders` table. 
*   **Integrity:** Enforced PK/FK constraints and handled Brazilian Portuguese text encoding within the SQL pipeline.
*   **Scale:** Manages 9 distinct entities including geolocation, payments, and localized product categories.

---

## Key Methodology & Statistical Pipeline
This project utilizes a robust pipeline to account for the non-normal distribution of e-commerce data:

| Test | Purpose |
| :--- | :--- |
| **Logistic Regression** | Quantified the 0.85% decrease in retention odds per day of delay. |
| **Fisher’s Exact Test** | Validated categorical retention differences in small sample segments. |
| **Kruskal-Wallis** | Analyzed variance in ordinal (1–5) review scores across delivery cohorts. |
| **Linear Regression** | Isolated the marginal effect: -0.034 points on review scores per delay day. |

---

## Strategic Impact
1.  **Stop Blanket Initiatives:** Platform-wide shipping speedup offers low ROI due to the small effect size on retention.
2.  **Fix Regional Bottlenecks:** Focus on high-delay transit corridors in specific Brazilian states.
3.  **Expectation Software:** Use predictive modeling to provide conservative delivery windows, mitigating negative reviews without altering physical supply chains.

## Repository Structure
*   `/SQL_Queries`: Database schema setup and data cleaning scripts.
*   `/R_Analysis`: The full statistical pipeline and visualization code.
*   `/Results`: Key exports and findings summaries.

---

### [Read the Full Case Study on Squarespace →](https://www.lucykanaventi.com/new-page-49)
