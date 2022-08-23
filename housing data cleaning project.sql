-- useing mysql
-- create table in advance since mysql needs it to be done at the first place to import a large amount of data. Table Data Import Wizard function only works for a small set of data.

use portfolioproject
create table datacleaningproject(
UniqueID INT,	
ParcelID VARCHAR(100),
LandUse	VARCHAR(100),
PropertyAddress	VARCHAR(100), 
SaleDate VARCHAR(100),   #pre-modify the format of saledate in excel
SalePrice int,
LegalReference VARCHAR(100),
SoldAsVacant VARCHAR(100),
OwnerName VARCHAR(100),
OwnerAddress VARCHAR(100)	,
Acreage float,
TaxDistrict	VARCHAR(100),
LandValue int,
BuildingValue	int,
TotalValue	int,
YearBuilt	int,
Bedrooms	int,
FullBath	int,
HalfBath int)

drop table if exists datacleaningproject  

-- using load data to import a large amount of data, originated from csv file with a header
-- since csv file has value in blank, and it will keep 0 unless stated it. Therefore using NULLIF function during LOAD DATA

LOAD DATA LOCAL INFILE 'C:/Users/bobie/Desktop/SQL/sql youtube project practice/Nashville Housing Data for Data Cleaning.csv' 
INTO TABLE datacleaningproject 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(UniqueID,ParcelID,LandUse,@PropertyAddress,SaleDate,SalePrice,LegalReference,SoldAsVacant,@OwnerName,@OwnerAddress,@Acreage,@TaxDistrict,@LandValue,@BuildingValue,@TotalValue,@YearBuilt,@Bedrooms,@FullBath,@HalfBath)
set 
PropertyAddress=NULLIF(@PropertyAddress,''),    
OwnerName=NULLIF(@OwnerName,''),
OwnerAddress=NULLIF(@OwnerAddress,''),
Acreage=NULLIF(@Acreage,''),
TaxDistrict=NULLIF(@TaxDistrict,''),
LandValue=NULLIF(@LandValue,''),
BuildingValue=NULLIF(@BuildingValue,''),
TotalValue=NULLIF(@TotalValue,''),
YearBuilt=NULLIF(@YearBuilt,''),
Bedrooms=NULLIF(@Bedrooms,''),
FullBath=NULLIF(@FullBath,''),
HalfBath=NULLIF(@HalfBath,'');

-- setting local_infile=1 to make LOAD DATA happen

set GLObal local_infile =1;
select * from datacleaningproject

--------------------------------------------------------------------------------------------------------------------------
-- Standardize Date Format


Update datacleaningproject
SET SaleDate = CONVERT(Date,SaleDate)

-- when it doesn't update properly then using:

ALTER TABLE datacleaningproject
Add SaleDateConverted Date;

Update datacleaningproject
SET SaleDateConverted = CONVERT(Date,SaleDate)

--------------------------------------------------------------------------------------------------------------------------
-- Populate Property Address data
-- finding that there are null values (29 rows) in propertyaddress which should not happen
Select *
From datacleaningproject
Where PropertyAddress is null
order by ParcelID

-- guessing that it might be caused by having the same parcelID, but not stating the propertyaddress; Therefore using self-join
Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, IFNULL(a.PropertyAddress,b.PropertyAddress)
From datacleaningproject a
JOIN datacleaningproject b
	on a.ParcelID = b.ParcelID
	AND a.UniqueID<> b.UniqueID 
Where a.PropertyAddress is null


update datacleaningproject a, datacleaningproject b
set b.propertyaddress=a.propertyaddress
where b.propertyaddress is NULL and b.parcelID=a.parcelID and a.propertyaddress is not null

--------------------------------------------------------------------------------------------------------------------------
-- Breaking out Address into Individual Columns (Address, City, State)
Select PropertyAddress
From datacleaningproject

SELECT
SUBSTRING(PropertyAddress, 1, locate(',', PropertyAddress) -1 ) as Address
, SUBSTRING(PropertyAddress, locate(',', PropertyAddress) + 1 , LENGTH(PropertyAddress)) as Address
From datacleaningproject

ALTER TABLE datacleaningproject
Add PropertySplitAddress varchar(100);
Update datacleaningproject
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, locate(',', PropertyAddress) -1 )


ALTER TABLE datacleaningproject
Add PropertySplitCity varchar(100);
Update datacleaningproject
SET PropertySplitCity = SUBSTRING(PropertyAddress, locate(',', PropertyAddress) + 1 , LENGTH(PropertyAddress))

--------------------------------------------------------------------------------------------------------------------------
select distinct(soldasvacant) from datacleaningproject

-- there are 4 outputs in soldasvacant
-- Change Y and N to Yes and No in "Sold as Vacant" field

Update datacleaningproject
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END

-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remove Duplicates 
-- using cte to do a quick check on how many duplicates are out there

WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
From datacleaningproject)
Select *
From RowNumCTE
Where row_num > 1
Order by PropertyAddress

delete a from datacleaningproject a, datacleaningproject b
where a.parcelID=b.parcelID and a.propertyaddress=b.propertyaddress and a.saleprice=b.saleprice and a.saledate=b.saledate and a.legalreference=b.legalreference and a.uniqueid>b.uniqueid

---------------------------------------------------------------------------------------------------------
-- Delete Unused Columns
-- for example the propertyaddress, since we have divided it into 2 seperate columns

Select *
From datacleaningproject


ALTER TABLE datacleaningproject
DROP COLUMN PropertyAddress
