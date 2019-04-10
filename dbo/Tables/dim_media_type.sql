CREATE TABLE [dbo].[dim_media_type] (
    [id]           INT             IDENTITY (1, 1) NOT NULL,
    [media_lawson] NVARCHAR (50)   NULL,
    [media_type]   NVARCHAR (1500) NULL,
    CONSTRAINT [PK_id_media_type] PRIMARY KEY CLUSTERED ([id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_media_type]
    ON [dbo].[dim_media_type]([media_type] ASC);

