SELECT *
FROM [Portfolio Project]..CovidDeaths
ORDER BY 3,4

--SELECT *
--FROM [Portfolio Project]..CovidVaccination
--ORDER BY 3,4

--SELECT Data that we are going to use
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM [Portfolio Project]..CovidDeaths
ORDER BY 1,2


-- Now we are going to see the Total Cases vs Total Deaths
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 'death_percentage'
FROM [Portfolio Project]..CovidDeaths
WHERE location LIKE '%Indonesia%'
ORDER BY 1,2
-- Note: The total_cases and total_deaths given are cummulative
-- It shows that the likelihood of dying if we are infected with COVID-19 in Indonesia
-- It says a 3.355% death_percentage


-- Looking at the Total Cases vs Population
SELECT location, date, total_cases, population, (total_cases/population)*100 'Indonesia_total_cases_percentage'
FROM [Portfolio Project]..CovidDeaths
WHERE location LIKE '%Indonesia%'
ORDER BY 1,2
-- Shows what percentage of population got Covid


-- Look at countries with the highest infection rate compared to population
SELECT location, population, MAX(total_cases)'highest_infection_count', MAX((total_cases/population))*100 'population_infected_percentage'
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY population_infected_percentage DESC


-- Showing the countries with the highest death rate
-- I'm using the CAST to change the data type of the total_deaths column (nvarchar to INT)
SELECT location, population, MAX(CAST(total_deaths AS INT))'total_death_count', MAX((total_deaths/population))*100 'population_death_percentage'
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY total_death_count DESC
-- Now we are going to see by continent
SELECT continent, MAX(CAST(total_deaths AS INT))'total_death_count'
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC


-- Global numbers
SELECT date, SUM(new_cases)'total_cases', SUM(CAST(new_deaths AS INT))'total_deaths', SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 'death_percentage'
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2
-- Total ALL
SELECT SUM(new_cases)'total_cases', SUM(CAST(new_deaths AS INT))'total_deaths', SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 'death_percentage'
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2



-- Let's look the covid vaccination table
SELECT *
FROM [Portfolio Project]..CovidVaccination
ORDER BY 3,4


-- Join the two table
SELECT *
FROM [Portfolio Project]..CovidDeaths death
JOIN [Portfolio Project]..CovidVaccination vac
ON death.location = vac.location AND death.date = vac.date

-- Total Population vs Vaccinations
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations
FROM [Portfolio Project]..CovidDeaths death
JOIN [Portfolio Project]..CovidVaccination vac
ON death.location = vac.location AND death.date = vac.date
WHERE death.continent IS NOT NULL
ORDER BY 1,2,3

-- For Indonesia
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations
FROM [Portfolio Project]..CovidDeaths death
JOIN [Portfolio Project]..CovidVaccination vac
ON death.location = vac.location AND death.date = vac.date
WHERE death.continent IS NOT NULL AND death.location = 'Indonesia'
ORDER BY 1,2,3

-- More depth
-- Or we can use CONVERT(INT, vac.new_vaccinations) to replace CAST AS ...
-- IMPORTANT: Use BIGINT if you have many data
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) 'vac_accumulated'
FROM [Portfolio Project]..CovidDeaths death
JOIN [Portfolio Project]..CovidVaccination vac
ON death.location = vac.location AND death.date = vac.date
WHERE death.continent IS NOT NULL
ORDER BY 2,3


-- MORE MORE DEPTH to create a good table
-- Use CTE
WITH PopulationVSVaccinations(continent, location, date, population, new_vaccinations, vac_accumulated)
AS
(
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) 'vac_accumulated'
--, (vac_accumulated/population)*100
FROM [Portfolio Project]..CovidDeaths death
JOIN [Portfolio Project]..CovidVaccination vac
ON death.location = vac.location AND death.date = vac.date
WHERE death.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (vac_accumulated/population)*100 'vaccinated_percentage'
FROM PopulationVSVaccinations



-- Temp Table
DROP TABLE IF EXISTS #PercentPopulationVaccinated --For my convenience :)
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
vac_accumulated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) 'vac_accumulated'
--, (vac_accumulated/population)*100
FROM [Portfolio Project]..CovidDeaths death
JOIN [Portfolio Project]..CovidVaccination vac
ON death.location = vac.location AND death.date = vac.date
WHERE death.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (vac_accumulated/population)*100 'vaccinated_percentage'
FROM #PercentPopulationVaccinated




-- Creating view to store data for visualizations
CREATE VIEW PercentVaccinated AS
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) 'vac_accumulated'
--, (vac_accumulated/population)*100
FROM [Portfolio Project]..CovidDeaths death
JOIN [Portfolio Project]..CovidVaccination vac
ON death.location = vac.location AND death.date = vac.date
WHERE death.continent IS NOT NULL