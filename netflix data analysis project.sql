-- NETFLIX PROJECT

create database netflix_db;
use netflix_db;

create table netflix (
show_id varchar(6),
type varchar(10),
title varchar(150),	
director varchar(250),
cast varchar(1000),
country varchar(150),
date_added varchar(50),
release_year int,
rating varchar(10),
duration varchar(15),
listed_in varchar(100),
description varchar(250)
);
select*from netflix;



LOAD DATA LOCAL INFILE 'C:/Users/harsh/Downloads/archive/netflix_titles.csv'
INTO TABLE netflix
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 rows;

SHOW VARIABLES LIKE 'local_infile';

SET GLOBAL local_infile = 1;


select
count(*) as total_content
from netflix;

select 
distinct type 
from netflix;

-- 15 BUSINESS PROBLEMS 

-- 1. COUNT THE NUMBER OF MOVIES VS TV SHOWS

select
type, count(*) as total_content
from netflix
group by type;

-- 2. FIND THE MOST COMMON RATING FOR MOVIES AND TV SHOWS

select 
type, rating
from (
select type, 
rating,
count(*),
rank() over (partition by type order by count(*) desc) as ranking
from netflix
group by 1, 2) as t1
where ranking = 1;

-- 3. LIST ALL THE MOVIES RELEASED IN THE SPECIFIC YEAR (Eg. 2020)

select type, title, release_year from netflix
where type = "Movie" and release_year = 2020;

-- 4. FIND THE TOP 5 COUNTRIES WITH THE MOST CONTENT ON NETFLIX


with recursive split_country as (
select
show_id,
trim(substring_index(country, ',', 1)) as country,
trim(substring(country, length(substring_index(country, ',', 1)) + 2)) as rest
from netflix

union all

select
show_id,
trim(substring_index(rest, ',', 1)),
trim(substring(rest, length(substring_index(rest, ',', 1)) +2))
from split_country
where rest <> ''
)

select
country, count(*) as total_titles
from split_country
where country is not null and country <> ''
group by country
order by 2 desc
limit 5;
 
 
-- 5. IDENTIFY THE LONGEST MOVIE


select title, type, duration,
cast(substring_index(duration, ' ', 1) as unsigned) as duration_in_minutes
from netflix
where type = "Movie"
and
duration like "%min"
order by duration_in_minutes desc;


-- 6. FIND CONTENT ADDED IN THE LAST 5 YEARS

select * from netflix
where                                                                            -- str_to_date() - convert date_added(string) to real date(sql format -> YYYY-MM-DD)  [%M (FULL MONTH NAME) %d (DAY OF THE MONTH) , %Y (4 DIGIT YEAR)]
str_to_date(date_added, '%M %d, %Y') >= current_date() - interval 5 year ;       -- e.g - January 15, 2023 -> 2023-01-15


-- 7. FIND ALL THE MOVIES / TV SHOWS BY DIRECTOR 'Rajiv Chilaka'

select title, type, director
from netflix
where lower(director) like "%Rajiv Chilaka%";            -- lower() -> if in lowercase exists(rajiv chilaka)

-- 8. LIST ALL TV SHOWS WITH MORE THAN 5 SEASONS

select title, type , duration
from netflix
where type = 'TV Show'
and 
duration > '5 Seasons';


-- 9. COUNT THE NUMBER OF CONTENT ITEMS IN EACH GENRE

with recursive genre_split as (
select
show_id,
(substring_index(listed_in, ',', 1)) as genre,                                    -- substring_index -> seperates the string by ',' nd returns the positon in the basis of delimeter
(substring(listed_in, length(substring_index(listed_in, ',', 1)) + 2)) as rest             -- substring(str,pos,len) -> return string with specific length
from netflix 

union all

select
show_id,
substring_index(rest, ',', 1),
substring(rest, length(substring_index(rest, ',', 1)) + 2)
from genre_split
where rest <> ''
)

select genre, count(show_id) as total_content
from genre_split
where genre is not null 
group by genre
order by total_content desc;


-- 10. FIND EACH YEAR AND THE AVERAGE NUMBERS OF CONTENT RELEASE IN INDIA ON NETFLIX. RETURN TOP 5 YEAR WITH HIGHEST AVG CONTENT RELEASE.

select
year (str_to_date(date_added, "%M %d, %Y")) as year,                -- year() -> to get the year only
count(*) as total_content,
round(count(*)/12,2) as avg_per_month                               -- round() -> round of to 2(as given) decimal places
from netflix
where country = "India"
group by year
order by total_content desc
limit 5;


-- 11. LIST ALL THE MOVIES THAT ARE DOCUMENTARIES

select title, type, listed_in 
from netflix
where type = "Movie"
and
listed_in like "%Documentaries%";


-- 12. FIND ALL THE CONTENT WITHOUT A DIRECTOR

select * from netflix
where director = "";
 
 
 -- 13. FIND IN HOW MANY MOVIES ACTOR 'SALMAN KHAN' APPEARED IN LAST 10 YEARS
 
 select * 
 from netflix
 where cast like "%Salman Khan%"
 and 
 release_year > extract(year from current_date) - 10;
 
 
 -- 14. FIND THE TOP 10 ACTORS WHO HAVE APPEARED IN THE HIGHEST NUMBER OF MOVIES PRODUCED IN INDIA
 

with recursive cast_split as (
select
show_id,
(substring_index(cast, ',', 1)) as actors,                                    -- substring_index -> seperates the string by ',' nd returns the positon in the basis of delimeter
(substring(cast, length(substring_index(cast, ',', 1)) + 2)) as rest             -- substring(str,pos,len) -> return string with specific length
from netflix 
where type = "Movie"
and country like "%India%"

union all

select
show_id,
substring_index(rest, ',', 1),
substring(rest, length(substring_index(rest, ',', 1)) + 2)
from cast_split
where rest <> ''
)
select actors,
count(show_id) as total_movies
from cast_split
where actors <> ""
group by actors
order by total_movies desc
limit 10;


-- 15. CATEGORIZE THE CONTENT BASED ON THE PRESENCE OF THE KEYWORDS 'KILL' AND 'VIOLENCE' IN THE DESCRIPTION FIELD. 
   --  LABEL CONTENT CONTAINING THESE KEYWORDS AS 'BAD' AND ALL OTHER CONTENT AS 'GOOD'. COUNT HOW MANY ITEMS FALL INTO EACH CATEGORY.
   
with category_cte as (
select *,
       case
       when 
          lower(description) like "%Kill%"
          or lower(description) like "%Violence%"
          then "Bad_Content"
		  else "Good_Content"
		end as category
from netflix
)
select category,
count(show_id) as total_content
from category_cte
group by category
order by total_content desc;

   