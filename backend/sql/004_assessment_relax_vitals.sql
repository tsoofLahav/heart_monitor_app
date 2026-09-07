-- Assessment relax-step vitals (PRE/POST step 12 analysis)
-- Run each batch separately in Azure Query editor if needed.

IF COL_LENGTH('dbo.Assessments', 'RelaxMeanHrBpm') IS NULL
BEGIN
    ALTER TABLE dbo.Assessments ADD RelaxMeanHrBpm FLOAT NULL;
END
GO

IF COL_LENGTH('dbo.Assessments', 'RelaxHrvRmssd') IS NULL
BEGIN
    ALTER TABLE dbo.Assessments ADD RelaxHrvRmssd FLOAT NULL;
END
GO

IF COL_LENGTH('dbo.Assessments', 'RelaxIbiCv') IS NULL
BEGIN
    ALTER TABLE dbo.Assessments ADD RelaxIbiCv FLOAT NULL;
END
GO

IF COL_LENGTH('dbo.Assessments', 'RelaxDurationSeconds') IS NULL
BEGIN
    ALTER TABLE dbo.Assessments ADD RelaxDurationSeconds FLOAT NULL;
END
GO

IF COL_LENGTH('dbo.Assessments', 'RelaxPeaksCount') IS NULL
BEGIN
    ALTER TABLE dbo.Assessments ADD RelaxPeaksCount INT NULL;
END
GO
