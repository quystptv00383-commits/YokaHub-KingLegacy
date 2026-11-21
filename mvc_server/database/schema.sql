-- YokaHub MVC Database Schema (Microsoft SQL Server / T-SQL)
IF DB_ID(N'YokaHubDB') IS NULL
BEGIN
    CREATE DATABASE [YokaHubDB];
END
GO

USE [YokaHubDB];
GO

IF OBJECT_ID(N'dbo.BossServers', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.BossServers (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        PlaceId BIGINT NOT NULL,
        JobId NVARCHAR(64) NOT NULL,
        EventName NVARCHAR(120) NOT NULL,
        BossSource NVARCHAR(64) NOT NULL DEFAULT N'yoka_sql',
        HealthCurrent BIGINT NOT NULL DEFAULT 100,
        HealthMax BIGINT NOT NULL DEFAULT 100,
        HealthPercent INT NOT NULL DEFAULT 100,
        PlayersCurrent INT NOT NULL DEFAULT 1,
        PlayersMax INT NOT NULL DEFAULT 12,
        Alive BIT NOT NULL DEFAULT 1,
        ExecutorName NVARCHAR(64) NULL,
        ReportedBy NVARCHAR(64) NULL,
        DiscordNotified BIT NOT NULL DEFAULT 0,
        FirstSeenAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT UQ_BossServers_Place_Job_Event UNIQUE (PlaceId, JobId, EventName)
    );
    CREATE INDEX IX_BossServers_Alive_Updated ON dbo.BossServers (Alive, UpdatedAt DESC);
END
GO

IF OBJECT_ID(N'dbo.DropLogs', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DropLogs (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        PlayerName NVARCHAR(64) NOT NULL DEFAULT N'Unknown',
        ItemKey NVARCHAR(128) NOT NULL,
        ItemName NVARCHAR(128) NOT NULL,
        Category NVARCHAR(32) NOT NULL DEFAULT N'mat',
        DeltaCount INT NOT NULL DEFAULT 1,
        TotalCount INT NOT NULL DEFAULT 1,
        SeaPlaceId BIGINT NOT NULL DEFAULT 15759515082,
        JobId NVARCHAR(64) NULL,
        DroppedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
    CREATE INDEX IX_DropLogs_DroppedAt ON dbo.DropLogs (DroppedAt DESC);
END
GO

IF OBJECT_ID(N'dbo.HunterSessions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HunterSessions (
        PlayerName NVARCHAR(64) PRIMARY KEY,
        JobId NVARCHAR(64) NULL,
        PlaceId BIGINT NOT NULL DEFAULT 15759515082,
        Mode NVARCHAR(32) NOT NULL DEFAULT N'off',
        HopsCount INT NOT NULL DEFAULT 0,
        StartBeli BIGINT NOT NULL DEFAULT 0,
        CurrentBeli BIGINT NOT NULL DEFAULT 0,
        StartGems BIGINT NOT NULL DEFAULT 0,
        CurrentGems BIGINT NOT NULL DEFAULT 0,
        StartedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
END
GO

IF OBJECT_ID(N'dbo.HubConfigs', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HubConfigs (
        ConfigKey NVARCHAR(64) PRIMARY KEY,
        ConfigJson NVARCHAR(MAX) NOT NULL,
        UpdatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
END
GO

IF OBJECT_ID(N'dbo.LicenseKeys', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.LicenseKeys (
        KeyHash NVARCHAR(128) PRIMARY KEY,
        KeyTier NVARCHAR(32) NOT NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        Note NVARCHAR(256) NULL,
        UpdatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
END
GO
