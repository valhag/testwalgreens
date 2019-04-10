CREATE TABLE [dbo].[ftp_265] (
    [dt_created]              DATETIME       NULL,
    [dt_updated]              DATETIME       NULL,
    [dt_filename]             NVARCHAR (255) NULL,
    [wag_forecast_initiative] NVARCHAR (500) NULL,
    [octlong]                 BIGINT         NULL,
    [octstring]               NVARCHAR (50)  NULL
);


GO
CREATE NONCLUSTERED INDEX [ix_ftp_265_dt_filename]
    ON [dbo].[ftp_265]([dt_filename] ASC);

