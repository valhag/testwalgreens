CREATE PROCEDURE dbo.usp_test
	@puerto_rico_initiative_yn CHAR(1)
    ,@CURRENTMONTH INT
    ,@CURRENTYEAR INT
    ,@programmatic varchar(100)
as

    --select * from Fact_Outcome
    --where id_type =  isnull(@programmatic,id_type)

    select * from dim_media_type
    where media_type  = isnull(@programmatic,media_type)
    
    