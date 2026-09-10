-- Prep / profile / appreciations / session schedules
-- Run each batch separately in Azure Query editor if needed.

-- Participants: FirstName, LastName, Phone
IF COL_LENGTH('dbo.Participants', 'FirstName') IS NULL
BEGIN
    ALTER TABLE dbo.Participants ADD FirstName NVARCHAR(64) NULL;
END
GO

IF COL_LENGTH('dbo.Participants', 'LastName') IS NULL
BEGIN
    ALTER TABLE dbo.Participants ADD LastName NVARCHAR(64) NULL;
END
GO

IF COL_LENGTH('dbo.Participants', 'Phone') IS NULL
BEGIN
    ALTER TABLE dbo.Participants ADD Phone NVARCHAR(32) NULL;
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Appreciations')
BEGIN
    CREATE TABLE Appreciations (
        Id          INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        TrialId     INT           NOT NULL,
        Phase       NVARCHAR(16)  NOT NULL, -- 'before' | 'after'
        AnswersJson NVARCHAR(MAX) NOT NULL,
        CreatedAt   DATETIME2     NOT NULL CONSTRAINT DF_Appreciations_CreatedAt DEFAULT SYSUTCDATETIME(),
        UpdatedAt   DATETIME2     NOT NULL CONSTRAINT DF_Appreciations_UpdatedAt DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_Appreciations_Trials FOREIGN KEY (TrialId) REFERENCES Trials(Id),
        CONSTRAINT UQ_Appreciations_Trial_Phase UNIQUE (TrialId, Phase),
        CONSTRAINT CK_Appreciations_Phase CHECK (Phase IN (N'before', N'after'))
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'SessionSchedules')
BEGIN
    CREATE TABLE SessionSchedules (
        Id               INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        TrialId          INT           NOT NULL,
        TrailStep        INT           NOT NULL, -- 1..10
        ScheduledAtUtc   DATETIME2     NOT NULL,
        LocalWallTime    NVARCHAR(32)  NOT NULL, -- YYYY-MM-DDTHH:mm Asia/Jerusalem wall
        DurationMinutes  INT           NOT NULL,
        TimeZoneId       NVARCHAR(64)  NOT NULL CONSTRAINT DF_SessionSchedules_Tz DEFAULT N'Asia/Jerusalem',
        CreatedAt        DATETIME2     NOT NULL CONSTRAINT DF_SessionSchedules_CreatedAt DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_SessionSchedules_Trials FOREIGN KEY (TrialId) REFERENCES Trials(Id),
        CONSTRAINT UQ_SessionSchedules_Trial_Step UNIQUE (TrialId, TrailStep),
        CONSTRAINT CK_SessionSchedules_TrailStep CHECK (TrailStep >= 1 AND TrailStep <= 10),
        CONSTRAINT CK_SessionSchedules_Duration CHECK (DurationMinutes IN (2, 7))
    );
END
GO
