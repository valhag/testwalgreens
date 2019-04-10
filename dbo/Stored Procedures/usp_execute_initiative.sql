
--	Stored procedure name: [usp_execute_initiative]
--	Description: usp that manages the process flow about initiatives,  validation if no errors generation if errors no generations (and email errors sent)
--	Parameters: @ExecutionID unique identifier by execution, used to retrieve information of current execution and send it by email.
--				@Result  0 errors, 1 no errors
--				@FileName file name currently processed
--	Author: HVA
--	Date Creation: 11/25/2018
--	Date modification: 01/22/2019 add id_date to link file and month/year for monthly log report

--	drop PROC [usp_execute_initiative]
--*************************************************** CREATING EXECUTE SP *********************************************************************************************



--*************************************************** CREATING EXECUTE SP *********************************************************************************************
CREATE PROC [dbo].[usp_execute_initiative] (
	@ExecutionID BIGINT OUTPUT
    ,@Result BIT OUTPUT
    ,@FileName VARCHAR(100) OUTPUT) 
AS
BEGIN
	   DECLARE @CURRENTYEAR AS INT
	DECLARE @CURRENTMONTH AS INT

	EXEC usp_validate_initiative
		@ExecutionID OUT
	    ,@Result OUT
	    ,@FileName OUT -- Calling Validate sp
	    ,@CURRENTYEAR OUT
	    ,@CURRENTMONTH OUT; -- Calling Validate sp

	IF @Result = 0
	BEGIN
		--EXEC usp_generate_initiative
		--	@ExecutionID -- If result is successful then call generate SP.
		RETURN 	-- if validation fails the process will stop and return 0 so, the alert mail with errors would be send here
	END
		ELSE
	BEGIN
		EXEC usp_generate_initiative 
			@ExecutionID ; -- Calling Validate sp-- If result is successful then call generate SP.
		RETURN
	END

END	

--************************************************************************************************************************************************************************/
