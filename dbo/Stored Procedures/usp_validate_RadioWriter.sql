--	stored procedure name: usp_validate_RadioWriter
--	description: usp that validates data about Radio Writer file type
--		  usp_create_execution_log call is to create a row in execution log and obtain @ExecutionId
----		  usp_update_execution_log call is to update (success or fail) the result of the execution
--	parameters: @ExecutionID unique identifier by execution, used to retrieve information of current execution and send it by email.
--				@Result  0 errors, 1 no errors
--				@FileName file name currently processed
--	returns 0 if there are errors call usp_update_execution_log to update error log
--			1 if there are not errors
--	author: HVA
--	Date Creation: 11/25/2018
--	Date modification: 01/23/2019 add id_date to link file and month/year for monthly log report
--                                 change STG_writerdigital_match to dim_writer_match

--  Date modification: 01/24/2019 INCLUDE VALIDATION FOR INPUT_FILE FIELD
--  Date modification: 02/01/2019 error messages updates
--  Date modification: 02/13/2019 change stg correct table
--	Date Modification 02/15/2019 allowing . on filename 
--	Date Modification 02/20/2019 allowing . on filename 
--	Date Modification 02/20/2019 validate inputfile 
--	Date Modification 03/11/2019 error messages 

--	drop PROC [usp_validate_RadioWriter]


CREATE PROC dbo.usp_validate_RadioWriter (
	@ExecutionID BIGINT OUTPUT
    ,@Result BIT OUTPUT
    ,@FileName VARCHAR(1000) OUTPUT
    ,@CURRENTYEAR INT OUTPUT
    ,@CURRENTMONTH INT OUTPUT) 
AS
BEGIN
	DECLARE @Folder AS VARCHAR(100)
	DECLARE @ID_DATE AS INT

	DELETE FROM STG_Writer_Radio
	WHERE 
		gl_code IS NULL
		AND estimate IS NULL
		AND month_of_service IS NULL

	IF EXISTS
			(
			 SELECT 
				 1
			 FROM 
				 STG_Writer_Radio
			) 
	BEGIN
		SELECT TOP 1 
			@FileName = filename
		    ,@Folder = directory
		    ,@CURRENTYEAR = CASE
							WHEN SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 6,1) = 2 THEN SUBSTRING(FILENAME,CHARINDEX('.XLS',
							UPPER(FILENAME)) - 6,4)
							ELSE SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 4,4)
						END
		    ,@CURRENTMONTH = CASE
							 WHEN SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 6,1) != 2 THEN SUBSTRING(FILENAME,CHARINDEX('.XLS',
							 UPPER(FILENAME)) - 6,2)
							 ELSE SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 2,2)
						 END
		FROM 
			STG_Writer_Radio
		SELECT 
			@ID_DATE = id_Dim_Date
		FROM 
			Dim_Date
		WHERE month = @CURRENTMONTH
			 AND year = @CURRENTYEAR
	END
		ELSE
	BEGIN
		SET @FileName = 'Radio Writer PROCESS NO ROWS'
		SET @Folder = 'Radio Writer NO ROWS'
		SELECT 
			@ID_DATE = id_Dim_Date
		FROM 
			Dim_Date
		WHERE month = MONTH(GETDATE())
			 AND year = YEAR(GETDATE())
	END

	EXEC usp_create_execution_log 
		@FileName
	    ,@Folder
	    ,@ID_DATE
	    ,@ExecutionID OUT-- Catching current ExecutionID


	IF @FileName = 'Radio Writer PROCESS NO ROWS'
	BEGIN
		INSERT INTO ERRORS
		VALUES (
			  @ExecutionID
			 ,@FileName
			 ,1
			 ,'Radio Writer PROCESS NO ROWS'
			 ,GETDATE()) 
	END

	INSERT INTO dbo.Errors
	--SELECT
	--		@ExecutionID
	--	    ,@FileName
	--	    ,srw.row_number + 1
	--	    ,'On excel row ' + CONVERT(VARCHAR(10),srw.row_number + 1) +
	--	    '; estimate "' + srw.estimate + ' exist however input file is not must be Radio Writer, change writer match file, incorrect input file is ' + wdm.input_file
	--	    ,GETDATE()
	--	FROM
	--		dbo.STG_Writer_Radio AS srw
	--		INNER JOIN dbo.dim_writer_match AS wdm
	--			ON srw.estimate = wdm.estimate
	--			   AND wdm.input_file != 'Radio Writer'

	SELECT 
		@ExecutionID
	    ,@FileName
	    ,srw.row_number + 1
	    ,'On excel row ' + CONVERT(VARCHAR(10),srw.row_number + 1) + '; Estimate "' + srw.estimate + --' exist however input file is not must be Radio Writer, change writer match file, incorrect input file is ' + wdm.input_file
		' does not match with a existing entry under the Radio Writer section. It does match with an entry in the "' + wdm.input_file +
		'" section. Please add an entry to the Radio Writer section for this Estimate name.'
	    ,GETDATE()
	FROM 
		dbo.STG_Writer_Radio AS srw
		JOIN dbo.dim_writer_match AS wdm
			ON srw.estimate = wdm.estimate
			   AND wdm.input_file != 'Radio Writer'
			   AND wdm.id_dim_date = @ID_DATE
	WHERE SRW.row_number NOT IN
						   (
						    SELECT 
							    srw.row_number
						    FROM 
							    STG_Writer_Radio AS srw
							    JOIN dbo.dim_writer_match AS wdm
								    ON srw.estimate = wdm.estimate
									  AND wdm.input_file = 'Radio Writer'
									  AND wdm.id_dim_date = @ID_DATE
						   ) 
	UNION
	SELECT 
		@ExecutionID
	    ,@FileName
	    ,srw.row_number + 1
	    ,'On row ' + CONVERT(VARCHAR(10),srw.row_number + 1) + ' gl_code is not complete or does not have correct format or is empty'
	    ,GETDATE()
	FROM 
		dbo.STG_Writer_Radio AS srw
	WHERE LEN(srw.gl_code) <> 13
		 OR SUBSTRING(srw.gl_code,7,1) != '-' --OR gl_code IS NULL 

	UNION 

	--validation that veryfies the GL_code is not empty and that the estimate is not null. 
	SELECT 
		@ExecutionID
	    ,@FileName
	    ,srw.row_number + 1
	    ,'On row ' + CONVERT(VARCHAR(10),srw.row_number + 1) + '; estimate or gl_code are empty'
	    ,GETDATE()
	FROM 
		dbo.STG_Writer_Radio AS srw
	WHERE gl_code IS NULL
		 OR estimate IS NULL
	UNION 

	--validation added to verify if the mediatype for each record exist in the media type dimension table 
	SELECT 
		@ExecutionID
	    ,@FileName
	    ,srw.row_number + 1
	    ,'On Excel row ' + CONVERT(VARCHAR(10),srw.row_number + 1) + '; Lawson Code part 2 "' + RIGHT(srw.gl_code,6) +
	    '" is not listed on Master Tracker Match File'
	    ,GETDATE()
	FROM 
		dbo.STG_Writer_Radio AS srw
	WHERE RIGHT(gl_code,6) NOT IN
							(
							 SELECT 
								 media_lawson
							 FROM 
								 dim_media_type
							) 
	UNION 

	--validation added to verify that all the information comming from sheet SpotRadio Writer is a Radio Media Type
	SELECT 
		@ExecutionID
	    ,@FileName
	    ,srw.row_number + 1
	    ,'On Excel row ' + CONVERT(VARCHAR(10),srw.row_number + 1) + ' estimate "' + +'" does not have a matching estimate on writer match file'
	    ,GETDATE()
	FROM 
		dbo.STG_Writer_Radio AS srw
	WHERE estimate NOT IN
					  (
					   SELECT 
						   estimate
					   FROM 
						   dim_writer_match
					   WHERE id_dim_date = @ID_DATE
					  ) 
	UNION

	--validation added to validate that the initiative assigned to each record in the sheet exist in initiave dimension table 
	--SELECT
	--		@ExecutionID
	--	    ,@FileName
	--	    ,srw.row_number + 1
	--	    ,'On Excel row ' + CONVERT(VARCHAR(10),srw.row_number + 1) + '; Initiative "' + wdm.initiative + '" does not exist on Master Tracker Match File'
	--	    ,GETDATE()
	--	FROM
	--		dbo.STG_Writer_Radio AS srw
	--		INNER JOIN dbo.dim_writer_match AS wdm
	--			ON srw.estimate = wdm.estimate
	--			   AND wdm.input_file = 'Radio Writer'
	--	WHERE wdm.initiative NOT IN
	--						   (
	--						    SELECT
	--							    initiative_name
	--						    FROM
	--							    dim_initiative
	--						   )

	SELECT 
		@ExecutionID
	    ,@FileName
	    ,wa.row_number + 1
	    ,ISNULL(CASE
				  WHEN dwm.id_initiative IS NULL
					  AND dwm.id_media_type IS NULL THEN 'On Excel row ' + CONVERT(VARCHAR(10),wa.row_number + 1) + '; The Initiative "' + di.
					  initiative_name +
					  '" in combination with Lawson Code Part 2: "301995" is not on the Master Tracker Match file.  If this combination  is correct, the Master Tracker Match File should be updated.'
			  END,'') AS error_initiative_media_type_combination
	    ,wa.filename
	FROM 
		dbo.STG_Writer_Radio AS wa
		LEFT JOIN dim_writer_match AS dw
			ON dw.estimate = wa.estimate
			AND dw.id_dim_date = @ID_DATE
		LEFT JOIN dim_initiative AS di
			ON di.initiative_name = dw.initiative
		LEFT JOIN dim_media_type AS dt
			ON dt.media_type = 'Radio'
		LEFT JOIN dim_wag_initiative_media_type AS dwm
			ON dwm.id_initiative = di.id
			   AND dwm.id_media_type = dt.id
			   AND dwm.id_dim_date = @ID_DATE
	WHERE dwm.id_initiative IS NULL
		 OR dwm.id_media_type IS NULL

	--********************************************************************************************************************************************************************************************************************************/

	--*********************************************************************** VALIDATING ERRORS *************************************************************************************************************************************    

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
		--********************************************************************************************************************************************************************************************************************************/

END

