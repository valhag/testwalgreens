CREATE TABLE [dbo].[STG_TV_Writer] (
    [row_number]  INT            NULL,
    [media]       VARCHAR (500)  NULL,
    [product]     VARCHAR (500)  NULL,
    [estimate]    VARCHAR (500)  NULL,
    [month]       VARCHAR (500)  NULL,
    [billable]    VARCHAR (500)  NULL,
    [filename]    NVARCHAR (MAX) NULL,
    [directory]   NVARCHAR (500) NULL,
    [dt_created]  DATETIME       NULL,
    [dt_updated]  DATETIME       NULL,
    [dt_filename] NVARCHAR (255) NULL
);


GO
CREATE NONCLUSTERED INDEX [ix_STG_TV_Writer_dt_filename]
    ON [dbo].[STG_TV_Writer]([dt_filename] ASC);

