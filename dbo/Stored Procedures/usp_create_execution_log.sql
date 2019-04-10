/*
    drop proc usp_create_execution_log
*/
CREATE PROC [dbo].[usp_create_execution_log](@FileName VARCHAR(100),@Folder VARCHAR(100),@Id_date int, @ExecutionID BIGINT OUTPUT)
AS
BEGIN
	INSERT INTO ExecutionLog([FileName],StartTime,EndTime,Step,[Status],[Message],[Folder],[Id_date])VALUES(@FileName,getDate(),NULL,'Validation','In progress',NULL, @Folder,@Id_date)
	SET @ExecutionID=IDENT_CURRENT( 'WalgreensMasterTracker.dbo.ExecutionLog' ) --Assigning it to ExecutionID variable
	RETURN 
END
