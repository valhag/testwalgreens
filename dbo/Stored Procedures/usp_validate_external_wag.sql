--	stored procedure name: usp_validate_external_wag
--	description: usp that validates data about EXTErnal wag file type
--		  usp_create_execution_log call is to create a row in execution log and obtain @ExecutionId
----		  usp_update_execution_log call is to update (success or fail) the result of the execution
--	parameters: @ExecutionID unique identifier by execution, used to retrieve information of current execution and send it by email.
--				@Result  0 errors, 1 no errors
--				@FileName file name currently processed
--	returns 0 if there are errors call usp_update_execution_log to update error log
--			1 if there are not errors
--	author: HVA
--	Date Creation: 11/25/2018
--	Date Modification: 24/01/2019 include id_time_generated
--	Date Modification: 01/31/2019 no validate non existing media types on dim_media_type just skip them

--	Date Modification: 02/01/2019 take out validation about wag initiatives
--	Date Modification 02/15/2019 allowing . on filename 
--	Date Modification 02/22/2019 allowing . on filename 

--	drop PROC [usp_validate_external_wag]


CREATE PROC dbo.usp_validate_external_wag (
	@ExecutionID BIGINT OUTPUT
    ,@Result BIT OUTPUT
    ,@FileName VARCHAR(1000) OUTPUT
    ,@CURRENTYEAR INT OUTPUT
    ,@CURRENTMONTH VARCHAR(2) OUTPUT
) 
AS
BEGIN
	DECLARE @Folder AS VARCHAR(100)
	DECLARE @ID_DATE AS INT

	IF EXISTS
			(
			 SELECT 
				 1
			 FROM 
				 STG_External_WAG_Forecast
			) 
	BEGIN
		SELECT TOP 1 
			@FileName = filename
		    ,@Folder = directory
		    ,@CURRENTYEAR = CASE
                                         WHEN SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 6,1) = 2 THEN SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 6,4)
                                         ELSE SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 4,4)
                                  END
                  ,@CURRENTMONTH =  CASE
                                         WHEN SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 6,1) != 2 THEN SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 6,2)
                                         ELSE SUBSTRING(FILENAME,CHARINDEX('.XLS',UPPER(FILENAME)) - 2,2)
                                  END

		FROM 
			STG_External_WAG_Forecast
			select @ID_DATE = id_Dim_Date  from Dim_Date where month = @CURRENTMONTH and year = @CURRENTYEAR
	END
		ELSE
	BEGIN
		SET @FileName = 'External Wag PROCESS NO ROWS'
		SET @Folder = 'External Wag NO ROWS'
		select @ID_DATE = id_Dim_Date  from Dim_Date where month = month(getdate()) and year = year(getdate())
	END

	EXEC usp_create_execution_log 
		@FileName
	    ,@Folder
	    ,@ID_DATE
	    ,@ExecutionID OUT-- Catching current ExecutionID


	IF @FileName = 'External Wag PROCESS NO ROWS'
	BEGIN
		INSERT INTO ERRORS
		VALUES (
			  @ExecutionID
			 ,@FileName
			 ,1
			 ,'External Wag PROCESS NO ROWS'
			 ,GETDATE()) 
	END

	
	
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

