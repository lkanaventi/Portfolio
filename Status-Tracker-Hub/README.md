# Status Tracker Hub: Quantitative UX Retrofit Pipeline

[🌐 **Read the Full UX Case Study & Business Impact on Squarespace**](https://www.lucykanaventi.com/status-tracker-hub-copy-1)


## 📌 Technical Overview
This repository showcases a quantitative upgrade to a legacy fintech UX research project. Using behavioral analytics and machine learning techniques gained during my Master's in Data Science, I built Python pipelines to evaluate navigation architecture and user interaction patterns. 

*🔒 **Data Privacy Note:** To protect proprietary bank information and user privacy, all analyses are executed using synthesized user behavior datasets engineered to mimic real-world interaction complexities.*

## 📂 Repository Structure
```text
Status-Tracker-Hub/
├── README.md                 <-- This technical overview
├── notebooks/                
│   ├── tree_test_analysis.ipynb   <-- Info architecture & task success analytics
│   └── click_test_analysis.ipynb  <-- Algorithmic user clustering & time-on-task math
```

## 🧪 Quant UX Upgrades & Python Packages
* **Tree Testing Notebook:** Evaluates information architecture by computing task success rates and completion time distributions using `pandas` and `numpy`.
* **Click Testing Notebook:** Re-evaluates interaction design using `scipy.stats` for task metrics. Features unsupervised machine learning (`sklearn.cluster.KMeans`) to segment user behavioral archetypes based on task completion time and first-click success parameters.
* **Exploratory Analytics:** Utilizes `matplotlib` and `seaborn` for behavioral data visualization and performance distributions.

## ⚙️ How to Run Locally

### 1. Clone the Repository
```bash
git clone https://github.com
cd YOUR_REPO_NAME/Status-Tracker-Hub
```

### 2. Install Dependencies
```bash
pip install pandas numpy scipy scikit-learn matplotlib seaborn notebook
```

### 3. Launch the Notebooks
```bash
jupyter notebook
```
