WITH subq AS 
    (SELECT 
        DISTINCT DATE_TRUNC(PARSE_DATE("%Y%m%d",CAST (SHOP_DATE AS STRING)), MONTH) AS Current_Month,
        CUST_CODE
    FROM (SELECT * FROM`animated-spider-298408.SupermarketData.SupermarketData`)
    WHERE CUST_CODE IS NOT NULL 
    ORDER BY CUST_CODE DESC, Current_Month DESC)

SELECT
   Current_Month,
   SUM(Cust_New) AS Cust_New,
   SUM(Cust_Repeat) AS Cust_Repeat,
   SUM(Cust_Reactivate) AS Cust_Reactivate,
   (-1) * LEAD(SUM(Cust_Churn)) OVER (ORDER BY Current_Month DESC) AS Cust_Churn,
FROM 
    (SELECT
        Current_Month,
        Last_Visit,
        Next_Visit,
        DATE_DIFF(Current_Month, Last_Visit, MONTH) As Last_Diff,
        DATE_DIFF(Next_Visit, Current_Month, MONTH) As Next_Diff,
        CUST_CODE,
        CASE WHEN Last_Visit IS NULL THEN 1 ELSE 0 END AS Cust_New, #New in that month
        CASE WHEN DATE_DIFF(Current_Month, Last_Visit, MONTH) = 1 THEN 1 ELSE 0 END AS Cust_Repeat,#Repeat in that month
        CASE WHEN DATE_DIFF(Current_Month, Last_Visit, MONTH) > 1 THEN 1 ELSE 0 END AS Cust_Reactivate,#Reactive in that month
        CASE WHEN DATE_DIFF(Next_Visit, Current_Month, MONTH) != 1 OR Next_Visit IS NULL THEN 1 ELSE 0 END AS Cust_Churn, #Churn in next month
        FROM
            (SELECT Current_Month,
            LEAD(Current_Month) OVER (PARTITION BY CUST_CODE ORDER BY Current_Month DESC) AS Last_Visit,
            LAG(Current_Month) OVER (PARTITION BY CUST_CODE ORDER BY Current_Month DESC) AS Next_Visit,
            CUST_CODE
            FROM subq)
    ORDER BY CUST_CODE DESC, Current_Month DESC)
GROUP BY Current_Month
ORDER BY Current_Month