
--	Stored procedure name: usp_execute_RadioWriter
--	Description: usp that manages the process flow about Radio Writer File Type,  validation if no errors generation if errors no generations (and email errors sent)
--	Parameters: @ExecutionID unique identifier by execution, used to retrieve information of current execution and send it by email.
--				@Result  0 errors, 1 no errors
--				@FileName file name currently processed
--	Author: HVA
--	Date Creation: 11/25/2018

--	drop PROC [usp_execute_RadioWriter]
--*************************************************** CREATING EXECUTE SP *********************************************************************************************

CREATE PROC dbo.usp_execute_RadioWriter (
	@ExecutionID BIGINT OUTPUT
    ,@Result BIT OUTPUT
    ,@FileName VARCHAR(100) OUTPUT) 
AS
BEGIN
	DECLARE @CURRENTYEAR AS INT
	DECLARE @CURRENTMONTH AS INT
	EXEC dbo.usp_validate_RadioWriter 
		@ExecutionID OUT
	    ,@Result OUT
	    ,@FileName OUT
	    ,@CURRENTYEAR OUT
	    ,@CURRENTMONTH OUT; -- Calling Validate sp

	IF @Result = 0
	BEGIN
		RETURN; 	-- if validation fails the process will stop and return 0 so, the alert mail with errors would be send here
	END;
		ELSE
	BEGIN
		EXEC dbo.usp_generate_RadiokWriter 
			@ExecutionID
		    ,@CURRENTYEAR
		    ,@CURRENTMONTH; -- If result is successful then call generate SP.
		RETURN;
	END;
END
