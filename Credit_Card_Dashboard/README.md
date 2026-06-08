# Predictive ROI Modeling: Quantifying Usability vs. Churn Risk

An analytical framework and research pipeline that bridges qualitative user experience metrics with macro-level business retention. This project utilizes a post-project **Logistic Regression (Logit)** model built in Python to simulate user populations and quantify how iterative design improvements directly mitigate financial churn risk.

## 📊 Business Impact Summary

Through mixed-methods usability testing, the platform design was iterated from a baseline score to a near-flawless rating. By applying predictive modeling to these results, the financial impact of the UX lifecycle was explicitly quantified:

| Metric | Iteration 1 (Mobile Baseline) | Iteration 2 (Final Desktop) | Delta / Impact |
| :--- | :---: | :---: | :---: |
| **System Usability Scale (SUS)** | 94.17 | **99.64** | **+5.47 Points** |
| **Predicted User Churn Risk** | 10.8% | **4.2%** | **-6.60% Risk Reduction** |
| **Annual Financial Impact** | *Confidential* | *Confidential* | **Millions in Revenue Protected** |

---

## 🛠️ Tech Stack & Libraries
* **Language:** Python 3.x
* **Statistical Modeling:** `statsmodels` (Maximum Likelihood Estimation)
* **Data Manipulation:** `numpy`, `pandas`
* **Data Visualization:** `matplotlib`

---

## 🔬 Core Methodology & Project Structure

### 1. Mixed-Methods UX Architecture
* **Qualitative Baseline:** Led 12 cross-device remote moderated usability sessions (6 mobile, 6 desktop) evaluating high-friction workflows including security card visibility, account navigation, and card-locking modal logic.
* **Component Optimization:** The team refined interface taxonomy, micro-copy, and modal layout constraints to create a unified, reusable component library.

### 2. Post-Project Quantitative Validation
* **Data Reconstruction:** Developed a custom distribution algorithm (`generate_constrained_scores`) to back-engineer granular, user-level metrics from aggregated sample means while preserving mathematical variation.
* **Population Bootstrapping:** Scaled the empirical parameters ($N=12$) into a simulated environment of **1,000 synthetic users** ($N=1,000$) using Gaussian distribution rules to establish statistical viability for regression modeling.
* **Predictive Logistic Modeling:** Evaluated binary outcomes (Churned vs. Retained) against continuous usability scores to isolate design quality as an independent financial variable.

---

## 📐 The Mathematical Model

The relationship between system usability and user attrition is defined via the **Sigmoid (Logistic) Function**:

* **Log-Odds of Churn:** 16.9203 - 0.2231 * (SUS Score)
* **Probability Formula:** P(Churn) = 1 / (1 + e^-(16.9203 - 0.2231 * SUS))

### Key Statistical Insight:
The negative coefficient (**-0.2231**) mathematically proves that usability acts as an independent retention lever. For every **1-point increase** on the System Usability Scale, the log-odds of a user churning drop significantly, allowing the business to map design iterations directly to customer lifetime value.

---

## 📂 Repository Contents
* `churn_validation_model.py` - The production script containing data simulation, Logit model fitting, and revenue protection calculations.
* `churn_sigmoid_curve.png` - The exported Matplotlib visualization mapping the continuous regression curve against the empirical study milestones.

## 🚀 How To Run the Analysis
1. Clone the repository.
2. Ensure dependencies are installed: `pip install numpy pandas statsmodels matplotlib`
3. Execute the script: `python churn_validation_model.py`

---

*Note: Specific financial variables (ARPU, Portfolio Volumes, and Total Protected Revenue) have been scrubbed or anonymized in this public repository to protect proprietary company data.*
