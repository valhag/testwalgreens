CREATE TABLE [dbo].[STG_Writer_Digital] (
    [row_number]           INT            NULL,
    [client]               VARCHAR (500)  NULL,
    [gl_code]              VARCHAR (500)  NULL,
    [media_type]           VARCHAR (500)  NULL,
    [product_code]         VARCHAR (500)  NULL,
    [estimate]             VARCHAR (500)  NULL,
    [site]                 VARCHAR (500)  NULL,
    [month_of_service]     VARCHAR (500)  NULL,
    [prisma_net_rate]      VARCHAR (500)  NULL,
    [billed_to_the_client] VARCHAR (500)  NULL,
    [payable]              VARCHAR (500)  NULL,
    [paid_to_the_site]     VARCHAR (500)  NULL,
    [billable]             VARCHAR (500)  NULL,
    [okay_to_pay_status]   VARCHAR (500)  NULL,
    [filename]             NVARCHAR (MAX) NULL,
    [directory]            NVARCHAR (500) NULL,
    [dt_created]           DATETIME       NULL,
    [dt_updated]           DATETIME       NULL,
    [dt_filename]          NVARCHAR (255) NULL
);


GO
CREATE NONCLUSTERED INDEX [ix_STG_Writer_Digital_dt_filename]
    ON [dbo].[STG_Writer_Digital]([dt_filename] ASC);

