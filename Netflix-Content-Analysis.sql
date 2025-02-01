-- query for creating table in the database;
CREATE TABLE netflix_data
(
    show_id      VARCHAR(5),
    type         VARCHAR(10),
    title        VARCHAR(500),
    director     VARCHAR(600),
    casts        VARCHAR(1500),
    country      VARCHAR(600),
    date_added   VARCHAR(100),
    release_year INT,
    rating       VARCHAR(25),
    duration     VARCHAR(25),
    listed_in    VARCHAR(500),
    description  VARCHAR(1000)
);

-- query for seeing the entire table;
select * from netflix_data;

-- making show_id as primary key for the main table
ALTER TABLE netflix_data
ADD CONSTRAINT pk_show_id PRIMARY KEY (show_id);

-- Data Cleaning from the main table
-- splitting the columns to new tables and removing them from main table
--for efficient data retrieval

-- splitting director column into a new table
create table directors
(
       show_id varchar(5) not null,
	   director varchar(100) not null
);

-- inserting data to new table
INSERT INTO directors (show_id, director)
SELECT
    show_id,
    INITCAP(TRIM(unnest(string_to_array(COALESCE(director, 'Unknown'), ',')))) AS director
FROM netflix_data;

-- splitting casts column into a new table
create table casts_name
(
       show_id varchar(5) not null,
	   casts_name varchar(100) not null
);

-- inserting data to new table
INSERT INTO casts_name (show_id, casts_name)
SELECT
    show_id,
    INITCAP(TRIM(unnest(string_to_array(COALESCE(casts, 'Unknown'), ',')))) AS casts_name
FROM netflix_data;

-- splitting country column into a new table
create table country_name
(
       show_id varchar(5) not null,
	   country_name varchar(100) not null
);

-- inserting data to new table
INSERT INTO country_name (show_id, country_name)
SELECT
    show_id,
    INITCAP(TRIM(unnest(string_to_array(COALESCE(country, 'Unknown'), ',')))) AS country_name
FROM netflix_data;

-- splitting listed_in(genre column) into a new table
create table genre
(
       show_id varchar(5) not null,
	   genre varchar(100) not null
);

-- inserting data to new table
INSERT INTO genre (show_id, genre)
SELECT
    show_id,
    INITCAP(TRIM(unnest(string_to_array(COALESCE(listed_in, 'Unknown'), ',')))) AS genre
FROM netflix_data;

-- assigning foreign key show_id of directors table with the primary key show_id of main table
ALTER TABLE directors
ADD CONSTRAINT fk_genre_show_id
FOREIGN KEY (show_id) REFERENCES netflix_data(show_id) ON DELETE CASCADE;

-- assigning foreign key show_id of casts table with the primary key show_id of main table
ALTER TABLE casts_name
ADD CONSTRAINT fk_cast_show_id
FOREIGN KEY (show_id) REFERENCES netflix_data(show_id) ON DELETE CASCADE;

-- assigning foreign key show_id of country table with the primary key show_id of main table
ALTER TABLE country_name
ADD CONSTRAINT fk_country_show_id
FOREIGN KEY (show_id) REFERENCES netflix_data(show_id) ON DELETE CASCADE;

-- assigning foreign key show_id of genre table with the primary key show_id of main table
ALTER TABLE genre
ADD CONSTRAINT fk_country_show_id
FOREIGN KEY (show_id) REFERENCES netflix_data(show_id) ON DELETE CASCADE;

-- droping columns director,casts,country,listed_in from main table coz
-- we have splitted the data from this columns to new tables and connected the new tables
-- with foreign keys to the main table
ALTER TABLE netflix_data
DROP COLUMN director,
DROP COLUMN casts,
DROP COLUMN country
DROP COLUMN listed_in;

-- removing leading and trailing spaces from date_added column
update netflix_data
set date_added = trim(date_added)

-- replacing some null values in duration column
update netflix_data
set duration = coalesce(duration, 'Unknown')

-- basic data exploration from the cleaned data 

-- Find the unique types of content (e.g., Movie, TV Show) and their respective counts.
select type, count(*) as count from netflix_data group by type;

-- Find the release year range (earliest and latest) for all movies and TV shows in the dataset, along with the total count of content items across all years.
SELECT
min(release_year) as early_year,
max(release_year) as latest_year,
count(*) as total_content from netflix_data;

-- Find count of all Movies and TV shows released in a country
SELECT DISTINCT c.type, cn.country_name, COUNT(*) AS count
FROM netflix_data AS c
FULL JOIN country_name AS cn
    ON cn.show_id = c.show_id
WHERE cn.country_name = 'India'
GROUP BY c.type, cn.country_name;

-- Find count of genre of Movies and TV shows released in a country
SELECT
  cn.country_name,
  cg.genre,
  c.type,
  COUNT(*) AS rating_count
FROM netflix_data AS c
FULL JOIN country_name AS cn ON cn.show_id = c.show_id
FULL JOIN genre AS cg ON cg.show_id = c.show_id
WHERE cn.country_name = 'India'
GROUP BY cn.country_name, cg.genre, c.type
ORDER BY rating_count DESC;

-- list top 50 directors by total content count in a country
SELECT 
  cn.country_name, 
  d.director, 
  COUNT(c.show_id) AS content_count
FROM netflix_data AS c
JOIN directors AS d ON c.show_id = d.show_id
JOIN country_name AS cn ON cn.show_id = c.show_id
WHERE cn.country_name = 'India'
  AND d.director IS NOT NULL 
  AND d.director <> 'Unknown'
GROUP BY cn.country_name, d.director
ORDER BY content_count DESC
LIMIT 50;

-- list top 50 actors/actress by total content count in a country
SELECT 
  cn.country_name, 
  ct.casts_name,
  COUNT(c.show_id) AS content_count
FROM netflix_data AS c
JOIN casts_name AS ct ON c.show_id = ct.show_id
JOIN country_name AS cn ON cn.show_id = c.show_id
WHERE cn.country_name = 'India'
  AND ct.casts_name IS NOT NULL 
  AND ct.casts_name <> 'Unknown'
GROUP BY cn.country_name, ct.casts_name
ORDER BY content_count DESC
LIMIT 50;

-- total content count by release year in a country
SELECT 
    cn.country_name, 
    c.release_year,
    c.type,
    COUNT(c.show_id) AS total_content_count
FROM netflix_data AS c
JOIN country_name AS cn ON cn.show_id = c.show_id
WHERE c.release_year IS NOT NULL
      AND cn.country_name = 'India'
GROUP BY cn.country_name, c.release_year, c.type
ORDER BY c.release_year DESC, c.type;

-- total content count by months added in a country
-- means, in which months there is more content added in netflix for a country
SELECT 
    cn.country_name,
    TO_CHAR(TO_DATE(c.date_added, 'Month DD, YYYY'), 'Month') AS added_month,
    c.type,
    COUNT(c.show_id) AS total_content_count
FROM netflix_data AS c
JOIN country_name AS cn ON cn.show_id = c.show_id
WHERE c.date_added IS NOT NULL
      AND cn.country_name = 'India'
GROUP BY cn.country_name, added_month, c.type
ORDER BY added_month DESC;

-- this was a data exploration and data validation done for a particular country.
-- for another countries just replace the country name by the countries available in the dataset it should be case sensitive