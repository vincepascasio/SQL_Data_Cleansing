/*
The purpose of this project is to clean the data we have imported to make it more usable for dashboards and KPIs that we may create from this data.
*/

SELECT *
FROM [Portfolio_Project].[dbo].[Nashville_Housing_Data_Data_Cleaning]


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Here we are populating the property address data
SELECT *
FROM [Portfolio_Project].[dbo].[Nashville_Housing_Data_Data_Cleaning]
ORDER BY ParcelID



/*If ParcelID is the same but PropertyAddress is missing, 
This query populates that same ParcelID with the same PropertyAddress.
At the same time, we want to make sure the UniqueID is different if the ParcelID and PropertyAddress are the same.
To do this, we need a self join.
*/
SELECT t1.ParcelID, 
	   t1.PropertyAddress,
	   t2.ParcelID,
	   t2.PropertyAddress,
	   ISNULL(t1.PropertyAddress, t2.PropertyAddress) AS NewPropertyAddress -- If t1 PropertAddress NULL, fill with t2 PropertyAddress
FROM [Portfolio_Project].[dbo].[Nashville_Housing_Data_Data_Cleaning] AS t1
INNER JOIN [Portfolio_Project].[dbo].[Nashville_Housing_Data_Data_Cleaning] AS t2
	ON t1.ParcelID = t2.ParcelID 
	AND t1.UniqueID <> t2.UniqueID
WHERE t1.PropertyAddress IS NULL



-- Updating the first table where the PropertyAddress was NULL when the ParcelID was the same
UPDATE t1
SET PropertyAddress = ISNULL(t1.PropertyAddress, t2.PropertyAddress) 
FROM [Portfolio_Project].[dbo].[Nashville_Housing_Data_Data_Cleaning] AS t1
INNER JOIN [Portfolio_Project].[dbo].[Nashville_Housing_Data_Data_Cleaning] AS t2
	ON t1.ParcelID = t2.ParcelID 
	AND t1.UniqueID <> t2.UniqueID
WHERE t1.PropertyAddress IS NULL


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Here we are breaking the PropertyAddress column into 3 unique columns: Address, City, and State.
-- To do this, we will be making use of the SUBSTRING, CHARINDEX, and LEN functions.
SELECT PropertyAddress
FROM [Portfolio_Project].[dbo].[Nashville_Housing_Data_Data_Cleaning]


SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address, -- Extracting address from beginning of PropertyAddress up to the delimiter (a.k.a, the comma). The (-1) is to not include the comma.
	   SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS City -- Extracting address from comma to end of address. The (+1) gets rid of the comma.
FROM [Portfolio_Project].[dbo].[Nashville_Housing_Data_Data_Cleaning]


ALTER TABLE [Portfolio_Project].[dbo].[Nashville_Housing_Data_Data_Cleaning] -- Adding new address column from above into the table
ADD PropertySplitAddress VARCHAR(255)

UPDATE [Portfolio_Project].[dbo].[Nashville_Housing_Data_Data_Cleaning]
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) 

ALTER TABLE [Portfolio_Project].[dbo].[Nashville_Housing_Data_Data_Cleaning] -- Adding new city column from above into the table
ADD PropertySplitCity VARCHAR(255)

UPDATE [Portfolio_Project].[dbo].[Nashville_Housing_Data_Data_Cleaning]
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))



-- We will be doing a similar thing to the OwnerAddress column now
-- This time, we will be using PARSENAME and REPLACE.
SELECT OwnerAddress
FROM [Portfolio_Project].[dbo].[Nashville_Housing_Data_Data_Cleaning]

SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS Address, -- PARSENAME only replaces periods, not commas; so, we have to change commas in OwnerAddress as periods to proceed.
	   PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS City,
	   PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS State
FROM [Portfolio_Project].[dbo].[Nashville_Housing_Data_Data_Cleaning]


ALTER TABLE [Portfolio_Project].[dbo].[Nashville_Housing_Data_Data_Cleaning] -- Adding new address column from above into the table
ADD OwnerSplitAddress VARCHAR(255)

UPDATE [Portfolio_Project].[dbo].[Nashville_Housing_Data_Data_Cleaning]
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) 

ALTER TABLE [Portfolio_Project].[dbo].[Nashville_Housing_Data_Data_Cleaning] -- Adding new city column from above into the table
ADD OwnerSplitCity VARCHAR(255)

UPDATE [Portfolio_Project].[dbo].[Nashville_Housing_Data_Data_Cleaning]
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE [Portfolio_Project].[dbo].[Nashville_Housing_Data_Data_Cleaning] -- Adding new city column from above into the table
ADD OwnerSplitState VARCHAR(255)

UPDATE [Portfolio_Project].[dbo].[Nashville_Housing_Data_Data_Cleaning]
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)



-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Change SoldAsVacant column to display "No" instead of 0 and "Yes" instead of 1 using CASE WHEN 

SELECT DISTINCT(SoldAsVacant),
	   COUNT(SoldAsVacant) AS NumVacantSymbol
FROM [Portfolio_Project].[dbo].[Nashville_Housing_Data_Data_Cleaning]
GROUP BY SoldAsVacant
ORDER BY 2


SELECT SoldAsVacant,
       CASE 
           WHEN SoldAsVacant = 'N' THEN 'No' 
		   WHEN SoldAsVacant = 'Y' THEN 'Yes'
           ELSE SoldAsVacant
       END
FROM [Portfolio_Project].[dbo].[Nashville_Housing_Data_Data_Cleaning]

UPDATE [Portfolio_Project].[dbo].[Nashville_Housing_Data_Data_Cleaning]
SET SoldAsVacant = (CASE 
                     WHEN SoldAsVacant = 'N' THEN 'No' 
					 WHEN SoldAsVacant = 'Y' THEN 'Yes'
                     ELSE SoldAsVacant
                     END);



-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Now we will be removing duplicates within the data by making use of a CTE and window functions
-- Partition by things unique to each row

WITH duplicate_cte AS(
SELECT *,
	   ROW_NUMBER() OVER(
	   PARTITION BY ParcelID,
					PropertyAddress,
					SalePrice,
					SaleDate,
					LegalReference
	   ORDER BY UniqueID
	   ) AS duplicate
FROM [Portfolio_Project].[dbo].[Nashville_Housing_Data_Data_Cleaning]
)
SELECT *
FROM duplicate_cte
WHERE duplicate > 1



-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*
Here we are deleting unused columns. This should mostly happen when views are created and a column is not needed.
Best practice is to not do it to raw data that is imported. This example is an exception.
*/

SELECT *
FROM [Portfolio_Project].[dbo].[Nashville_Housing_Data_Data_Cleaning]


ALTER TABLE [Portfolio_Project].[dbo].[Nashville_Housing_Data_Data_Cleaning]
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress