-- Space missions exploratory 
-- *MOST OF THE QUERIES IN THIS FILE ARE FOR PRACTICE, there are many ways to obtain the same result set and some options might be easier to implement.
-- 0. The general goal is to create dim-fact table format, helpful for the star schema.
-- Give insights of the following
	-- 1. Access to the general panorama.
	-- 2. Know the total missions launched by country.
	-- 2.1 Know the total missions launched by year and how launched it.
	-- 2.2 Get the same results where the order of launches is not important, only the count of missions by year.
	-- 2.3 Get the total and year where most of the launches occured. (By a Common Table Expression CTE).
	-- 2.4 Difference between first-latest mission, first-now & latest-now in years.
	-- 2.5 Fail and Success Rate Global
	-- 2.6 Fail and Success Total of Missions by Country
	-- 2.6bFail and Success Total of Missions by Country (Same result as 2.6, just different format).
	-- 2.7 Fail and Success Rate by Country
	-- 3. Know how much does each country/company spent.
	-- 3.1Know how much does each country/company spent through the years.

-- 0. Preparation of tables.
-- As I want to create a Star Schema for Visualization, I need to create tables at least for Country, but I can go further with the Company, Rocket, Mission, RocketStatus and Mission Status.
-- Creating a table for the Countries.
CREATE TABLE Countries
(
	Country_id INT IDENTITY(1,1) PRIMARY KEY,
	Country_name varchar(100)
);
-- Inserting values to the table Countries.
INSERT INTO Countries(Country_name)
SELECT DISTINCT TRIM(PARSENAME(REPLACE(Location, ',', '.'), 1))
FROM SpaceMissions..space_missions;
-- Update the NULL value to NA string.
UPDATE SpaceMissions..Countries
SET Country_name = 'NA'
WHERE Country_name IS NULL;
-- Now, I need to alter the original table, update the values and then drop the original location column.
	-- Adding one column into the original table for the Country Id.
ALTER TABLE SpaceMissions..space_missions
ADD Country_id INT;
	-- Update the new column created just for the id.
UPDATE SpaceMissions..space_missions
SET Country_id = 8
WHERE TRIM(PARSENAME(REPLACE(Location, ',', '.'), 1)) IS NULL;
	-- Drop the original column location as I am not going to use it.
ALTER TABLE SpaceMissions..space_missions
DROP COLUMN Location;

-- Then, I can create a rocket status table and I can update the values on the original table.
CREATE TABLE RocketStatusTable
(
	Status_Id INT IDENTITY(1,1) PRIMARY KEY,
	Status_Name varchar(100)
);
-- Inserting values to the table RocketStatusTable
INSERT INTO RocketStatusTable(Status_Name)
SELECT DISTINCT RocketStatus
FROM SpaceMissions..space_missions;
-- Update the original table.
UPDATE SpaceMissions..space_missions
SET RocketStatus = 2
WHERE RocketStatus IN ('Active');

-- Finally, I will create the Mission Status Table following the same concept of the previous one.
CREATE TABLE MissionStatusTable
(
	MissionStatus_Id INT IDENTITY(1,1) PRIMARY KEY,
	MissionStatus varchar(100)
);
-- Inserting values to the table MissionStatusTable
INSERT INTO MissionStatusTable(MissionStatus)
SELECT DISTINCT MissionStatus
FROM SpaceMissions..space_missions;
-- Update the original table.
UPDATE SpaceMissions..space_missions
SET MissionStatus = 4
WHERE MissionStatus IN ('Failure');

-- 1. Look into the dataset for general panorama.
SELECT *
FROM SpaceMissions..space_missions;

-- Look for the total companies that launched a mission.
SELECT Company, COUNT(*) AS Total_Missions
FROM SpaceMissions..space_missions
GROUP BY Company
ORDER BY COUNT(*) DESC;

-- 2. Know the total missions launched by country.
SELECT COUNT(mst.MissionStatus) OVER (PARTITION BY cts.Country_Name ORDER BY Date) Total_Missions
	,cts.Country_name country
	,Date
	,Company ,Rocket, Mission
FROM SpaceMissions..space_missions spm 
INNER JOIN SpaceMissions..MissionStatusTable mst
	ON spm.MissionStatus = mst.MissionStatus_Id
INNER JOIN SpaceMissions..Countries cts
	ON spm.Country_id = cts.Country_id;

	-- 2.1 Know the total missions launched by year and how launched it.
SELECT YEAR(DATE) Year_of_Mission
	,cts.Country_name country
	,COUNT(mst.MissionStatus) OVER (PARTITION BY YEAR(Date) ORDER BY Date) Total_Missions_By_Year
FROM SpaceMissions..space_missions spm 
INNER JOIN SpaceMissions..MissionStatusTable mst
	ON spm.MissionStatus = mst.MissionStatus_Id
INNER JOIN SpaceMissions..Countries cts
	ON spm.Country_id = cts.Country_id;

	-- 2.2 Get the same results where the order of launches is not important, only the count of missions by year.
SELECT COUNT(*) Total_Missions_By_Year
	,YEAR(Date) Year_of_Mission
FROM SpaceMissions..space_missions spm 
INNER JOIN SpaceMissions..MissionStatusTable mst
	ON spm.MissionStatus = mst.MissionStatus_Id
INNER JOIN SpaceMissions..Countries cts
	ON spm.Country_id = cts.Country_id
GROUP BY YEAR(Date)
ORDER BY 2 ASC;

	-- 2.3 Get the total and year where most of the launches occured. (By a Common Table Expression CTE).
WITH Total_Launches_By_Year AS(
	SELECT COUNT(*) Total_Missions_By_Year
		,YEAR(Date) Year_of_Mission
	FROM SpaceMissions..space_missions spm 
	INNER JOIN SpaceMissions..MissionStatusTable mst
		ON spm.MissionStatus = mst.MissionStatus_Id
	INNER JOIN SpaceMissions..Countries cts
		ON spm.Country_id = cts.Country_id
	GROUP BY YEAR(Date)
),	Max_Missions AS(
	SELECT MAX(Total_Missions_By_Year) Max_Num_Missions
	FROM Total_Launches_By_Year
)
SELECT Max_Num_Missions, Year_of_Mission
FROM Max_Missions mm INNER JOIN Total_Launches_By_Year tl
	ON mm.Max_Num_Missions = tl.Total_Missions_By_Year;

	-- 2.4 Difference between first-latest mission, first-now & latest-now in years.
SELECT Country_name
	,MIN(date) First_Mission, MAX(date) Latest_Mission
	,DATEDIFF(YEAR, MIN(date), MAX(date)) Difference_Between_First_And_Latest_Mission_In_Years
	,DATEDIFF(YEAR, MIN(date), GETDATE()) Difference_Between_First_And_Current_Date_In_Years
	,DATEDIFF(YEAR, MAX(date), GETDATE()) Difference_Between_Latest_And_Current_Date_In_Years
FROM SpaceMissions..space_missions spm INNER JOIN SpaceMissions..Countries cou
ON spm.Country_id = cou.Country_id
GROUP BY Country_name
ORDER BY 6, Country_name;

	-- 2.5 Fail and Success Rate Global
WITH StatusGroups AS(
	SELECT 
	CASE
		WHEN MissionStatus = 2 THEN 'Success'
		ELSE 'Fail'
	END AS Status
	FROM SpaceMissions..space_missions
)
SELECT Status, COUNT(*) AS Total_Missions, CONVERT(decimal(5,2),100.0 * COUNT(*)/(SELECT COUNT(*) FROM StatusGroups)) AS Percentage_Status_Rate
FROM StatusGroups
GROUP BY Status;

	-- 2.6 Fail and Success Total of Missions by Country
WITH StatusGroups AS(
	SELECT Country_id
	,CASE
		WHEN MissionStatus = 2 THEN 'Success'
		ELSE 'Fail'
	END AS Status
	FROM SpaceMissions..space_missions
)
SELECT Country_name, Status, COUNT(*) AS Total_Missions
FROM StatusGroups stg INNER JOIN SpaceMissions..Countries cou
ON stg.Country_id = cou.Country_id
GROUP BY Country_name, Status
ORDER BY Country_name;

	-- 2.6bFail and Success Total of Missions by Country
SELECT Country_name
	,SUM(CASE WHEN MissionStatus = 2 THEN 1 ELSE 0 END) Successful_Missions
	,SUM(CASE WHEN MissionStatus <> 2 THEN 1 ELSE 0 END) Failure_Any_Type_Missions
FROM SpaceMissions..space_missions spm INNER JOIN SpaceMissions..Countries cou
ON spm.Country_id = cou.Country_id
GROUP BY Country_name
ORDER BY Country_name;

	-- 2.7 Fail and Success Rate by Country (TODO)
SELECT Country_name
	,SUM(CASE WHEN MissionStatus = 2 THEN 1 ELSE 0 END) Successful_Missions
	,COUNT(*) Total_Missions
	-- Repeating the previos calculus just for having all the information in columns.
	,CONVERT(decimal(5,2), 100.0 * SUM(CASE WHEN MissionStatus = 2 THEN 1 ELSE 0 END) / COUNT(*)) AS Success_Rate_By_Country
FROM SpaceMissions..space_missions spm INNER JOIN SpaceMissions..Countries cou
ON spm.Country_id = cou.Country_id
GROUP BY Country_name
ORDER BY Country_name;

 	-- 3. Know how much does each country/company spent.
SELECT cou.Country_name, ROUND(SUM(spm.Price),2) as Total_Cost_US_Millions
FROM SpaceMissions..space_missions spm INNER JOIN SpaceMissions..Countries cou
ON spm.Country_id = cou.Country_id
GROUP BY cou.Country_name
ORDER BY 2 DESC;

SELECT Company, ROUND(SUM(Price),2) as Total_Cost_US_Millions
FROM SpaceMissions..space_missions
GROUP BY Company
ORDER BY 2 DESC;

 	-- 3.1 Know how much does each country/company spent, through the years.
SELECT cou.Country_name, spm.Date, CONVERT(decimal(10,2), SUM(spm.Price) OVER(PARTITION BY cou.Country_name ORDER BY cou.Country_Name, spm.Date)) as Total_Cost_US_Millions
FROM SpaceMissions..space_missions spm INNER JOIN SpaceMissions..Countries cou
ON spm.Country_id = cou.Country_id
GROUP BY cou.Country_name, spm.Date, spm.Price
HAVING SUM(spm.Price) > 0
ORDER BY cou.Country_name, spm.Date ASC;

SELECT Company, Date, CONVERT(decimal(10,2),SUM(Price) OVER(PARTITION BY Company ORDER BY Company, Date)) as Total_Cost_US_Millions
FROM SpaceMissions..space_missions
GROUP BY Company, Date, Price
HAVING SUM(Price) > 0
ORDER BY Company, Date ASC;