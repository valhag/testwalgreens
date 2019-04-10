CREATE TABLE [dbo].[Master_Tracker_Match_stg] (
    [initiative]                      NVARCHAR (500) NULL,
    [lawson]                          NVARCHAR (500) NULL,
    [media_lawson_lawson_code_part_2] NVARCHAR (500) NULL,
    [media_types]                     NVARCHAR (500) NULL,
    [puerto_rico_initiative]          NVARCHAR (500) NULL,
    [wag_forecast_initiative]         NVARCHAR (500) NULL,
    [dt_created]                      DATETIME       NULL,
    [dt_updated]                      DATETIME       NULL,
    [dt_filename]                     NVARCHAR (255) NULL,
    [puerto_rico_initiative_yn]       NVARCHAR (500) NULL
);


GO
CREATE NONCLUSTERED INDEX [ix_Master_Tracker_Match_stg_dt_filename]
    ON [dbo].[Master_Tracker_Match_stg]([dt_filename] ASC);

