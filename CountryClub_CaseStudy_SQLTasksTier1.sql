/* Welcome to the SQL mini project. You will carry out this project partly in
the PHPMyAdmin interface, and partly in Jupyter via a Python connection.

This is Tier 1 of the case study, which means that there'll be more guidance for you about how to 
setup your local SQLite connection in PART 2 of the case study. 

The questions in the case study are exactly the same as with Tier 2. 

PART 1: PHPMyAdmin
You will complete questions 1-9 below in the PHPMyAdmin interface. 
Log in by pasting the following URL into your browser, and
using the following Username and Password:

URL: https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

In this case study, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */


/* QUESTIONS */
/* Q1: Some of the facilities charge a fee to members, but some do not.
Write a SQL query to produce a list of the names of the facilities that do. */
select name AS 'Facility Name'
from Facilities
where membercost > 0;

/* Q2: How many facilities do not charge a fee to members? */
select name AS 'Facility Name'
from Facilities
where membercost = 0;

/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */
-- Do we need to calculate the total fee received and its ratio to monthly maintenance cost?

select facid, name, membercost, monthlymaintenance
from Facilities
where membercost > 0
and membercost/monthlymaintenance > 0.2;

/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */

select facid, name, membercost, monthlymaintenance
from Facilities
where facid in (1,5);

/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */

SELECT name, monthlymaintenance,
CASE
	WHEN monthlymaintenance > 100 THEN 'Expensive'
	ELSE 'Cheap' END AS 'Category'
FROM Facilities;

/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */

SELECT firstname, surname
FROM Members
where joindate =
	(SELECT MAX(joindate) FROM Members);

/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */

SELECT firstname,surname, tennis_court_usage.facilityname
FROM Members m,
 (SELECT distinct b.memid, f.name AS facilityname
	FROM Bookings b
	INNER JOIN Facilities f
	ON b.facid = f.facid
	AND f.name in ('Tennis Court 1','Tennis Court 2')) AS tennis_court_usage
WHERE m.memid = tennis_court_usage.memid;

/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */

SELECT m.firstname,m.surname, f.name,
CASE
	WHEN b.memid = 0 THEN f.guestcost * slots
	ELSE f.membercost * slots END AS totalcost
FROM Bookings b
INNER JOIN Facilities f
ON b.facid = f.facid
INNER JOIN Members m
on b.memid = m.memid
WHERE date(b.starttime) = '2012-09-14'
HAVING totalcost > 30
ORDER BY totalcost DESC;

/* Q9: This time, produce the same result as in Q8, but using a subquery. */
SELECT m.firstname , m.surname, booking_cost.name, booking_cost.totalcost
FROM Members m,
 (SELECT booking_14sep.memid, f.name,
   CASE
	WHEN booking_14sep.memid = 0 THEN f.guestcost * booking_14sep.slots
	ELSE f.membercost * booking_14sep.slots END AS totalcost
  FROM Facilities f,
  (SELECT b.memid, b.facid, b.slots
   FROM Bookings b
   WHERE date(b.starttime) = '2012-09-14') booking_14sep
  WHERE booking_14sep.facid = f.facid) booking_cost
WHERE m.memid = booking_cost.memid
AND  booking_cost.totalcost > 30
ORDER BY totalcost DESC;

/* PART 2: SQLite */
/* We now want you to jump over to a local instance of the database on your machine. 

Copy and paste the LocalSQLConnection.py script into an empty Jupyter notebook, and run it. 

Make sure that the SQLFiles folder containing thes files is in your working directory, and
that you haven't changed the name of the .db file from 'sqlite\db\pythonsqlite'.

You should see the output from the initial query 'SELECT * FROM FACILITIES'.

Complete the remaining tasks in the Jupyter interface. If you struggle, feel free to go back
to the PHPMyAdmin interface as and when you need to. 

You'll need to paste your query into value of the 'query1' variable and run the code block again to get an output.
QUESTIONS:
Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */
    SELECT  booking_cost.name, SUM(booking_cost.totalcost)
    FROM
    (SELECT b.facid,b.bookid, f.name,
    CASE
        WHEN b.memid = 0 THEN f.guestcost * b.slots
        ELSE f.membercost * b.slots END AS totalcost
    FROM Facilities f,
        Bookings b
    WHERE b.facid = f.facid) booking_cost
    GROUP BY booking_cost.name
    HAVING SUM(booking_cost.totalcost) < 1000;


/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */
        SELECT m.surname || ' ' ||  m.firstname AS 'Member Name', rec.firstname || ' ' || rec.surname as 'Recommended BY'
        FROM Members m
        LEFT OUTER JOIN Members rec
        ON m.recommendedby = rec.memid
        WHERE m.recommendedby !=''
        ORDER BY 'Member Name'

/* Q12: Find the facilities with their usage by member, but not guests */

    SELECT f.name, COUNT(b.facid) 'usage_count', SUM(f.membercost * b.slots) AS 'total_cost'
    FROM Bookings b
     INNER JOIN Facilities f
     ON f.facid = b.facid
    WHERE b.memid != 0
    GROUP BY f.name;

/*--Facilities used by members
WITH member_used AS
(SELECT DISTINCT b.facid
FROM Bookings b
WHERE b.memid != 0),
--Facilities used by guests
guest_used AS
(SELECT DISTINCT b.facid
FROM Bookings b
WHERE b.memid = 0)

SELECT f.name
FROM Facilities f
WHERE f.facid IN ( SELECT mu.facid FROM member_used mu)
AND f.facid NOT IN ( SELECT gu.facid FROM guest_used gu);*/


/* Q13: Find the facilities usage by month, but not guests */
    SELECT f.name, strftime('%Y',starttime)||strftime('%m',starttime) AS 'Month',COUNT(b.facid) AS 'TotalUsage'
    FROM Bookings b
     INNER JOIN Facilities f
     ON f.facid = b.facid
    WHERE b.memid != 0
    GROUP BY f.name, 'Month'
