CREATE TABLE [dbo].[dim_initiative] (
    [id]                         INT            IDENTITY (1, 1) NOT NULL,
    [id_wag_forecast_initiative] INT            NULL,
    [initiative_name]            NVARCHAR (100) NULL,
    [puerto_rico_initiative_yn]  CHAR (1)       NULL,
    CONSTRAINT [PK_id_initiative] PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [FK_id_initiative_id_wag_forecast_] FOREIGN KEY ([id_wag_forecast_initiative]) REFERENCES [dbo].[dim_wag_forecast_initiative] ([id])
);


GO
CREATE NONCLUSTERED INDEX [IX_initiative_name]
    ON [dbo].[dim_initiative]([initiative_name] ASC);

