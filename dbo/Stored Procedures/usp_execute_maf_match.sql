
--	Stored procedure name: [usp_execute_maf_match]
--	Description: usp that manages the process flow about maf match type,  validation if no errors generation if errors no generations (and email errors sent)
--	Parameters:	@ExecutionID unique identifier by execution, used to retrieve information of current execution and send it by email.
--				@Result  0 errors, 1 no errors
--				@FileName file name currently processed
--	Author: HVA
--	Date Creation: 11/25/2018
--	Date Creation: 11/25/2018 with errors no data generation
--	Date modification: 02/10/2019 if current month MAF match data does not exist copy all data from previous month


--	drop PROC [usp_execute_maf_match]
--*************************************************** CREATING EXECUTE SP *********************************************************************************************

CREATE PROC dbo.usp_execute_maf_match (
	@ExecutionID BIGINT OUTPUT
    ,@Result BIT OUTPUT
    ,@FileName VARCHAR(100) OUTPUT) 
AS
BEGIN
	DECLARE @CURRENTYEAR AS INT
	DECLARE @CURRENTMONTH AS INT
	EXEC usp_validate_maf_match 
		@ExecutionID OUT
	    ,@Result OUT
	    ,@FileName OUT
	    ,@CURRENTYEAR OUT
	    ,@CURRENTMONTH OUT; -- Calling Validate sp

	IF @Result = 0
	BEGIN
		--EXEC usp_generate_maf_match
		--@ExecutionID -- If result is successful then call generate SP.
		RETURN; 	-- if validation fails the process will stop and return 0 so, the alert mail with errors would be send here
	END;
		ELSE
	BEGIN
		EXEC usp_generate_maf_match 
			@ExecutionID
		    ,@CURRENTYEAR
		    ,@CURRENTMONTH; -- If result is successful then call generate SP.
		RETURN;
	END;
END
