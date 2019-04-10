CREATE TABLE [dbo].[Fact_Outcome_History] (
    [id_Fact_Outcome] INT   NULL,
    [value]           MONEY NULL,
    [executionid]     INT   NULL,
    CONSTRAINT [FK_Id_fact_outcome] FOREIGN KEY ([id_Fact_Outcome]) REFERENCES [dbo].[Fact_Outcome] ([id_Fact_Outcome])
);

