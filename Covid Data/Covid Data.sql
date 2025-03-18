-- Select Data that we are going to be using

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows the chance of dying if you contract covid in your country

SELECT Location, date, total_cases, total_deaths, (CONVERT(float, total_deaths) / CONVERT(float, total_cases)) * 100 AS death_percentage
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid

SELECT Location, date, total_cases, population, (CONVERT(float, total_cases) / CONVERT(float, population)) * 100 contracted_percentage
FROM CovidDeaths
ORDER BY 1,2

-- Looking at Countries with Highest Infection Rate comapared to the Population

SELECT Location, population, MAX(CONVERT(int, total_cases)) AS highest_count, MAX(CONVERT(float, total_cases) / CONVERT(float, population)) * 100 contracted_percentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location, population
ORDER BY contracted_percentage DESC

-- Showing Countries with the Highest Death Count per Population

SELECT Location, Population, MAX(CONVERT(int, total_deaths)) AS highest_death_count
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location, Population
ORDER BY highest_death_count DESC

-- Showing Continents and Income Status with the Highest Death Count per Population

SELECT Location, Population, MAX(CONVERT(int, total_deaths)) AS highest_death_count
FROM CovidDeaths
WHERE continent IS NULL
GROUP BY Location, Population
ORDER BY highest_death_count DESC

-- Global Numbers

SELECT SUM(CONVERT(INT, new_cases)) AS total_cases, SUM(CONVERT(INT, new_deaths)) AS total_deaths,
	   SUM(CONVERT(FLOAT, new_deaths))/SUM(CONVERT(FLOAT, new_cases))*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Looking at Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) 
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- Using CTE

WITH PopVsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
	FROM CovidDeaths AS dea
	JOIN CovidVaccinations AS vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL AND dea.location = 'India'
)

SELECT *, (RollingPeopleVaccinated/Population) * 100 AS PeopleVaccinatedPercentage
FROM PopVsVac

-- Using Temp Table

Drop Table IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 

SELECT *, (RollingPeopleVaccinated/Population) * 100 AS PeopleVaccinatedPercentage
FROM #PercentPopulationVaccinated

-- Creating View for Visualization

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 

CREATE VIEW ContinentHighestDeath AS
SELECT Location, Population, MAX(CONVERT(int, total_deaths)) AS highest_death_count
FROM CovidDeaths
WHERE continent IS NULL
GROUP BY Location, Population

CREATE VIEW CountriesHighestDeath AS
SELECT Location, Population, MAX(CONVERT(int, total_deaths)) AS highest_death_count
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location, Population

CREATE VIEW CountriesHighestContracted AS
SELECT Location, population, MAX(CONVERT(int, total_cases)) AS highest_count,
	MAX(CONVERT(float, total_cases) / CONVERT(float, population)) * 100 contracted_percentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location, population

