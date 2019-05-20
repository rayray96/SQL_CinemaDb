-- Creating database, tables, constraints and references.
CREATE DATABASE [Cinema]
GO

ALTER DATABASE [Cinema]
COLLATE Cyrillic_General_CI_AS
GO

USE [Cinema]
GO

CREATE TABLE [TicketStatus]
(
Id int IDENTITY(1,1),
[Status] nvarchar(50) NOT NULL,
CONSTRAINT PK_TicketStatus_Id PRIMARY KEY (Id)
);
GO

CREATE TABLE [Genres]
(
Id int IDENTITY(1,1),
GenreName nvarchar(50) NOT NULL,
GenreId int FOREIGN KEY REFERENCES Genres(Id),
CONSTRAINT PK_Genres_Id PRIMARY KEY (Id)
);
GO

CREATE TABLE [Movies]
(
Id int IDENTITY(1,1),
MovieName nvarchar(50) UNIQUE NOT NULL,
[Description] nvarchar(255),
Duration int,
CONSTRAINT PK_Movies_Id PRIMARY KEY (Id)
);
GO


CREATE TABLE [MovieGenres]
(
MovieId int NOT NULL,
GenreId int NOT NULL,
CONSTRAINT PK_MovieGenres_MovieIdGenreId PRIMARY KEY (MovieId, GenreId),
CONSTRAINT FK_MovieGenres_MovieId FOREIGN KEY (MovieId) REFERENCES Movies(Id),
CONSTRAINT FK_MovieGenres_GenreId FOREIGN KEY (GenreId) REFERENCES Genres(Id)
);
GO

CREATE TABLE [DeliveryMethods]
(
Id int IDENTITY(1,1),
DeliveryMethodName nvarchar(10) NOT NULL,
CONSTRAINT PK_DeliveryMethods_Id PRIMARY KEY (Id)
);
GO

CREATE TABLE [MovieDeliveryMethods]
(
Id int IDENTITY(1,1),
MovieId int NOT NULL,
DeliveryMethodId int NOT NULL,
CONSTRAINT PK_MovieDeliveryMethods_Id PRIMARY KEY (Id),
CONSTRAINT FK_MovieDeliveryMethods_MovieId FOREIGN KEY (MovieId) REFERENCES Movies(Id),
CONSTRAINT FK_MovieDeliveryMethods_DeliveryMethodsId FOREIGN KEY (DeliveryMethodId) REFERENCES DeliveryMethods(Id)
);
GO

CREATE TABLE [CinemaHalls]
(
Id int IDENTITY(1,1),
HallName nvarchar(50) NOT NULL,
SeatsNumber int,
CONSTRAINT PK_CinemaHalls_Id PRIMARY KEY (Id)
);
GO

CREATE TABLE [Sessions]
(
Id int IDENTITY(1,1),
SessionDateTime datetime NOT NULL,
HallId int,
MovieDeliveryMethodsId int,
CONSTRAINT PK_Sessions_Id PRIMARY KEY (Id),
CONSTRAINT FK_Sessions_HallId FOREIGN KEY (HallId) REFERENCES CinemaHalls(Id),
CONSTRAINT FK_Sessions_MovieDeliveryMethodsId FOREIGN KEY (MovieDeliveryMethodsId) REFERENCES MovieDeliveryMethods(Id)
	ON DELETE SET DEFAULT
	ON UPDATE CASCADE
);
GO

CREATE TABLE [Seats]
(
Id int IDENTITY(1,1),
Seat int NOT NULL,
[Row] int NOT NULL,
HallId int NOT NULL,
CONSTRAINT PK_Seats_Id PRIMARY KEY (Id),
CONSTRAINT FK_Seats_HallId FOREIGN KEY (HallId) REFERENCES CinemaHalls(Id)
);
GO

CREATE TABLE [TicketOrders]
(
Id int IDENTITY(1,1),
SessionId int,
SeatId int,
Cost float,
Price float CONSTRAINT CK_TicketOrders_Price CHECK (Price > 0),
TicketStatusId int,
CONSTRAINT PK_TicketOrders_Id PRIMARY KEY (Id),
CONSTRAINT FK_TicketOrders_SessionId FOREIGN KEY (SessionId) REFERENCES [Sessions](Id)
	ON DELETE SET DEFAULT
	ON UPDATE CASCADE,
CONSTRAINT FK_TicketOrders_SeatId FOREIGN KEY (SeatId) REFERENCES Seats(Id),
CONSTRAINT FK_TicketOrders_TicketStatusId FOREIGN KEY (TicketStatusId) REFERENCES TicketStatus(Id)
);
GO

CREATE TRIGGER trTicketOrders
ON TicketOrders
	AFTER INSERT
AS
IF @@ROWCOUNT = 0
	RETURN

SET NOCOUNT ON

DECLARE @sessionId int, @seatId int, @cost float, @id int;
SELECT @sessionId = SessionId, @seatId = SeatId, @cost = Cost, @id = Id FROM inserted;

DECLARE @ticketPrice float, @deliveryMethodName nvarchar(10);
DECLARE @tableVar table([Row] int, [Id] int);

;WITH Format_CTE
AS
(SELECT d.DeliveryMethodName FROM [dbo].[Sessions] s
JOIN [dbo].[MovieDeliveryMethods] md ON s.MovieDeliveryMethodsId=md.Id
JOIN [dbo].[DeliveryMethods] d ON d.Id=md.DeliveryMethodId
WHERE s.Id = @sessionId)

SELECT @deliveryMethodName = DeliveryMethodName FROM Format_CTE

;WITH Seats_CTE
AS
(SELECT s.[Id], s.[Row] FROM [dbo].[Seats] s
JOIN [dbo].[CinemaHalls] c ON c.Id=s.HallId
WHERE c.Id = (SELECT TOP(1) [HallId] FROM [dbo].[Seats] WHERE Id = @seatId))

INSERT INTO @tableVar ([Row], [Id])
SELECT TOP(50) PERCENT t.[Row], t.[Id] FROM (SELECT TOP(70) PERCENT [Row], [Id] FROM Seats_CTE ORDER BY [Row] ASC) t 
ORDER BY t.[Row] DESC

DECLARE @deliveryRate float, @seatRate float;
-- Calculating rate for seat in the hall. 
IF @seatId IN (SELECT [Id] FROM @tableVar)
	BEGIN
SET @seatRate = 0.25
	END
ELSE
	BEGIN
SET @seatRate = 0.0
	END
-- Calculating rate for delivery method(2D or 3D). 
IF @deliveryMethodName = '3D'
	BEGIN  
SET @deliveryRate = 0.25
	END   
ELSE IF @deliveryMethodName = '2D'  
	BEGIN    
SET @deliveryRate = 0.0
	END  
-- Calculating price for ticket. 
SET @ticketPrice = @cost * (1 + @seatRate + @deliveryRate)
		
UPDATE TicketOrders
SET Price = @ticketPrice
WHERE Id = @id
GO

CREATE PROCEDURE spInsertSeats(@rows int, @seats int, @hallId int)
AS

DECLARE @counter1 int = 0, @counter2 int = 0;

WHILE @rows > @counter1
	BEGIN
	SET @counter1 = @counter1 + 1
	SET @counter2 = 0
		WHILE @seats > @counter2
		BEGIN
		SET @counter2 = @counter2 + 1
		INSERT INTO [Seats] 
		([Row], [Seat], [HallId])
		VALUES (@counter1, @counter2, @hallId)
		END
	END
GO

----------------------------- VERSION 1 --------------------------------------

--CREATE FUNCTION Calculate_Price(@sessionId int, @cost float)  
--	RETURNS float
--	WITH SCHEMABINDING   
--AS   
--	BEGIN  

--DECLARE @ticketPrice float, @sessionDateTime datetime, @premiere datetime, @deliveryMethodName nvarchar(10);

--;WITH Price_CTE
--AS
--(SELECT s.SessionDateTime, m.Premiere, d.DeliveryMethodName FROM [dbo].[Sessions] s
--JOIN [dbo].[MovieDeliveryMethods] md ON s.MovieDeliveryMethodsId=md.Id
--JOIN [dbo].[DeliveryMethods] d ON d.Id=md.DeliveryMethodId
--JOIN [dbo].[Movies] m ON md.MovieId=m.Id
--WHERE s.Id = @sessionId)

--SELECT @sessionDateTime = SessionDateTime, @premiere = Premiere, @deliveryMethodName = DeliveryMethodName FROM Price_CTE

--DECLARE @dayTimePayRate float, @ageRate float = 1.0, @deliveryRate float;
---- Calculating rate for session it depends on a day of the time. 
--DECLARE @dayTime time = CONVERT(TIME, @sessionDateTime, 114);
--IF  @dayTime > '18:00:00.000'
--	BEGIN  
--SET @dayTimePayRate = 1.1 
--	END   
--ELSE   
--	BEGIN    
--SET @dayTimePayRate = 1.0
--	END  
---- Calculating rate for premiere. 
--DECLARE @counter int = 30, @dayDiff int = DATEDIFF(DAY, @premiere, GETDATE());
--  WHILE @counter > @dayDiff  
--BEGIN	
--	SET @ageRate = @ageRate + 0.02
--	SET @dayDiff = @dayDiff + 1
--END
---- Calculating rate for delivery method(2D or 3D). 
--IF @deliveryMethodName = '3D'
--	BEGIN  
--SET @deliveryRate = 1.2 
--	END   
--ELSE IF @deliveryMethodName = '2D'  
--	BEGIN    
--SET @deliveryRate = 1.0
--	END  
---- Calculating price for ticket. 
--SET @ticketPrice = @cost*@dayTimePayRate*@ageRate*@deliveryRate
---- Returning results.
--RETURN @ticketPrice;   
--	END  
--GO

--IF OBJECTPROPERTY (OBJECT_ID(N'[dbo].[Calculate_Price]'),'IsDeterministic') = 1
--   PRINT 'Function is detrministic.'
--ELSE IF OBJECTPROPERTY (OBJECT_ID(N'[dbo].[Calculate_Price]'),'IsDeterministic') = 0
--   PRINT 'Function is NOT detrministic'
--GO

----------------------------- VERSION 2 --------------------------------------

--CREATE FUNCTION Calculate_Price(@sessionId int, @seatId int, @cost float)  
--	RETURNS float
--	WITH SCHEMABINDING   
--AS   
--	BEGIN  

--DECLARE @ticketPrice float, @deliveryMethodName nvarchar(10);
--DECLARE @tableVar table([Row] int, [Id] int);

--;WITH Format_CTE
--AS
--(SELECT d.DeliveryMethodName FROM [dbo].[Sessions] s
--JOIN [dbo].[MovieDeliveryMethods] md ON s.MovieDeliveryMethodsId=md.Id
--JOIN [dbo].[DeliveryMethods] d ON d.Id=md.DeliveryMethodId
--WHERE s.Id = @sessionId)

--SELECT @deliveryMethodName = DeliveryMethodName FROM Format_CTE

--;WITH Seats_CTE
--AS
--(SELECT s.[Id], s.[Row] FROM [dbo].[Seats] s
--JOIN [dbo].[CinemaHalls] c ON c.Id=s.HallId
--WHERE s.Id = (SELECT TOP(1) [HallId] FROM [dbo].[Seats] WHERE Id = @seatId))

--INSERT INTO @tableVar 
--SELECT TOP 50 PERCENT [Row], [Id] FROM (SELECT TOP 70 PERCENT [Row], [Id] FROM Seats_CTE) t 
--ORDER BY t.[Row] DESC

--DECLARE @deliveryRate float, @seatRate float;
---- Calculating rate for seat in the hall. 
--IF @seatId IN (SELECT [Id] FROM @tableVar)
--	BEGIN
--SET @seatRate = 1.25
--	END
--ELSE
--	BEGIN
--SET @seatRate = 1.0
--	END
---- Calculating rate for delivery method(2D or 3D). 
--IF @deliveryMethodName = '3D'
--	BEGIN  
--SET @deliveryRate = 1.25
--	END   
--ELSE IF @deliveryMethodName = '2D'  
--	BEGIN    
--SET @deliveryRate = 1.0
--	END  
---- Calculating price for ticket. 
--SET @ticketPrice = @cost*@seatRate*@deliveryRate
---- Returning results.
--RETURN @ticketPrice;   
--	END  
--GO