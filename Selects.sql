--Selects.
USE [Cinema]
GO

--Select all movies information with possible delivery method
SELECT m.MovieName, IIF(m.[Description] IS NULL, 'No - description',  CONCAT(LEFT(m.[Description], 20), '...')) AS [Description],
 m.Duration, d.DeliveryMethodName FROM MovieDeliveryMethods md
	JOIN Movies m ON m.Id = md.MovieId
	JOIN DeliveryMethods d ON d.Id = md.DeliveryMethodId
GO

--Select movies with genres
SELECT m.MovieName, g.GenreName FROM MovieGenres mg
	JOIN Genres g ON mg.GenreId = g.Id
	JOIN Movies m ON m.Id = mg.MovieId
GO

--Select schedule for today with all movies in all cinema halls and delivery methods specified 
SELECT s.SessionDateTime, c.HallName, m.MovieName, m.[Description], m.Duration, d.DeliveryMethodName FROM MovieDeliveryMethods md
	JOIN Movies m ON m.Id = md.MovieId
	JOIN DeliveryMethods d ON d.Id = md.DeliveryMethodId
	JOIN [Sessions] s ON s.MovieDeliveryMethodsId = md.Id
	JOIN CinemaHalls c ON c.Id = s.HallId
	WHERE DATEDIFF(DAY, s.SessionDateTime, GETDATE()) = 0
GO

--Select movies that have more than two genres. Show count of genres.
SELECT m.MovieName, COUNT(g.GenreName) AS GenreNumbers FROM MovieGenres mg
	JOIN Genres g ON mg.GenreId = g.Id
	JOIN Movies m ON m.Id = mg.MovieId
	GROUP BY m.MovieName
	HAVING COUNT(g.GenreName) > 2
GO

--Select the most popular movie in cinema.
SELECT TOP(1) WITH TIES t.MovieName, t.BoughtTickets FROM (SELECT m.MovieName, COUNT(ts.Status) AS BoughtTickets FROM TicketOrders ti
	JOIN TicketStatus ts ON ts.Id = ti.TicketStatusId
	JOIN [Sessions] s ON s.Id = ti.SessionId
	JOIN Movies m ON m.Id = s.MovieDeliveryMethodsId
	WHERE ts.Status = 'bought' 
	GROUP BY m.MovieName) t
	ORDER BY t.BoughtTickets DESC
GO

--	Select all genres and tree level as number for genre.
;WITH Tree_CTE 
AS
(
    SELECT g1.Id, g1.GenreId, g1.GenreName, [Level] = 1, [Path] = CAST('Root' AS varchar(100))
    FROM Genres g1
    WHERE g1.GenreId IS NULL

	    UNION ALL

    SELECT g2.Id, g2.GenreId, g2.GenreName, [level] = Tree_CTE .[level] + 1, 
    [Path] = CAST(Tree_CTE .[Path] + '/' + RIGHT(CAST(g2.Id AS varchar(10)),10) AS varchar(100))
    FROM Genres g2 
	JOIN Tree_CTE  ON Tree_CTE .Id = g2.GenreId
)

SELECT Tree_CTE.[Path], Tree_CTE.Id, GenreId, Tree_CTE.GenreName FROM Tree_CTE 
ORDER BY [Path]

--Select profitability for movies in cinema last month. Round to 2 decimal places. (Profitability is ratio of total profit for all movie sessions to total cinema profit)

--1st method
DECLARE @@tableVar table (MovieName nvarchar(50), BoughtTickets int, Amount float);

INSERT INTO @@tableVar (MovieName, BoughtTickets, Amount)
SELECT m.MovieName, COUNT(ts.Status) AS BoughtTickets, SUM(ti.Price) AS Amount FROM TicketOrders ti
	JOIN TicketStatus ts ON ts.Id = ti.TicketStatusId
	JOIN Sessions s ON s.Id = ti.SessionId
	JOIN Movies m ON m.Id = s.MovieDeliveryMethodsId
	WHERE ts.Status = 'bought' AND  DATEDIFF(DAY, s.SessionDateTime, GETDATE()) < 30 
	GROUP BY m.MovieName

DECLARE @@TotalAmount int = (SELECT SUM(Amount) AS TotalAmount FROM @@tableVar)

SELECT MovieName, ROUND(Amount/@@TotalAmount, 2) AS Profitability FROM @@tableVar

-- 2nd method
CREATE VIEW Profitability
WITH SCHEMABINDING
AS
	SELECT t2.MovieName, ROUND(t2.Amount /  (SELECT SUM(t1.Amount) AS TotalAmount FROM (SELECT m.MovieName, COUNT(ts.Status) AS BoughtTickets, SUM(ti.Price) AS Amount FROM [dbo].[TicketOrders] ti
											JOIN [dbo].[TicketStatus] ts ON ts.Id = ti.TicketStatusId
											JOIN [dbo].[Sessions] s ON s.Id = ti.SessionId
											JOIN [dbo].[Movies] m ON m.Id = s.MovieDeliveryMethodsId
											WHERE ts.Status = 'bought' AND  DATEDIFF(DAY, s.SessionDateTime, GETDATE()) < 30 
											GROUP BY m.MovieName) t1), 2) AS Profitability
	
	FROM	(SELECT m.MovieName, COUNT(ts.Status) AS BoughtTickets, SUM(ti.Price) AS Amount FROM [dbo].[TicketOrders] ti
			JOIN [dbo].[TicketStatus] ts ON ts.Id = ti.TicketStatusId
			JOIN [dbo].[Sessions] s ON s.Id = ti.SessionId
			JOIN [dbo].[Movies] m ON m.Id = s.MovieDeliveryMethodsId
			WHERE ts.Status = 'bought' AND  DATEDIFF(DAY, s.SessionDateTime, GETDATE()) < 30 
			GROUP BY m.MovieName) t2
GO
--It won't work, because the view references derived table "t2".
CREATE UNIQUE CLUSTERED INDEX IX_CL_Profitability_MovieName
ON Profitability(MovieName)

SELECT * FROM Profitability


--Select schedule for this week with all movies in all cinema halls and delivery methods specified. 
--Provide count of occupied  places (booked/bought), and total places. Format date as short date. 
CREATE VIEW GeneralInformation
WITH SCHEMABINDING
AS
	SELECT CONVERT(VARCHAR(10), ss.SessionDateTime, 103) AS [Date], m.MovieName, ch.HallName, d.DeliveryMethodName, 
	COUNT_BIG(s.Id) AS OccupiedPlace, ch.SeatsNumber AS TotalPlaces FROM [dbo].[Sessions] ss
		JOIN [dbo].[MovieDeliveryMethods] md ON md.Id = ss.MovieDeliveryMethodsId
		JOIN [dbo].[DeliveryMethods] d ON d.Id = md.DeliveryMethodId
		JOIN [dbo].[Movies] m ON m.Id = md.MovieId
		JOIN [dbo].[TicketOrders] t ON t.SessionId = ss.Id
		JOIN [dbo].[Seats] s ON s.Id = t.SeatId
		JOIN [dbo].[CinemaHalls] ch ON ch.Id = ss.HallId
		JOIN [dbo].[TicketStatus] ts ON ts.Id = t.TicketStatusId
		WHERE (ss.SessionDateTime BETWEEN CONVERT(date, DATEADD(DAY , 2 - DATEPART(WEEKDAY, GETDATE()), GETDATE()), 103)
		  AND CONVERT(date, DATEADD(DAY , 8 - DATEPART(WEEKDAY, GETDATE()), GETDATE()), 103))
		  AND ts.[Status] LIKE 'bought' OR ts.[Status] LIKE 'booked'
		GROUP BY CONVERT(VARCHAR(10), ss.SessionDateTime, 103), m.MovieName, ch.HallName, d.DeliveryMethodName, ch.SeatsNumber
GO
-- It won't work, because we use non-deterministic function GETDATE() in view!
CREATE UNIQUE CLUSTERED INDEX IX_CL_GeneralInformation_Date
ON GeneralInformation([Date])

SELECT * FROM GeneralInformation