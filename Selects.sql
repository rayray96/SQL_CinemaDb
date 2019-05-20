--Selects.
USE [Cinema]
GO

--Select all movies information with possible delivery method
SELECT m.MovieName, m.Description, m.Duration, d.DeliveryMethodName FROM MovieDeliveryMethods md
	JOIN Movies m ON m.Id = md.MovieId
	JOIN DeliveryMethods d ON d.Id = md.DeliveryMethodId
GO
--Select movies with genres
SELECT m.MovieName, g.GenreName FROM MovieGenres mg
	JOIN Genres g ON mg.GenreId = g.Id
	JOIN Movies m ON m.Id = mg.MovieId
GO
--Select schedule for today with all movies in all cinema halls and delivery methods specified 
SELECT s.SessionDateTime, c.HallName, m.MovieName, m.Description, m.Duration, d.DeliveryMethodName FROM MovieDeliveryMethods md
	JOIN Movies m ON m.Id = md.MovieId
	JOIN DeliveryMethods d ON d.Id = md.DeliveryMethodId
	JOIN Sessions s ON s.MovieDeliveryMethodsId = md.Id
	JOIN CinemaHalls c ON c.Id = s.HallId
	WHERE DATEDIFF(DAY, s.SessionDateTime, GETDATE()) = 0
GO
--Select movies that have more than two genres. Show count of genres.
SELECT t.MovieName, t.GenreNumbers FROM (SELECT m.MovieName, COUNT(g.GenreName) AS GenreNumbers FROM MovieGenres mg
	JOIN Genres g ON mg.GenreId = g.Id
	JOIN Movies m ON m.Id = mg.MovieId
	GROUP BY m.MovieName) t
WHERE t.GenreNumbers > 2
GO
--Select the most popular movie in cinema.
SELECT TOP(1) m.MovieName, COUNT(ts.Status) AS BoughtTickets FROM TicketOrders ti
	JOIN TicketStatus ts ON ts.Id = ti.TicketStatusId
	JOIN Sessions s ON s.Id = ti.SessionId
	JOIN Movies m ON m.Id = s.MovieDeliveryMethodsId
	WHERE ts.Status = 'bought' 
	GROUP BY m.MovieName
GO
--Select profitability for movies in cinema last month. Round to 2 decimal places. (Profitability is ratio of total profit for all movie sessions to total cinema profit)
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
