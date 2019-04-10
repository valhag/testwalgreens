-- drop PROC usp_retrieve_master_tracker_version
-- exec usp_retrieve_master_tracker_version
-- DBCC CHECKIDENT ('MASTERTRACKEREXECUTIONGLOBAL', RESEED, 0)




create PROC usp_retrieve_master_tracker_version
@CURRENTMONTH AS INT
, @CURRENTYEAR AS INT
as
BEGIN

    declare @version table
    ( number int
    )

    UPDATE DIM_DATE SET VERSION = VERSION + 1 
    OUTPUT deleted.version into @version
    WHERE YEAR= @CURRENTYEAR AND MONTH = @CURRENTMONTH
    
    select number from @version
    /*
    DELETE FROM MASTERTRACKEREXECUTIONGLOBAL
	INSERT INTO MASTERTRACKEREXECUTIONGLOBAL
	VALUES (
		  1) 


	SELECT 
		IDENT_CURRENT('WalgreensMasterTracker.dbo.MASTERTRACKEREXECUTIONGLOBAL') as returnedversion

		*/
END

