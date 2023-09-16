--SQL Advance Case Study


--Q1--BEGIN 

SELECT DISTINCT L.State
FROM FACT_TRANSACTIONS T
JOIN DIM_LOCATION L
ON L.IDLocation = T.IDLocation
JOIN DIM_DATE D
ON D.DATE = T.Date
JOIN DIM_CUSTOMER C
ON C.IDCustomer = T.IDCustomer
WHERE D.YEAR BETWEEN '2005'  AND (SELECT DATEPART(YEAR, GETDATE()));


--Q1--END


--Q2--BEGIN
	
SELECT TOP 1 L.State, COUNT(T.IDCustomer) AS Total_Orders
FROM FACT_TRANSACTIONS T
JOIN DIM_LOCATION L
ON L.IDLocation = T.IDLocation
JOIN DIM_MODEL M
ON M.IDModel = T.IDModel
JOIN DIM_MANUFACTURER P
ON P.IDManufacturer = M.IDManufacturer
WHERE L.Country = 'US' AND P.Manufacturer_Name = 'Samsung'
GROUP BY L.State
ORDER BY COUNT(T.IDCustomer) DESC


--Q2--END


--Q3--BEGIN      
	
SELECT M.Model_Name, L.ZipCode, L.State, COUNT(T.IDCustomer) AS No_of_Transaction
FROM FACT_TRANSACTIONS T
JOIN DIM_DATE D
ON D.DATE = T.Date
JOIN DIM_LOCATION L
ON L.IDLocation = T.IDLocation
JOIN DIM_MODEL M
ON M.IDModel = T.IDModel
GROUP BY M.Model_Name, L.ZipCode, L.State;

--Q3--END



--Q4--BEGIN

SELECT TOP 1 M.Model_Name, T.TotalPrice
FROM FACT_TRANSACTIONS T
JOIN DIM_MODEL M
ON T.IDModel = M.IDModel
JOIN DIM_MANUFACTURER P
ON M.IDManufacturer = P.IDManufacturer
ORDER BY T.TotalPrice ASC;

--Q4--END



--Q5--BEGIN

SELECT M.Model_Name, AVG(T.TotalPrice/T.Quantity) AS Model_Avg_Price
FROM FACT_TRANSACTIONS T
JOIN DIM_MODEL M
on M.IDModel = T.IDModel
JOIN DIM_MANUFACTURER P
ON P.IDManufacturer = M.IDManufacturer
WHERE P.Manufacturer_Name IN (
						select TOP 5 P.Manufacturer_Name
						from FACT_TRANSACTIONS T
						join DIM_MODEL M
						on M.IDModel = T.IDModel
						JOIN DIM_MANUFACTURER P
						ON P.IDManufacturer = M.IDManufacturer
						GROUP BY P.Manufacturer_Name
						ORDER BY AVG(T.TotalPrice/T.Quantity) DESC) 
GROUP BY M.Model_Name;


--Q5--END



--Q6--BEGIN

SELECT D.YEAR, C.Customer_Name, AVG(T.TotalPrice) AS Average_Spend
FROM FACT_TRANSACTIONS T
JOIN DIM_CUSTOMER C
ON T.IDCustomer = C.IDCustomer
JOIN DIM_DATE D
ON T.Date = D.DATE
GROUP BY D.YEAR, C.Customer_Name
HAVING D.YEAR = '2009' AND AVG(T.TotalPrice)>500
ORDER BY D.YEAR;

--Q6--END


	
--Q7--BEGIN  

WITH CTE AS (SELECT
		ROW_NUMBER() OVER(PARTITION BY YEAR(T.Date) ORDER BY SUM(T.Quantity) DESC) AS RN,
		T.IDModel,
		YEAR(T.Date) AS Year_No,
		SUM(T.Quantity) AS Qty_sold
		FROM FACT_TRANSACTIONS T
		WHERE YEAR(T.date) IN (2008,2009,2010)
        GROUP BY T.IDModel, YEAR(T.Date)
	)
SELECT CTE.IDModel, COUNT(CTE.IDModel) AS Frequency
FROM CTE
WHERE RN <6
GROUP BY CTE.IDModel
HAVING COUNT(CTE.IDModel)=3;


--Q7--END	



--Q8--BEGIN

SELECT X.Year, X.Manufacturer_Name FROM
	(SELECT D.YEAR AS Year, P.Manufacturer_Name, SUM(T.Quantity) AS Total_Qty_Sold,
	RANK() OVER(PARTITION BY D.YEAR ORDER BY SUM(T.Quantity) DESC) AS Sales_Rank
	FROM FACT_TRANSACTIONS T
	JOIN DIM_DATE D
	ON T.Date = D.DATE
	JOIN DIM_MODEL M
	ON M.IDModel = T.IDModel
	JOIN DIM_MANUFACTURER P
	ON M.IDManufacturer = P.IDManufacturer
	GROUP BY D.YEAR, P.Manufacturer_Name) X
WHERE X.Year IN ('2009','2010') AND X.Sales_Rank = 2


--Q8--END



--Q9--BEGIN
	
SELECT P.*
FROM DIM_MANUFACTURER P
WHERE EXISTS (SELECT 1
				FROM FACT_TRANSACTIONS T
				JOIN DIM_MODEL M
				ON T.IDModel = M.IDModel
				WHERE P.IDManufacturer = M.IDManufacturer
				AND
				T.Date >= '2010-01-01' AND  T.Date < '2011-01-01'
			)AND
	NOT EXISTS (SELECT 1
				FROM FACT_TRANSACTIONS T
				JOIN DIM_MODEL M
				ON T.IDModel = M.IDModel
				WHERE M.IDManufacturer = P.IDManufacturer
				AND
				T.Date >= '2009-01-01' AND  T.Date < '2010-01-01'
	);


--Q9--END



--Q10--BEGIN
	

SOLUTION#1: If we have to find the top 100 customer based on total purchase by year 
WITH cte_report as( 
	select D.YEAR AS Year, T.IDCustomer AS CustID, 
	AVG(T.TotalPrice) AS Avg_customer_spend,
	AVG(T.Quantity) AS Avg_quantity_purchased,
	SUM(T.TotalPrice) AS Total_Spend,
	(SUM(T.TotalPrice) - LAG(SUM(T.TotalPrice)) OVER(PARTITION BY T.IDCustomer ORDER BY D.YEAR ASC))/LAG(SUM(T.TotalPrice)) OVER(PARTITION BY T.IDCustomer ORDER BY D.YEAR ASC)*100 AS change_in_spending,
	ROW_NUMBER() OVER(ORDER BY SUM(T.TotalPrice) DESC) AS rn
	from FACT_TRANSACTIONS T
	join DIM_DATE D on D.DATE = T.Date
	GROUP BY D.YEAR, T.IDCustomer)
select R.CustID, R.Year, R.Avg_customer_spend, R.Avg_quantity_purchased, R.Total_Spend, R.change_in_spending, R.rn
from cte_report AS R
where R.rn <=100
ORDER BY R.CustID, R.Year;


--Q10--END