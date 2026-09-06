-- Experiment schema for Azure SQL
-- Participants / Trials / Assessments / Sessions

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Participants')
BEGIN
    CREATE TABLE Participants (
        Id              INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        ClientInstallId NVARCHAR(64)  NOT NULL,
        ParticipantCode NVARCHAR(32)  NOT NULL,
        Condition       NVARCHAR(16)  NOT NULL, -- 'real' | 'control' (server-only)
        Name            NVARCHAR(128) NULL,
        Age             INT           NULL,
        CreatedAt       DATETIME2     NOT NULL CONSTRAINT DF_Participants_CreatedAt DEFAULT SYSUTCDATETIME(),
        CONSTRAINT UQ_Participants_ClientInstallId UNIQUE (ClientInstallId),
        CONSTRAINT UQ_Participants_ParticipantCode UNIQUE (ParticipantCode),
        CONSTRAINT CK_Participants_Condition CHECK (Condition IN (N'real', N'control'))
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Trials')
BEGIN
    CREATE TABLE Trials (
        Id              INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        ParticipantId   INT           NOT NULL,
        Status          NVARCHAR(32)  NOT NULL CONSTRAINT DF_Trials_Status DEFAULT N'not_started',
        CurrentSession  INT           NOT NULL CONSTRAINT DF_Trials_CurrentSession DEFAULT 0,
        StartedAt       DATETIME2     NULL,
        CompletedAt     DATETIME2     NULL,
        CreatedAt       DATETIME2     NOT NULL CONSTRAINT DF_Trials_CreatedAt DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_Trials_Participants FOREIGN KEY (ParticipantId) REFERENCES Participants(Id),
        CONSTRAINT CK_Trials_Status CHECK (Status IN (
            N'not_started', N'pre_assessment', N'training', N'post_assessment', N'completed'
        )),
        CONSTRAINT CK_Trials_CurrentSession CHECK (CurrentSession >= 0 AND CurrentSession <= 8)
    );
    CREATE INDEX IX_Trials_ParticipantId ON Trials(ParticipantId);
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Assessments')
BEGIN
    CREATE TABLE Assessments (
        Id                  INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        TrialId             INT           NOT NULL,
        Phase               NVARCHAR(8)   NOT NULL, -- 'pre' | 'post'
        HeartbeatScore      FLOAT         NULL,
        QuestionnaireScore  FLOAT         NULL,
        CreatedAt           DATETIME2     NOT NULL CONSTRAINT DF_Assessments_CreatedAt DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_Assessments_Trials FOREIGN KEY (TrialId) REFERENCES Trials(Id),
        CONSTRAINT UQ_Assessments_Trial_Phase UNIQUE (TrialId, Phase),
        CONSTRAINT CK_Assessments_Phase CHECK (Phase IN (N'pre', N'post'))
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Sessions')
BEGIN
    CREATE TABLE Sessions (
        Id              INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        TrialId         INT           NOT NULL,
        SessionNumber   INT           NOT NULL,
        Score           FLOAT         NULL,
        Accuracy        FLOAT         NULL,
        AvgHeartRate    FLOAT         NULL,
        DurationSeconds FLOAT         NULL,
        StartedAt       DATETIME2     NULL,
        CompletedAt     DATETIME2     NULL,
        CONSTRAINT FK_Sessions_Trials FOREIGN KEY (TrialId) REFERENCES Trials(Id),
        CONSTRAINT UQ_Sessions_Trial_SessionNumber UNIQUE (TrialId, SessionNumber),
        CONSTRAINT CK_Sessions_SessionNumber CHECK (SessionNumber >= 1 AND SessionNumber <= 8)
    );
END
GO
