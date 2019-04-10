CREATE TABLE [dbo].[dim_writer_match] (
    [estimate]    NVARCHAR (500) NULL,
    [initiative]  NVARCHAR (500) NULL,
    [input_file]  NVARCHAR (500) NULL,
    [product]     NVARCHAR (500) NULL,
    [id_dim_date] INT            NULL,
    [executionid] BIGINT         NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_estimate]
    ON [dbo].[dim_writer_match]([estimate] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_product]
    ON [dbo].[dim_writer_match]([product] ASC);

