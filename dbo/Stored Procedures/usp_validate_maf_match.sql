--	stored procedure name: usp_validate_maf_match
--	description: usp that generates data on dim_maf_match
--		  (where the maf match initiatives are saved)
--		  usp_create_execution_log call is to create a row in execution log and obtain @ExecutionId
--		  usp_update_execution_log call is to update (success or fail) the result of the execution
--	parameters: @ExecutionID unique identifier by execution, used to retrieve information of current execution and send it by email.
--				@Result  0 errors, 1 no errors
--				@FileName file name currently processed
--	returns 0 if there are errors call usp_update_execution_log to update error log
--			1 if there are not errors
--	author: HVA
--	Date Creation: 11/25/2018
--	Date Modification: 01/15/2019 change error message
--	Date modification: 01/22/2019 add id_date to link file and month/year for monthly log report
--	Date modification: 02/10/2019 avoid duplicates maf initiatives
--	Date Modification 02/15/2019 allowing . on filename 
--	Date Modification 03/05/2019 put above id generation
--	Date Modification 03/11/2019 ISSUE 36
--	Date Modification 03/19/2019 error message update

--	drop PROC [usp_validate_maf_match]

CREATE PROC usp_validate_maf_match (
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
				 STG_maf_match
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
			STG_maf_match
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
		SET @FileName = 'MAF MATCH PROCESS NO ROWS'
		SET @Folder = 'MAF MATCH PROCESS NO ROWS'

	END

	
	EXEC usp_create_execution_log 
		@FileName
	    ,@Folder
	    ,@ID_DATE
	    ,@ExecutionID OUT-- Catching current ExecutionID

	   
	INSERT INTO ERRORS
	SELECT 
		@ExecutionID
	    ,sw.filename
	    ,sw.row_number
	    ,' On excel row, ' + CONVERT(VARCHAR(10),row_number + 1) + '; maf initiative "' + maf_initiative + '"  is duplicated '
	    ,GETDATE()
	FROM 
		STG_maf_match AS sw
	WHERE maf_initiative IN
				   (
				    SELECT 
					    maf_initiative
				    FROM 
					    STG_maf_match
				    WHERE maf_initiative != ''
				    GROUP BY 
					    maf_initiative
				    HAVING COUNT(*) > 1
				   ) 
    UNION 
    SELECT 
		@ExecutionID
	    ,@filename
	    ,stg.row_number + 1
	    ,'On excel row' + CONVERT(VARCHAR(10),row_number + 1) + '; Master Tracker Initative Name "' + stg.maf_initiative + '" does not exist on Master Tracker Match File.'
	    ,getdate()
	FROM 
		STG_maf_match AS stg
		where stg.maf_initiative is not null
	and stg.maf_initiative NOT IN
						   (
						    SELECT 
							    initiative_name
						    FROM 
							    dim_initiative
						   )

	


	IF @FileName = 'MAF MATCH PROCESS NO ROWS'
	BEGIN
		INSERT INTO ERRORS
		VALUES (
			  @ExecutionID
			 ,@FileName
			 ,1
			 ,'MAF MATCH PROCESS NO ROWS'
			 ,GETDATE()) 
	END

	
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
