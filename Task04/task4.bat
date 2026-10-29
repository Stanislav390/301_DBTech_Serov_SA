
#!/bin/bash

sqlite3 movies_rating.db < db_init.sql

echo "1. Найти все пары пользователей, оценивших один и тот же фильм. Устранить дубликаты и исключить пары с самим собой. Первые 100 записей."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "
SELECT DISTINCT
       u1.name AS user1,
       u2.name AS user2,
       m.title AS movie
FROM ratings AS r1
JOIN ratings AS r2
    ON r1.movie_id = r2.movie_id
   AND r1.user_id < r2.user_id
JOIN users AS u1 ON u1.id = r1.user_id
JOIN users AS u2 ON u2.id = r2.user_id
JOIN movies AS m ON m.id = r1.movie_id
ORDER BY u1.name, u2.name, m.title
LIMIT 100;
"
echo " "


echo "2. Найти 10 самых старых оценок от разных пользователей. Вывести фильм, пользователя, оценку и дату отзыва."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "
SELECT m.title AS movie,
       u.name AS user,
       r.rating,
       date(r.timestamp, 'unixepoch') AS rating_date
FROM ratings AS r
JOIN users AS u ON u.id = r.user_id
JOIN movies AS m ON m.id = r.movie_id
ORDER BY r.timestamp ASC, r.user_id ASC
LIMIT 10;
"
echo " "


echo "3. Найти фильмы с максимальным и минимальным средним рейтингом. Для максимального указать Да, для минимального Нет."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "
WITH movie_avg AS (
    SELECT
        m.id,
        m.title,
        m.year,
        AVG(r.rating) AS avg_rating
    FROM movies AS m
    JOIN ratings AS r ON r.movie_id = m.id
    GROUP BY m.id, m.title, m.year
),
extremes AS (
    SELECT
        MAX(avg_rating) AS max_avg,
        MIN(avg_rating) AS min_avg
    FROM movie_avg
)
SELECT
    movie_avg.title AS movie,
    movie_avg.year AS year,
    ROUND(movie_avg.avg_rating, 2) AS avg_rating,
    CASE
        WHEN movie_avg.avg_rating = extremes.max_avg THEN 'Да'
        ELSE 'Нет'
    END AS 'Рекомендуем'
FROM movie_avg
CROSS JOIN extremes
WHERE movie_avg.avg_rating = extremes.max_avg
   OR movie_avg.avg_rating = extremes.min_avg
ORDER BY movie_avg.year, movie_avg.title;
"
echo " "


echo "4. Подсчитать количество оценок и средний рейтинг, выставленный мужчинами в период с 2011 по 2014 год."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "
SELECT
    COUNT(*) AS rating_count,
    ROUND(AVG(r.rating), 2) AS avg_rating
FROM ratings AS r
JOIN users AS u ON u.id = r.user_id
WHERE u.gender = 'male'
  AND strftime('%Y', r.timestamp, 'unixepoch')
      BETWEEN '2011' AND '2014';
"
echo " "



echo "5. Вывести фильмы со средним рейтингом и количеством пользователей, поставивших оценку. Сортировка по году и названию, первые 20 записей."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "
SELECT
    m.title AS movie,
    m.year AS year,
    ROUND(AVG(r.rating), 2) AS avg_rating,
    COUNT(DISTINCT r.user_id) AS user_count
FROM movies AS m
JOIN ratings AS r ON r.movie_id = m.id
GROUP BY m.id, m.title, m.year
ORDER BY m.year, m.title
LIMIT 20;
"
echo " "



echo "6. Определить самый распространённый жанр и количество фильмов этого жанра."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "
WITH RECURSIVE split(movie_id, rest, genre) AS (
    SELECT id, genres || '|', ''
    FROM movies
    WHERE genres IS NOT NULL AND genres <> ''

    UNION ALL

    SELECT
        movie_id,
        substr(rest, instr(rest, '|') + 1),
        trim(substr(rest, 1, instr(rest, '|') - 1))
    FROM split
    WHERE rest <> ''
),
genre_counts AS (
    SELECT
        genre,
        COUNT(DISTINCT movie_id) AS movie_count
    FROM split
    WHERE genre <> ''
    GROUP BY genre
)
SELECT
    genre,
    movie_count
FROM genre_counts
WHERE movie_count = (
    SELECT MAX(movie_count)
    FROM genre_counts
)
ORDER BY genre;
"
echo " "



echo "7. Вывести 10 последних зарегистрированных пользователей в формате Фамилия Имя|Дата регистрации."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "
SELECT
    trim(substr(name, instr(name, ' ') + 1)) || ' ' ||
    substr(name, 1, instr(name, ' ') - 1) || '|' ||
    register_date AS 'Фамилия Имя|Дата регистрации'
FROM users
ORDER BY register_date DESC, id DESC
LIMIT 10;
"
echo " "



echo "8. С помощью рекурсивного CTE определить день недели дня рождения в каждом году с 2006 по 2026."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "
WITH RECURSIVE years(y) AS (
    SELECT 2006
    UNION ALL
    SELECT y + 1
    FROM years
    WHERE y < 2026
)
SELECT
    y AS year,
    printf('%02d.%02d.%04d', 29, 11, y) AS birthday,
    CASE strftime('%w', printf('%04d-11-29', y))
        WHEN '0' THEN 'Воскресенье'
        WHEN '1' THEN 'Понедельник'
        WHEN '2' THEN 'Вторник'
        WHEN '3' THEN 'Среда'
        WHEN '4' THEN 'Четверг'
        WHEN '5' THEN 'Пятница'
        WHEN '6' THEN 'Суббота'
    END AS weekday
FROM years
ORDER BY y;
"
echo " "

