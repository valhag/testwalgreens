CREATE TABLE [dbo].[STG_MAF] (
    [row_number]   INT            NULL,
    [client_code]  NVARCHAR (500) NULL,
    [lawson]       NVARCHAR (500) NULL,
    [initiative]   NVARCHAR (500) NULL,
    [media_type]   NVARCHAR (500) NULL,
    [media_lawson] NVARCHAR (500) NULL,
    [annual_maf_]  NVARCHAR (500) NULL,
    [filename]     NVARCHAR (500) NULL,
    [directory]    NVARCHAR (500) NULL,
    [dt_created]   DATETIME       NULL,
    [dt_updated]   DATETIME       NULL,
    [dt_filename]  NVARCHAR (255) NULL
);


GO
CREATE NONCLUSTERED INDEX [ix_STG_MAF_dt_filename]
    ON [dbo].[STG_MAF]([dt_filename] ASC);

