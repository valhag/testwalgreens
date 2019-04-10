CREATE TABLE [dbo].[STG_WAG_Adjustment] (
    [row_number]                      INT             NULL,
    [initiative]                      NVARCHAR (500)  NULL,
    [media_lawson_lawson_code_part_2] NVARCHAR (500)  NULL,
    [wag_adjustment]                  NVARCHAR (500)  NULL,
    [filename]                        NVARCHAR (500)  NULL,
    [directory]                       NVARCHAR (500)  NULL,
    [dt_created]                      DATETIME        NULL,
    [dt_updated]                      DATETIME        NULL,
    [dt_filename]                     NVARCHAR (255)  NULL,
    [wag_adjustment1]                 NUMERIC (13, 4) NULL
);


GO
CREATE NONCLUSTERED INDEX [ix_STG_WAG_Adjustment_dt_filename]
    ON [dbo].[STG_WAG_Adjustment]([dt_filename] ASC);

