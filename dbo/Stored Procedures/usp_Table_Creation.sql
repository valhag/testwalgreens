CREATE PROC usp_Table_Creation
AS
BEGIN
	

	IF OBJECT_ID('Errors') IS NOT NULL
		DROP TABLE Errors

	CREATE TABLE Errors
	(
		filename varchar(500)
		, row varchar(500)
		, message varchar(500)
		, timestamp datetime
	)

	IF OBJECT_ID('dim_wag_forecast_initiative') IS NOT NULL
		DROP TABLE dim_wag_forecast_initiative


	CREATE TABLE dim_wag_forecast_initiative
	(
		id int identity(1,1) 
		, lawson nvarchar(50)
		, wag_forecast_initiative nvarchar(1500)
		, CONSTRAINT PK_id_wag_forecast PRIMARY KEY (id)
	)

	IF OBJECT_ID('dim_media_type') IS NOT NULL
		DROP TABLE dim_media_type
	
	CREATE TABLE dim_media_type
	(
		id int identity(1,1)
		, media_lawson nvarchar(50)
		, media_type nvarchar(1500)
		, CONSTRAINT PK_id_media_type PRIMARY KEY (id)
	)

	IF OBJECT_ID('dim_initiative') IS NOT NULL
		drop table dim_initiative

	CREATE TABLE dim_initiative
	(
		id int identity(1,1)
		,id_wag_forecast_initiative int
		,initiative_name nvarchar(100)
		, CONSTRAINT PK_id_initiative PRIMARY KEY (id)
		, CONSTRAINT FK_id_initiative_id_wag_forecast_ FOREIGN KEY  (id_wag_forecast_initiative)  REFERENCES dim_wag_forecast_initiative (ID)    
	)

	IF OBJECT_ID('Fact_Outcome') IS NOT NULL
		drop table Fact_Outcome
	create table Fact_Outcome
	(
		id_initiative int
		, id_media_type int
		, value money
		, id_time   int
		, id_type int
		, CONSTRAINT PK_Fact_Outcome PRIMARY KEY (id_initiative, id_media_type)
		, CONSTRAINT FK_id_initiative_id_initiative FOREIGN KEY  (id_initiative)  REFERENCES dim_initiative (id)    
		, CONSTRAINT FK_id_initiative_id_media_type FOREIGN KEY  (id_media_type)  REFERENCES dim_media_type (id)    
	)

	IF OBJECT_ID('dim_maf_match') IS NOT NULL
		drop table dim_maf_match

	create table dim_maf_match
	(
	maf_initiative nvarchar(500)
	, master_tracker_initiative nvarchar(500)
	)

END