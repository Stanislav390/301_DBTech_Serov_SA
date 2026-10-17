#!/bin/bash

sqlite3 movies_rating.db < db_init.sql

echo "1. Составить список фильмов, имеющих хотя бы одну оценку. Сортировка по году выпуска и названию. Первые 10 фильмов."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "

SELECT DISTINCT m.title, m.year
FROM movies AS m
JOIN ratings AS r ON r.movie_id = m.id
WHERE m.year IS NOT NULL
ORDER BY m.year, m.title
LIMIT 10;

"
echo " "

echo "2. Вывести пользователей, фамилии которых начинаются на букву A. Сортировка по дате регистрации. Первые 5 пользователей."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "
SELECT id, name, email, gender, register_date, occupation
FROM users
WHERE trim(substr(name, instr(name, ' ') + 1)) LIKE 'A%'
ORDER BY register_date
LIMIT 5;
"
echo " "

echo "3. Рейтинги в читаемом формате: эксперт, фильм, год, оценка и дата оценки. Сортировка по имени эксперта, названию фильма и оценке. Первые 50 записей."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "
SELECT u.name AS expert,
       m.title AS movie,
       m.year,
       r.rating,
       date(r.timestamp, 'unixepoch') AS rating_date
FROM ratings AS r
JOIN users AS u ON u.id = r.user_id
JOIN movies AS m ON m.id = r.movie_id
ORDER BY u.name, m.title, r.rating
LIMIT 50;
"
echo " "

echo "4. Фильмы и присвоенные им теги. Сортировка по году, названию и тегу. Первые 40 записей."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "
SELECT m.title, m.year, t.tag
FROM movies AS m
JOIN tags AS t ON t.movie_id = m.id
WHERE m.year IS NOT NULL
ORDER BY m.year, m.title, t.tag
LIMIT 40;
"
echo " "

echo "5. Самые свежие фильмы: все фильмы с максимальным годом выпуска в базе."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "
SELECT title, year, genres
FROM movies
WHERE year = (SELECT MAX(year) FROM movies)
ORDER BY title;
"
echo " "

echo "6. Драмы после 2005 года, понравившиеся женщинам: оценка не ниже 4.5. Вывод количества таких оценок."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "
SELECT m.title,
       m.year,
       COUNT(*) AS high_female_ratings
FROM movies AS m
JOIN ratings AS r ON r.movie_id = m.id
JOIN users AS u ON u.id = r.user_id
WHERE m.year > 2005
  AND ('|' || m.genres || '|') LIKE '%|Drama|%'
  AND u.gender = 'female'
  AND r.rating >= 4.5
GROUP BY m.id, m.title, m.year
ORDER BY m.year, m.title;
"
echo " "

echo "7. Количество регистраций по годам. Отмечены годы с максимальным и минимальным количеством регистраций."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "
WITH yearly AS (
    SELECT strftime('%Y', register_date) AS year,
           COUNT(*) AS user_count
    FROM users
    GROUP BY strftime('%Y', register_date)
)
SELECT year,
       user_count,
       CASE
           WHEN user_count = (SELECT MAX(user_count) FROM yearly)
               THEN 'Больше всего'
           WHEN user_count = (SELECT MIN(user_count) FROM yearly)
               THEN 'Меньше всего'
           ELSE ''
       END AS analysis
FROM yearly
ORDER BY year;
"
echo " "
