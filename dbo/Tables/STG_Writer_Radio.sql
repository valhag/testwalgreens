CREATE TABLE [dbo].[STG_Writer_Radio] (
    [row_number]       INT            NULL,
    [client]           VARCHAR (500)  NULL,
    [gl_code]          VARCHAR (500)  NULL,
    [media_type]       VARCHAR (500)  NULL,
    [product_code]     VARCHAR (500)  NULL,
    [estimate]         VARCHAR (500)  NULL,
    [month_of_service] VARCHAR (500)  NULL,
    [billable]         VARCHAR (500)  NULL,
    [filename]         NVARCHAR (MAX) NULL,
    [directory]        NVARCHAR (500) NULL,
    [dt_created]       DATETIME       NULL,
    [dt_updated]       DATETIME       NULL,
    [dt_filename]      NVARCHAR (255) NULL
);


GO
CREATE NONCLUSTERED INDEX [ix_STG_Writer_Radio_dt_filename]
    ON [dbo].[STG_Writer_Radio]([dt_filename] ASC);

