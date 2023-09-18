SELECT *
FROM PortfolioProject.dbo.CovidDeaths$
ORDER BY 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths$

--Covid fatality and Infection rate, day by day in Israel

SELECT date, total_cases, total_deaths,
(total_deaths/total_cases)*100 AS FatalityRate,
(total_cases/population)*100 AS InfectionRate
FROM PortfolioProject.dbo.CovidDeaths$
WHERE location = 'Israel'

--Countries with highest infection rate

SELECT TOP(20) Location,
	MAX(total_cases) AS TotalCases, Population,
	(MAX(total_cases)/population)*100 AS InfectionRate
FROM PortfolioProject.dbo.CovidDeaths$
GROUP BY location, population
ORDER BY InfectionRate DESC

--Countries with highest Covid fatality rate

SELECT TOP(20) Location,
	MAX(cast(total_deaths AS INT)) AS TotalDeaths, 
	MAX(total_cases) AS TotalCases,
   (MAX(cast(total_deaths AS INT))/MAX(total_cases))*100 AS FatalityRate
FROM PortfolioProject.dbo.CovidDeaths$
GROUP BY location
ORDER BY FatalityRate DESC

--LOOKING AT CONTINENTS

--Total deaths and Infections

SELECT Location,
	MAX(cast(total_deaths AS INT)) AS TotalDeaths, 
	MAX(total_cases) AS TotalCases
FROM PortfolioProject.dbo.CovidDeaths$
WHERE continent is null
GROUP BY location
ORDER BY TotalDeaths DESC

/* Ignore 'International' location since its numbers are negligible
'European Union' numbers are included in Europe */

--GLOBAL NUMBERS

--Fatality rate, day by day

SELECT Date, 
	SUM(cast(new_deaths AS INT)) AS NewDeaths, 
	SUM(new_cases) AS NewCases,
    (SUM(cast(new_deaths AS INT))/SUM(new_cases))*100 AS FatalityRate
FROM PortfolioProject.dbo.CovidDeaths$
WHERE continent is not null
GROUP BY Date
ORDER BY Date 

/* Vaccination rate (assume each person gets maximum 1 vaccine)
Using CTE */

--WITH CTE_join AS
--(SELECT DEATH.Continent, DEATH.Location, DEATH.Date,
--	DEATH.Population, VACC.Total_vaccinations
--FROM PortfolioProject.dbo.CovidDeaths$ DEATH
--JOIN PortfolioProject.dbo.CovidVaccinations$ VACC
--	ON DEATH.Date = VACC.Date
--	AND DEATH.Location = VACC.Location
--WHERE DEATH.Continent IS NOT NULL
--)
--SELECT *, (CAST(total_vaccinations AS INT)/population)*100 AS VaccRate
--FROM CTE_join
--ORDER BY Continent, Location, Date


--Total vaccinations per country by accumulating new vaccinations

SELECT death.continent, death.location, death.date, death.population
	,CAST(vacc.new_vaccinations AS INT) AS NewVacc
	,SUM(CAST(vacc.new_vaccinations AS INT)) OVER 
		(PARTITION BY vacc.Location ORDER BY vacc.Date) AS RollingVacc
FROM PortfolioProject.dbo.CovidDeaths$ as death
	JOIN PortfolioProject.dbo.CovidVaccinations$ as vacc
	ON death.Location = vacc.Location
	AND death.date = vacc.date
WHERE death.continent IS NOT NULL
ORDER BY 2, 3 

--Vaccination rate using using CTE 

WITH CTE_PopVSVacc AS (
SELECT death.continent, death.location, death.date, death.population
	,CAST(vacc.new_vaccinations AS INT) AS NewVacc
	,SUM(CAST(vacc.new_vaccinations AS INT)) OVER 
		(PARTITION BY vacc.Location ORDER BY vacc.Date) AS RollingVacc
FROM PortfolioProject.dbo.CovidDeaths$ as death
	JOIN PortfolioProject.dbo.CovidVaccinations$ as vacc
	ON death.Location = vacc.Location
	AND death.date = vacc.date
WHERE death.continent IS NOT NULL
)
SELECT *, (RollingVacc/Population)*100 AS VaccRate
FROM CTE_PopVSVacc

--Vaccination rate using Temporary Table

DROP TABLE IF EXISTS #TEMP_PopVSVacc
CREATE TABLE #TEMP_PopVSVacc (
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
NewVacc numeric,
RollingVacc numeric
)

INSERT INTO #TEMP_PopVSVacc 
SELECT death.continent, death.location, death.date, death.population
	,CAST(vacc.new_vaccinations AS INT) AS NewVacc
	,SUM(CAST(vacc.new_vaccinations AS INT)) OVER 
	(PARTITION BY vacc.Location ORDER BY vacc.Date) AS RollingVacc
FROM PortfolioProject.dbo.CovidDeaths$ as death
	JOIN PortfolioProject.dbo.CovidVaccinations$ as vacc
	ON death.Location = vacc.Location
	AND death.date = vacc.date
WHERE death.continent IS NOT NULL

SELECT *, (RollingVacc/Population)*100 AS VaccRate
FROM #TEMP_PopVSVacc
ORDER BY 2,3 

--Create View for visualization later..

Create View VaccinationRateView AS
SELECT DEATH.continent, DEATH.location, DEATH.date, DEATH.population
	,CAST(VACC.new_vaccinations AS INT) AS NewVacc
	,SUM(CAST(VACC.new_vaccinations AS INT)) OVER 
	(PARTITION BY VACC.Location ORDER BY VACC.Date) AS RollingVacc
FROM PortfolioProject.dbo.CovidDeaths$ as DEATH
	JOIN PortfolioProject.dbo.CovidVaccinations$ as VACC
	ON DEATH.Location = VACC.Location
	AND DEATH.date = VACC.date
WHERE DEATH.continent IS NOT NULL 

DROP VIEW [VaccinationRate];

