--Creating the 'attendance_ws' and 'stadiums' tables   

create table attend_qtr_wc(
    Date date,
    Time varchar(100),
    Home varchar(50),
    Away varchar(50),
    Attendance varchar(100),
    Venue varchar(150)
);

create table stadiums (
    name varchar(150),
    city varchar(150),
    capacity int
);	

--2 Adding a foreign key to the 'stadiums' table

ALTER TABLE stadiums
ADD CONSTRAINT unique_stadium_name UNIQUE (name);

Alter table attend_qtr_wc
add constraint fk_stadium
foreign key (stadium)
references stadiums(name);

--3 Uploading and inserting data

--For 'attend_qtr_wc' table 

COPY attend_qtr_wc FROM 'PATH/world_cup_project/attend_qtr_wc.csv' DELIMITER ',' CSV HEADER;

--For 'stadiums table'

insert into stadiums (name,city,capacity) values ('Al Bayt Stadium','Al Khor',68895);
insert into stadiums (name,city,capacity) values ('Lusail Iconic Stadium','Lusail City',88966);
insert into stadiums (name,city,capacity) values ('Ahmad Bin Ali Stadium','Umm Al Afaei',45032);
insert into stadiums (name,city,capacity) values ('Al Janoub Stadium','Al Wakrah',44325);
insert into stadiums (name,city,capacity) values ('Al Thumama Stadium','Al Thumama',44400);
insert into stadiums (name,city,capacity) values ('Education City Stadium','Al Rayyan',44667);
insert into stadiums (name,city,capacity) values ('Khalifa International Stadium','Aspire',45857);
insert into stadiums (name,city,capacity) values ('Stadium 974','Ras Abu Aboud',44089);


--3 Transforming and updating the time and attendance columns

-- Changing the datatype to date time for the time column

ALTER TABLE attend_qtr_wc
ALTER COLUMN time TYPE time USING time::time;

-- Changing the datatype of the attendance column from varchar to integer to remove the ','

UPDATE attend_qtr_wc
SET attendance = cast(replace(attendance, ',','') AS INTEGER);
ALTER TABLE attend_qtr_wc
ALTER attendance TYPE INTEGER USING cast(attendance as INTEGER);

--- To add a primary key with a name of "id" as row numbers in PostgreSQL, 
-- we can use the SERIAL keyword to automatically create an auto-incrementing integer column:

Alter table attend_qtr_wc
add column id SERIAL PRIMARY KEY;

--we can use the ALTER TABLE statement along with the 
--RENAME COLUMN clause to change the name of a column in a table. 
--For example, we will change the name of column venue to staduim 

alter table attendance_wc
rename column venue to stadium;

--update the names of some values

UPDATE attend_qtr_wc
SET stadium = 'Ahmad Bin Ali Stadium'
WHERE stadium = 'Ahmed bin Ali Stadium';

UPDATE attend_qtr_wc
SET stadium = 'Al Thumama Stadium'
WHERE stadium = 'Al Thumama Stadium (Neutral Site)';
 
--- Answering some interesting questions using the 'attend_wc' and 'stadiums' tables through data analysis

--What is the average attendance at each stadium?

SELECT stadium, ROUND(AVG(attendance)::NUMERIC) as average_attendance
FROM attend_qtr_wc
GROUP BY stadium
ORDER BY 2 desc;


---How does the attendance throughout the week?

SELECT 
    to_char(date, 'Day') as day_of_week, 
    Round(AVG(attendance::integer),0) as avg_attendance
FROM 
    attend_qtr_wc
GROUP BY 
    to_char(date, 'Day')
ORDER BY 
    2 DESC;



--What is the occupancy rate for each stadium throughout the tournament 

SELECT 
    s.name as stadium, 
    ROUND(avg(wc.attendance)::numeric / s.capacity::numeric * 100, 2) as avg_attendance_percentage
FROM 
    attend_qtr_wc wc
    JOIN stadiums s ON wc.stadium = s.name
GROUP BY 
    s.name, s.capacity
ORDER BY 
    avg_attendance_percentage DESC;	


--What is the average attendance for each team throughout the tournament?
	
WITH teams_attendance AS (
    SELECT team, SUM(attendance) as sum_attendance, COUNT(*) as number_of_games
    FROM (
      SELECT home as team, attendance
      FROM attend_qtr_wc
      UNION
      SELECT away as team, attendance
      FROM attend_qtr_wc
    ) as games
    GROUP BY team
)
SELECT distinct team, ROUND(sum_attendance/number_of_games) as average_attendance
FROM teams_attendance
ORDER BY average_attendance DESC;


	
--What is the average attendance for each game throughout the tournament?

WITH 
   attendance_percentage AS (
    SELECT 
        home AS team,
        ROUND(AVG(attendance::numeric / capacity::numeric * 100)::numeric, 2) as avg_attendance_percentage
    FROM 
        attend_qtr_wc wc
        JOIN stadiums s ON wc.stadium = s.name
    GROUP BY 
        home
    UNION
    SELECT 
        away AS team,
        ROUND(AVG(attendance::numeric / capacity::numeric * 100)::numeric, 2) as avg_attendance_percentage
    FROM 
        attend_qtr_wc wc
        JOIN stadiums s ON wc.stadium = s.name
    GROUP BY 
        away
    )
SELECT 
    team, 
    TRUNC(AVG(avg_attendance_percentage), 2) as avg_attendance_percentage
FROM 
    attendance_percentage
GROUP BY 
    team
ORDER BY 
    avg_attendance_percentage desc;

---How does the attendance vary by day of the week for each individual stadium?

WITH 
  day_of_week AS (
    SELECT 
      stadium,
      date,
      to_char(date,'Day') as day_name,
      SUM(attendance) as total_attendance
    FROM 
      attend_qtr_wc
    GROUP BY 
      stadium,date,day_name
    ORDER BY 
      day_name
  )
SELECT 
  stadium,
  day_name,
  ROUND(AVG(total_attendance),0) as avg_attendance
FROM 
  day_of_week
GROUP BY 
  stadium,day_name
ORDER BY 
  stadium,day_name
);

 ---How does the daily attendance at each stadium compare to its capacity?

SELECT 
    wc.stadium, 
    date,
    ROUND(AVG(wc.attendance::numeric / s.capacity::numeric * 100)::numeric, 2) as avg_attendance_percentage
FROM 
    attend_qtr_wc wc
    JOIN stadiums s ON wc.stadium = s.name
WHERE wc.attendance IS NOT NULL and wc.attendance!=0
GROUP BY 
    wc.stadium, date
ORDER BY 
    wc.stadium, date
);
	
 ---What is the percentage of games played in each stadium throughout the entire tournament?
 
WITH cte AS (
  SELECT 
    s.name as stadium, 
    COUNT(a.stadium) as games_played 
  FROM attend_qtr_wc a 
  JOIN stadiums s ON a.stadium = s.name
  GROUP BY s.name
)
SELECT 
  stadium, 
  games_played, 
  ROUND((games_played / (SELECT SUM(games_played) FROM cte)) * 100,1) as "percent_of_games"
FROM cte)
;
