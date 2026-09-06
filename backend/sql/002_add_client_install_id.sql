-- Align live Azure SQL with experiment API.
-- IMPORTANT: Keep the GO separators. SQL Server cannot ADD a column and
-- reference it in the same batch (causes "Invalid column name 'ClientInstallId'").

-- Batch 1: add nullable column
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.Participants')
      AND name = N'ClientInstallId'
)
BEGIN
    ALTER TABLE dbo.Participants
        ADD ClientInstallId NVARCHAR(64) NULL;
END
GO

-- Batch 2: backfill (column now exists)
IF EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.Participants')
      AND name = N'ClientInstallId'
)
BEGIN
    UPDATE dbo.Participants
    SET ClientInstallId = CONCAT(N'legacy-', CAST(Id AS NVARCHAR(32)))
    WHERE ClientInstallId IS NULL;
END
GO

-- Batch 3: enforce NOT NULL
IF EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.Participants')
      AND name = N'ClientInstallId'
)
BEGIN
    ALTER TABLE dbo.Participants
        ALTER COLUMN ClientInstallId NVARCHAR(64) NOT NULL;
END
GO

-- Batch 4: unique constraint
IF EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.Participants')
      AND name = N'ClientInstallId'
)
AND NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'dbo.Participants')
      AND name = N'UQ_Participants_ClientInstallId'
)
BEGIN
    ALTER TABLE dbo.Participants
        ADD CONSTRAINT UQ_Participants_ClientInstallId UNIQUE (ClientInstallId);
END
GO

-- Verify
SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = N'Participants'
ORDER BY ORDINAL_POSITION;
