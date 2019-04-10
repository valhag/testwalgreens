CREATE TABLE [dbo].[STG_maf_match] (
    [row_number]                INT            NULL,
    [maf_initiative]            NVARCHAR (400) NOT NULL,
    [master_tracker_initiative] NVARCHAR (400) NOT NULL,
    [filename]                  NVARCHAR (500) NULL,
    [directory]                 NVARCHAR (500) NULL,
    [dt_created]                DATETIME       NULL,
    [dt_updated]                DATETIME       NULL,
    [dt_filename]               NVARCHAR (255) NULL
);


GO
CREATE NONCLUSTERED INDEX [ix_STG_maf_match_dt_filename]
    ON [dbo].[STG_maf_match]([dt_filename] ASC);

