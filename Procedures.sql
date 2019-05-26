--Procedures.
USE [Cinema]
GO

CREATE PROCEDURE spInsertSeats(@rows int, @seats int, @hallId int)
AS
	IF EXISTS (SELECT * FROM [Seats] WHERE HallId = @hallId)
		BEGIN
			RAISERROR('There are seats for the current HallId', 11, 1)
			RETURN
		END
	
	DECLARE @counterRow int = 0, @counterSeat int = 0;
	
	WHILE @rows > @counterRow
		BEGIN
		SET @counterRow = @counterRow + 1
		SET @counterSeat = 0
			WHILE @seats > @counterSeat
			BEGIN
			SET @counterSeat = @counterSeat + 1
					IF (@seats*0.2) <= @counterSeat AND @counterSeat <= (@seats*0.8) AND (@rows*0.2) <= @counterRow AND @counterRow <= (@rows*0.8)
					BEGIN  
						INSERT INTO [Seats] 
						([Row], [Seat], [HallId], [StandardEviation])
						VALUES (@counterRow, @counterSeat, @hallId,   1.25)
					END
				ELSE
					BEGIN  
						INSERT INTO [Seats] 
						([Row], [Seat], [HallId], [StandardEviation])
						VALUES (@counterRow, @counterSeat, @hallId, 1.0)
					END
			END
		END
GO

CREATE PROCEDURE spInsertDataInTicketOrders(@sessionId int, @cost float)
AS
	IF EXISTS (SELECT * FROM [TicketOrders] WHERE SessionId = @sessionId)
		BEGIN
			RAISERROR('There are data for the current SessionId', 11, 1)
			RETURN
		END
	
		DECLARE @ticketStatusId int;
		SET @ticketStatusId = (SELECT TOP(1) Id FROM TicketStatus WHERE [Status] = 'free')
	
		;WITH Data_CTE
		AS
		(
			SELECT ss.Id AS SessionId, s.Id AS SeatId, Cost = @cost, TicketStatusId = @ticketStatusId FROM [Sessions] ss
				JOIN [CinemaHalls] ch ON ch.Id = ss.HallId
				JOIN [Seats] s ON s.HallId = ch.Id
				WHERE ss.Id = @sessionId
		)
	
		INSERT INTO [TicketOrders] (SessionId, SeatId, Cost, TicketStatusId)
		SELECT Data_CTE.SessionId, Data_CTE.SeatId, Data_CTE.Cost, Data_CTE.TicketStatusId FROM Data_CTE
GO

CREATE PROCEDURE spCreateTicketRequest(@seatId int, @sessionId int, @statusId int)
AS
	BEGIN TRANSACTION trans1 SET TRANSACTION ISOLATION LEVEL SERIALIZABLE

	DECLARE @sessionExists bit, @seatExists bit, @statusExists bit;
	SET @sessionExists = IIF((SELECT COUNT(Id) FROM [Sessions] WHERE Id = @sessionId) = 1, 1, 0)
	SET @seatExists = IIF((SELECT COUNT(s.Id) FROM [Sessions] ss
							JOIN [CinemaHalls] c ON c.Id = ss.HallId
							JOIN [Seats] s ON s.HallId = c.Id WHERE s.Id = @seatId AND ss.Id = @sessionId) = 1, 1, 0)
	SET @statusExists = IIF((SELECT COUNT(Id) FROM [TicketStatus] WHERE Id = @statusId) = 1, 1, 0)

	IF (@sessionExists = 0 OR @seatExists = 0 OR @statusExists = 0)
		BEGIN
			RAISERROR('Arguments have not found', 11, 1)
			ROLLBACK TRANSACTION trans1
		END

	DECLARE @isNotBusy bit;
	SET @isNotBusy = IIF((SELECT COUNT(Id) FROM [TicketOrders] WHERE SessionId = @sessionId AND SeatId = @seatId AND TicketStatusId = 1) = 1, 0, 1)
	
	IF @isNotBusy != 1
		BEGIN
			RAISERROR('This seat was booked/bought', 11, 1)
			ROLLBACK TRANSACTION trans1
		END
	ELSE
		BEGIN
			UPDATE [TicketOrders]
			SET TicketStatusId = @statusId
			WHERE SessionId = @sessionId AND SeatId = @seatId
		END

	COMMIT TRANSACTION trans1
GO