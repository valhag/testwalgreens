--	stored procedure name: usp_generate_master_tracker_match
--	description: usp that generates (insert/update) data of dim_wag_initiative_media_type (where relationship between initiatives and media types are located)
--	parameters: @ExecutionID: execution id from execution log table
--               @CURRENTYEAR : processing current year 
--               @CURRENTMONTH: processing current month
--	author: HVA
--	Date Creation: 20/11/2018

--	drop PROC usp_generate_master_tracker_match

CREATE PROC usp_generate_master_tracker_match (
	@ExecutionID BIGINT
    ,@CURRENTYEAR INT
    ,@CURRENTMONTH INT) 
AS
BEGIN


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


	-- @FY is a variable to save the fiscal year where the combination media type - initiative apply
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


	DECLARE @ID_DIM_DATE AS INT

	SELECT 
		@ID_DIM_DATE = id_dim_date
	FROM 
		dim_date
	WHERE month = @CURRENTMONTH
		 AND year = @CURRENTYEAR


	-- change of month 
	--     INSERT INTO dim_wag_initiative_media_type (id_media_type,id_initiative,id_dim_date,executionid,FiscalYear)
	--	SELECT
	--		id_media_type
	--	    ,id_initiative
	--	    ,@ID_DIM_DATE
	--	    ,@ExecutionID
	--	    ,@FY
	--	FROM
	--		dim_wag_initiative_media_type AS dw1
	--	WHERE id_dim_date = @ID_DIM_DATE - 1 and FiscalYear = @FY
	--		 AND NOT EXISTS
	--					 (
	--					  SELECT
	--						  1
	--					  FROM
	--						  dim_wag_initiative_media_type AS dw2
	--					  WHERE id_dim_date = @ID_DIM_DATE
	--						   AND dw1.id_initiative = dw2.id_initiative
	--						   AND dw1.id_media_type = dw2.id_media_type
	--					 )



	-- dim_wag_initiative_media_type_history will save every previous data on the media type - initiative table used for restore previous values in case you realize there is an error on master tracker match file
	INSERT INTO dim_wag_initiative_media_type_history
	SELECT 
		dm.id AS id_media_type
	    ,di.id AS id_initiative
	    ,@ID_DIM_DATE AS id_dim_date
	    ,d.executionid
	    ,d.FiscalYear
	    ,@ExecutionID
	FROM 
		dim_wag_initiative_media_type AS d
		JOIN dim_media_type AS dm
			ON dm.id = d.id_media_type
		JOIN dim_initiative AS di
			ON di.id = d.id_initiative
		JOIN dim_wag_forecast_initiative AS dwi
			ON dwi.id = di.id_wag_forecast_initiative
	WHERE d.id_dim_date = @ID_DIM_DATE
		 AND CHARINDEX('ExtWag',di.initiative_name) = 0
		 AND NOT EXISTS
					 (
					  SELECT 
						  1
					  FROM 
						  STG_Master_Tracker_Match AS stg
					  WHERE stg.wag_forecast_initiative = dwi.wag_forecast_initiative
						   AND stg.initiative = di.initiative_name
						   AND stg.media_types = dm.media_type
					 )


	-- delete on same month rows in case not exist on an update month master tracker match   
	DELETE FROM dim_wag_initiative_media_type
	WHERE 
		id IN
			 (
			  SELECT 
				  dwi.id-- di.initiative_name, dm.media_type 
			  FROM 
				  dim_wag_initiative_media_type AS dwi
				  JOIN dim_initiative AS di
					  ON di.id = dwi.id_initiative
				  JOIN dim_media_type AS dm
					  ON dm.id = dwi.id_media_type
						AND NOT EXISTS
									(
									 SELECT 
										 1
									 FROM 
										 STG_Master_Tracker_Match
									 WHERE initiative = di.initiative_name
										  AND media_types = dm.media_type
									)
			  WHERE CHARINDEX('ExtWag',UPPER(di.initiative_name)) = 0
				   AND dwi.id_dim_date = @ID_DIM_DATE
			 ) 


	-- save data on dim_wag_initiative_media_type 
	MERGE dim_wag_initiative_media_type AS target
	USING
		 (
		  SELECT 
			  dm.id AS id_media_type
			 ,di.id AS id_initiative
			 ,
			   (
			    SELECT 
				    id_dim_date
			    FROM 
				    dim_date
			    WHERE year = @CURRENTYEAR
					AND month = @CURRENTMONTH
			   ) AS id_dim_date
			 ,@ExecutionID AS executionid
			 ,@FY AS fiscalyear
		  FROM 
			  STG_Master_Tracker_Match AS mtm
			  JOIN dim_wag_forecast_initiative AS dw
				  ON dw.wag_forecast_initiative = mtm.wag_forecast_initiative
					AND dw.lawson = mtm.lawson
			  JOIN dim_initiative AS di
				  ON mtm.initiative = di.initiative_name
					AND di.id_wag_forecast_initiative = dw.id
			  JOIN dim_media_type AS dm
				  ON mtm.media_lawson_lawson_code_part_2 = dm.media_lawson
					AND mtm.media_types = dm.media_type
		 ) AS source
		 ON source.id_media_type = target.id_media_type
		    AND source.id_initiative = target.id_initiative
		    AND source.id_dim_date = target.id_dim_date
		WHEN NOT MATCHED
		 THEN
		 INSERT(
		id_media_type
	    ,id_initiative
	    ,id_dim_date
	    ,executionid
	    ,fiscalyear)
		 VALUES (
			   source.id_media_type
			  ,source.id_initiative
			  ,source.id_dim_date
			  ,source.executionid
			  ,source.fiscalyear);
	
	--********************************************** UPDATE SUCCESS EXECUTION LOG *************************************************************************************************

	EXEC usp_update_execution_log 
		@ExecutionID
	    ,'Success'
	    ,'Generate'
	    ,'Process finished successfully all steps.'
	--******************************************************************************************************************************************************************************/
END
