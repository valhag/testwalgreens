--	stored procedure name: [usp_validate_PrintWriter]
--	description: usp that validates data about Print Writer file type
--		  usp_create_execution_log call is to create a row in execution log and obtain @ExecutionId
----		  usp_update_execution_log call is to update (success or fail) the result of the execution
--	parameters: @ExecutionID unique identifier by execution, used to retrieve information of current execution and send it by email.
--				@Result  0 errors, 1 no errors
--				@FileName file name currently processed
--	returns 0 if there are errors call usp_update_execution_log to update error log
--			1 if there are not errors
--	author: HVA
--	Date Creation: 11/25/2018
--	Date modification: 01/23/2019 stg by dim_writer_match
--	Date modification: 01/30/2019 add validations about estimate matching between stg and dim_match and input_file
--	Date modification: 01/31/2019 message updates
--	Date modification: 02/01/2019 message updates
--	Date Modification 02/15/2019 allowing . on filename 
--	Date Modification 02/19/2019 allowing . on filename 
--	Date Modification 03/20/2019 error messages

--	drop PROC [usp_validate_PrintWriter]



CREATE PROC dbo.usp_validate_PrintWriter (
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
				 STG_Writer_Print
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
			STG_Writer_Print
		SELECT 
			@ID_DATE = id_Dim_Date
		FROM 
			Dim_Date
		WHERE month = @CURRENTMONTH
			 AND year = @CURRENTYEAR
	END
		ELSE
	BEGIN
		SET @FileName = 'Print Writer PROCESS NO ROWS'
		SET @Folder = 'Print Writer NO ROWS'
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


	IF @FileName = 'Print Writer PROCESS NO ROWS'
	BEGIN
		INSERT INTO ERRORS
		VALUES (
			  @ExecutionID
			 ,@FileName
			 ,1
			 ,'Print Writer PROCESS NO ROWS'
			 ,GETDATE()) 
	END

	INSERT INTO dbo.Errors
	SELECT 
		@ExecutionID
	    ,@FileName
	    ,nw.row_number + 1
	    ,'On excel row ' + CONVERT(VARCHAR(10),nw.row_number + 1) + '; gl_code should have at least 6 characters'
	    ,GETDATE()
	FROM 
		dbo.STG_Writer_Print AS nw
	WHERE LEN(nw.gl_code) < 6
	UNION
	SELECT 
		@ExecutionID
	    ,@FileName
	    ,srw.row_number + 1
	    ,'On Excel row ' + CONVERT(VARCHAR(10),srw.row_number + 1) + '; estimate or gl_code are not complete or do not have correct format or are empty'
	    ,GETDATE()
	FROM 
		dbo.STG_Writer_Print AS srw
	WHERE gl_code IS NULL
		 OR estimate IS NULL
	UNION 

	--validation added to verify if the mediatype for each record exist in the media type dimension table 
	SELECT 
		@ExecutionID
	    ,@FileName
	    ,nw.row_number + 1
	    ,'On excel row ' + CONVERT(VARCHAR(10),nw.row_number + 1) + '; Lawson Code part 2: "' + RIGHT(nw.gl_code,6) +
	    '" is not listed on Master Tracker Match file'
	    ,GETDATE()
	FROM 
		dbo.STG_Writer_Print AS nw
	WHERE RIGHT(gl_code,6) NOT IN
							(
							 SELECT 
								 media_lawson
							 FROM 
								 dim_media_type
							) 
	UNION
	SELECT 
		@ExecutionID
	    ,@FileName
	    ,wa.row_number + 1
	     ,'On Excel row ' + CONVERT(VARCHAR(10),wa.row_number + 1) + '; Initiative' + isnull(di.initiative_name,'') + '" in combination with Lawson Code Part 2: "' + RIGHT
	    (gl_code,6) + '" is not on the Master Tracker Match file.  If this combination is correct, the Master Tracker Match File should be updated.'
	    ,GETDATE()
	FROM 
		STG_Writer_Print AS wa
		LEFT JOIN dim_writer_match AS dw
			ON dw.estimate = wa.estimate
			   AND dw.input_file = 'Print Writer'
			   AND dw.id_dim_date = @ID_DATE
		LEFT JOIN dim_initiative AS di
			ON di.initiative_name = dw.initiative
		LEFT JOIN dim_media_type AS dt
			ON dt.media_lawson = RIGHT(gl_code,6)
		LEFT JOIN dim_wag_initiative_media_type AS dwm
			ON dwm.id_initiative = di.id
			   AND dwm.id_media_type = dt.id
			   AND dwm.id_dim_date = @ID_DATE
	WHERE dwm.id_initiative IS NULL
		 OR dwm.id_media_type IS NULL
	UNION
	-- validation to verify if estimate fields match between stg and di match tables
	SELECT 
		@ExecutionID
	    ,@FileName
	    ,nw.row_number + 1
	    ,'On excel row ' + CONVERT(VARCHAR(10),nw.row_number + 1) + '; estimate "' + nw.estimate +
	    '" does not have a matching estimate name on writer match file '
	    ,GETDATE()
	FROM 
		STG_Writer_Print AS nw
	WHERE nw.estimate NOT IN
						(
						 SELECT 
							 estimate
						 FROM 
							 dim_writer_match
							 where id_dim_date = @ID_DATE
						) 
	UNION
	-- validation to verify the input file is valid
	SELECT 
		@ExecutionID
	    ,@FileName
	    ,nw.row_number + 1
	    ,'On excel row ' + CONVERT(VARCHAR(10),nw.row_number + 1) + '; estimate "' + nw.estimate +
	    '" does not match with a existing entry under the Print Writer section.  It does match with an entry in the "' + wdm.input_file +
	    '" section. Please add an entry to the Print Writer section for this Estimate name.'
	    ,GETDATE()
	FROM 
		dbo.STG_Writer_Print AS nw
		JOIN dbo.dim_writer_match AS wdm
			ON nw.estimate = wdm.estimate
			   AND wdm.input_file != 'Print Writer'
			   and id_dim_date = @ID_DATE
	WHERE nw.row_number NOT IN
						  (
						   SELECT 
							   srw.row_number
						   FROM 
							   STG_Writer_Print AS srw
							   JOIN dbo.dim_writer_match AS wdm
								   ON srw.estimate = wdm.estimate
									 AND wdm.input_file = 'Print Writer'
									 and id_dim_date = @ID_DATE
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
		ELSE
	BEGIN
		SET @Result = 1
		RETURN
	END
		--********************************************************************************************************************************************************************************************************************************/

END

