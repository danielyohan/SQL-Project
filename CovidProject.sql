SELECT *
FROM PortfolioProject.dbo.CovidDeaths$
ORDER BY 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths$

--Total deaths vs total cases in Israel
--IFR = Infection Fatality Rate 

SELECT Location, date, total_cases, total_deaths,
(total_deaths/total_cases)*100
AS IFR
FROM PortfolioProject.dbo.CovidDeaths$
WHERE location = 'Israel'

--Total cases vs population in Israel

SELECT location, date, total_cases, population,
(total_cases/population)*100
AS InfectedPercentage
FROM PortfolioProject.dbo.CovidDeaths$
WHERE location = 'Israel'

--Countries with highest total cases vs poulation

SELECT TOP(20) Location, MAX(total_cases) AS TotalCases, Population,
MAX(total_cases/population)*100 AS InfectedPercentage
FROM PortfolioProject.dbo.CovidDeaths$
GROUP BY location, population
ORDER BY 4 DESC

--Countries with highest death count

SELECT TOP(20) Location, MAX(cast(Total_deaths AS INT)) AS TotalDeaths, Population
FROM PortfolioProject.dbo.CovidDeaths$
WHERE Continent IS NOT NULL
GROUP BY continent, Location, Population
ORDER BY 2 DESC

--LOOKING AT CONTINENTS

--Continents with highest death count

SELECT Location, MAX(cast(Total_deaths AS INT)) AS TotalDeaths
FROM PortfolioProject.dbo.CovidDeaths$
WHERE Continent IS NULL 
GROUP BY Location
ORDER BY 2 DESC

--Continents with highest death count vs population

SELECT Location, MAX(cast(Total_deaths AS INT)) AS TotalDeaths,
Population, MAX(cast(Total_deaths AS INT)/Population)*100 AS DeathRate
FROM PortfolioProject.dbo.CovidDeaths$
WHERE Continent IS NULL 
GROUP BY Location, Population
ORDER BY 2 DESC

--LOOKING WORLDWIDE

--Cases per day
--Had to use CASEs in order to avoid division by 0

SELECT Date,
New_cases,
CAST(New_deaths AS INT) AS NewDeaths,
CASE 
	WHEN New_cases = 0 
		THEN 0
	ELSE
		(CAST(New_deaths AS INT)/New_cases)*100
END AS DeathRate
FROM PortfolioProject.dbo.CovidDeaths$
WHERE Location = 'World'
ORDER BY Date

--Total population vs vaccinations

SELECT death.continent, death.location, death.date, death.population
,vacc.new_vaccinations
FROM PortfolioProject.dbo.CovidDeaths$ as death
JOIN PortfolioProject.dbo.CovidVaccinations$ as vacc
ON death.Location = vacc.Location
AND death.date = vacc.date
WHERE death.continent IS NOT NULL
ORDER BY 2, 3 

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

--Total population vs vaccinations using CTE 

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
SELECT *, (RollingVacc/Population)*100 AS RollingVaccRate
FROM CTE_PopVSVacc

--Total population vs vaccinations using Temporary Table

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

SELECT *, (RollingVacc/Population)*100 AS RollingVaccRate
FROM #TEMP_PopVSVacc
ORDER BY 2, 3 
