CREATE TABLE [dbo].[ftp_267] (
    [dt_created]     DATETIME        NULL,
    [dt_updated]     DATETIME        NULL,
    [dt_filename]    NVARCHAR (255)  NULL,
    [filename]       NVARCHAR (MAX)  NULL,
    [row_number]     BIGINT          NULL,
    [janstring]      NVARCHAR (50)   NULL,
    [febstring]      NVARCHAR (50)   NOT NULL,
    [aprstring]      NVARCHAR (50)   NULL,
    [maystring]      NVARCHAR (50)   NULL,
    [junstring]      NVARCHAR (50)   NULL,
    [julstring]      NVARCHAR (50)   NULL,
    [augstring]      NVARCHAR (50)   NULL,
    [sepstring]      NVARCHAR (50)   NULL,
    [octstring]      NVARCHAR (50)   NULL,
    [novstring]      NVARCHAR (50)   NULL,
    [decstring]      NVARCHAR (50)   NOT NULL,
    [martring]       NUMERIC (13, 4) NULL,
    [wag_initiative] NVARCHAR (MAX)  NULL
);


GO
CREATE NONCLUSTERED INDEX [ix_ftp_267_dt_filename]
    ON [dbo].[ftp_267]([dt_filename] ASC);

