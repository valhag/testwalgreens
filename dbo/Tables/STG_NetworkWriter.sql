CREATE TABLE [dbo].[STG_NetworkWriter] (
    [row_number]       INT            NULL,
    [media]            VARCHAR (500)  NULL,
    [gl_code]          VARCHAR (500)  NULL,
    [product]          VARCHAR (500)  NULL,
    [estimate]         VARCHAR (500)  NULL,
    [month_of_service] VARCHAR (500)  NULL,
    [billable]         VARCHAR (500)  NULL,
    [filename]         NVARCHAR (500) NULL,
    [directory]        NVARCHAR (500) NULL,
    [dt_created]       DATETIME       NULL,
    [dt_updated]       DATETIME       NULL,
    [dt_filename]      NVARCHAR (255) NULL
);


GO
CREATE NONCLUSTERED INDEX [ix_STG_NetworkWriter_dt_filename]
    ON [dbo].[STG_NetworkWriter]([dt_filename] ASC);

