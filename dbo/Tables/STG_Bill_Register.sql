CREATE TABLE [dbo].[STG_Bill_Register] (
    [row_number]  INT            NULL,
    [client]      VARCHAR (500)  NULL,
    [gl_code]     VARCHAR (500)  NULL,
    [product]     VARCHAR (500)  NULL,
    [estimate]    VARCHAR (500)  NULL,
    [mos]         VARCHAR (500)  NULL,
    [actual_amnt] VARCHAR (500)  NULL,
    [filename]    NVARCHAR (MAX) NULL,
    [dt_created]  DATETIME       NULL,
    [dt_updated]  DATETIME       NULL,
    [dt_filename] NVARCHAR (255) NULL,
    [directory]   VARCHAR (1000) NULL
);

