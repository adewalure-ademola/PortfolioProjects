-- Exploratory Data Analysis

select *
from layoffs_staging2;

-- The highest number of people laid off by a company in a day
select max(total_laid_off)
from layoffs_staging2;

-- Highest number of layoffs whereby the company laid off all of it's workers
select *
from layoffs_staging2
where percentage_laid_off = 1
order by total_laid_off desc;

-- Total number of people laid off by company
select company, sum(total_laid_off)
from layoffs_staging2
group by company
order by 2 desc;

-- Total number of people laid off by industry
select industry, sum(total_laid_off)
from layoffs_staging2
group by industry
order by 2 desc;

-- Total number of people laid off by year
select year(`date`), sum(total_laid_off)
from layoffs_staging2
group by year(`date`)
order by 2 desc;

-- Timeframe from first recored layoffs to the last layoff in this document
select min(`date`), max(`date`)
from layoffs_staging2;

-- Rolling total of layoffs

with rolling_total as
(
select substring(`date`, 1, 7) as `year_month`, sum(total_laid_off) as total_off
from layoffs_staging2
where substring(`date`, 1, 7) is not null
group by `year_month`
order by 1
)
select `year_month`, total_off, sum(total_off) over(order by `year_month`) as total_rolling_count
from rolling_total;

-- Ranking companies with the most layoffs per year
with company_year (company, years, total_laid_off) as
(
select company, year(`date`), sum(total_laid_off)
from layoffs_staging2
group by company, year(`date`)
), company_year_rank as
(
select
	*,
    dense_rank() over(partition by years order by total_laid_off desc) as ranking
from company_year
where years is not null
)
select *
from company_year_rank
where ranking <= 5
;

-- Creating a view

CREATE VIEW layoffs_ranking AS
with company_year (company, years, total_laid_off) as
(
select company, year(`date`), sum(total_laid_off)
from layoffs_staging2
group by company, year(`date`)
), company_year_rank as
(
select
	*,
    dense_rank() over(partition by years order by total_laid_off desc) as ranking
from company_year
where years is not null
)
select *
from company_year_rank
where ranking <= 5
;






