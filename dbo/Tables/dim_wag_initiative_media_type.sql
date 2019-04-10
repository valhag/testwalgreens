CREATE TABLE [dbo].[dim_wag_initiative_media_type] (
    [id]            INT            IDENTITY (1, 1) NOT NULL,
    [id_media_type] INT            NULL,
    [id_initiative] NVARCHAR (100) NULL,
    [id_dim_date]   INT            NULL,
    [executionid]   BIGINT         NULL,
    [FiscalYear]    INT            NULL,
    CONSTRAINT [PK_dim_wag_initiative_media_type] PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [UQ_media_type_initiative] UNIQUE NONCLUSTERED ([id_media_type] ASC, [id_initiative] ASC, [id_dim_date] ASC, [FiscalYear] ASC)
);

