/*

Queries used for Tableau Project

*/



-- 1. Global Covid Fatality Rate

SELECT SUM(new_cases) AS total_cases, 
	SUM(CAST(new_deaths AS INT)) AS total_deaths, 
	SUM(CAST(new_deaths AS INT))/SUM(New_Cases)*100 AS FatalityRate
From PortfolioProject.dbo.CovidDeaths$
where continent is not null 
order by 1,2


-- 2. Total death count by continent

SELECT Location, SUM(CAST(new_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths$
WHERE continent IS NULL
AND Location NOT IN ('World', 'European Union', 'International')
GROUP BY Location
ORDER BY TotalDeathCount DESC


-- 3. Infection rate by country

SELECT 
    Location, 
    ISNULL(Population,0) AS Population,
    ISNULL(MAX(total_cases), 0) AS HighestInfectionCount,
    ISNULL(MAX((total_cases/population))*100, 0) AS PercentPopulationInfected
FROM PortfolioProject.dbo.CovidDeaths$
WHERE Location NOT LIKE '%International%'
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC;



-- 4. Vacc rate by country, day by day

SELECT Location, Population,date,
	ISNULL(MAX(total_cases), 0) AS HighestInfectionCount,
	ISNULL(MAX((total_cases/population))*100, 0) AS PercentPopulationInfected
FROM PortfolioProject.dbo.CovidDeaths$
WHERE Location NOT LIKE '%International%'
GROUP BY Location, Population, date
ORDER BY PercentPopulationInfected DESC



-- Queries I originally had, but excluded some because it created too long of video
-- Here only in case you want to check them out


-- 1.

Select dea.continent, dea.location, dea.date, dea.population
, MAX(vac.total_vaccinations) as RollingPeopleVaccinated
From PortfolioProject.dbo.CovidDeaths$ dea
Join PortfolioProject.dbo.CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
group by dea.continent, dea.location, dea.date, dea.population
order by 1,2,3




-- 2.
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject.dbo.CovidDeaths$
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2

-- 3.


Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
From PortfolioProject.dbo.CovidDeaths$
--Where location like '%states%'
Where continent is null 
and location not in ('World', 'European Union', 'International')
Group by location
order by TotalDeathCount desc



-- 4.

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject.dbo.CovidDeaths$
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc



-- 5.

--Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
--From PortfolioProject..CovidDeaths
----Where location like '%states%'
--where continent is not null 
--order by 1,2

-- took the above query and added population
Select Location, date, population, total_cases, total_deaths
From PortfolioProject.dbo.CovidDeaths$
--Where location like '%states%'
where continent is not null 
order by 1,2


-- 6. 


With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject.dbo.CovidDeaths$ dea
Join PortfolioProject.dbo.CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100 as PercentPeopleVaccinated
From PopvsVac


-- 7. 

Select Location, Population,date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject.dbo.CovidDeaths$
--Where location like '%states%'
Group by Location, Population, date
order by PercentPopulationInfected desc
