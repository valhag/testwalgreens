CREATE TABLE [dbo].[STG_Master_Tracker_Match] (
    [row_number]                      INT            NULL,
    [initiative]                      NVARCHAR (500) NULL,
    [lawson]                          NVARCHAR (500) NULL,
    [media_lawson_lawson_code_part_2] NVARCHAR (500) NULL,
    [media_types]                     NVARCHAR (500) NULL,
    [puerto_rico_initiative_yn]       NVARCHAR (500) NULL,
    [wag_forecast_initiative]         NVARCHAR (500) NULL,
    [filename]                        NVARCHAR (MAX) NULL,
    [directory]                       NVARCHAR (500) NULL,
    [dt_created]                      DATETIME       NULL,
    [dt_updated]                      DATETIME       NULL,
    [dt_filename]                     NVARCHAR (255) NULL
);


GO
CREATE NONCLUSTERED INDEX [ix_STG_Master_Tracker_Match_dt_filename]
    ON [dbo].[STG_Master_Tracker_Match]([dt_filename] ASC);

