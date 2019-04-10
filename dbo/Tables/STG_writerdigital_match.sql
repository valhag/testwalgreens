CREATE TABLE [dbo].[STG_writerdigital_match] (
    [row_number]  INT            NULL,
    [input_file]  NVARCHAR (400) NULL,
    [estimate]    NVARCHAR (400) NULL,
    [product]     NVARCHAR (400) NULL,
    [initiative]  NVARCHAR (400) NULL,
    [filename]    NVARCHAR (MAX) NULL,
    [directory]   NVARCHAR (500) NULL,
    [dt_created]  DATETIME       NULL,
    [dt_updated]  DATETIME       NULL,
    [dt_filename] NVARCHAR (255) NULL
);


GO
CREATE NONCLUSTERED INDEX [ix_STG_writerdigital_match_dt_filename]
    ON [dbo].[STG_writerdigital_match]([dt_filename] ASC);

