SELECT * FROM coviddeaths
order by 3,4; -- We order by specific columns location and date

-- Select Data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM coviddeaths
order by 1,2; -- We select a specific columns and order by location and date

-- Compare Total Cases vs. Total Deaths

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 as CasesVsDeathsPercentage
FROM coviddeaths
where location like '%spain%'
order by 1,2; -- We select a specific columns, make a percentatge of deaths in total cases and order by location and date

-- Looking at Total Cases vs. Population

SELECT location, date, total_cases, population, (total_cases/population) *100 as  CasesVsPopulationPercentage
FROM coviddeaths
-- where location like '%spain%'
order by 1,2;

-- Looking at Total Deaths vs. Population

SELECT location, date, total_cases, total_deaths, population, (total_deaths/population) *100 as  DeathsVsPopulationPercentage
FROM coviddeaths
-- where location like '%spain%'
order by 1,2;

-- Looking at Countris with Higest Infection Rate compared to Population

SELECT location, population,SUM(new_cases) as TotalInfectionCount, MAX((total_cases/population)*100) as PercentPopulationInfected
FROM coviddeaths
-- where location like '%andorra%'
group by location, population
order by PercentPopulationInfected desc;


-- Looking at Countris with Higest Deaths Rate compared to Population

SELECT location,population, SUM(new_deaths) as TotalDeathsCount, MAX((total_deaths/population)*100) as PercentPopulationDeath
FROM coviddeaths
-- where location like '%spain%'
group by location, population
order by PercentPopulationDeath desc;

-- LET'S BREAK DOWN BY CONTINENT

-- Looking at Continents with Higest Infection Rate compared to Population

SELECT continent, SUM(new_cases) as TotalInfectionCount, MAX((total_cases/population)*100) as PercentPopulationInfected
FROM coviddeaths
-- where continent like '%europe%'
where continent is not null
group by continent
order by PercentPopulationInfected desc;

-- Looking at Continents with Higest Deaths Rate compared to Population

SELECT continent, SUM(new_deaths) as TotalDeathsCount, MAX((total_deaths/population)*100) as PercentPopulationDeath
FROM coviddeaths
-- where continent like '%europe%'
where continent is not null
group by continent
order by PercentPopulationDeath desc;

-- GLOBAL NUMBERS

-- Total New Cases, New Deads and Deaths Percentage group by Date

SELECT date, SUM(new_cases) as NewCases, SUM(new_deaths) as NewDeaths, (SUM(new_deaths)/SUM(new_cases))*100 as DeathsPercentage
FROM coviddeaths
group by date;

-- Total New Cases, New Deads and Deaths Percentage in global

SELECT SUM(new_cases) as NewCases, SUM(new_deaths) as NewDeaths, (SUM(new_deaths)/SUM(new_cases))*100 as DeathsPercentage
FROM coviddeaths;

-- JOIN TABLES coviddeaths AND covidvaccinations

-- Inspect covidvaccinations

SELECT *
FROM covidvaccinations;

-- Join

SELECT *
FROM coviddeaths dea
JOIN covidvaccinations vac
	on dea.location = vac.location
    and dea.date = vac.date;
    
-- Looking at Total Population Vs. Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (partition by dea.location order by dea.location, dea.date) as total_vaccinations
FROM coviddeaths dea
JOIN covidvaccinations vac
	on dea.location = vac.location
    and dea.date = vac.date
where dea.continent is not null
order by 2,3;

-- USE CTE

WITH PopVsVac (continent, location, date, population, new_vaccinations, total_vaccinations)
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (partition by dea.location order by dea.location, dea.date) as total_vaccinations
FROM coviddeaths dea
JOIN covidvaccinations vac
	on dea.location = vac.location
    and dea.date = vac.date
where dea.continent is not null
-- order by 2,3;
)

-- Looking Total Vaccination rolling Vs. Population

SELECT *, (total_vaccinations/population)*100 as VaccinationsPercentage
FROM PopVsVac;

-- TEMP TABLE

DROP Table if exists PercentPopulationVaccinated;

Create Table PercentPopulationVaccinated
(
  Continent CHAR(255) CHARACTER SET UTF8MB4,
  Location CHAR(255) CHARACTER SET UTF8MB4,
  Date datetime,
  Population numeric,
  new_vaccinations numeric,
  total_vaccinations numeric
);

INSERT INTO PercentPopulationVaccinated (Continent, Location, Date, Population, new_vaccinations, total_vaccinations)
SELECT dea.continent, dea.location, dea.date, dea.population, COALESCE(vac.new_vaccinations, 0),
       SUM(COALESCE(vac.new_vaccinations, 0)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as total_vaccinations
FROM coviddeaths dea
JOIN covidvaccinations vac
  ON dea.location = vac.location
  AND dea.date = vac.date;
-- where dea.continent is not null
-- order by 2,3;

SELECT *
FROM vaccinationspercentage;

-- CREATING VIEW TO STORE DATA FOR LATER VISUALIZATIONS

DROP VIEW if exists PopulationVaccinated;

CREATE VIEW PopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (partition by dea.location order by dea.location, dea.date) as total_vaccinations
FROM coviddeaths dea
JOIN covidvaccinations vac
	on dea.location = vac.location
    and dea.date = vac.date
where dea.continent is not null;

DROP VIEW if exists PercentPopulationVaccinated;

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, COALESCE(vac.new_vaccinations, 0),
       SUM(COALESCE(vac.new_vaccinations, 0)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as total_vaccinations
FROM coviddeaths dea
JOIN covidvaccinations vac
  ON dea.location = vac.location
  AND dea.date = vac.date
  where dea.continent is not null;