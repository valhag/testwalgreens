﻿--	Stored procedure name: usp_execute_NetworkWriter
--	Description: usp that manages the process flow about NETWORK WRITER FILE TYPE,  validation if no errors generation if errors no generations (and email errors sent)
--	Parameters: @ExecutionID unique identifier by execution, used to retrieve information of current execution and send it by email.
--				@Result  0 errors, 1 no errors
--				@FileName file name currently processed
--	Author: HVA
--	Date Creation: 11/25/2018

--	drop PROC [usp_execute_NetworkWriter]
--*************************************************** CREATING EXECUTE SP *********************************************************************************************
CREATE PROC dbo.usp_execute_NetworkWriter (
	@ExecutionID BIGINT OUTPUT
    ,@Result BIT OUTPUT
    ,@FileName VARCHAR(100) OUTPUT) 
AS
BEGIN
	DECLARE @CURRENTYEAR AS INT
	DECLARE @CURRENTMONTH AS INT

	EXEC usp_validate_NetworkWriter 
		@ExecutionID OUT
	    ,@Result OUT
	    ,@FileName OUT
	    ,@CURRENTYEAR OUT
	    ,@CURRENTMONTH OUT; -- Calling Validate sp

	IF @Result = 0
	BEGIN
		RETURN 	-- if validation fails the process will stop and return 0 so, the alert mail with errors would be send here
	END
		ELSE
	BEGIN
		EXEC usp_generate_NetworkWriter 
			@ExecutionID
		    ,@CURRENTYEAR
		    ,@CURRENTMONTH; -- If result is successful then call generate SP.
		RETURN
	END

END	

--************************************************************************************************************************************************************************/
