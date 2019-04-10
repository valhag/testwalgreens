-- DROP proc usp_create_match_new_month

CREATE PROC usp_create_match_new_month (
	@CURRENTMONTH INT
    ,@CURRENTYEAR INT) 
AS
BEGIN
	BEGIN

		DECLARE @ExecutionID BIGINT


		DECLARE @ID_DIM_DATE AS INT

		SELECT 
			@ID_DIM_DATE = id_dim_date
		FROM 
			dim_date
		WHERE month = @CURRENTMONTH
			 AND YEAR = @CURRENTYEAR

		EXEC usp_create_execution_log 
			'Automatic Process Generate Match'
		    ,'N/A'
		    ,@ID_DIM_DATE
		    ,@ExecutionID OUT-- Catching current ExecutionID


		DECLARE @YEARINI INT
		DECLARE @YEAREND INT
		DECLARE @FY AS INT

		IF @CURRENTMONTH >= 9
		BEGIN
			SET @YEARINI = @CURRENTYEAR
			SET @YEAREND = @CURRENTYEAR + 1
		END
			ELSE
		BEGIN
			SET @YEARINI = @CURRENTYEAR - 1
			SET @YEAREND = @CURRENTYEAR
		END;

		SELECT 
			@FY = MAX(year)
		FROM
			(
			 SELECT 
				 id_Dim_Date
				,year
			 FROM 
				 Dim_Date
			 WHERE year IN (@YEARINI)
				  AND month >= 9
				  AND year = @YEARINI
			 UNION
			 SELECT 
				 id_Dim_Date
				,year
			 FROM 
				 Dim_Date
			 WHERE year IN (@YEAREND)
				  AND month BETWEEN 1 AND 8
				  AND year = @YEAREND
			) AS y


		--following statement fills dim_writer_match if there is no current month rows, based on previous month rows, if there is no rows on FY process wont take previous month rows
		IF NOT EXISTS
				    (
					SELECT TOP 1 
						*
					FROM 
						dim_writer_match
					WHERE id_dim_date = @ID_DIM_DATE
				    ) 
		BEGIN
			INSERT INTO dim_writer_match(
				estimate
			    ,initiative
			    ,input_file
			    ,product
			    ,id_dim_date
			    ,ExecutionID)
			SELECT 
				estimate
			    ,initiative
			    ,input_file
			    ,product
			    ,@ID_DIM_DATE
			    ,@ExecutionID
			FROM 
				dim_writer_match
			WHERE id_dim_date = @ID_DIM_DATE - 1
		END


		--following statement fills dim_wag_initiative_media_type if there is no current month rows, based on previous month rows, if there is no rows on FY process wont take previous month rows
		IF NOT EXISTS
				    (
					SELECT TOP 1 
						*
					FROM 
						dim_wag_initiative_media_type
					WHERE id_dim_date = @ID_DIM_DATE
				    ) 
		BEGIN
			INSERT INTO dim_wag_initiative_media_type(
				id_initiative
			    ,id_media_type
			    ,id_dim_date
			    ,executionid
			    ,FiscalYear)
			SELECT 
				id_initiative
			    ,id_media_type
			    ,@ID_DIM_DATE
			    ,@ExecutionID
			    ,@FY
			FROM 
				dim_wag_initiative_media_type
			WHERE id_dim_date = @ID_DIM_DATE - 1
		END


		--following statement fills dim_maf_match if there is no current month rows, based on previous month rows, if there is no rows on FY process wont take previous month rows
		IF NOT EXISTS
				    (
					SELECT TOP 1 
						*
					FROM 
						dim_maf_match
					WHERE id_dim_date = @ID_DIM_DATE
				    ) 
		BEGIN
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
		END
			--END
	END


	EXEC usp_update_execution_log 
		@ExecutionID
	    ,'Success'
	    ,'Generate'
	    ,'Process finished successfully all steps.'
END