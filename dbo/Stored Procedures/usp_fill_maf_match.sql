CREATE PROC usp_fill_maf_match (
    @CURRENTMONTH INT
    ,@CURRENTYEAR INT) 
as
begin 


    declare @ExecutionID BIGINT
    DECLARE @ID_DIM_DATE AS INT

	SELECT 
		@ID_DIM_DATE = id_dim_date
	FROM 
		dim_date
	WHERE month = @CURRENTMONTH
		 AND YEAR = @CURRENTYEAR

		 print @ID_DIM_DATE


		 EXEC usp_create_execution_log 
		'MAF Match Generation'
	    ,'N/A'
	    ,@ID_DIM_DATE
	    ,@ExecutionID OUT-- Catching current ExecutionID


    if not exists
    (select * from dim_maf_match
    where id_dim_date = @ID_DIM_DATE)
    begin
	   print @ID_DIM_DATE
	   INSERT INTO dim_maf_match(
			maf_initiative
		    ,master_tracker_initiative
		    ,id_dim_date
		    ,executionid)
		SELECT
			maf_initiative
		    ,master_tracker_initiative
		    ,@ID_DIM_DATE
		    ,@ExecutionID
		FROM
			dim_maf_match
		WHERE id_dim_date = @ID_DIM_DATE - 1
    end

    EXEC usp_update_execution_log 
		@ExecutionID
	    ,'Success'
	    ,'Generate'
	    ,'Process finished successfully all steps.'


end