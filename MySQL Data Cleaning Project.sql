-- Data Cleaning

Select *
From
	layoffs;
/*   
1. Remove Duplicates
2. Standardize the Data
3. Null Values or Blank Values
4. Remove Any Columns
*/
-- Duplicating the layoffs table to avoid altering the raw data
Create Table layoffs_staging
Like layoffs;

Insert layoffs_staging
Select *
From layoffs;

-----------------------------------------------------------------------------------------------
-- Removing Duplicates

-- Creating a CTE with a Row_Number() windows function to identify duplicates

With duplicate_cte As
(
Select
	*,
    Row_Number() Over(
		Partition by company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised
    ) As row_num
From
	layoffs_staging
)
Select *
From duplicate_cte
Where
	row_num > 1; 

-- Creating a new table to delete duplicates
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` text,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised` double DEFAULT NULL,
  `row_num` Int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

Insert Into layoffs_staging2
Select
	*,
    Row_Number() Over(
		Partition by company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised
    ) As row_num
From
	layoffs_staging;
-- Deleting the duplicates
Delete
From layoffs_staging2
Where row_num > 1;

-------------------------------------------------------------------------------------------------------
-- Standardizing Data to Find Issues and Fixing It
select *
from layoffs_staging2;
-- Triming company column and updating it
select company, trim(company)
from layoffs_staging2;

update layoffs_staging2
set company = trim(company);

-- Updating the industry column where it's wrongly spelt
select distinct industry
from layoffs_staging2
order by 1;

select *
from layoffs_staging2
where industry like 'Crypto%';

update layoffs_staging2
set industry = 'Crypto'
where industry like 'Crypto%';
-- Removing trailing '.' from United States
select distinct country
from layoffs_staging2
order by 1;

select *
from layoffs_staging2
where country like 'United States%'
order by 1;

select distinct country, trim(trailing '.' from country)
from layoffs_staging2
order by 1;

update layoffs_staging2
set country = trim(trailing '.' from country)
where industry like 'United States%';

-- Changing the date format/datatype

select `date`,
str_to_date(`date`, '%m/%d/%Y')
from layoffs_staging2;

update layoffs_staging2
set `date` = str_to_date(`date`, '%m/%d/%Y');

alter table layoffs_staging2
modify column `date` date;

----------------------------------------------------------------------
-- Null Values or Blank Values
select *
from layoffs_staging2
where industry is null or industry = '';

select *
from layoffs_staging2
where company = 'Airbnb';

-- Changing blanks to nulls
update layoffs_staging2
set industry = null
where industry = '';

select *
From
	layoffs_staging2 t1
    join layoffs_staging2 t2
    on t1.company = t2.company
where
	(t1.industry is null or t1.industry = '')
    and t2.industry is not null;
    
update layoffs_staging2 t1
    join layoffs_staging2 t2
    on t1.company = t2.company
set t1.industry = t2.industry
where
	t1.industry is null
    and t2.industry is not null;

------------------------------------------------------------------
-- Removing columns and null rows
select *
from layoffs_staging2
where
	percentage_laid_off is null
    and total_laid_off is null;
-- deleting rows where percent laid off and total laid off is null
delete
from layoffs_staging2
where
	percentage_laid_off is null
    and total_laid_off is null;

-- deleting the row_num column
alter table layoffs_staging2
drop column row_num;