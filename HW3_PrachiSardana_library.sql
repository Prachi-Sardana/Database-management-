-- TOPIC: JOIN QUERIES
-- THEME: Books that will change your life

-- Instructions: Run the script "library_setup.sql" in a ROOT connection
-- This will create a new schema called "library"
-- Write a query that answers each question below.
-- Save this file as HW4_YourFullName.sql and submit

-- Questions 1-12 are 8 points each. Question 13 is worth 4 points.


use library;

-- show tables;
-- select * from book;
-- select * from borrow;
-- select * from genre;
-- select * from payment;
-- select * from user;

-- 1. Which book(s) are Science Fiction books written in the 1960's?
-- List title, author, and year of publication


SELECT 
    book.title, book.author, book.year 
FROM 
    book 
inner JOIN 
    genre ON book.genre_id = genre.genre_id 
WHERE 
    genre.genre_name = 'Science Fiction'
    AND book.year between 1960 and 1970;


-- 2. Which users have borrowed no books?
-- Give name and city they live in
-- Write the query in two ways, once by selecting from only one table
-- and using a subquery, and again by joining two tables together.

-- Method using subquery (4 points)


SELECT user_name, city
FROM user 
WHERE user_id NOT IN (
    SELECT DISTINCT user_id
    FROM borrow
);

-- Method using a join (4 points)

-- selected user name from user and user city 
-- performed left join to join borrow table and user table based on user id 
-- where borrow user id is null since we need to find out users which have borrowed no books

SELECT u.user_name, u.city
FROM user u
LEFT JOIN borrow b ON u.user_id = b.user_id
WHERE b.user_id IS NULL;


-- 3. How many books were borrowed by each user in each month?
-- Your table should have three columns: user_name, month, num_borrowed
-- You may ignore users that didn't borrow any books and months in which no books were borrowed.
-- Sort by name, then month
-- The month(date) function returns the month number (1,2,3,...12) of a given date. This is adequate for output.

SELECT u.user_name, month(b.borrow_dt) as months, count(b.book_id) as num_borrowed
FROM borrow b
join user u using (user_id)
group by u.user_name, months
having num_borrowed > 0  
order by u.user_name, months;



-- 4. How many times was each book checked out?
-- Output the book's title, genre name, and the number of times it was checked out, and whether the book is still in circulation
-- Books not in circulation are presumably lost or stolen
-- Include books never borrowed
-- Order from most borrowed to least borrowed

SELECT bk.title, g.genre_name,
count(borrow_dt) as books_checked_out , bk.in_circulation
FROM book bk
left JOIN borrow b ON bk.book_id = b.book_id
left JOIN genre g ON bk.genre_id = g.genre_id
group by bk.title, g.genre_name, bk.in_circulation
order by books_checked_out desc;


-- 5. How many times did each user return a book late?
-- Include users that never returned a book late or never even borrowed a book
-- Sort by most number of late returns to least number of late returns (regardless of HOW late the returns were.)


SELECT
    u.user_id,
    u.user_name,
     SUM(CASE WHEN DATEDIFF(b.return_dt, b.due_dt) > 0 THEN 1 ELSE 0 END) as late_returns 
    FROM
    user u
LEFT JOIN borrow b ON u.user_id = b.user_id
GROUP BY u.user_id, u.user_name
ORDER BY late_returns DESC;



-- 6. How many books of each genre where published after 1950?
-- Include genres that are not represented by any book in our catalog
-- as well as genres for which there are books but none published after 1950.
-- Sort output by number of titles in each genre (most to least)


SELECT
    SUM(CASE WHEN bk.year > 1950 THEN 1 ELSE 0 END) AS num_books_published_after_1950,
    g.genre_name
FROM
    genre g
LEFT JOIN
    book bk ON g.genre_id = bk.genre_id AND bk.year <= 1950
GROUP BY
    g.genre_name
ORDER BY
    num_books_published_after_1950 DESC;



-- 7. For each genre, compute a) the number of books borrowed and b) the average
-- number of days borrowed.
-- Includes books never borrowed and genres with no books
-- and in these cases, show zeros instead of null values.
-- Round the averages to one decimal point
-- Sort output in descending order by average
-- Helpful functions: ROUND, IFNULL, DATEDIFF

SELECT
    g.genre_name,
    IFNULL(COUNT(DISTINCT b.book_id), 0) as books_borrowed,
    ROUND(IFNULL(AVG(DATEDIFF(b.return_dt, b.borrow_dt)), 0), 1) as avg_days
FROM
    genre g
LEFT JOIN
    book bk ON g.genre_id = bk.genre_id
LEFT JOIN
    borrow b ON bk.book_id = b.book_id
GROUP BY
    g.genre_name
ORDER BY
    avg_days DESC;



-- 8. List all pairs of books published within 10 years of each other
-- Don't include the book with itself
-- Only list (X,Y) pairs where X was published earlier
-- Output the two titles, and the years they were published, the number of years apart they were published
-- Order pairs from those published closest together to farthest

select bk1.title as book_title1, 
bk1.year as year1 , 
bk2.title as book_title2, 
bk2.year as year2, 
(bk2.year - bk1.year) as years_apart
from book bk1
join book bk2 on bk1.book_id < bk2.book_id 
and (bk2.year - bk1.year) <= 10 
where bk1.year < bk2.year
order by years_apart asc;



-- 9. Assuming books are returned completely read,
-- Rank the users from fastest to slowest readers (pages per day)
-- include users that borrowed no books (report reading rate as 0.0)

select u.user_id , 
u.user_name, 
    CASE 
        WHEN SUM(DATEDIFF(b.return_dt, b.borrow_dt)) = 0 OR SUM(DATEDIFF(b.return_dt, b.borrow_dt)) IS NULL THEN 0.0
        ELSE ROUND(SUM(bk.pages) / SUM(DATEDIFF(b.return_dt, b.borrow_dt)), 2)
        End as reading_rate
FROM user u
LEFT JOIN 
borrow b ON u.user_id = b.user_id
LEFT JOIN 
book bk ON b.book_id = bk.book_id
group by u.user_id, u.user_name
order by reading_rate desc;


-- 10. How many books of each genre were checked out by John?
-- Sort descending by number of books checked out in each genre category.
-- Only include genres where at least two books of that genre were checked out.
-- (Count each time the book was checked out even if the same book was checked out
-- by John more than once.)


SELECT g.genre_name,
COUNT(*) AS books_checked_out
FROM borrow b
JOIN user u ON b.user_id = u.user_id
JOIN book bk ON b.book_id = bk.book_id
JOIN genre g ON bk.genre_id = g.genre_id
WHERE u.user_name = 'John'
GROUP BY g.genre_name
HAVING COUNT(*) >= 2
ORDER BY books_checked_out DESC;

-- 11. On average how many books are borrowed per user?
-- Output two averages in one row: one average that includes users that
-- borrowed no books, and one average that excludes users that borrowed no books


SELECT 
    round(AVG(total_books_borrowed),2) AS avg_books_including_no_borrow,
    round(AVG(NULLIF(total_books_borrowed, 0)),2) AS avg_books_excluding_no_borrow
FROM (
    SELECT 
        u.user_id,
        u.user_name,
        COUNT(b.book_id) AS total_books_borrowed
    FROM 
        user u
    LEFT JOIN 
        borrow b ON u.user_id = b.user_id
    GROUP BY 
        u.user_id, u.user_name
) AS calculate_user_borrow;



-- 12. How much does each user owe the library. Include users owing nothing
-- Factor in the 10 cents per day fine for late returns and how much they have already paid the library
-- HINTS:
--     The DATEDIFF function takes two dates and counts the number of dates between them
--     The IF function, used in a SELECT clause, might also be helpful.  IF(condition, result_if_true, result_if_false)
--     IF functions can be used inside aggregation functions!


select payment_table.user_name, (borrow - payment) as net_due  from (select 
         user_name, round(SUM(IF(DATEDIFF(b.return_dt, b.due_dt) > 0, DATEDIFF(b.return_dt, b.due_dt) * 0.10, 0)), 2) as borrow from user u
LEFT JOIN borrow b ON u.user_id = b.user_id  group by user_name) borrow_table inner join 

(select 
         user_name, round(if(SUM(amount) > 0, sum(amount), 0), 2) as payment from user u
LEFT JOIN payment p  ON u.user_id = p.user_id  group by user_name) payment_table  on payment_table.user_name = borrow_table.user_name;


-- 13. (4 points) Which books will change your life?
-- Answer: All books.
-- Select all the books.

select * from book;