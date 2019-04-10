--	stored procedure name: usp_validate_maf
--	description: usp that generates data on fact_outcome table maf file type
--		  (where the all the process data are saved)
--		  usp_create_execution_log call is to create a row in execution log and obtain @ExecutionId
--		  usp_update_execution_log call is to update (success or fail) the result of the execution
--	parameters: @ExecutionID unique identifier by execution, used to retrieve information of current execution and send it by email.
--				@Result  0 errors, 1 no errors
--				@FileName file name currently processed
--	returns 0 if there are errors call usp_update_execution_log to update error log
--			1 if there are not errors
--	author: HVA
--	Date Creation: 11/25/2018
--	Date Modification: 02/01/2018 add delete to avoid empty rows/ update message errors
--	Date Modification: 02/10/2018 modify error messages
--	Date Modification 02/15/2019 allowing . on filename 
--	Date Modification 02/19/2019 allowing . on filename 
--	Date Modification 02/19/2019 issue 37
--  Date Modification 03/11/2019 update error messages
--  Date Modification 03/19/2019 update error messages


--	drop PROC [usp_validate_maf]


CREATE PROC dbo.usp_validate_maf (
	@ExecutionID BIGINT OUTPUT
    ,@Result BIT OUTPUT
    ,@FileName VARCHAR(1000) OUTPUT
    ,@CURRENTYEAR INT OUTPUT
    ,@CURRENTMONTH INT OUTPUT) 
AS
BEGIN
	--*******************************************************************************************************************************************************************************************************************************/

	--**************************************************************************************** DECLARE & SET VARIABLES *************************************************************************************************************

	DECLARE @Folder AS VARCHAR(100)
	DECLARE @ID_DATE AS INT

	DELETE FROM stg_maf
	WHERE 
		annual_maf_ IS NULL

	IF EXISTS
			(
			 SELECT 
				 1
			 FROM 
				 STG_MAF
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
			STG_MAF
		SELECT 
			@ID_DATE = id_Dim_Date
		FROM 
			Dim_Date
		WHERE month = @CURRENTMONTH
			 AND year = @CURRENTYEAR
	END
		ELSE
	BEGIN
		SET @FileName = 'MAF PROCESS NO ROWS'
		SET @Folder = 'MAF Wag NO ROWS'
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


	IF @FileName = 'MAF PROCESS NO ROWS'
	BEGIN
		INSERT INTO ERRORS
		VALUES (
			  @ExecutionID
			 ,@FileName
			 ,1
			 ,'MAF PROCESS NO ROWS'
			 ,GETDATE()) 
	END

	INSERT INTO ERRORS
	SELECT 
		@ExecutionID
	    ,tmp.filename
	    ,(tmp.row_number + 1) as row_number
	    ,' On excel row ' + CONVERT(VARCHAR(10),row_number+1) + '; '+ CASE
													   WHEN tmp.error_media_type != ''
														   AND tmp.error_initiative != '' THEN tmp.error_initiative + ' and ' + tmp.
														   error_media_type 
													   ELSE CASE
															   WHEN tmp.error_initiative != '' THEN tmp.error_initiative +
															   ', on filename ' + tmp.filename
															   ELSE tmp.error_media_type 
														   END
												   END AS message
	    ,GETDATE()
	FROM
		(
		 SELECT 
			 m.row_number 
			,ISNULL(CASE
					   WHEN di.initiative_name IS NULL THEN ' Initiative "' + m.initiative + '" does not exist on the MAF Tracker Match '
				   END,'') AS error_initiative
			,ISNULL(CASE
					   WHEN dt.media_type IS NULL THEN ' Media Type MAF name "' + m.media_type + '" is not on Master Tracker Match File '
				   END,'') AS error_media_type
			,m.filename
		 FROM 
			 STG_MAF AS m
			 LEFT JOIN dim_maf_match AS mm
				 ON mm.maf_initiative = m.initiative
				 and mm.id_dim_date = @ID_DATE
			 LEFT JOIN dim_initiative AS di
				 ON di.initiative_name = mm.master_tracker_initiative
			 LEFT JOIN dim_wag_forecast_initiative AS dw
				 ON dw.id = di.id_wag_forecast_initiative
			 LEFT JOIN dim_media_type AS dt
				 ON dt.media_type = m.media_type
				    AND dt.media_lawson = m.media_lawson
			 LEFT JOIN dim_wag_initiative_media_type AS dwm
				 ON dwm.id_initiative = di.id
				    AND dwm.id_media_type = dt.id
				    and dwm.id_dim_date = @ID_DATE
		 WHERE client_code = 'WAG'
			  AND di.initiative_name IS NULL
			  OR dt.media_type IS NULL
		) AS tmp
	UNION
	SELECT 
		@ExecutionID
	    ,tmp.filename
	    ,(tmp.row_number + 1) as row_number
	    ,' On excel row ' + CONVERT(VARCHAR(10),row_number+1) + '; The combination of Initiative "' + tmp.initiative + '" as matched from MAF Match File) and media type "' +  tmp.media_type + 
	    '" does not exist on the Master Tracker Match File ' 
	    ,GETDATE()
	FROM
		(
		 SELECT 
			 dim.id_initiative AS id_initiativerel
			,dim.id_media_type AS id_media_typerel
			,di.id AS id_initiative
			,dt.id AS id_media_type
			,m.initiative
			,m.media_type
			,mm.master_tracker_initiative
			,m.row_number
			,m.filename
		 FROM 
			 STG_MAF AS m
			 JOIN dim_maf_match AS mm
				 ON mm.maf_initiative = m.initiative
				 and mm.id_dim_date = @ID_DATE
			 JOIN dim_initiative AS di
				 ON di.initiative_name = mm.master_tracker_initiative
			 JOIN dim_media_type AS dt
				 ON dt.media_type = m.media_type
				    AND dt.media_lawson = m.media_lawson
			 LEFT JOIN dim_wag_initiative_media_type AS dim
				 ON dim.id_initiative = di.id
				    AND dim.id_media_type = dt.id
				    and dim.id_dim_date = @ID_DATE
		) AS tmp
	WHERE tmp.id_initiativerel IS NULL
		 OR tmp.id_media_typerel IS NULL
	ORDER BY 
		row_number
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

