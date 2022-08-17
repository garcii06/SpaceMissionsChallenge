-- Space missions exploratory 
-- 0. The general goal is to create dim-fact table format, helpful for the star schema.
-- Give insights of the following
	-- 1. Access to the general panorama.
	-- 1.1 
	-- 2. Know the countries success rate. Can be by a timeframe or company (By a window function implementation).
	-- 3. Know how much does each country/company spent.

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

-- 2. Know the countries success rate. Can be by a timeframe or company (By a window function implementation).
SELECT COUNT(mst.MissionStatus) OVER (PARTITION BY cts.Country_Name ORDER BY Date) Total_Missions
	,cts.Country_name country
	,Date
	,Company ,Rocket, Mission
FROM SpaceMissions..space_missions spm 
INNER JOIN SpaceMissions..MissionStatusTable mst
	ON spm.MissionStatus = mst.MissionStatus_Id
INNER JOIN SpaceMissions..Countries cts
	ON spm.Country_id = cts.Country_id;

-- 2. Know the countries success rate. Can be by a timeframe or company (By a window function implementation).
	-- 2.1 Know the total missions by each year, and the order of launches according to the country
SELECT COUNT(mst.MissionStatus) OVER (PARTITION BY YEAR(Date) ORDER BY Date) Total_Missions_By_Year
	,YEAR(DATE) Year_of_Mission
	,cts.Country_name country
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

-- 	-- 3. Know how much does each country/company spent.