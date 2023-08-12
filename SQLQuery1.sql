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
