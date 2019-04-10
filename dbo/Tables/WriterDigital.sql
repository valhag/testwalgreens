CREATE TABLE [dbo].[WriterDigital] (
    [dt_created]           DATETIME        NULL,
    [dt_updated]           DATETIME        NULL,
    [dt_filename]          NVARCHAR (255)  NULL,
    [billable]             NUMERIC (13, 4) NULL,
    [billed_to_the_client] NUMERIC (13, 4) NULL,
    [client]               NVARCHAR (200)  NOT NULL,
    [estimate]             NVARCHAR (200)  NOT NULL,
    [gl_code]              NVARCHAR (200)  NOT NULL,
    [media_type]           NVARCHAR (200)  NOT NULL,
    [month_of_service]     NVARCHAR (200)  NOT NULL,
    [okay_to_pay_status]   BIT             NULL,
    [paid_to_the_site]     NUMERIC (13, 4) NULL,
    [payable]              NUMERIC (13, 4) NULL,
    [prisma_net_rate]      NUMERIC (13, 4) NULL,
    [product_code]         NVARCHAR (200)  NOT NULL,
    [site]                 NVARCHAR (200)  NOT NULL,
    PRIMARY KEY CLUSTERED ([client] ASC, [estimate] ASC, [gl_code] ASC, [media_type] ASC, [month_of_service] ASC, [product_code] ASC, [site] ASC),
    CHECK ([okay_to_pay_status]=(1) OR [okay_to_pay_status]=(0))
);


GO
CREATE NONCLUSTERED INDEX [ix_WriterDigital_dt_filename]
    ON [dbo].[WriterDigital]([dt_filename] ASC);

