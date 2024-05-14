--Vieing data to see if the Import is correct
Select *
From
	PortfolioProject.dbo.CovidDeaths
Where continent is not null

select *
from
	PortfolioProject.dbo.CovidVaccinations
Where continent is not null


-- Select data that we are going to be using

Select 
	location, 
	date, 
	total_cases, 
	new_cases, 
	total_deaths, 
	population
From
	PortfolioProject.dbo.CovidDeaths
Where continent is not null
Order By 1, 2

-- Looking at Total Cases vs Total Deaths
-- Shows likelihod of dying if you contract covid in your country
Select location, date, total_cases, total_deaths, (CAST(total_deaths as float)/total_cases)* 100 as DeathPercentage
From
	PortfolioProject.dbo.CovidDeaths
WHERE 
	total_deaths IS NOT NULL 
	and total_cases IS NOT NULL 
	and location like '%states%'
	and continent is not null

Order By 1, 2

-- Shows likelihod of dying if you contract covid in your country wiyh a Case Statement

SELECT 
    location, 
    date, 
    total_cases, 
    total_deaths, 
    CASE 
        WHEN total_cases = 0 THEN 0  -- Avoid division by zero
        ELSE (CAST(total_deaths AS float) / total_cases)*100  -- Cast to float to preserve decimal precision
    END AS DeathPercentage
FROM 
    PortfolioProject.dbo.CovidDeaths
WHERE 
    total_deaths IS NOT NULL 
    AND total_cases IS NOT NULL
    AND total_cases <> 0  -- Additional condition to avoid division by zero
	and continent is not null
ORDER BY 
    location, 
    date;

-- Looking at Total Cases vs Population
Select 
	location, 
	date, 
	population,
	total_cases, 
	(total_cases/population)* 100 as PercentPoulationInfected
From
	PortfolioProject.dbo.CovidDeaths
WHERE 
	location like '%states%'
	and continent is not null
Order By 1, 2

-- Looking at countries with the Highest Infection Rate compared to Population
Select
	location,
	population,
	max(total_cases) as HighestInfectionCount, 
	(max(total_cases)/population)* 100 as PercentPoulationInfected
From
	PortfolioProject.dbo.CovidDeaths
Where continent is not null
group by location, population
Order By PercentPoulationInfected desc

-- Showing Countries with Highest Death Count per Population
Select
	location,
	max(cast(total_deaths as int)) as TotalDeathCount
From
	PortfolioProject.dbo.CovidDeaths
Where continent is not null
group by location
Order By TotalDeathCount desc 

--  Showing Continents with Highest Death Count per Population

Select
	location,
	max(cast(total_deaths as int)) as TotalDeathCount
From
	PortfolioProject.dbo.CovidDeaths
Where 
	continent is null
	-- and location IN ('Europe', 'North America', 'Asia', 'South America', 'Africa', 'Oceania')
group by location
Order By TotalDeathCount desc 

--  Not entirely correct but we want to use the continent column

Select
	continent,
	max(cast(total_deaths as int)) as TotalDeathCount
From
	PortfolioProject.dbo.CovidDeaths
Where 
	continent is not null
	-- and location IN ('Europe', 'North America', 'Asia', 'South America', 'Africa', 'Oceania')
group by continent
Order By TotalDeathCount desc 

-- Global Numbers

Select
--	date,
	SUM(new_cases) as total_cases,
	SUM(new_deaths) as total_deaths,
	CASE 
        WHEN SUM(new_cases) = 0 THEN 0  -- Avoid division by zero
        ELSE (SUM(new_deaths)/SUM(new_cases))* 100 -- Cast to float to preserve decimal precision
    END AS DeathPercentage
From
	PortfolioProject.dbo.CovidDeaths
Where 
	continent is not null
	--and new_deaths is not null
	--and new_cases is not null
--group by date
Order By 1, 2


--Joining the tables
Select *
From
	PortfolioProject.dbo.CovidDeaths dea
	join PortfolioProject.dbo.CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date

-- Lookin at Total Population vs Vaccinations
Select 
	dea.continent, 
	dea.location, 
	dea.date,
	dea.population,
	vac.new_vaccinations,
	sum(convert(bigint, vac.new_vaccinations)) 
		over (partition by dea.location
			order by dea.location, dea.date
			) as RollingPeopleVaccinated
From
	PortfolioProject.dbo.CovidDeaths dea
	join PortfolioProject.dbo.CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3


-- Percentage of Population Vaccinated Using a CTE

with PopvsVac (continent, 
	location, 
	date,
	population,
	new_vaccinations,
	RollingPeopleVaccinated
	)
as
(
Select 
	dea.continent, 
	dea.location, 
	dea.date,
	dea.population,
	vac.new_vaccinations,
	sum(convert(bigint, vac.new_vaccinations)) 
		over (partition by dea.location
			order by dea.location, dea.date
			) as RollingPeopleVaccinated
From
	PortfolioProject.dbo.CovidDeaths dea
	join PortfolioProject.dbo.CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
select *, (RollingPeopleVaccinated/population) *100 as PopulationVaccinated
from PopvsVac

-- Temp Table: Percentage of Population Vaccinated
Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccination numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select 
	dea.continent, 
	dea.location, 
	dea.date,
	dea.population,
	vac.new_vaccinations,
	sum(convert(bigint, vac.new_vaccinations)) 
		over (partition by dea.location
			order by dea.location, dea.date
			) as RollingPeopleVaccinated
From
	PortfolioProject.dbo.CovidDeaths dea
	join PortfolioProject.dbo.CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

select *, (RollingPeopleVaccinated/population) *100 as PopulationVaccinated
from #PercentPopulationVaccinated

-- Creating View to Store data for later Visualisation
CREATE VIEW PercentagePopulationVaccinated as
Select 
	dea.continent, 
	dea.location, 
	dea.date,
	dea.population,
	vac.new_vaccinations,
	sum(convert(bigint, vac.new_vaccinations)) 
		over (partition by dea.location
			order by dea.location, dea.date
			) as RollingPeopleVaccinated
From
	PortfolioProject.dbo.CovidDeaths dea
	join PortfolioProject.dbo.CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

select *
from PercentagePopulationVaccinated
