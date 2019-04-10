CREATE TABLE [dbo].[dim_wag_initiative_media_type_history] (
    [id_media_type]       INT    NULL,
    [id_initiative]       INT    NULL,
    [id_dim_date]         INT    NULL,
    [executionid]         BIGINT NULL,
    [fiscalyear]          INT    NULL,
    [executionidprevious] BIGINT NULL
);

