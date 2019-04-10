
--	Stored procedure name: usp_execute_wag_adjustment
--	Description: usp that manages the process flow about wag adjustment file type,  validation if no errors generation if errors no generations (and email errors sent)
--	Parameters: @ExecutionID unique identifier by execution, used to retrieve information of current execution and send it by email.
--				@Result  0 errors, 1 no errors
--				@FileName file name currently processed
--	Author: HVA
--	Date Creation: 11/25/2018
--	Date modification: 01/23/2019 add id_date to link file and month/year for monthly log report
--	Date modification: 01/31/2019 change out parameters to generate sp

--	drop PROC [usp_execute_wag_adjustment]
--*************************************************** CREATING EXECUTE SP *********************************************************************************************

CREATE PROC dbo.usp_execute_wag_adjustment (
	@ExecutionID BIGINT OUTPUT
    ,@Result BIT OUTPUT
    ,@FileName VARCHAR(100) OUTPUT) 
AS
BEGIN

	DECLARE @CURRENTYEAR AS INT
	DECLARE @CURRENTMONTH AS INT

	EXEC usp_validate_wag_adjustment 
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
		EXEC usp_generate_wag_adjustment 
			@ExecutionID
		    ,@CURRENTYEAR 
		    ,@CURRENTMONTH ; --  If result is successful then call generate SP.
		RETURN;
	END;
END
