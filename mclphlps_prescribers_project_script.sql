/*PRESCIBERS DATABASE SQL PROJECT*/

-------------------------------------------------------------------------------------------------------------------------
--EDA--
--
SELECT * FROM prescriber; --PK npi, 25050 DISTINCT rows
SELECT * FROM prescription; --FK npi to prescriber., 656058 rows
							--FK drug_name to drug., 1821 DISTINCT drug_name rows
SELECT * FROM drug; --FK drug_name to presciption., 3425 rows, 3253 DISTINCT rows (172 extra rows)

--fipscounty
SELECT * FROM fips_county; --PK fipscounty, 3272 rows, 3271 DISTINCT rows (one extra row?)
SELECT * FROM zip_fips; --FK zip to prescriber., 54181 rows, 39461 DISTINCT rows
						--FK fipscounty to fips_county., 3227 DISTINCT rows
SELECT * FROM cbsa; --FK fipscounty to fips_county. AND zip_fips, 1238 rows, 1237 DISTINCT rows (one extra row?)
SELECT * FROM population; --FK fipscounty to fips_county. AND zip_fips., 95 rows DISTINCT
SELECT * FROM overdose_deaths; --FK fipscounty to fips_county., 380 rows, 95 DISTINCT fipscounty, 4 DISTINCT years

--DISTINCTS
SELECT DISTINCT fipscounty FROM zip_fips;
--3227 rows
SELECT DISTINCT cbsa FROM cbsa;
--409 rows
SELECT DISTINCT fipscounty FROM overdose_deaths;
--95 rows
SELECT DISTINCT fipscounty FROM cbsa;
--1237 rows
SELECT DISTINCT drug_name FROM drug;
--3253
SELECT DISTINCT drug_name FROM prescription;
--1821 rows
SELECT DISTINCT npi
FROM prescriber;
--25050
SELECT DISTINCT nppes_provider_zip5
FROM prescriber;
--440 rows
SELECT DISTINCT drug_name FROM prescription;
--1821
SELECT zip
FROM zip_fips;
--54181 rows
SELECT DISTINCT fipscounty FROM population;
--95 rows
SELECT DISTINCT zip
FROM zip_fips;
--39461 rows

--END EDA--

-------------------------------------------------------------------------------------------------------------------------

-- -- -- MVP QUESTIONS -- -- --
-- -- -- For this exericse, you'll be working with a database derived from the Medicare Part D Prescriber Public Use File. More information about the data is contained in the Methodology PDF file. See also the included entity-relationship diagram.

-- -- -- 1a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
SELECT
	npi,
	SUM(total_claim_count) total_num_claims
FROM prescription
GROUP BY npi
ORDER BY total_num_claims DESC
LIMIT 1;
-- -- -- ANSWER
-- -- -- "npi"		| "total_num_claims"
-- -- -- 1881634483	| 99707


-- -- -- 1b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, and the total number of claims.
SELECT
	npi,
	nppes_provider_first_name,
	nppes_provider_last_org_name,
	specialty_description,
	SUM(total_claim_count) total_num_claims
FROM prescription
LEFT JOIN prescriber USING(npi)
GROUP BY npi, nppes_provider_first_name, nppes_provider_last_org_name, specialty_description
ORDER BY total_num_claims DESC
LIMIT 1;
-- -- -- ANSWER
-- -- -- "npi"		|"nppes_provider_first_name"|"nppes_provider_last_org_name" |"specialty_description"|"total_num_claims"
-- -- -- 1881634483	|"BRUCE"					|"PENDLEY"						|"Family Practice"		|99707

-- -- -- 2a. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT
	specialty_description,
	SUM(total_claim_count) total_num_claims
FROM prescription
LEFT JOIN prescriber USING(npi)
GROUP BY specialty_description
ORDER BY total_num_claims DESC
LIMIT 1;
-- -- -- ANSWER
-- -- -- "specialty_description"|"total_num_claims"
-- -- -- "Family Practice"		|9752347

-- -- -- 2b. Which specialty had the most total number of claims for opioids?
SELECT
	specialty_description,
	SUM(total_claim_count) total_num_claims
FROM prescription
LEFT JOIN prescriber USING(npi)
LEFT JOIN drug USING(drug_name)
WHERE drug.opioid_drug_flag = 'Y'	
GROUP BY specialty_description
ORDER BY total_num_claims DESC
LIMIT 1;
-- -- -- ANSWER
-- -- -- "specialty_description"|"total_num_claims"
-- -- -- "Nurse Practitioner"	|900845

-- -- -- 2c. CHALLENGE QUESTION: Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
SELECT
	specialty_description,
	SUM(total_claim_count) total_num_claims
FROM prescription
RIGHT JOIN prescriber USING(npi)
GROUP BY specialty_description
ORDER BY total_num_claims DESC, specialty_description;
-- -- -- ANSWER
/*
"specialty_description"	"total_num_claims"
"Ambulatory Surgical Center"	
"Chiropractic"	
"Contractor"	
"Developmental Therapist"	
"Hospital"	
"Licensed Practical Nurse"	
"Marriage & Family Therapist"	
"Medical Genetics"	
"Midwife"	
"Occupational Therapist in Private Practice"	
"Physical Therapist in Private Practice"	
"Physical Therapy Assistant"	
"Radiology Practitioner Assistant"	
"Specialist/Technologist, Other"	
"Undefined Physician type"	
*/

-- -- -- 2d. DIFFICULT BONUS: DO NOT ATTEMPT UNTIL YOU HAVE SOLVED ALL OTHER PROBLEMS! For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

-- -- -- ANSWER

-- -- -- 3a. Which drug (generic_name) had the highest total drug cost?
SELECT
	DISTINCT generic_name,
	SUM(total_drug_cost) total_drug_cost
FROM prescription
LEFT JOIN drug USING(drug_name)
GROUP BY generic_name
ORDER BY total_drug_cost DESC
LIMIT 1;
-- -- -- ANSWER
-- -- -- "generic_name"					 |"total_drug_cost"
-- -- -- "INSULIN GLARGINE,HUM.REC.ANLOG"|104264066.35

-- -- -- 3b. Which drug (generic_name) has the hightest total cost per day? BONUS: ROUND YOUR COST PER DAY COLUMN TO 2 DECIMAL PLACES. GOOGLE ROUND TO SEE HOW THIS WORKS.
SELECT
	DISTINCT generic_name,
	ROUND((SUM(total_drug_cost) / SUM(total_day_supply)), 2) AS cost_per_day
FROM prescription
LEFT JOIN drug USING(drug_name)
GROUP BY generic_name
ORDER BY cost_per_day DESC
LIMIT 1;
-- -- -- ANSWER
-- -- --"generic_name"			|"cost_per_day"
-- -- --"C1 ESTERASE INHIBITOR"	|3495.22

-- -- -- 4a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. Hint: You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/
SELECT 
	drug_name,
	CASE 
    	WHEN opioid_drug_flag = 'Y' THEN 'opioid'
        WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
        ELSE 'neither'
	END AS drug_type
FROM drug;
-- -- -- ANSWER: execute query above

-- -- -- 4b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
SELECT 
	CAST(SUM(total_drug_cost) AS money) AS money_spent,
	CASE 
    	WHEN opioid_drug_flag = 'Y' THEN 'opioid'
        WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
        ELSE 'neither'
	END AS drug_type
FROM drug
LEFT JOIN prescription USING(drug_name)
GROUP BY drug_type
ORDER BY money_spent DESC;
-- -- -- ANSWER opioid > antibiotic
-- -- -- "money_spent"		|"drug_type"
-- -- -- "$105,080,626.37"	|"opioid"
-- -- -- "$38,435,121.26"	|"antibiotic"

-- -- -- 5a. How many CBSAs are in Tennessee? WARNING: The cbsa table contains information for all states, not just Tennessee.
SELECT
	state,
	COUNT(cbsa) AS num_of_cbsas
FROM cbsa
LEFT JOIN fips_county USING(fipscounty)
WHERE state = 'TN'
GROUP BY state;
-- -- -- ANSWER: 42

-- -- -- 5b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
SELECT
	cbsaname,
	SUM(population) AS total_population
FROM cbsa
LEFT JOIN population USING(fipscounty)
WHERE population IS NOT NULL
GROUP BY cbsaname
ORDER BY total_population DESC;
-- -- -- ANSWER: 
-- -- --"cbsaname"										|"total_population"
-- -- --"Nashville-Davidson--Murfreesboro--Franklin, TN"|1830410| HIGHEST
-- -- --"Morristown, TN"								|116352 | LOWEST

-- -- -- 5c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
SELECT
	DISTINCT county AS county_name,
	population
FROM population
INNER JOIN fips_county USING(fipscounty)
WHERE 
	fipscounty NOT IN (SELECT fipscounty FROM cbsa)
ORDER BY population DESC
LIMIT 1;
-- -- -- ANSWER
-- -- --"county_name"|"population"
-- -- --"SEVIER"	 |95523

-- -- -- 6a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT 
	drug_name,
	total_claim_count
FROM prescription
WHERE total_claim_count > 3000;
-- -- -- ANSWER
-- -- --"drug_name"				   |"total_claim_count"
-- -- --"OXYCODONE HCL"			   |4538
-- -- --"LEVOTHYROXINE SODIUM"	   |3023
-- -- --"LEVOTHYROXINE SODIUM"	   |3138
-- -- --"MIRTAZAPINE"			   |3085
-- -- --"HYDROCODONE-ACETAMINOPHEN"|3376
-- -- --"LEVOTHYROXINE SODIUM"	   |3101
-- -- --"GABAPENTIN"			   |3531
-- -- --"LISINOPRIL"			   |3655
-- -- --"FUROSEMIDE"			   |3083

-- -- -- 6b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
SELECT 
	drug_name,
	total_claim_count,
	CASE
		WHEN drug.opioid_drug_flag = 'Y' THEN 'true'
		WHEN drug.opioid_drug_flag = 'N' THEN 'false'
	END AS is_opioid
FROM prescription
JOIN drug USING(drug_name)
WHERE total_claim_count > 3000;
-- -- -- ANSWER
-- -- --"drug_name"					|"total_claim_count"|"is_opioid"
-- -- --"OXYCODONE HCL"				|4538				|"true"
-- -- --"LEVOTHYROXINE SODIUM"		|3023				|"false"
-- -- --"HYDROCODONE-ACETAMINOPHEN"	|3376				|"true"
-- -- --"MIRTAZAPINE"				|3085				|"false"
-- -- --"GABAPENTIN"				|3531				|"false"
-- -- --"FUROSEMIDE"				|3083				|"false"
-- -- --"LEVOTHYROXINE SODIUM"		|3101				|"false"
-- -- --"LEVOTHYROXINE SODIUM"		|3138				|"false"
-- -- --"LISINOPRIL"				|3655				|"false"

-- -- -- 6c. Add another column to your answer from the previous part which gives the prescriber first and last name associated with each row.
SELECT 
	drug_name,
	total_claim_count,
	CASE
		WHEN drug.opioid_drug_flag = 'Y' THEN 'true'
		WHEN drug.opioid_drug_flag = 'N' THEN 'false'
	END AS is_opioid,
	nppes_provider_first_name,
	nppes_provider_last_org_name
FROM prescription
JOIN drug USING(drug_name)
JOIN prescriber USING(npi)
WHERE total_claim_count > 3000;
-- -- -- ANSWER
-- -- --"drug_name"					|"total_claim_count"|"is_opioid"|"nppes_provider_first_name"|"nppes_provider_last_org_name"
-- -- --"OXYCODONE HCL"				|4538				|"true"		|"DAVID"					|"COFFEY"
-- -- --"HYDROCODONE-ACETAMINOPHEN" |3376				|"true"		|"DAVID"					|"COFFEY"
-- -- --"LEVOTHYROXINE SODIUM"		|3101				|"false"	|"ERIC"						|"HASEMEIER"
-- -- --"GABAPENTIN"				|3531				|"false"	|"BRUCE"					|"PENDLEY"
-- -- --"MIRTAZAPINE"				|3085				|"false"	|"BRUCE"					|"PENDLEY"
-- -- --"LISINOPRIL"				|3655				|"false"	|"BRUCE"					|"PENDLEY"
-- -- --"FUROSEMIDE"				|3083				|"false"	|"MICHAEL"					|"COX"
-- -- --"LEVOTHYROXINE SODIUM"		|3023				|"false"	|"BRUCE"					|"PENDLEY"
-- -- --"LEVOTHYROXINE SODIUM"		|3138				|"false"	|"DEAVER"					|"SHATTUCK"

-- -- -- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. HINT: The results from all 3 parts will have 637 rows.

-- -- -- 7a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). WARNING: Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
SELECT
	npi,
	drug_name
FROM prescriber
CROSS JOIN drug
WHERE specialty_description = 'Pain Management'
		AND opioid_drug_flag = 'Y'
		AND nppes_provider_city = 'NASHVILLE';
	
-- -- -- ANSWER: execute query above

-- -- -- 7b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
WITH sq AS(
	SELECT
		npi,
		drug_name
	FROM prescriber
	CROSS JOIN drug
	WHERE specialty_description = 'Pain Management'
			AND opioid_drug_flag = 'Y'
			AND nppes_provider_city = 'NASHVILLE')
SELECT
	sq.npi,
	sq.drug_name,
	total_claim_count
FROM prescription AS script
--adding right join because i only want total_claim_count if these conditions are met after the subquery
RIGHT JOIN sq
	ON script.npi = sq.npi
	AND script.drug_name = sq.drug_name
ORDER BY total_claim_count;
-- -- -- ANSWER: execute query above

-- -- -- 7c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
WITH sq AS(
	SELECT
		npi,
		drug_name
	FROM prescriber
	CROSS JOIN drug
	WHERE specialty_description = 'Pain Management'
			AND opioid_drug_flag = 'Y'
			AND nppes_provider_city = 'NASHVILLE')
SELECT
	sq.npi,
	sq.drug_name,
	COALESCE(total_claim_count, '0') AS total_claim_count
FROM prescription AS script
--adding right join because i only want total_claim_count if these conditions are met after the subquery
RIGHT JOIN sq
	ON script.npi = sq.npi
	AND script.drug_name = sq.drug_name
ORDER BY total_claim_count DESC;
-- -- -- ANSWER: execute query above

-------------------------------------------------------------------------------------------------------------------------
-- -- GROUPING SETS QUESTIONS -- --
-- -- In this set of exercises you are going to explore additional ways to group and organize the output of a query when using postgres.

-- -- For the first few exercises, we are going to compare the total number of claims from Interventional Pain Management Specialists compared to those from Pain Managment specialists.

-- -- 1. Write a query which returns the total number of claims for these two groups. Your output should look like this:
-- -- specialty_description			 | total_claims
-- -- Interventional Pain Management | 55906
-- -- Pain Management				 | 70853
SELECT 
	specialty_description,
	SUM(total_claim_count) AS total_claims
FROM prescriber
JOIN prescription USING(npi)
WHERE specialty_description ILIKE '%pain%'
GROUP BY specialty_description;
-- -- ANSWER: execute query above

-- -- 2. Now, let's say that we want our output to also include the total number of claims between these two groups. Combine two queries with the UNION keyword to accomplish this. Your output should look like this:
-- -- specialty_description			| total_claims
-- --                       		| 126759
-- -- Interventional Pain Management| 55906
-- -- Pain Management 				| 70853
SELECT 
	specialty_description,
	SUM(total_claim_count) AS total_claims
FROM prescriber
JOIN prescription USING(npi)
WHERE specialty_description ILIKE '%pain%'
GROUP BY specialty_description
UNION
SELECT 
	NULL specialty_description,
	SUM(total_claim_count) AS total_claims
FROM prescriber
JOIN prescription USING(npi)
WHERE specialty_description ILIKE '%pain%';
-- -- ANSWER: execute query above

-- -- 3. Now, instead of using UNION, make use of GROUPING SETS (https://www.postgresql.org/docs/10/queries-table-expressions.html#QUERIES-GROUPING-SETS) to achieve the same output.
SELECT 
	specialty_description,
	SUM(total_claim_count) AS total_claims
FROM prescriber
JOIN prescription USING(npi)
WHERE specialty_description ILIKE '%pain%'
GROUP BY GROUPING SETS ((specialty_description), ());
-- -- ANSWER: execute query above

-- -- 4. In addition to comparing the total number of prescriptions by specialty, let's also bring in information about the number of opioid vs. non-opioid claims by these two specialties. Modify your query (still making use of GROUPING SETS so that your output also shows the total number of opioid claims vs. non-opioid claims by these two specialites:
-- -- specialty_description			|opioid_drug_flag|total_claims|
-- --                       		|                |      129726|
-- --                       		|Y               |       76143|
-- --                       		|N               |       53583|
-- -- Pain Management 				| 				 |		 72487| 
-- -- Interventional Pain Management|				 |		 57239|
SELECT 
	specialty_description,
	opioid_drug_flag,
	SUM(total_claim_count) AS total_claims
FROM prescriber
JOIN prescription USING(npi)
JOIN drug ON prescription.drug_name = drug.drug_name
WHERE
	specialty_description ILIKE '%pain%'
GROUP BY GROUPING SETS ((opioid_drug_flag),(specialty_description), ());
-- -- ANSWER: execute query above

-- -- 5. Modify your query by replacing the GROUPING SETS with ROLLUP(opioid_drug_flag, specialty_description). How is the result different from the output from the previous query?
SELECT 
	specialty_description,
	opioid_drug_flag,
	SUM(total_claim_count) AS total_claims
FROM prescriber
JOIN prescription USING(npi)
JOIN drug ON prescription.drug_name = drug.drug_name
WHERE
	specialty_description ILIKE '%pain%'
GROUP BY ROLLUP (opioid_drug_flag, specialty_description);
-- -- ANSWER: returns the combinations for opioid_drug_flag, including null
-- -- "specialty_description"			|"opioid_drug_flag"	|"total_claims"
-- -- 									|					|129726
-- -- "Pain Management"					|"N"				|30386
-- -- "Pain Management"					|"Y"				|42101
-- -- "Interventional Pain Management"	|"Y"				|34042
-- -- "Interventional Pain Management"	|"N"				|23197
-- -- 									|"Y"				|76143
-- -- 									|"N"				|53583

-- -- 6. Switch the order of the variables inside the ROLLUP. That is, use ROLLUP(specialty_description, opioid_drug_flag). How does this change the result?
SELECT 
	specialty_description,
	opioid_drug_flag,
	SUM(total_claim_count) AS total_claims
FROM prescriber
JOIN prescription USING(npi)
JOIN drug ON prescription.drug_name = drug.drug_name
WHERE
	specialty_description ILIKE '%pain%'
GROUP BY ROLLUP (specialty_description, opioid_drug_flag);
-- -- ANSWER: returns the combinations for specialty_description, including null
-- -- "specialty_description"			|"opioid_drug_flag"	|"total_claims"
-- -- 									|					|129726
-- -- "Pain Management"					|"Y"				|42101
-- -- "Pain Management"					|"N"				|30386
-- -- "Interventional Pain Management"	|"N"				|23197
-- -- "Interventional Pain Management"	|"Y"				|34042
-- -- "Interventional Pain Management"	|					|57239
-- -- "Pain Management"					|					|72487

-- -- 7. Finally, change your query to use the CUBE function instead of ROLLUP. How does this impact the output?
SELECT 
	specialty_description,
	opioid_drug_flag,
	SUM(total_claim_count) AS total_claims
FROM prescriber
JOIN prescription USING(npi)
JOIN drug ON prescription.drug_name = drug.drug_name
WHERE
	specialty_description ILIKE '%pain%'
GROUP BY CUBE (specialty_description, opioid_drug_flag);
-- -- ANSWER: returns all possible combinations for all three variable combinations (null, specialty_description, opioid_drug_flag)
-- -- "specialty_description"			|"opioid_drug_flag"	|"total_claims"
-- -- 									|					|129726
-- -- "Pain Management"					|"Y"				|42101
-- -- "Pain Management"					|"N"				|30386
-- -- "Interventional Pain Management"	|"N"				|23197
-- -- "Interventional Pain Management"	|"Y"				|34042
-- -- "Interventional Pain Management"	|					|57239
-- -- "Pain Management"					|					|72487
-- -- 									|"Y"				|76143
-- -- 									|"N"				|53583

-- -- 8. In this question, your goal is to create a pivot table showing for each of the 4 largest cities in Tennessee (Nashville, Memphis, Knoxville, and Chattanooga), the total claim count for each of six common types of opioids: Hydrocodone, Oxycodone, Oxymorphone, Morphine, Codeine, and Fentanyl. For the purpose of this question, we will put a drug into one of the six listed categories if it has the category name as part of its generic name. For example, we could count both of "ACETAMINOPHEN WITH CODEINE" and "CODEINE SULFATE" as being "CODEINE" for the purposes of this question.

-- -- The end result of this question should be a table formatted like this:

-- -- |city		  |codeine|fentanyl|hyrdocodone|morphine|oxycodone|oxymorphone|
-- -- |CHATTANOOGA|	1323  |  3689  |	68315  | 12126	| 49519	  | 1317	  |
-- -- |KNOXVILLE  | 2744  |	4811   |	78529  | 20946	| 84730	  | 9186	  |
-- -- |MEMPHIS	  | 4697  |	3666   |	68036  | 4898	| 38295	  | 189		  |
-- -- |NASHVILLE  | 2043  |	6119   |	88669  | 13572	| 62859	  | 1261	  |
-- -- For this question, you should look into use the crosstab function, which is part of the tablefunc extension (https://www.postgresql.org/docs/9.5/tablefunc.html). In order to use this function, you must (one time per database) run the command CREATE EXTENSION tablefunc;

-- -- Hint #1: First write a query which will label each drug in the drug table using the six categories listed above. Hint #2: In order to use the crosstab function, you need to first write a query which will produce a table with one row_name column, one category column, and one value column. So in this case, you need to have a city column, a drug label column, and a total claim count column. Hint #3: The sql statement that goes inside of crosstab must be surrounded by single quotes. If the query that you are using also uses single quotes, you'll need to escape them by turning them into double-single quotes.
-- -- CREATE EXTENSION tablefunc;

-- -- Run this query to get 24 rows to set up CROSSTAB 
SELECT
	nppes_provider_city AS city,
	CASE
		WHEN drug_name ILIKE '%codeine%' THEN 'codeine'
		WHEN drug_name ILIKE '%fentanyl%' THEN 'fentanyl'
		WHEN drug_name ILIKE '%hydrocodone%' THEN 'hydrocodone'
		WHEN drug_name ILIKE '%morphine%' THEN 'morphine'
		WHEN drug_name ILIKE '%oxycodone%' THEN 'oxycodone'
		WHEN drug_name ILIKE '%oxymorphone%' THEN 'oxymorphone'
		ELSE 'other'
	END AS opioid_category,
	SUM(total_claim_count) AS total_claim_count
FROM
	prescription
JOIN prescriber USING(npi)
WHERE
	(drug_name ILIKE '%codeine%'
	OR drug_name ILIKE '%fentanyl%'
	OR drug_name ILIKE '%hydrocodone%'
	OR drug_name ILIKE '%morphine%'
	OR drug_name ILIKE '%oxycodone%'
	OR drug_name ILIKE '%oxymorphone%')
	AND
	(nppes_provider_city = 'CHATTANOOGA'
	OR nppes_provider_city = 'KNOXVILLE'
	OR nppes_provider_city = 'MEMPHIS'
	OR nppes_provider_city = 'NASHVILLE')
GROUP BY
	city,
	opioid_category
ORDER BY city, opioid_category;

-- -- CROSSTAB -- --
SELECT *
FROM CROSSTAB($$
	SELECT
		nppes_provider_city AS city,
		CASE
			WHEN drug_name ILIKE '%codeine%' THEN 'codeine'
			WHEN drug_name ILIKE '%fentanyl%' THEN 'fentanyl'
			WHEN drug_name ILIKE '%hydrocodone%' THEN 'hydrocodone'
			WHEN drug_name ILIKE '%morphine%' THEN 'morphine'
			WHEN drug_name ILIKE '%oxycodone%' THEN 'oxycodone'
			WHEN drug_name ILIKE '%oxymorphone%' THEN 'oxymorphone'
		END AS opioid_category,
		SUM(total_claim_count) AS total_claim_count
	FROM
		prescription
	JOIN prescriber USING(npi)
	WHERE
		(drug_name ILIKE '%codeine%'
		OR drug_name ILIKE '%fentanyl%'
		OR drug_name ILIKE '%hydrocodone%'
		OR drug_name ILIKE '%morphine%'
		OR drug_name ILIKE '%oxycodone%'
		OR drug_name ILIKE '%oxymorphone%')
		AND
		(nppes_provider_city = 'CHATTANOOGA'
		OR nppes_provider_city = 'KNOXVILLE'
		OR nppes_provider_city = 'MEMPHIS'
		OR nppes_provider_city = 'NASHVILLE')
	GROUP BY
		city,
		opioid_category
	ORDER BY city;
$$) AS pivot_table (
	city TEXT,
	codeine NUMERIC,
	fentanyl NUMERIC,
	hydrocodone NUMERIC,
	morphine NUMERIC,
	oxycodone NUMERIC,
	oxymorphone NUMERIC)
ORDER BY city;
-- -- ANSWER: execute query above

-------------------------------------------------------------------------------------------------------------------------
-- -- Barry's script as another example
/*
WITH drugs_and_cities AS
	(SELECT
		nppes_provider_city AS city,  
		CASE 
			WHEN drug_name ILIKE '%codeine%' THEN 'codeine' 
			WHEN drug_name ILIKE '%hydrocodone%' THEN 'hydrocodone'
			WHEN drug_name ILIKE '%oxycodone%' THEN 'oxycodone'
			WHEN drug_name ILIKE '%oxymorphone%' THEN 'oxymorphone'
			WHEN drug_name ILIKE '%morphine%' THEN 'morphine'
			WHEN drug_name ILIKE '%fentanyl%' THEN 'fentanyl'
		END AS drug_name, 
		total_claim_count
	FROM
		prescriber INNER JOIN prescription USING(npi)
	WHERE
		nppes_provider_city IN ('CHATTANOOGA', 'KNOXVILLE', 'MEMPHIS', 'NASHVILLE')
		AND (drug_name ILIKE '%codeine%' OR drug_name ILIKE '%hydrocodone%' OR drug_name ILIKE '%oxycodone%'
		OR drug_name ILIKE '%oxymorphone%' OR drug_name ILIKE '%morphine%' OR drug_name ILIKE '%fentanyl%')
	)

SELECT
	city,
	drug_name,
	SUM(total_claim_count)
FROM
	drugs_and_cities
GROUP BY
	city, drug_name
ORDER BY city;
*/

-------------------------------------------------------------------------------------------------------------------------
-- -- BARRY FIXING ILIKE on '%codeine%' to '%code%'to get 1323 for chattanooga from question example, whereas we got 1310

/*WITH drugs_and_cities AS
	(SELECT
		CASE
			WHEN nppes_provider_city ILIKE 'chat%' THEN 'CHATTANOOGA'
			WHEN nppes_provider_city ILIKE 'nash%' THEN 'NASHVILLE'
			WHEN nppes_provider_city ILIKE 'knox%' THEN 'KNOXVILLE'
			WHEN nppes_provider_city ILIKE 'mem%' THEN 'MEMPHIS'
		END AS city,
		CASE
			WHEN drug_name ILIKE '%code%' THEN 'codeine'
			WHEN drug_name ILIKE '%hydrocodone%' THEN 'hydrocodone'
			WHEN drug_name ILIKE '%oxycodone%' THEN 'oxycodone'
			WHEN drug_name ILIKE '%oxymorphone%' THEN 'oxymorphone'
			WHEN drug_name ILIKE '%morphine%' THEN 'morphine'
			WHEN drug_name ILIKE '%fentanyl%' THEN 'fentanyl'
		END AS drug_name,
		total_claim_count
	FROM
		prescriber INNER JOIN prescription USING(npi)
	WHERE
		LEFT(nppes_provider_city, 4) IN ('CHAT', 'KNOX', 'MEMP', 'NASH')
		AND (drug_name ILIKE '%code%' OR drug_name ILIKE '%hydrocodone%' OR drug_name ILIKE '%oxycodone%'
		OR drug_name ILIKE '%oxymorphone%' OR drug_name ILIKE '%morphine%' OR drug_name ILIKE '%fentanyl%')
	)
SELECT
	city,
	drug_name,
	SUM(total_claim_count)
FROM
	drugs_and_cities
GROUP BY
	city, drug_name;
*/	

-------------------------------------------------------------------------------------------------------------------------
-- BONUS QUESTIONS --
-- 1. How many npi numbers appear in the prescriber table but not in the prescription table?
SELECT
	COUNT(prescriber.npi) AS num_prescribers_with_no_scripts
FROM
	prescriber
LEFT JOIN 
	prescription USING(npi)
	WHERE prescription.npi IS NULL;
-- ANSWER: 4458

-- 2a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.
SELECT
	generic_name,
	SUM(total_claim_count) AS total_claim_count
FROM
	prescription
JOIN drug USING(drug_name)
JOIN prescriber USING(npi)
WHERE
	specialty_description = 'Family Practice'
GROUP BY generic_name
ORDER BY total_claim_count DESC
LIMIT 5;
-- ANSWER: execute query above

-- 2b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.
SELECT
	generic_name,
	SUM(total_claim_count) AS total_claim_count
FROM
	prescription
JOIN drug USING(drug_name)
JOIN prescriber USING(npi)
WHERE
	specialty_description = 'Cardiology'
GROUP BY generic_name
ORDER BY total_claim_count DESC
LIMIT 5;
-- ANSWER: execute query above

-- 2c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.
SELECT
	generic_name,
	SUM(total_claim_count) AS total_claim_count
FROM
	prescription
JOIN drug USING(drug_name)
JOIN prescriber USING(npi)
WHERE
	specialty_description = 'Cardiology'
	OR specialty_description = 'Family Practice'
GROUP BY generic_name
ORDER BY total_claim_count DESC
LIMIT 5;
-- ANSWER: execute query above

-- 3. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
-- 3a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.
SELECT
	npi,
	SUM(total_claim_count) AS total_claim_count,
	nppes_provider_city AS city
FROM prescriber
JOIN prescription USING(npi)
WHERE nppes_provider_city = 'NASHVILLE'
GROUP BY
	npi,
	city
ORDER BY
	total_claim_count DESC
LIMIT 5;
-- ANSWER: execute query above

-- 3b. Now, report the same for Memphis.
SELECT
	npi,
	SUM(total_claim_count) AS total_claim_count,
	nppes_provider_city AS city
FROM prescriber
JOIN prescription USING(npi)
WHERE nppes_provider_city = 'MEMPHIS'
GROUP BY
	npi,
	city
ORDER BY
	total_claim_count DESC
LIMIT 5;
-- ANSWER: execute query above

-- 3c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.
WITH nashville_5 AS
	(SELECT
		npi,
		SUM(total_claim_count) AS total_claim_count,
		nppes_provider_city AS city
	FROM prescriber
	JOIN prescription USING(npi)
	WHERE nppes_provider_city = 'NASHVILLE'
	GROUP BY
		npi,
		city
	ORDER BY
		total_claim_count DESC
	LIMIT 5),
memphis_5 AS
	(SELECT
		npi,
		SUM(total_claim_count) AS total_claim_count,
		nppes_provider_city AS city
	FROM prescriber
	JOIN prescription USING(npi)
	WHERE nppes_provider_city = 'MEMPHIS'
	GROUP BY
		npi,
		city
	ORDER BY
		total_claim_count DESC
	LIMIT 5),
knoxville_5 AS
	(SELECT
		npi,
		SUM(total_claim_count) AS total_claim_count,
		nppes_provider_city AS city
	FROM prescriber
	JOIN prescription USING(npi)
	WHERE nppes_provider_city = 'KNOXVILLE'
	GROUP BY
		npi,
		city
	ORDER BY
		total_claim_count DESC
	LIMIT 5),
chattanooga_5 AS
	(SELECT
		npi,
		SUM(total_claim_count) AS total_claim_count,
		nppes_provider_city AS city
	FROM prescriber
	JOIN prescription USING(npi)
	WHERE nppes_provider_city = 'CHATTANOOGA'
	GROUP BY
		npi,
		city
	ORDER BY
		total_claim_count DESC
	LIMIT 5)
--perform UNIONs
SELECT * FROM nashville_5
UNION
SELECT * FROM memphis_5
UNION
SELECT * FROM knoxville_5
UNION
SELECT * FROM chattanooga_5
ORDER BY city, total_claim_count DESC;
-- ANSWER: execute query above

-- 4. Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.
SELECT
	fips_county.county,
	SUM(overdose_deaths) AS total_overdose_deaths
FROM overdose_deaths
JOIN fips_county ON
	overdose_deaths.fipscounty::text = fips_county.fipscounty
WHERE overdose_deaths > (SELECT AVG(overdose_deaths) FROM overdose_deaths)
GROUP BY county
ORDER BY total_overdose_deaths;
-- ANSWER: execute query above. Average overdose deaths for whole set is 12.6. Set includes 95 counties x 4 years for each county.

-- 5a. Write a query that finds the total population of Tennessee.
SELECT
	SUM(population)
FROM population;
--OR
SELECT
	SUM(population)
FROM population
JOIN fips_county USING(fipscounty)
WHERE state = 'TN';
-- ANSWER: 6,597,381

-- 5b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, and the percentage of the total population of Tennessee that is contained in that county.
SELECT
	county,
	SUM(population) AS county_population,
	ROUND(SUM(population) * 100.0 / SUM(SUM(population)) OVER (), 2) AS percent_of_total
FROM population
JOIN fips_county USING(fipscounty)
WHERE state = 'TN'
GROUP BY county
ORDER BY percent_of_total DESC;
-- ANSWER: execute query above
