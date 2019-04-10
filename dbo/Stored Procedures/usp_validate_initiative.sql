--	stored procedure name: usp_validate_initiative
--	description: usp that validates bussiness rules to save or not data on dim_initiative (where the media types are saved), every validation process will call usp_create_execution_log to obtain a @ExecutionId
--			   usp_create_execution_log call is to create a row in execution log and obtain @ExecutionId
--			   usp_update_execution_log call is to update (success or fail) the result of the execution
--	parameters: @ExecutionID unique identifier by execution, used to retrieve information of current execution and send it by email.
--				@Result  0 errors, 1 no errors
--				@FileName file name currently processed
--	returns 0 if there are errors call usp_update_execution_log to update error log
--			1 if there are not errors
--	author: HVA
--	Date Creation: 11/25/2018
--	Date Modification: 01/15/2019 change error message
--	Date modification: 01/22/2019 add id_date to link file and month/year for monthly log report
--	Date Modification 02/15/2019 allowing . on filename 

--	drop PROC usp_validate_initiative

CREATE PROC usp_validate_initiative (
	@ExecutionID BIGINT OUTPUT
    ,@Result BIT OUTPUT
    ,@FileName VARCHAR(1000) OUTPUT
    ,@CURRENTYEAR INT OUTPUT
    ,@CURRENTMONTH INT OUTPUT) 
AS
BEGIN

	DECLARE @Folder AS VARCHAR(100)
	DECLARE @ID_DATE AS INT

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
							WHEN SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 6,1) = 2 THEN SUBSTRING(FILENAME,CHARINDEX('.',FILENAME) - 6,4)
							ELSE SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 4,4)
						END
		    ,@CURRENTMONTH = CASE
							 WHEN SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 6,1) != 2 THEN SUBSTRING(FILENAME,CHARINDEX('.',FILENAME) - 6,2)
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
		SET @FileName = 'Initiative PROCESS NO ROWS'
		SET @Folder = 'Initiative  NO ROWS'

	END

	EXEC usp_create_execution_log 
		@FileName
	    ,@Folder
	    ,@ID_DATE
	    ,@ExecutionID OUT-- Catching current ExecutionID


	IF @FileName = 'Initiative PROCESS NO ROWS'
	BEGIN
		INSERT INTO ERRORS
		VALUES (
			  @ExecutionID
			 ,@FileName
			 ,1
			 ,'Initiative  PROCESS NO ROWS'
			 ,GETDATE()) 
	END

	INSERT INTO Errors
	SELECT 
		@ExecutionID
	    ,filename
	    ,row_number
	    ,' On row ' + CONVERT(VARCHAR(10),row_number) + ', the initiative ' + initiative +
	    ' is assigned to more than one WAG Forecast Initiative. This row assigns it to  ' + wag_forecast_initiative
	    ,GETDATE()
	FROM 
		STG_Master_Tracker_Match
	WHERE initiative IN
					(
					 SELECT 
						 initiative
					 FROM
						 (
						  SELECT DISTINCT 
							  initiative
							 ,wag_forecast_initiative
						  FROM 
							  STG_Master_Tracker_Match
						 ) AS v1
					 GROUP BY 
						 initiative
					 HAVING COUNT(*) > 1
					)
	ORDER BY 
		row_number

	IF EXISTS
			(
			 SELECT 
				 *
			 FROM 
				 Errors
			 WHERE ExecutionID = @ExecutionID
			) 
	BEGIN
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

