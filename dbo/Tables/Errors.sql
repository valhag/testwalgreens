CREATE TABLE [dbo].[Errors] (
    [ExecutionID] BIGINT        NULL,
    [filename]    VARCHAR (500) NULL,
    [row]         VARCHAR (500) NULL,
    [message]     VARCHAR (500) NULL,
    [timestamp]   DATETIME      NULL,
    CONSTRAINT [FK_IdExecutionLog] FOREIGN KEY ([ExecutionID]) REFERENCES [dbo].[ExecutionLog] ([ExecutionID])
);

