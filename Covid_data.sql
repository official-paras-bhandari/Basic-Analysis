--SELECT * FROM Portfolio_Project..CovidDeaths$
-- c
--ORDER BY 3,4

--SELECT Location, date, new_cases, total_cases, total_deaths, population FROM
--Portfolio_Project..CovidDeaths$

-- Looking at Total_case VS Total_deaths

SELECT Location, date,  total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage FROM
Portfolio_Project..CovidDeaths$
Where location LIKE '%state%' and  continent is not null
ORDER BY 1,2


-- Looking at Total Case vs population
-- Shows what percentage  of population got covid or what percentage 
SELECT Location, date,  total_cases, (total_cases/population)*100 as population_percentage
FROM
Portfolio_Project..CovidDeaths$
Where location LIKE '%state%' and  continent is not null
ORDER BY 1,2

-- What country is the higest infection rate

SELECT Location, population,  MAX(total_cases) as HigestInfection, MAX((total_cases/population))*100 as
PercentagePeopleInfected
FROM
Portfolio_Project..CovidDeaths$
WHERE continent is not null
Group By location, population
ORDER BY PercentagePeopleInfected DESC


-- Showing Countries with Hightest Death count per population

SELECT Location, population,  MAX(cast(total_deaths as INT)) death_per_population
FROM
Portfolio_Project..CovidDeaths$
Where continent is not null
Group By location, population
ORDER BY death_per_population DESC



-- Showing by Continent

Select continent, MAX(cast(total_deaths as int)) FROM Portfolio_Project..CovidDeaths$
Where continent is not null
Group BY continent
Order BY 2

-- Global Numbers

SELECT SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths  ,
SUM(cast(new_deaths as int))/SUM(new_cases)*100 as death_percentage
FROM Portfolio_Project..CovidDeaths$
WHERE continent is not null
-- GROUP BY date
Order by 1,2


-- Looking at total population vs total vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPepoleVaccinated
FROM Portfolio_Project..CovidDeaths$ dea
JOIN Portfolio_Project..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
Order BY 1,2


-- USE CTE

with PopVsVac ( Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccination) as
( 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPepoleVaccinated
FROM Portfolio_Project..CovidDeaths$ dea
JOIN Portfolio_Project..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--Order BY 2,3
) 
Select *,(RollingPeopleVaccination/Population)*100 From PopVsVac


-- Temp Table
Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccination numeric
)

Insert into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPepoleVaccinated
FROM Portfolio_Project..CovidDeaths$ dea
JOIN Portfolio_Project..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date

Select *,(RollingPeopleVaccination/Population)*100 From #PercentPopulationVaccinated

-- Create View to store data for later visualizations
DROP VIEW IF EXISTS PercentPopulationVaccinated;

Create View  PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPepoleVaccinated
FROM Portfolio_Project..CovidDeaths$ dea
JOIN Portfolio_Project..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
	Where dea.continent is not null
	--Order By 2,3

Select * From PercentPopulationVaccinated



-------------------------------------------------------------------------------------------------------
/*
Cleaning Data in SQL Queries
*/
--------------------------------------------------------------------------------------------------------

Select * From Portfolio_Project..Sheet1$

----------------------------

-- Standardize Date Format
-- Adding New Column

Alter Table Portfolio_Project..sheet1$
ADD SaleDateConverted Date

UPDATE Portfolio_Project..Sheet1$
SET SaleDateConverted = CONVERT(DATE, saledate)

Select SaleDateConverted From Portfolio_Project..Sheet1$

-- Populate Property Address data
-- Selecting Unique value
-- if is it null than just repalce value from b.ProperyAddress to a.PropertyAddress

Select *  
From Portfolio_Project..Sheet1$
Where PropertyAddress is null
order by ParcelID

Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
From Portfolio_Project..Sheet1$ a
Join Portfolio_Project..Sheet1$ b
	On a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]

Where a.PropertyAddress is null

Update a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
From Portfolio_Project..Sheet1$ a
Join Portfolio_Project..Sheet1$ b
	On a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null


---------------------------------------------------------------------------------------------------
-- Breaking out Address into Columns (Address, City, States)
/*
This part of the query is using the SUBSTRING function to extract a portion of the PropertyAddress column. 
It starts from the beginning of the PropertyAddress and goes up to the character just before the first comma (,).
The result of this substring extraction is given the alias Address.
Select PropertyAddress From Portfolio_Project..Sheet1$
*/
Select 
-- Extract all data from first Index (1) untill ',' Encounter 
SUBSTRING(PropertyAddress,1,Charindex(',',PropertyAddress)-1) as Address,

--Extract the characters right after the first comma in the PropertyAddress and extend the extraction to the end of the address.
SUBSTRING(PropertyAddress,Charindex(',',PropertyAddress)+1, LEN(PropertyAddress)) as Address
From Portfolio_Project..Sheet1$

Alter Table Portfolio_Project..sheet1$
ADD PropertySplitAddress NVarchar(255)

UPDATE Portfolio_Project..Sheet1$
SET PropertySplitAddress = SUBSTRING(PropertyAddress,1,Charindex(',',PropertyAddress)-1)

Alter Table Portfolio_Project..sheet1$
ADD PropertySplitCity  NVarchar(255)

UPDATE Portfolio_Project..Sheet1$
SET PropertySplitCity = SUBSTRING(PropertyAddress,Charindex(',',PropertyAddress)+1, LEN(PropertyAddress))



-- We use the REPLACE function to replace commas with periods in the OwnerAddress column. 
--The result of this operation for the example row would be '123 Main St. City. Country'.

-- We then use the PARSENAME function to parse the modified address string.
-- In this context, PARSENAME treats the periods as delimiters and extracts parts of the string.
-- The second argument (1) indicates that we want to extract the first part of the parsed string, which corresponds to '123 Main St'.


Select
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
From  Portfolio_Project..Sheet1$


ALTER TABLE  Portfolio_Project..Sheet1$
Add OwnerSplitAddress Nvarchar(255);

Update  Portfolio_Project..Sheet1$
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)


ALTER TABLE  Portfolio_Project..Sheet1$
Add OwnerSplitCity Nvarchar(255);

Update  Portfolio_Project..Sheet1$
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)



ALTER TABLE  Portfolio_Project..Sheet1$
Add OwnerSplitState Nvarchar(255);

Update  Portfolio_Project..Sheet1$
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)

Select *
From  Portfolio_Project..Sheet1$



-- Change Y and N to Yes and No in "solid as Vacant" field

Select Distinct(SoldAsVacant), count(SoldAsVacant) from 
Portfolio_Project..Sheet1$
Group BY SoldAsVacant
Order By 2

Select SoldAsVacant,
Case When SoldAsVacant = 'Y' Then 'YES'
	When SoldAsVacant = 'N' Then 'No'
	Else SoldAsVacant
	END
From Portfolio_Project..Sheet1$

Update Portfolio_Project..Sheet1$
Set SoldAsVacant = Case When SoldAsVacant = 'Y' Then 'YES'
	When SoldAsVacant = 'N' Then 'No'
	Else SoldAsVacant
	END
From Portfolio_Project..Sheet1$




----------------------------------------------------------------------------------------------------------------------------------

-- Delete Unused Columns

Select * 
From Portfolio_Project..Sheet1$

Alter Table Portfolio_Project..Sheet1$
Drop Column OwnerAddress, TaxDistrict, PropertyAddress
