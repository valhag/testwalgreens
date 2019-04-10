
--	Stored procedure name: usp_execute_external_wag
--	Description: usp that manages the process flow about external wag file type,  validation if no errors generation if errors no generations (and email errors sent)
--	Parameters: @ExecutionID unique identifier by execution, used to retrieve information of current execution and send it by email.
--				@Result  0 errors, 1 no errors
--				@FileName file name currently processed
--	Author: HVA
--	Date Creation: 11/25/2018
--	Date Modification: 25/01/2019 include id_time_generated

--	drop PROC [usp_execute_external_wag]

--*************************************************** CREATING EXECUTE SP *********************************************************************************************
CREATE PROC dbo.usp_execute_external_wag (
	@ExecutionID BIGINT OUTPUT
    ,@Result BIT OUTPUT
    ,@FileName VARCHAR(100) OUTPUT) 
AS
BEGIN

	DECLARE @CURRENTYEAR AS INT
	DECLARE @CURRENTMONTH AS VARCHAR(2)

	EXEC usp_validate_external_wag 
		@ExecutionID OUT
	    ,@Result OUT
	    ,@FileName OUT
	    ,@CURRENTYEAR OUT
	    ,@CURRENTMONTH OUT -- Calling Validate sp

	IF @Result = 0
	BEGIN
	   EXEC usp_generate_external_wag 
			@ExecutionID
		    ,@CURRENTYEAR 
		    ,@CURRENTMONTH -- If result is successful then call generate SP.
		RETURN 	-- if validation fails the process will stop and return 0 so, the alert mail with errors would be send here
	END
		ELSE
	BEGIN
		EXEC usp_generate_external_wag 
			@ExecutionID
		    ,@CURRENTYEAR 
		    ,@CURRENTMONTH -- If result is successful then call generate SP.
		RETURN
	END

END	

--************************************************************************************************************************************************************************/
