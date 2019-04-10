-- drop PROC usp_remove_writer_match 

CREATE PROC usp_remove_writer_match 
	@filename AS VARCHAR(200)
AS
BEGIN


	DECLARE @executionid INT


	SELECT 
		@executionid = MAX(executionid)
	FROM 
		ExecutionLog
	WHERE FileName = @filename
		 AND STATUS = 'Success'

	BEGIN TRY
		BEGIN TRAN Removing
		DELETE FROM dim_writer_match
		WHERE 
			executionid = @executionid

		INSERT INTO dim_writer_match
		SELECT 
			estimate
		    ,initiative
		    ,input_file
		    ,product
		    ,id_dim_date
		    ,executionidprevious
		FROM 
			dim_writer_match_history
		WHERE executionid = @executionid
			 AND executionid != executionidprevious

		DELETE FROM dim_writer_match_history
		WHERE 
			executionid = @executionid

		COMMIT TRANSACTION Removing
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK TRAN Removing
		END
	END CATCH


END