--Inserting data.
USE [Cinema]
GO

INSERT INTO [TicketStatus]
([Status])
VALUES
('free'),
('booked'),
('bought')
GO

INSERT INTO [Genres]
([GenreName], [GenreId])
VALUES
('Action',				NULL),
('Adventure',			NULL),
('Comedy',				NULL),
('Drama',				NULL),
('Horror',				NULL),
('Science Fiction',		NULL),
('Occult',				5),
('Slasher',				5),
('Tragicomedy',			3),
('Superhero Movie',		1),
('Political',			4),
('Time Travel',			6)
GO

INSERT INTO [Movies]
([MovieName], [Duration], [Description])
VALUES
('Avengers: ENDGAME',	'181',		'After the devastating events of Avengers: Infinity War (2018), the universe is in ruins. With the help of remaining allies, the Avengers assemble once more in order to undo Thanos actions and restore order to the universe.'),
('The Nun',				'96',		'A priest with a haunted past and a novice on the threshold of her final vows are sent by the Vatican to investigate the death of a young nun in Romania and confront a malevolent force in the form of a demonic nun.'),
('Predestination',		'97',		'For his final assignment, a top temporal agent must pursue the one criminal that has eluded him throughout time. The chase turns into a unique, surprising and mind-bending exploration of love, fate, identity and time travel taboos.'),
('Focus',				'105',		'In the midst of veteran con man Nickys latest scheme, a woman from his past - now an accomplished femme fatale - shows up and throws his plans for a loop.'),
('Darkest Hour',		'125',		'In May 1940, the fate of Western Europe hangs on British Prime Minister Winston Churchill, who must decide whether to negotiate with Adolf Hitler, or fight on knowing that it could mean a humiliating defeat for Britain and its empire.')
GO

INSERT INTO [MovieGenres]
([MovieId], [GenreId])
VALUES
(1,	1),
(1,	10),
(2,	5),
(2,	7),
(3,	6),
(3,	12),
(4,	3),
(4,	4),
(4,	9),
(5,	4),
(5,	11)
GO

INSERT INTO [DeliveryMethods]
([DeliveryMethodName])
VALUES
('2D'),
('3D')
GO

INSERT INTO [MovieDeliveryMethods]
([MovieId], [DeliveryMethodId])
VALUES
(1,	1),
(1,	2),
(2,	1),
(3,	1),
(3,	2),
(4,	1),
(5, 1)
GO

INSERT INTO [CinemaHalls]
([HallName], [SeatsNumber])
VALUES
('Alpha',	100),
('Beta',	70),
('Gamma',	50),
('Delta',	30)
GO

INSERT INTO [Sessions]
([SessionDateTime], [HallId], [MovieDeliveryMethodsId])
VALUES
('5/20/2019 12:00:00', 1, 1),
('5/20/2019 12:00:00', 2, 2),
('5/20/2019 12:00:00', 3, 3),
('5/20/2019 15:30:00', 4, 4),
('5/20/2019 16:00:00', 1, 5),
('5/20/2019 19:00:00', 2, 6),
('5/20/2019 21:00:00', 3, 7),
('5/24/2019 12:00:00', 1, 1),
('5/24/2019 12:00:00', 2, 2),
('5/24/2019 12:00:00', 3, 3),
('5/24/2019 15:30:00', 4, 4),
('5/24/2019 16:00:00', 1, 5),
('5/24/2019 19:00:00', 2, 6),
('5/24/2019 21:00:00', 3, 7)
GO

EXEC spInsertSeats @rows = 10, @seats = 10, @hallId = 1
EXEC spInsertSeats @rows = 7, @seats = 10, @hallId = 2
EXEC spInsertSeats @rows = 5, @seats = 10, @hallId = 3
EXEC spInsertSeats @rows = 3, @seats = 10, @hallId = 4

INSERT INTO [TicketOrders]
([Cost], [SeatId], [SessionId], [TicketStatusId])
VALUES
(50, 49,	1, 3),
(50, 52,	1, 2),
(50, 101,	2, 3),
(50, 175,	3, 1),
(50, 222,	4, 2),
(50, 235,	4, 3),
(50, 95,	1, 1),
(50, 34,	1, 2),
(50, 11,	5, 3),
(50, 2,		5, 2)
GO