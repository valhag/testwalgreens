CREATE TABLE [dbo].[dim_writer_match_history] (
    [estimate]            NVARCHAR (500) NULL,
    [initiative]          NVARCHAR (500) NULL,
    [input_file]          NVARCHAR (500) NULL,
    [product]             NVARCHAR (500) NULL,
    [id_dim_date]         INT            NULL,
    [executionid]         INT            NULL,
    [executionidprevious] INT            NULL
);

