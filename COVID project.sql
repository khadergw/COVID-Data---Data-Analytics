SELECT *
FROM CovidDeaths
WHERE continent is not null
--------------------------------------------
--Changing data type from bigint to decimal

Alter Table CovidDeaths
Alter Column total_deaths decimal(38, 0)

Alter Table CovidDeaths
Alter Column total_cases decimal(38, 0)

Alter Table CovidDeaths
Alter Column new_deaths decimal(18, 3)

Alter Table CovidDeaths
Alter Column new_cases decimal(18, 3)

Alter Table CovidDeaths
Alter Column population decimal(38, 0)

Alter Table CovidVaccinations
Alter Column new_vaccinations decimal(38, 0)
------------------------------------------------
-- Death cases vs. total cases

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM CovidDeaths
WHERE total_cases>0 AND continent is not null
ORDER BY 1,2

------------------------------------------------
-- Total cases vs. population

SELECT Location, date, population, total_cases, (total_cases/population)*100 as CasesPercentage
FROM CovidDeaths
WHERE continent is not null
ORDER BY 1,2

------------------------------------------------
-- Countries with highest infection rate compared to their population

SELECT Location, population, MAX(total_cases) as HighestCasesNumber, MAX((total_cases/population))*100 as CasesPercentage
FROM CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY CasesPercentage DESC

------------------------------------------------
-- Countries with highest death rate compared to their population

SELECT Location, population, MAX(total_deaths) as HighestDeathsNumber, MAX((total_deaths/population))*100 as DeathsPercentage
FROM CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY DeathsPercentage DESC

------------------------------------------------
-- Countries with the highest death cases 

SELECT Location, MAX(total_deaths) as HighestDeathsNumber
FROM CovidDeaths
WHERE continent is not null 
GROUP BY location
ORDER BY HighestDeathsNumber DESC

------------------------------------------------
-- Continents with the highest death cases 

SELECT Location, MAX(total_deaths) as HighestDeathsNumber
FROM CovidDeaths
WHERE continent is null 
GROUP BY location
ORDER BY HighestDeathsNumber DESC

--SELECT continent, MAX(total_deaths) as HighestDeathsNumber
--FROM CovidDeaths
--WHERE continent is not null 
--GROUP BY continent
--ORDER BY HighestDeathsNumber DESC

------------------------------------------------
-- Number of cases and deaths each day around the world

SELECT date, SUM(CAST(new_cases as decimal(32,0))) as TotalCases, SUM(new_deaths) as TotalDeaths, SUM(new_deaths)/SUM(new_cases)*100 as DeathsPercentage
FROM CovidDeaths
WHERE continent is not null AND new_cases>0
GROUP BY date
ORDER BY date

------------------------------------------------
-- Total number of cases and deaths around the world

SELECT SUM(new_cases) as TotalCases, SUM(new_deaths) as TotalDeaths, SUM(new_deaths)/SUM(new_cases)*100 as DeathsPercentage
FROM CovidDeaths
WHERE continent is not null 

------------------------------------------------
-- Joining deaths and vaccinations tables

SELECT * from CovidDeaths 
join CovidVaccinations 
on CovidDeaths. location = CovidVaccinations. location
and CovidDeaths. date = CovidVaccinations. date

------------------------------------------------
-- Population vs vaccinations number

SELECT D.location, D.date, D.population, V.new_vaccinations from CovidDeaths D
join CovidVaccinations V
on D. location = V. location
and D. date = V. date
WHERE D.continent is not null
ORDER BY 1,2

------------------------------------------------
-- Population vs total vaccinations for each location

-- Create temp table 

DROP TABLE if exists #PercentagePopulationVaccinated

CREATE TABLE #PercentagePopulationVaccinated
(
location nvarchar(50),
date datetime,
population numeric,
new_vaccinations numeric,
TotalPeopleVaccinated numeric
)

INSERT INTO #PercentagePopulationVaccinated

SELECT D.location, D.date, D.population, V.new_vaccinations, SUM(V.new_vaccinations) OVER (partition by D.location ORDER BY D.date) as TotalPeopleVaccinated 
from CovidDeaths D
join CovidVaccinations V
on D. location = V. location
and D. date = V. date
WHERE D.continent is not null
ORDER BY 1,2

SELECT *, (TotalPeopleVaccinated/Population)*100 as PercentagePeopleVaccinated
FROM #PercentagePopulationVaccinated
ORDER BY 1,2

-------------------------------------------------

--Create views for data visualization:

--View1:Death total cases and percentage around the world

--CREATE VIEW DeathPercentage as 
SELECT SUM(new_cases) as TotalCases, SUM(new_deaths) as TotalDeaths, SUM(new_deaths)/SUM(new_cases)*100 as DeathsPercentage
FROM CovidDeaths
WHERE continent is not null
ORDER BY 1,2
 
--View2:Death total cases and in the continents

--CREATE VIEW TotalDeaths as 
SELECT location, SUM(new_deaths) as TotalDeaths
FROM CovidDeaths
WHERE continent is null
AND location not in ('World', 'High income', 'Upper middle income', 'Lower middle income', 'Low income', 'European Union')
GROUP BY location
ORDER BY 2 DESC

--View3:Countries with highest infection rate compared to their population

--CREATE VIEW InfectionPercentage as 
SELECT Location, population, MAX(total_cases) as HighestCasesNumber, MAX((total_cases/population))*100 as CasesPercentage
FROM CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY CasesPercentage DESC

--View4:Daily infection percentage per location  

--CREATE VIEW DailyInfectionPercentage as 
SELECT Location, population, date, MAX(total_cases) as HighestCasesNumber, MAX((total_cases/population))*100 as CasesPercentage
FROM CovidDeaths
WHERE continent is not null
GROUP BY location, population, date
ORDER BY CasesPercentage DESC

--View5:Total cases vs. total deaths

--CREATE VIEW TotalCasesVsDeaths as 
SELECT Location, date, population, total_cases, total_deaths
FROM CovidDeaths
WHERE continent is not null
ORDER BY 1,2

--View6:Total people vaccinated compared to population for each location

--CREATE VIEW TotalPeopleVaccinated as 
SELECT D.continent, D.location, D.date, D.population, MAX(V.new_vaccinations)as TotalPeopleVaccinated 
from CovidDeaths D
join CovidVaccinations V
on D. location = V. location
and D. date = V. date
WHERE D.continent is not null
GROUP BY D.continent, D.location, D.date, D.population
ORDER BY 1,2,3

--View7:Percentage of people vaccinated for each location

With PopulationVsVaccination (continent, Location, Date, Population, New_Vaccinations, TotalPeopleVaccinated
)
as
(
Select D.continent, D.location, D.date, D.population, V.new_vaccinations
, SUM(V.new_vaccinations) OVER (Partition by D.Location Order by D.location, D.Date) as TotalPeopleVaccinated
From CovidDeaths D
Join CovidVaccinations V
	On D.location = V.location
	and D.date = V.date
where D.continent is not null 
)
Select *, (TotalPeopleVaccinated/Population)*100 as PercentPeopleVaccinated
From PopulationVsVaccination


