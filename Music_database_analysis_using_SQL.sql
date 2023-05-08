/* Q1: Who is the senior most employee based on job title? */
select
*
from
Employee
order by 
levels desc
limit 1

/* Q2: Which countries have the most Invoices? */
select
count(*) as C,
billing_country
from
invoice
group by
billing_country
order by
c desc

/* Q3: What are top 3 values of total invoice? */
select
total
from
invoice
order by
total desc
limit 3

/* Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals */
select
sum(total) as invoice_total,
billing_city
from
invoice
group by billing_city
order by invoice_total desc

/* Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/
select
c.customer_id,
c.first_name,
c.last_name,
sum(i.total) as total
from
customer as c
join invoice as i
on c.customer_id = i.customer_id
group by c.customer_id
order by
total desc
limit 1



/* Question Set 2 - Moderate */

/* Q1: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */
select
c.email,
c.first_name,
c.last_name
from
customer as c
join invoice as i
on c.customer_id = i.customer_id
join invoice_line as il
on i.invoice_id = il.invoice_id
where track_id in(
select track_id from track as t
	join genre as g
	on t.genre_id = g.genre_id
	where g.name like 'Rock'
)
order by
email;

/* Q2: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */
select
at.artist_id,
at.name,
count(at.artist_id) as Number_of_songs
from
track as t
join album as a
on t.album_id = a.album_id
join artist as at
on a.artist_id = at.artist_id
join genre as g
on t.genre_id = g.genre_id
group by
at.artist_id
order by
Number_of_songs  desc
limit 10;

/* Q3: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */
select
name,
milliseconds
from
track
where milliseconds > (
	select avg(milliseconds) as avg_track_length
	from track
)
order by
milliseconds desc



/* Question Set 3 - Advance */

/* Q1: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent */

/* Steps to Solve: First, find which artist has earned the most according to the InvoiceLines. Now use this artist to find 
which customer spent the most on this artist. For this query, you will need to use the Invoice, InvoiceLine, Track, Customer, 
Album, and Artist tables. Note, this one is tricky because the Total spent in the Invoice table might not be on a single product, 
so you need to use the InvoiceLine table to find out how many of each product was purchased, and then multiply this by the price
for each artist. */
WITH best_selling_artist AS(
	select
at.artist_id as artist_id,
at.name as artist_name,
sum(il.unit_price*il.quantity) as total_sales
from
invoice_line as il
join track as t
on il.track_id = t.track_id
join album as a
on t.album_id = a.album_id
join artist as at
on a.artist_id = at.artist_id
group by 1
order by 3 desc
limit 1
)
select
c.customer_id, c.first_name, c.last_name, bsa.artist_name,
sum(il.unit_price*il.quantity) as total_spent
from
invoice as i
join customer as c
on i.customer_id = c.customer_id
join invoice_line as il
on il.invoice_id = i.invoice_id
join track as t
on il.track_id = t.track_id
join album as a
on t.album_id = a.album_id
join best_selling_artist  as bsa
on bsa.artist_id = a.artist_id
group by 1,2,3,4
order by 5 desc;


/* Q2: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

/* Steps to Solve:  There are two parts in question- first most popular music genre and second need data at country level. */

/* Method 1: Using CTE */
WITH popular_genre as(
	select
count(il.quantity) as purchases, c.country, g.name, g.genre_id,
Row_number() over(partition by c.country order by count(il.quantity) desc) as Rowno
from
invoice_line as il
join invoice as i
on il.invoice_id = i.invoice_id
join customer as c
on i.customer_id = c.customer_id
join track as t
on il.track_id = t.track_id
join genre as g
on t.genre_id = g.genre_id
group by 2,3,4
	order by 2 asc, 1 desc
)
select * from popular_genre where Rowno <=1

/* Method 2: Using Recursive*/

WITH RECURSIVE
	sales_per_country AS(
		SELECT COUNT(*) AS purchases_per_genre, customer.country, genre.name, genre.genre_id
		FROM invoice_line
		JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
		JOIN customer ON customer.customer_id = invoice.customer_id
		JOIN track ON track.track_id = invoice_line.track_id
		JOIN genre ON genre.genre_id = track.genre_id
		GROUP BY 2,3,4
		ORDER BY 2
	),
	max_genre_per_country AS (SELECT MAX(purchases_per_genre) AS max_genre_number, country
		FROM sales_per_country
		GROUP BY 2
		ORDER BY 2)

SELECT sales_per_country.* 
FROM sales_per_country
JOIN max_genre_per_country ON sales_per_country.country = max_genre_per_country.country
WHERE sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number;


/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

/* Steps to Solve:  Similar to the above question. There are two parts in question- 
first find the most spent on music for each country and second filter the data for respective customers. */

/* Method 1: using Recursive */
WITH RECURSIVE 
	customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 2,3 DESC),

	country_max_spending AS(
		SELECT billing_country,MAX(total_spending) AS max_spending
		FROM customter_with_country
		GROUP BY billing_country)

SELECT cc.billing_country, cc.total_spending, cc.first_name, cc.last_name, cc.customer_id
FROM customter_with_country cc
JOIN country_max_spending ms
ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.max_spending
ORDER BY 1;

/* Method 2: using Recursive CTE */

WITH Customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending,
	    ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo 
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 4 ASC,5 DESC)
SELECT * FROM Customter_with_country WHERE RowNo <= 1

--Thank You--


