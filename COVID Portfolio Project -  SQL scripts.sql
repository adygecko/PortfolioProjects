select * from SQLPortofolioProject..CovidDeaths
where continent IS NOT NULL
order by 3,4

select * from SQLPortofolioProject..CovidVaccinations

--Total cases vs total deaths
-- Shows the likelyhood of dying if you contracted COVID in your country
SELECT Location, date, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100,2) AS DeathPercentage
FROM SQLPortofolioProject..CovidDeaths
WHERE Location LIKE 'Romania%'
ORDER BY 1,2 -- order by the first 2 columns

-- Looking at Total cases vs Population
-- shows what percentage of population got COVID in each country
SELECT Location, date,Population,total_cases, ROUND((total_cases/Population)*100,2) AS CasesPercentage
FROM SQLPortofolioProject..CovidDeaths
WHERE Location LIKE 'Romania%'
ORDER BY 1,2 -- order by the first 2 columns

--Show what countries have the highest infection rates compared to population
SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount, ROUND((MAX(total_cases/Population))*100,2) AS PopulationInfectedPercent
FROM SQLPortofolioProject..CovidDeaths
GROUP BY Location, Population
ORDER BY PopulationInfectedPercent DESC

--Show the countries with the highest death count per population
SELECT Location, MAX(CAST(total_deaths as INT)) AS TotalDeathCount --since total_deaths was saved as VARCHAR we need to cast it as an INT
FROM SQLPortofolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC

----------BREAK DOWN BY CONTINENT -------
--Show the continent with the highest death rate
SELECT continent, MAX(CAST(total_deaths as INT)) AS TotalDeathCount 
FROM SQLPortofolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

--SELECT location, MAX(CAST(total_deaths as INT)) AS TotalDeathCount 
--FROM SQLPortofolioProject..CovidDeaths
--WHERE continent IS NULL
--GROUP BY location
--ORDER BY TotalDeathCount DESC

--GLOBAL NUMBERS
--global numbers per day
SELECT date, SUM(new_cases) AS TotalCases, SUM(cast(new_deaths as INT)) AS TotalDeaths, SUM(cast(new_deaths as INT))/SUM(new_cases) AS DeathPercentage
FROM SQLPortofolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2 

-- global numbers since it started
SELECT SUM(new_cases) AS TotalCases, SUM(cast(new_deaths as INT)) AS TotalDeaths, ROUND(SUM(cast(new_deaths as INT))/SUM(new_cases),2) AS DeathPercentage
FROM SQLPortofolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2 

--look at total population vs vaccinations
SELECT dea.continent
	, dea.location
	, dea.date
	, dea.population
	, vac.new_vaccinations
	, SUM(CONVERT(INT, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated --break by location 
FROM SQLPortofolioProject..CovidDeaths dea 
JOIN SQLPortofolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3


--USE A CTE

WITH PopvsVac (Continent, Location, Date, Population,New_Vaccinations, RollingPeopleVaccinated)
AS
(SELECT dea.continent
	, dea.location
	, dea.date
	, dea.population
	, vac.new_vaccinations
	, SUM(CONVERT(INT, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated --break by location 
FROM SQLPortofolioProject..CovidDeaths dea 
JOIN SQLPortofolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac

----TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255), 
Location nvarchar(255), 
Date datetime, 
Population numeric,
New_Vaccinations numeric, 
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent
	, dea.location
	, dea.date
	, dea.population
	, vac.new_vaccinations
	, SUM(CONVERT(INT, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated --break by location 
FROM SQLPortofolioProject..CovidDeaths dea 
JOIN SQLPortofolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated

-- Creating View to store data for later visualisation
CREATE VIEW PercentVaccinatedPopulation AS 
SELECT dea.continent
	, dea.location
	, dea.date
	, dea.population
	, vac.new_vaccinations
	, SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated --break by location 
FROM SQLPortofolioProject..CovidDeaths dea 
JOIN SQLPortofolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL


