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
[Description] nvarchar(250),
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
StandardEviation float NOT NULL,
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

CREATE TABLE [tbSessions]
(
Id int IDENTITY(1,1),
SessionDateTime datetime NOT NULL,
HallId int,
MovieDeliveryMethodsId int,
IsDeleted BIT NOT NULL CONSTRAINT DF_Sessions_IsDeleted DEFAULT ((0)),
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
StandardEviation float NOT NULL,
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
CONSTRAINT FK_TicketOrders_SessionId FOREIGN KEY (SessionId) REFERENCES [tbSessions](Id)
	ON DELETE SET DEFAULT
	ON UPDATE CASCADE,
CONSTRAINT FK_TicketOrders_SeatId FOREIGN KEY (SeatId) REFERENCES Seats(Id),
CONSTRAINT FK_TicketOrders_TicketStatusId FOREIGN KEY (TicketStatusId) REFERENCES TicketStatus(Id)
);
GO

----- View for soft delete -----
CREATE VIEW [Sessions]
WITH SCHEMABINDING
AS
	SELECT Id, SessionDateTime, HallId, MovieDeliveryMethodsId FROM [dbo].[tbSessions] s WHERE IsDeleted = 0
GO

CREATE UNIQUE CLUSTERED INDEX IX_CL_Sessions_Id
ON [Sessions]([Id])

CREATE NONCLUSTERED INDEX IX_CL_Sessions_SessionDateTime
ON [Sessions]([SessionDateTime])