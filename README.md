# SpaceMissionsChallenge
## Space mission challenge from Maven Analytics.
The following repository was made for the Maven Analytics challenge (August 2022 - September 2022).  
The purpose was to create a single page dashboard telling the story of space missions through the years.  
For this Challenge I used `SQL` and `Power BI` for the analysis, cleaning and visualization of the data.

## Table of Contents
- [Original Dataset](#Original-Dataset)
- [Data cleaning and transformation](#how-to-create-your-profile)
- [SQL Analysis](#SQL-Analysis)
- [Dashboard](#Dashboard)

### Original Dataset  
The original dataset can be downloaded in Kaggle, but I also included it in this repository for you😀.  
[Original Dataset](https://www.kaggle.com/datasets/agirlcoding/all-space-missions-from-1957)

### Data cleaning and transformation  
For the data transformation section, I use `SQL` to go from a single table to several dimensional tables almost ready for a `star schema`.  
With a star schema, it is easier for SQL and Power BI to process and is a *must* in database design.  
Preview of a table dimensional table for the countries created in SQL:  
| ID_Country | Country Name |
| --- | --- |
| 1 | USA |
| 2 | Russia |
| 3 | China |

### SQL-Analysis  
For the analysis I get insights about the rate success, total missions, etc. 
- The general panorama.  
- Total missions launched by country.  
- Difference between first-latest mission, first-now & latest-now in years.  
- Fail and success rate globally, by country.
- Cost of the missions by country and company.

```sql
#Preview of a query included in the analysis.
SELECT Country_name
	,SUM(CASE WHEN MissionStatus = 2 THEN 1 ELSE 0 END) Successful_Missions
	,SUM(CASE WHEN MissionStatus <> 2 THEN 1 ELSE 0 END) Failure_Any_Type_Missions
FROM SpaceMissions..space_missions spm INNER JOIN SpaceMissions..Countries cou
ON spm.Country_id = cou.Country_id
GROUP BY Country_name
ORDER BY Country_name;
```
### Dashboard
Finally, the creation of a storytelling dashboard was created in Power BI, trying to highlight by the usage of colors, forms, text.  
You can see the submitted dashboard in the following LinkedIn [post](https://www.linkedin.com/posts/isra-gca_mavenspacechallenge-data-analytics-activity-6966099340893319168-UALN?utm_source=linkedin_share&utm_medium=member_desktop_web). 
