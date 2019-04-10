--    stored procedure name: [usp_validate_wag_initiative]
--	description: usp that generates data on [usp_validate_wag_initiative]
--		  (where wag initiatives are saved)
--		  usp_create_execution_log call is to create a row in execution log and obtain @ExecutionId
--		  usp_update_execution_log call is to update (success or fail) the result of the execution
--	parameters: @ExecutionID unique identifier by execution, used to retrieve information of current execution and send it by email.
--				@Result  0 errors, 1 no errors
--				@FileName file name currently processed
--	returns 0 if there are errors call usp_update_execution_log to update error log
--			1 if there are not errors
--	author: HVA
--	Date Creation: 11/25/2018
--	Date Modification: 01/15/2019 add folder
--	Date modification: 01/22/2019 add id_date to link file and month/year for monthly log report
--	Date Modification 02/15/2019 allowing . on filename 
--   Date Modification 03/11/2019 error messages 

--	drop PROC [usp_validate_wag_initiative]

CREATE PROC dbo.usp_validate_wag_initiative (
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
		    ,@CURRENTMONTH =  CASE
						 WHEN SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 6,1) != 2 THEN SUBSTRING(FILENAME,CHARINDEX('.',FILENAME) - 6,2)
						 ELSE SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 2,2)
					 END
		FROM 
			STG_Master_Tracker_Match
		  select @ID_DATE = id_Dim_Date  from Dim_Date where month = @CURRENTMONTH and year = @CURRENTYEAR
	END
		ELSE
	BEGIN
		SET @FileName = 'Wag Initiative PROCESS NO ROWS'
		SET @Folder = 'Wag Initiative PROCESS NO ROWS'
		select @ID_DATE = id_Dim_Date  from Dim_Date where month = month(getdate()) and year = year(getdate())

	END

	EXEC usp_create_execution_log 
		@FileName
	    ,@Folder
	    ,@ID_DATE
	    ,@ExecutionID OUT-- Catching current ExecutionID


	IF @FileName = 'Wag Initiative PROCESS NO ROWS'
	BEGIN
		INSERT INTO ERRORS
		VALUES (
			  @ExecutionID
			 ,@FileName
			 ,1
			 ,'Wag Initiative PROCESS NO ROWS'
			 ,GETDATE()) 
	END

	INSERT INTO Errors
	SELECT 
		@ExecutionID
	    ,filename
	    ,row_number
	    ,' On excel row ' + CONVERT(VARCHAR(10),row_number + 1) + ' Initiative "' + wag_forecast_initiative +
	    '" is assigned to more than 1 Wag Forecast initiatives. This row assigns it to ' + STR(lawson)
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
	    ,row_number
	    ,' On row ' + CONVERT(VARCHAR(10),row_number + 1) + ', the Lawson Code Part 1: ' + STR(lawson) +
	    ' is assigned to more than 1 WAG Forecast Initiative. This row assigns it to ' + wag_forecast_initiative
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
