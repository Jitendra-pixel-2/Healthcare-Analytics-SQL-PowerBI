CREATE DATABASE IF NOT EXISTS hospital_analytics;
USE hospital_analytics;

DROP TABLE IF EXISTS patient_records;

CREATE TABLE IF NOT EXISTS patient_records (
    Admission_ID INT PRIMARY KEY,
    Patient_ID INT,
    Admission_Date DATETIME,
    Discharge_Order_Time DATETIME,
    Actual_Discharge_Time DATETIME,
    Department VARCHAR(50),
    Payer_Mix VARCHAR(50),
    Total_Billed_Amount DECIMAL(10,2)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Final_SQL_Ready_Data.txt'
INTO TABLE patient_records
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM patient_records LIMIT 10;

-- 30-Day Readmission Analysis (NABH Compliance)

-- Step 1: Create a Common Table Expression (CTE) to track patient history.
-- Using the LAG() window function to fetch the previous discharge date for the same patient.
WITH PatientHistory AS (
    SELECT 
        Patient_ID,
        Admission_ID,
        Department,
        Admission_Date,
        LAG(Actual_Discharge_Time) OVER (PARTITION BY Patient_ID ORDER BY Admission_Date) AS Previous_Discharge_Date
    FROM patient_records
)

-- Step 2: Calculate the gap in days using DATEDIFF.
-- Filter the records to show only those patients who were readmitted within 30 days.
SELECT 
    Patient_ID,
    Admission_ID AS Current_Admission_ID,
    Department,
    Previous_Discharge_Date,
    Admission_Date AS Re_Admission_Date,
    DATEDIFF(Admission_Date, Previous_Discharge_Date) AS Days_Between_Admissions
FROM PatientHistory
WHERE DATEDIFF(Admission_Date, Previous_Discharge_Date) BETWEEN 0 AND 30
  AND Previous_Discharge_Date IS NOT NULL
ORDER BY Days_Between_Admissions ASC;

-- TAT (Turnaround Time) Delay Analysis
-- Calculating the delay between doctor's discharge order and actual physical discharge in hours.

SELECT 
    Admission_ID,
    Department,
    Payer_Mix AS Insurance_Type,
    Discharge_Order_Time,
    Actual_Discharge_Time,
    -- TIMESTAMPDIFF function hours me time difference nikalta hai
    TIMESTAMPDIFF(HOUR, Discharge_Order_Time, Actual_Discharge_Time) AS Delay_In_Hours
FROM patient_records
WHERE TIMESTAMPDIFF(HOUR, Discharge_Order_Time, Actual_Discharge_Time) > 0
ORDER BY Delay_In_Hours DESC;

-- Department Revenue and Performance Analysis
-- Grouping data by department to calculate total patients, total revenue, and average bill.

SELECT 
    Department,
    COUNT(Patient_ID) AS Total_Patients,
    SUM(Total_Billed_Amount) AS Total_Revenue,
    ROUND(AVG(Total_Billed_Amount), 2) AS Avg_Revenue_Per_Patient
FROM patient_records
GROUP BY Department
ORDER BY Total_Revenue DESC;