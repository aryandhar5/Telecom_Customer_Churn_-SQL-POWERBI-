SELECT * FROM telecom_db.telecom_churn;

SELECT * FROM telecom_churn;
SET SQL_SAFE_UPDATES = 0;

-- Convert TotalCharges to Numeric and Handle Nulls
UPDATE telecom_db.telecom_churn 
SET TotalCharges = CAST(NULLIF(TotalCharges, '') AS DECIMAL(10,2));

## check data type
DESC telecom_churn;

## checking for remaining NULL values or empty values
SELECT * FROM telecom_churn WHERE TotalCharges IS NULL OR TotalCharges = '';

-- Step 4: Verify Data Cleaning
SELECT * FROM telecom_churn WHERE TotalCharges IS NULL;

-- ------------ Exploratory Data Analysis (EDA) --------------------------

----- Total Customers and Churn Rate-----
SELECT COUNT(*) AS total_customers,
SUM(CASE
    WHEN Churn='Yes' THEN 1 ELSE 0
END) AS Churn_Customers,
ROUND(100 * SUM(CASE
    WHEN Churn='Yes' THEN 1 ELSE 0 END)/COUNT(*),2) AS Churn_Rate,
    ROUND(100.0 * SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate
FROM telecom_churn
;

-- Churn by Contract Type -----------
SELECT 
    Contract,
    COUNT(*) AS total_customers,
	SUM(CASE WHEN Churn='Yes' THEN 1 ELSE 0 END) AS Churned_customers,
	ROUND(100.0 * SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate

FROM telecom_churn
GROUP BY Contract
ORDER BY Churn_rate DESC
;

----- Churn by Payment Method --------------------

SELECT 
    PaymentMethod, 
    COUNT(*) AS total_customers, 
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers, 
    ROUND(100.0 * SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate
FROM telecom_churn
GROUP BY PaymentMethod
ORDER BY churn_rate DESC;

-- Impact of Monthly Charges on Churn----
SELECT 
    CASE 
        WHEN MonthlyCharges < 30 THEN 'Low'
        WHEN MonthlyCharges BETWEEN 30 AND 70 THEN 'Medium'
        ELSE 'High'
    END AS charge_category,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(100.0 * SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate
FROM telecom_churn
GROUP BY charge_category
ORDER BY churn_rate DESC;

-- Impact of Tenure on Churn
SELECT 
    CASE 
        WHEN tenure < 12 THEN 'New (0-12 months)'
        WHEN tenure BETWEEN 12 AND 24 THEN '1-2 years'
        ELSE 'Long-term (>2 years)'
    END AS tenure_category,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(100.0 * SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate
FROM telecom_churn
GROUP BY tenure_category
ORDER BY churn_rate DESC;

--  Identify at-risk customers early and offer discounts or loyalty perks.

SELECT 
    customerID,
    tenure,
    MonthlyCharges,
    Contract,
    PaymentMethod,
    CASE 
        WHEN tenure < 12 AND MonthlyCharges > 70 AND Contract = 'Month-to-month' THEN 'High Risk'
        WHEN tenure BETWEEN 12 AND 24 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS Churn_Risk
FROM telecom_churn;

-- Early Churn Detection (Customers Likely to Leave in Next 3 Months)
SELECT 
    customerID,
    tenure,
    MonthlyCharges,
    Contract,
    PaymentMethod,
    (CASE 
        WHEN tenure < 6 AND Contract = 'Month-to-month' AND PaymentMethod LIKE '%Mailed Check%' THEN 'Likely to Churn'
        ELSE 'Stable'
    END) AS Churn_Prediction
FROM telecom_churn;

-- Effect of Bundled Services on Churn

SELECT 
    InternetService, 
    StreamingTV, 
    StreamingMovies, 
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(100.0 * SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate
FROM telecom_churn
WHERE InternetService != 'No'
GROUP BY InternetService, StreamingTV, StreamingMovies
ORDER BY churn_rate DESC;

-- revenue loss due to churn 

SELECT 
    InternetService, 
    StreamingTV, 
    StreamingMovies, 
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(AVG(MonthlyCharges), 2) AS avg_monthly_charge,
    ROUND(SUM(CASE WHEN Churn = 'Yes' THEN MonthlyCharges ELSE 0 END), 2) AS total_monthly_revenue_lost,
    ROUND(SUM(CASE WHEN Churn = 'Yes' THEN MonthlyCharges ELSE 0 END) * 12, 2) AS total_annual_revenue_lost
FROM telecom_churn
WHERE InternetService != 'No'
GROUP BY InternetService, StreamingTV, StreamingMovies
ORDER BY total_annual_revenue_lost DESC;

-- Customer Lifetime Value (CLV)
SELECT 
    customerID,
    tenure,
    MonthlyCharges,
    (tenure * MonthlyCharges) AS CLV
FROM telecom_churn
WHERE Churn = 'Yes'
ORDER BY CLV DESC;



