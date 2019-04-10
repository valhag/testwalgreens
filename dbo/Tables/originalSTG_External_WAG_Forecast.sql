CREATE TABLE [dbo].[originalSTG_External_WAG_Forecast] (
    [row_number]     INT            NULL,
    [initiative]     NVARCHAR (500) NULL,
    [wag_initiative] NVARCHAR (500) NULL,
    [sepstring]      NVARCHAR (500) NULL,
    [octstring]      NVARCHAR (500) NULL,
    [novstring]      NVARCHAR (500) NULL,
    [decstring]      NVARCHAR (500) NULL,
    [janstring]      NVARCHAR (500) NULL,
    [febstring]      NVARCHAR (500) NULL,
    [martring]       NVARCHAR (500) NULL,
    [aprstring]      NVARCHAR (500) NULL,
    [maystring]      NVARCHAR (500) NULL,
    [junstring]      NVARCHAR (500) NULL,
    [julstring]      NVARCHAR (500) NULL,
    [augstring]      NVARCHAR (500) NULL,
    [filename]       NVARCHAR (500) NULL,
    [directory]      NVARCHAR (500) NULL,
    [dt_created]     DATETIME       NULL,
    [dt_updated]     DATETIME       NULL,
    [dt_filename]    NVARCHAR (255) NULL
);

