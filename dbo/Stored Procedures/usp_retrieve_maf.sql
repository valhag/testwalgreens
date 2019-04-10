CREATE PROC usp_retrieve_maf
AS
BEGIN 

	SELECT dw.wag_forecast_initiative , dw.lawson as Lawson, di.Initiative_name,  dm.media_type, dm.media_lawson , isnull(f.value,0) as value, isnull(f.id_type,0) as type
	from dim_wag_initiative_media_type dwm
	left join  Fact_Outcome f on f.id_initiative = dwm.id_initiative and f.id_media_type = dwm.id_media_type
	join dim_initiative di on di.id = dwm.id_initiative 
	join dim_wag_forecast_initiative dw on dw.id = di.id_wag_forecast_initiative
	join dim_media_type dm on dm.id = dwm.id_media_type

END