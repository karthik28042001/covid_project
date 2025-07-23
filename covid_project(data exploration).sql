-- use sql_project;

SELECT * 
from sql_project.`coviddeaths latest`
Where continent is not null 
 order by 3,4;


/*SELECT *
 FROM sql_project.covidvaccinations
 order by 3,4;*/
 
 
 -- selecting the data that we are going to be using
 select location, date,total_cases,new_cases,total_deaths,population
 from sql_project.`coviddeaths latest`
 Where continent is not null 
 order by 1,2;
 
 
 -- looking at total cases vs total deaths
 -- here we calculate the deathpercentage by using total_deaths,total_cases , i mainly focused on the usa, we can change order by or where condition , by our preference.
 select location, date,total_cases,total_deaths,(total_deaths/total_cases)*100 as deathpercentage
 from sql_project.`coviddeaths latest`
 where location like '%states%' and  continent is not null 
 order by 1,2;
 
 -- looking at total cases  vs poupulation
 -- shows what percentage of population got covid
 select location, date,population,total_cases,(total_cases/population)*100 as percentpopulationinfected
 from sql_project.`coviddeaths latest`
 -- where location like '%states%'
 order by 1,2;
 
 
 -- looking at countires  with highest infection rate compared to poupulation
 select location,population,max(total_cases) as highestinfectioncount,max((total_cases/population))*100 as percentpopulationinfected
 from sql_project.`coviddeaths latest`
 -- where location like '%states%'
 group by location,population
 order by percentpopulationinfected desc;
 
 
 -- showing countries with highest death count per population
select location,max(cast(total_deaths as signed)) as totaldeathcount
 from sql_project.`coviddeaths latest`
 -- where location like '%states%'
 Where continent is not null 
 group by location
 order by totaldeathcount desc;
 
 
 
 -- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population
select continent,max(cast(total_deaths as signed)) as totaldeathcount
 from sql_project.`coviddeaths latest`
 -- where location like '%states%'
 Where continent is not null 
 group by continent
 order by totaldeathcount desc;
 
 
 
 -- global numbers
 Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as signed)) as total_deaths, SUM(cast(new_deaths as signed))/SUM(New_Cases)*100 as DeathPercentage
From sql_project.`coviddeaths latest`
-- Where location like '%states%'
where continent is not null 
-- Group By date
order by 1,2;


SELECT *
 FROM sql_project.covidvaccinations;
 


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
 
 Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(Cast(vac.new_vaccinations as signed)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
-- (RollingPeopleVaccinated/population)*100
From sql_project.`coviddeaths latest` dea
Join sql_project.covidvaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3;



-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(Cast(vac.new_vaccinations as signed)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
-- (RollingPeopleVaccinated/population)*100
From sql_project.`CovidDeaths latest` dea
Join sql_project.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
-- order by 2,3.   we can't use order by in cte otherwise we can use it in the main query.
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac;



-- Using Temp Table to perform Calculation on Partition By in previous query

-- 1. First clean your data (run this once)
UPDATE sql_project.CovidVaccinations 
SET new_vaccinations = 0 
WHERE new_vaccinations = '' OR new_vaccinations IS NULL;

-- 2. Then run your main query
DROP TEMPORARY TABLE IF EXISTS PercentPopulationVaccinated;

CREATE TEMPORARY TABLE PercentPopulationVaccinated (
    Continent varchar(255),
    Location varchar(255),
    Date date,
    Population int,
    New_vaccinations int,
    RollingPeopleVaccinated int
);

INSERT INTO PercentPopulationVaccinated
SELECT 
    dea.continent,
    dea.location,
    STR_TO_DATE(dea.date, '%m/%d/%y') AS date,
    dea.population,
    CAST(vac.new_vaccinations AS SIGNED) AS new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (
        PARTITION BY dea.Location 
        ORDER BY STR_TO_DATE(dea.date, '%m/%d/%y')
    ) AS RollingPeopleVaccinated
FROM 
    sql_project.`CovidDeaths latest` dea
JOIN 
    sql_project.CovidVaccinations vac
    ON dea.location = vac.location
    AND STR_TO_DATE(dea.date, '%m/%d/%y') = STR_TO_DATE(vac.date, '%m/%d/%y');

-- Get results
SELECT 
    *,
    (RollingPeopleVaccinated/Population)*100 AS VaccinationPercentage
FROM 
    PercentPopulationVaccinated
ORDER BY 
    Location, 
    Date;
    
    
-- Creating View to store data for later visualizations

-- If you can't drop the existing object, use a different name
CREATE OR REPLACE VIEW PercentPopulationVaccinated_v2 AS
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations, 
    SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (
        PARTITION BY dea.location 
        ORDER BY dea.date
    ) AS RollingPeopleVaccinated
FROM 
    sql_project.`CovidDeaths latest` dea 
JOIN 
    sql_project.CovidVaccinations vac 
    ON dea.location = vac.location 
    AND dea.date = vac.date 
WHERE 
    dea.continent IS NOT NULL;
    
select * from PercentPopulationVaccinated_v2;