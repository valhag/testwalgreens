
--	Stored procedure name: usp_execute_writer_match
--	Description: usp that manages the process flow about writer digital file type,  validation if no errors generation if errors no generations (and email errors sent)
--	Parameters: @ExecutionID unique identifier by execution, used to retrieve information of current execution and send it by email.
--				@Result  0 errors, 1 no errors
--				@FileName file name currently processed
--	Author: HVA
--	Date Creation: 11/25/2018
--	Date Modification 01/22/2019: add id_date to link filename with a month/year in order to obtain monthly log tab on master tracker outcome file
--   02/08/2019 if current month writer match data does not exist copy all data from previous month

--	drop PROC [usp_execute_writer_match]

--*************************************************** CREATING EXECUTE SP *********************************************************************************************
CREATE PROC dbo.usp_execute_writer_match (
	@ExecutionID BIGINT OUTPUT
    ,@Result BIT OUTPUT
    ,@FileName VARCHAR(100) OUTPUT) 
AS
BEGIN
	DECLARE @CURRENTYEAR AS INT
	DECLARE @CURRENTMONTH AS INT

	EXEC usp_validate_writer_match 
		@ExecutionID OUT
	    ,@Result OUT
	    ,@FileName OUT
	    ,@CURRENTYEAR OUT
	    ,@CURRENTMONTH OUT; -- Calling Validate sp; -- Calling Validate sp

	IF @Result = 0
	BEGIN
		--EXEC usp_generate_writerdigital 
		--	@ExecutionID; -- If result is successful then call generate SP.
		RETURN; 	-- if validation fails the process will stop and return 0 so, the alert mail with errors would be send here
	END;
		ELSE
	BEGIN
		EXEC usp_generate_writer_match 
			@ExecutionID
		    ,@CURRENTYEAR
		    ,@CURRENTMONTH
		RETURN;
	END;
END
