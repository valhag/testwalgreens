CREATE TABLE [dbo].[fact_outcome03252019] (
    [id_initiative]     INT   NOT NULL,
    [id_media_type]     INT   NOT NULL,
    [value]             MONEY NULL,
    [id_time]           INT   NOT NULL,
    [id_type]           INT   NOT NULL,
    [id_time_generated] INT   NULL,
    [id_Fact_Outcome]   INT   IDENTITY (1, 1) NOT NULL
);

