--	stored procedure name: usp_validate_media_type
--	description: usp that generates data on dim_wag_initiative_media_type
--		  (where media types are saved)
--		  usp_create_execution_log call is to create a row in execution log and obtain @ExecutionId
--		  usp_update_execution_log call is to update (success or fail) the result of the execution
--	parameters: @ExecutionID unique identifier by execution, used to retrieve information of current execution and send it by email.
--				@Result  0 errors, 1 no errors
--				@FileName file name currently processed
--	returns 0 if there are errors call usp_update_execution_log to update error log
--			1 if there are not errors
--	author: HVA
--	Date Creation: 11/25/2018
--	Date modification: 01/22/2019 add id_date to link file and month/year for monthly log report
--	Date modification: 01/30/2019 add new validation to check duplicated media types 
--	Date Modification 02/15/2019 allowing . on filename 

--	drop PROC usp_validate_media_type


CREATE PROC usp_validate_media_type (
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
		SET @FileName = 'Media Type PROCESS NO ROWS'
		SET @Folder = 'Media Type  NO ROWS'

	END

	EXEC usp_create_execution_log 
		@FileName
	    ,@Folder
	    ,@ID_DATE
	    ,@ExecutionID OUT-- Catching current ExecutionID


	IF @FileName = 'Media Type PROCESS NO ROWS'
	BEGIN
		INSERT INTO ERRORS
		VALUES (
			  @ExecutionID
			 ,@FileName
			 ,1
			 ,'Media Type PROCESS NO ROWS'
			 ,GETDATE()) 
	END
	INSERT INTO Errors
	SELECT 
		@ExecutionID
	    ,filename
	    ,row_number
	    ,' On excel row ' + CONVERT(VARCHAR(10),row_number + 1) + ' the Lawson Code Part 2: ' + STR(media_lawson_lawson_code_part_2) +
	    ' is assigned to more than 1 Media Type. This row assigns it to  ' + media_types
	    ,GETDATE()
	FROM 
		STG_Master_Tracker_Match
	WHERE media_lawson_lawson_code_part_2 IN
									 (
									  SELECT DISTINCT 
										  media_lawson_lawson_code_part_2
									  FROM 
										  STG_Master_Tracker_Match
									  WHERE media_lawson_lawson_code_part_2 IN
																	   (
																	    SELECT 
																		    media_lawson_lawson_code_part_2
																	    FROM
																		    (
																			SELECT DISTINCT 
																				media_lawson_lawson_code_part_2
																			    ,media_types
																			FROM 
																				STG_Master_Tracker_Match
																		    ) AS v1
																	    GROUP BY 
																		    media_lawson_lawson_code_part_2
																	    HAVING COUNT(*) > 1
																	   )
									 ) 
	UNION
	SELECT @ExecutionID
		,filename
	    ,row_number
	    ,' On excel row ' + CONVERT(VARCHAR(10),row_number + 1) + ' the Media Type: ' + media_types +
	    ' is assigned to more than 1 Lawson Code Part 2. This row assigns it to ' + STR(media_lawson_lawson_code_part_2)
	    ,GETDATE()
	FROM 
		STG_Master_Tracker_Match
	WHERE media_types IN
					 (
					  SELECT DISTINCT 
						  media_types
					  FROM 
						  STG_Master_Tracker_Match
					  WHERE media_types IN
									   (
									    SELECT 
										    media_types
									    FROM
										    (
											SELECT DISTINCT 
												media_lawson_lawson_code_part_2
											    ,media_types
											FROM 
												STG_Master_Tracker_Match
										    ) AS v1
									    GROUP BY 
										    media_types
									    HAVING COUNT(*) > 1
									   )
					 ) 

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
END
