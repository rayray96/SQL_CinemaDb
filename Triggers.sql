--Triggers
USE [Cinema]
GO

CREATE TRIGGER trTicketOrders
	ON TicketOrders
	AFTER INSERT
AS
	IF @@ROWCOUNT = 0
		RETURN
	
	SET NOCOUNT ON
	
	UPDATE	t 
	SET		Price = ROUND(t.Cost * (d.StandardEviation + s.StandardEviation - 1), 0)
	FROM		 [dbo].[TicketOrders] t
			JOIN [dbo].[Sessions] ss ON ss.Id = t.SessionId
			JOIN [dbo].[MovieDeliveryMethods] md ON md.Id = ss.MovieDeliveryMethodsId 
			JOIN [dbo].[DeliveryMethods] d ON d.Id = md.DeliveryMethodId
			JOIN [dbo].[Seats] s ON s.Id = t.SeatId
			JOIN inserted i ON t.Id = i.Id
GO

CREATE TRIGGER trOnDeleteDataSessions
	ON [Sessions]
	INSTEAD OF DELETE
AS
	IF @@ROWCOUNT = 0
		RETURN

	SET NOCOUNT ON

	UPDATE	s
	SET		s.IsDeleted = 1
	FROM	[dbo].[tbSessions] s 
			JOIN deleted d ON d.Id = s.Id
GO