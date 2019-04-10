--	stored procedure name: usp_validate_master_tracker_match
--	description: usp that generates data on dim_wag_initiative_media_type
--		  (where the relationships between initiatives and media types are saved)
--		  usp_create_execution_log call is to create a row in execution log and obtain @ExecutionId
--		  usp_update_execution_log call is to update (success or fail) the result of the execution
--	parameters: @ExecutionID unique identifier by execution, used to retrieve information of current execution and send it by email.
--				@Result  0 errors, 1 no errors
--				@FileName file name currently processed
--	returns 0 if there are errors call usp_update_execution_log to update error log
--			1 if there are not errors
--	author: HVA
--	Date Creation: 11/25/2018

--	drop PROC [usp_validate_master_tracker_match]

CREATE PROC usp_validate_master_tracker_match (
	@ExecutionID BIGINT OUTPUT
    ,@Result BIT OUTPUT
    ,@FileName VARCHAR(1000) OUTPUT
    ,@CURRENTYEAR INT OUTPUT
    ,@CURRENTMONTH INT OUTPUT) 
AS
BEGIN

	DECLARE @Folder AS VARCHAR(100)
	DECLARE @ID_DATE AS INT


	-- validation to check if there are rows on STG_Master_Tracker_Match if not adverity does not load any data and an error is retrieved
	IF EXISTS
			(
			 SELECT 
				 1
			 FROM 
				 STG_Master_Tracker_Match
			) 
	BEGIN
		SELECT TOP 1 
			@FileName = filename
		    ,@Folder = directory
		    ,@CURRENTYEAR = CASE
							WHEN SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 6,1) = 2 THEN SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 6,4)
							ELSE SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 4,4)
						END
		    ,@CURRENTMONTH = CASE
							 WHEN SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 6,1) != 2 THEN SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 6,2)
							 ELSE SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 2,2)
						 END
		FROM 
			STG_Master_Tracker_Match
		SELECT 
			@ID_DATE = id_Dim_Date
		FROM 
			Dim_Date
		WHERE month = @CURRENTMONTH
			 AND year = @CURRENTYEAR
	END
		ELSE
	BEGIN
		SELECT 
			@ID_DATE = id_Dim_Date
		FROM 
			Dim_Date
		WHERE month = MONTH(GETDATE())
			 AND year = YEAR(GETDATE())
		SET @FileName = 'Initiative-Media Type PROCESS NO ROWS'
		SET @Folder = 'Initiative-Media Type  NO ROWS'

	END


	-- usp_create_execution_log generates a row on executionlog table to monitor the process
	EXEC usp_create_execution_log 
		@FileName
	    ,@Folder
	    ,@ID_DATE
	    ,@ExecutionID OUT-- Catching current ExecutionID


	IF @FileName = 'Initiative-Media Type PROCESS NO ROWS'
	BEGIN
		INSERT INTO ERRORS
		VALUES (
			  @ExecutionID
			 ,@FileName
			 ,1
			 ,'Initiative-Media Type PROCESS NO ROWS'
			 ,GETDATE()) 
	END

	-- if there are errors email is sent
	INSERT INTO Errors
	SELECT 
		@ExecutionID
	    ,filename
	    ,row_number + 1
	    ,' On excel row; ' + CONVERT(VARCHAR(10),row_number + 1) + ' combination initiative "' + sw.initiative +
	    '" & media type "' + sw.media_types + '" is duplicated, remove duplicated rows '
	    ,GETDATE()
	    from STG_Master_Tracker_Match sw
	    join 

	    (
	    SELECT 
	initiative
    ,media_types
FROM 
	STG_Master_Tracker_Match
GROUP BY 
	initiative
    ,media_types
HAVING COUNT(*) > 1
	) as t on t.initiative = sw.initiative and t.media_types = sw.media_types
	UNION
	SELECT 
		@ExecutionID
	    ,filename
	    ,row_number + 1
	    ,' On excel row; ' + CONVERT(VARCHAR(10),row_number + 1) + ' initiative "' + wag_forecast_initiative +
	    '" is assigned to more than 1 WAG Forecast Initiative. This row assigns it to "' + lawson + '"'
	    ,GETDATE()
	FROM 
		STG_Master_Tracker_Match
	WHERE wag_forecast_initiative IN
							   (
							    SELECT 
								    v1.wag_forecast_initiative
							    FROM
								    (
									SELECT DISTINCT 
										lawson
									    ,wag_forecast_initiative
									FROM 
										STG_Master_Tracker_Match
								    ) AS v1
							    GROUP BY 
								    wag_forecast_initiative
							    HAVING COUNT(*) > 1
							   ) 
	UNION
	SELECT 
		@ExecutionID
	    ,filename
	    ,row_number + 1
	    ,' On excel row ' + CONVERT(VARCHAR(10),row_number + 1) + '; the lawson code part 1: "' + lawson +
	    '" is assigned to more than 1 WAG Forecast Initiative. This row assigns it to "' + wag_forecast_initiative + '"'
	    ,GETDATE()
	FROM 
		STG_Master_Tracker_Match
	WHERE lawson IN
				 (
				  SELECT 
					  v2.lawson
				  FROM
					  (
					   SELECT DISTINCT 
						   lawson
						  ,wag_forecast_initiative
					   FROM 
						   STG_Master_Tracker_Match
					  ) AS v2
				  GROUP BY 
					  lawson
				  HAVING COUNT(*) > 1
				 )
	--ORDER BY 
	--	row_number

	IF EXISTS
			(
			 SELECT 
				 *
			 FROM 
				 Errors
			 WHERE ExecutionID = @ExecutionID
			) 
	BEGIN
		  -- executionlog table is updated with error and powershell script will take this @executionid to sent email.
		EXEC usp_update_execution_log 
			@ExecutionID
		    ,'Failed'
		    ,'Validation'
		    ,'Process failed on validation step.'
		SET @Result = 0
		RETURN
	END
		ELSE
	BEGIN
		SET @Result = 1
		RETURN
	END

END
