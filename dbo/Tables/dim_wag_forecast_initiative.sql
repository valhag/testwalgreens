CREATE TABLE [dbo].[dim_wag_forecast_initiative] (
    [id]                      INT             IDENTITY (1, 1) NOT NULL,
    [lawson]                  NVARCHAR (50)   NULL,
    [wag_forecast_initiative] NVARCHAR (1500) NULL,
    CONSTRAINT [PK_id_wag_forecast] PRIMARY KEY CLUSTERED ([id] ASC)
);

