CREATE TABLE [dbo].[ExecutionLog] (
    [ExecutionID] BIGINT         IDENTITY (1, 1) NOT NULL,
    [FileName]    VARCHAR (500)  NOT NULL,
    [StartTime]   DATETIME       NOT NULL,
    [EndTime]     DATETIME       NULL,
    [Status]      VARCHAR (50)   NOT NULL,
    [Step]        VARCHAR (50)   NOT NULL,
    [Message]     VARCHAR (1000) NULL,
    [Folder]      VARCHAR (1000) NULL,
    [Id_date]     INT            NULL,
    [id_type]     INT            NULL,
    CONSTRAINT [PK_ExecutionLog] PRIMARY KEY CLUSTERED ([ExecutionID] ASC)
);

