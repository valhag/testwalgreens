--    stored procedure name: usp_validate_WriterDigital
--	description: usp that generates data on fact_outcome with writer digital data
--		  usp_create_execution_log call is to create a row in execution log and obtain @ExecutionId
--		  usp_update_execution_log call is to update (success or fail) the result of the execution
--	parameters: @ExecutionID unique identifier by execution, used to retrieve information of current execution and send it by email.
--				@Result  0 errors, 1 no errors
--				@FileName file name currently processed
--	returns 0 if there are errors call usp_update_execution_log to update error log
--			1 if there are not errors
--	author: HVA
--	Date Creation: 11/25/2018
--	Date Modification 01/22/2019: add id_date to link filename with a month/year in order to obtain monthly log tab on master tracker outcome file
--	Date Modification 02/01/2019: change stg for dim_writer_match/ error message
--	Date Modification 02/06/2019: change error message to kurt standard
--	Date Modification 02/15/2019 allowing . on filename 
--	Date Modification 02/19/2019 allowing . on filename 
--	Date Modification 02/25/2019 input file validation
--   Date Modification 03/11/2019 error messages 

--    DROP PROC dbo.usp_validate_WriterDigital 



CREATE PROC dbo.usp_validate_WriterDigital (
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
				 STG_Writer_Digital
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
			STG_Writer_Digital
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
		SET @FileName = 'WRITER DIGITAL PROCESS NO ROWS'
		SET @Folder = 'WRITER DIGITAL NO ROWS'

	END

	EXEC usp_create_execution_log 
		@FileName
	    ,@Folder
	    ,@ID_DATE
	    ,@ExecutionID OUT-- Catching current ExecutionID


	IF @FileName = 'WRITER DIGITAL PROCESS NO ROWS'
	BEGIN
		INSERT INTO ERRORS
		VALUES (
			  @ExecutionID
			 ,@FileName
			 ,1
			 ,'WRITER DIGITAL PROCESS NO ROWS'
			 ,GETDATE()) 
	END

	INSERT INTO ERRORS
	SELECT 
		@ExecutionID
	    ,sw.filename
	    ,sw.row_number
	    ,' On excel row; ' + CONVERT(VARCHAR(10),row_number + 1) + '; Lawson Code Part 2 (gl_code) does not have at least 6 characters'
	    ,GETDATE()
	FROM 
		STG_Writer_Digital AS sw
	--WHERE LEN(gl_code) != 13
	--	 OR SUBSTRING(gl_code,7,1) != '-'
	WHERE LEN(gl_code) < 6
	UNION
	SELECT 
		@ExecutionID
	    ,sw.filename
	    ,sw.row_number
	    ,'On excel row; ' + CONVERT(VARCHAR(10),row_number + 1) + '; Lawson code Part 2 "' + RIGHT(sw.gl_code,6) +
	    '" does not exist on master tracker match file'
	    ,GETDATE()
	FROM 
		STG_Writer_Digital AS sw
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
	    ,wd.filename
	    ,wd.row_number
	    ,'On excel row; ' + CONVERT(VARCHAR(10),row_number + 1) + '; Estimate "' + estimate + +
	    '" does not have a matching estimate on writer match file'
	    ,GETDATE()
	FROM 
		STG_Writer_Digital AS wd
	WHERE estimate NOT IN
					  (
					   SELECT 
						   estimate
					   FROM 
						   dim_writer_match
					   WHERE id_dim_date = @ID_DATE
					  ) 
	UNION
	--	SELECT
	--		@ExecutionID
	--	    ,wd.filename
	--	    ,wd.row_number
	--	    ,'On excel row;' + CONVERT(VARCHAR(10),wd.row_number + 1) + '; Estimate name "' + wd.estimate + '" links to Initiative: "' + wdm.initiative
	--	    + '" does not exist on master tracker match file'
	--	    ,GETDATE()
	--	FROM
	--		STG_Writer_Digital AS wd
	--		JOIN dim_writer_match AS wdm
	--			ON wd.estimate = wdm.estimate
	--			   AND wdm.id_dim_date = @ID_DATE
	--	WHERE wdm.initiative NOT IN
	--						   (
	--						    SELECT
	--							    initiative_name
	--						    FROM
	--							    dim_initiative
	--						   )
	--	UNION

	SELECT 
		@ExecutionID
	    ,nw.filename
	    ,nw.row_number + 1
		--,'On row ' + CONVERT(VARCHAR(10),nw.row_number + 1) + '; estimate "' + nw.estimate +
		--'" matches with estimate on writer match file but input file is not Digital Writer input file is ' + wdm.input_file
	    ,'On Excel row ' + CONVERT(VARCHAR(10),nw.row_number + 1) + '; Estimate "' + nw.estimate +
	    '"  does not match with a existing entry under the Digital Writer section. It does match with an entry in the ' + wdm.input_file +
	    ' section. Please add an entry to the Digital Writer section for this Estimate name.'
	    ,GETDATE()
	FROM 
		dbo.STG_Writer_Digital AS nw
		JOIN dbo.dim_writer_match AS wdm
			ON nw.estimate = wdm.estimate
			   AND wdm.input_file != 'Digital Writer'
	WHERE nw.row_number NOT IN
						  (
						   SELECT 
							   srw.row_number
						   FROM 
							   STG_Writer_Digital AS srw
							   JOIN dbo.dim_writer_match AS wdm
								   ON srw.estimate = wdm.estimate
									 AND wdm.input_file = 'Digital Writer'
									 AND wdm.id_dim_date = @ID_DATE
						  ) 
	UNION
	SELECT 
		@ExecutionID
	    ,@FileName
	    ,wa.row_number + 1
	    ,'On Excel row ' + CONVERT(VARCHAR(10),wa.row_number + 1) + ';' + ISNULL(di.initiative_name,'') +
	    '" in combination with Lawson Code Part 2: "' + RIGHT(gl_code,6) +
	    '" is not on the Master Tracker Match file.  If this combination is correct, the Master Tracker Match File should be updated.'
	    ,wa.filename
	FROM 
		STG_Writer_Digital AS wa
		LEFT JOIN dim_writer_match AS dw
			ON dw.estimate = wa.estimate
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

