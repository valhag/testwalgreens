CREATE TABLE [dbo].[dim_maf_match] (
    [maf_initiative]            NVARCHAR (500) NULL,
    [master_tracker_initiative] NVARCHAR (500) NULL,
    [id_dim_date]               INT            NULL,
    [executionid]               BIGINT         NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_maf_estimate]
    ON [dbo].[dim_maf_match]([maf_initiative] ASC);

