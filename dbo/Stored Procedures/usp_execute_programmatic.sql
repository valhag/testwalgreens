--	Stored procedure name: [usp_execute_programmatic]
--	Description: usp that manages the process flow about PROGRAMMATIC file type,  validation if no errors generation if errors no generations (and email errors sent)
--	Parameters: @ExecutionID unique identifier by execution, used to retrieve information of current execution and send it by email.
--				@Result  0 errors, 1 no errors
--				@FileName file name currently processed
--	Author: HVA
--	Date Creation: 11/25/2018
--	Date modification: 01/23/2019 add id_date to link file and month/year for monthly log report
--	Date modification: 02/06/2019 remove out identifier

--	drop PROC [usp_execute_programmatic]
--*************************************************** CREATING EXECUTE SP *********************************************************************************************

CREATE PROC dbo.usp_execute_programmatic (
	@ExecutionID BIGINT OUTPUT
    ,@Result BIT OUTPUT
    ,@FileName VARCHAR(100) OUTPUT) 
AS
BEGIN

	DECLARE @CURRENTYEAR AS INT
	DECLARE @CURRENTMONTH AS INT

	EXEC usp_validate_programmatic 
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
		EXEC usp_generate_programmatic 
			@ExecutionID
		    ,@CURRENTYEAR 
		    ,@CURRENTMONTH ; -- Calling Validate sp-- If result is successful then call generate SP.
		RETURN
	END

END	

--************************************************************************************************************************************************************************/