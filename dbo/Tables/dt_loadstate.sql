CREATE TABLE [dbo].[dt_loadstate] (
    [datastream_id]    BIGINT         NULL,
    [datastream_name]  VARCHAR (255)  NULL,
    [datastream_url]   VARCHAR (1024) NULL,
    [extract_filename] VARCHAR (1024) NULL,
    [range_start]      DATETIME       NULL,
    [range_end]        DATETIME       NULL,
    [uuid]             VARCHAR (64)   NULL,
    [load_state]       VARCHAR (20)   NULL,
    [load_start]       DATETIME       NULL,
    [load_end]         DATETIME       NULL
);

