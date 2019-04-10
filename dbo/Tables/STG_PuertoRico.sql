CREATE TABLE [dbo].[STG_PuertoRico] (
    [row_number]             INT            NULL,
    [initiative]             NVARCHAR (500) NULL,
    [media_type]             NVARCHAR (500) NULL,
    [lawson]                 NVARCHAR (500) NULL,
    [media_lawson]           NVARCHAR (500) NULL,
    [sep_mediacom_register]  NVARCHAR (500) NULL,
    [oct_mediacom_register]  NVARCHAR (500) NULL,
    [nov_mediacom_register]  NVARCHAR (500) NULL,
    [dec_mediacom_register]  NVARCHAR (500) NULL,
    [jan_mediacom_register]  NVARCHAR (500) NULL,
    [feb_mediacom_register]  NVARCHAR (500) NULL,
    [mar_mediacom_register]  NVARCHAR (500) NULL,
    [apr_mediacom_register]  NVARCHAR (500) NULL,
    [may_mediacom_register]  NVARCHAR (500) NULL,
    [jun_mediacom_register]  NVARCHAR (500) NULL,
    [jul_mediacom_register]  NVARCHAR (500) NULL,
    [aug_mediacom_register]  NVARCHAR (500) NULL,
    [filename]               NVARCHAR (500) NULL,
    [directory]              NVARCHAR (500) NULL,
    [dt_created]             DATETIME       NULL,
    [dt_updated]             DATETIME       NULL,
    [dt_filename]            NVARCHAR (255) NULL,
    [july_mediacom_register] BIGINT         NULL,
    [june_mediacom_register] BIGINT         NULL,
    [sept_mediacom_register] BIGINT         NULL
);


GO
CREATE NONCLUSTERED INDEX [ix_STG_PuertoRico_dt_filename]
    ON [dbo].[STG_PuertoRico]([dt_filename] ASC);

