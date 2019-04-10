CREATE TABLE [dbo].[Fact_Outcome] (
    [id_initiative]     INT   NOT NULL,
    [id_media_type]     INT   NOT NULL,
    [value]             MONEY NULL,
    [id_time]           INT   NOT NULL,
    [id_type]           INT   NOT NULL,
    [id_time_generated] INT   NULL,
    [id_Fact_Outcome]   INT   IDENTITY (1, 1) NOT NULL,
    CONSTRAINT [PK_Id_fact_outcome] PRIMARY KEY CLUSTERED ([id_Fact_Outcome] ASC),
    CONSTRAINT [FK_id_initiative_id_initiative] FOREIGN KEY ([id_initiative]) REFERENCES [dbo].[dim_initiative] ([id]),
    CONSTRAINT [FK_id_initiative_id_media_type] FOREIGN KEY ([id_media_type]) REFERENCES [dbo].[dim_media_type] ([id]),
    CONSTRAINT [FK_Id_time] FOREIGN KEY ([id_time]) REFERENCES [dbo].[Dim_Date] ([id_Dim_Date]),
    CONSTRAINT [FK_Id_time_generated] FOREIGN KEY ([id_time_generated]) REFERENCES [dbo].[Dim_Date] ([id_Dim_Date]),
    CONSTRAINT [FK_Id_Type] FOREIGN KEY ([id_type]) REFERENCES [dbo].[dim_type] ([id]),
    CONSTRAINT [UQ_fact_outcome] UNIQUE NONCLUSTERED ([id_initiative] ASC, [id_media_type] ASC, [id_type] ASC, [id_time] ASC, [id_time_generated] ASC)
);

