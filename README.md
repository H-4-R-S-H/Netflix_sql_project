# Netflix Movies and TV Shows Data Analysis using SQL

![](https://github.com/najirh/netflix_sql_project/blob/main/logo.png)

## Overview
This project involves a comprehensive analysis of Netflix's movies and TV shows data using SQL. The goal is to extract valuable insights and answer various business questions based on the dataset. The following README provides a detailed account of the project's objectives, business problems, solutions, findings, and conclusions.

## Objectives

- Analyze the distribution of content types (movies vs TV shows).
- Identify the most common ratings for movies and TV shows.
- List and analyze content based on release years, countries, and durations.
- Explore and categorize content based on specific criteria and keywords.

## Dataset

The data for this project is sourced from the Kaggle dataset:

- **Dataset Link:** [Movies Dataset](https://www.kaggle.com/datasets/anandshaw2001/netflix-movies-and-tv-shows?resource=download)

## Schema

```sql
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
```

## Business Problems and Solutions

### 1. Count the Number of Movies vs TV Shows

```sql
select
type, count(*) as total_content
from netflix
group by type;
```

**Objective:** Determine the distribution of content types on Netflix.

### 2. Find the Most Common Rating for Movies and TV Shows

```sql
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
```

**Objective:** Identify the most frequently occurring rating for each type of content.

### 3. List All Movies Released in a Specific Year (e.g., 2020)

```sql
select type, title, release_year from netflix
where type = "Movie" and release_year = 2020;
```

**Objective:** Retrieve all movies released in a specific year.

### 4. Find the Top 5 Countries with the Most Content on Netflix

```sql
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
```

**Objective:** Identify the top 5 countries with the highest number of content items.

### 5. Identify the Longest Movie

```sql
select title, type, duration,
cast(substring_index(duration, ' ', 1) as unsigned) as duration_in_minutes
from netflix
where type = "Movie"
and
duration like "%min"
order by duration_in_minutes desc;
```

**Objective:** Find the movie with the longest duration.

### 6. Find Content Added in the Last 5 Years

```sql
select * from netflix
where                                                                             
str_to_date(date_added, '%M %d, %Y') >= current_date() - interval 5 year ;       
```

**Objective:** Retrieve content added to Netflix in the last 5 years.

### 7. Find All Movies/TV Shows by Director 'Rajiv Chilaka'

```sql
select title, type, director
from netflix
where lower(director) like "%Rajiv Chilaka%";
```

**Objective:** List all content directed by 'Rajiv Chilaka'.

### 8. List All TV Shows with More Than 5 Seasons

```sql
select title, type , duration
from netflix
where type = 'TV Show'
and 
duration > '5 Seasons';
```

**Objective:** Identify TV shows with more than 5 seasons.

### 9. Count the Number of Content Items in Each Genre

```sql
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
```

**Objective:** Count the number of content items in each genre.

### 10.Find each year and the average numbers of content release in India on netflix. 
return top 5 year with highest avg content release!

```sql
select
year (str_to_date(date_added, "%M %d, %Y")) as year,                -- year() -> to get the year only
count(*) as total_content,
round(count(*)/12,2) as avg_per_month                               -- round() -> round of to 2(as given) decimal places
from netflix
where country = "India"
group by year
order by total_content desc
limit 5;
```

**Objective:** Calculate and rank years by the average number of content releases by India.

### 11. List All Movies that are Documentaries

```sql
select title, type, listed_in 
from netflix
where type = "Movie"
and
listed_in like "%Documentaries%";
```

**Objective:** Retrieve all movies classified as documentaries.

### 12. Find All Content Without a Director

```sql
select * from netflix
where director = "";
```

**Objective:** List content that does not have a director.

### 13. Find How Many Movies Actor 'Salman Khan' Appeared in the Last 10 Years

```sql
select * 
from netflix
where cast like "%Salman Khan%"
and 
release_year > extract(year from current_date) - 10;
```

**Objective:** Count the number of movies featuring 'Salman Khan' in the last 10 years.

### 14. Find the Top 10 Actors Who Have Appeared in the Highest Number of Movies Produced in India

```sql
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
```

**Objective:** Identify the top 10 actors with the most appearances in Indian-produced movies.

### 15. Categorize Content Based on the Presence of 'Kill' and 'Violence' Keywords

```sql
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
```

**Objective:** Categorize content as 'Bad' if it contains 'kill' or 'violence' and 'Good' otherwise. Count the number of items in each category.

## Findings and Conclusion

- **Content Distribution:** The dataset contains a diverse range of movies and TV shows with varying ratings and genres.
- **Common Ratings:** Insights into the most common ratings provide an understanding of the content's target audience.
- **Geographical Insights:** The top countries and the average content releases by India highlight regional content distribution.
- **Content Categorization:** Categorizing content based on specific keywords helps in understanding the nature of content available on Netflix.

This analysis provides a comprehensive view of Netflix's content and can help inform content strategy and decision-making.


---


This project is part of my portfolio, showcasing the SQL skills essential for data analyst roles. If you have any questions, feedback, or would like to collaborate, feel free to get in touch!


