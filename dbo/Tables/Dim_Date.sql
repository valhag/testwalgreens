CREATE TABLE [dbo].[Dim_Date] (
    [id_Dim_Date] INT      IDENTITY (1, 1) NOT NULL,
    [date]        DATETIME NULL,
    [month]       INT      NULL,
    [year]        INT      NULL,
    [version]     INT      NULL,
    PRIMARY KEY CLUSTERED ([id_Dim_Date] ASC)
);

