
CREATE PROC dbo.usp_update_execution_log (
	@ExecutionID BIGINT
    ,@Status VARCHAR(100)
    ,@Step VARCHAR(100)
    ,@Message VARCHAR(1000)) 
AS
	BEGIN
		UPDATE ExecutionLog
		SET 
			EndTime = GETDATE()
		    ,Status = @Status
		    ,Step = @Step
		    ,Message = @Message
		WHERE 
			ExecutionID = @ExecutionID
	END
