;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; polar_som_info.ncl
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; -Procedures to configure and set paramaters for common SOM work in the 
;  polar regions.
;   polarSOMInfo - sets different mapping paramaters
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; procedure to set the map settings for different dominas/projections
procedure polarSOMdomain(x:string, res:logical)
  ; x:string         -variable indicating SOM domain
  ; res:logical      -resource to set SOM domain settings
begin
  if (x .eq. "CFR_wind") then
    ; set the domain title and plotting map region
    res@title = "Colorado Front Range - Wind Extremes"
    res@map = "CFR_wind"
    ; mask using lat/lon min/max ranges
    res@use_latlon_mask = True
    ; set the lat/lon min/max values
    res@max_lat = 41.
    res@min_lat = 37.
    res@max_lon = 258.   ;-102.W
    res@min_lon = 254.   ;-106. W
    ; mask using i,j values from the input data
    res@use_ij_mask     = False
    ; set a threshold to mask values above a specified elevation
    res@use_elev_mask = True
    res@elev_mask_hgt = 2600.
    ; mask by land - land points only (landmask)
    res@use_land_mask = False
    ; mask by ocean - ocean points only (inverted landmask)
    res@use_ocean_mask = False
  end if  ; CFR circulation
  if (x .eq. "CFR_circ") then
    ; set the domain title and plotting map region
    res@title = "Colorado Front Range - Circulation"
    res@map = "CFR_circ"
    ; mask using lat/lon min/max ranges
    res@use_latlon_mask = True
    ; set the lat/lon min/max values
    res@max_lat = 44.
    res@min_lat = 35.
    res@max_lon = 263.   ;-97.W
    res@min_lon = 245.   ;-115W.E
    ; mask using i,j values from the input data
    res@use_ij_mask     = False
    ; set a threshold to mask values above a specified elevation
    res@use_elev_mask = True
    res@elev_mask_hgt = 2600.
    ; mask by land - land points only (landmask)
    res@use_land_mask = False
    ; mask by ocean - ocean points only (inverted landmask)
    res@use_ocean_mask = False
  end if  ; CFR circulation
  if (x .eq. "CMIP6-pan_arctic") then
    ; set the domain title and plotting map region
    res@title = "CMIP6/ERA5 - Arctic"
    res@map = "ease_nh50km_arctic"
    ; mask using lat/lon min/max ranges
    res@use_latlon_mask = False
    ; set the lat/lon min/max values
    res@max_lat = -999.
    res@min_lat = -999.
    res@max_lon = -999.  ;-125.W
    res@min_lon = -999.  ;170.E
    ; mask using i,j values from the input data
    res@use_ij_mask     = False
    ; set a threshold to mask values above a specified elevation
    res@use_elev_mask = True
    res@elev_mask_hgt = 500.
    ; mask by land - land points only (landmask)
    res@use_land_mask = False
    ; mask by ocean - ocean points only (inverted landmask)
    res@use_ocean_mask = False
  end if
  if (x .eq. "CMIP6-c_arctic") then
    ; set the domain title and plotting map region
    res@title = "CMIP6/ERA5 - Central Arctic"
    res@map = "ease_nh50km_c_arctic"
    ; mask using lat/lon min/max ranges
    res@use_latlon_mask = False
    ; set the lat/lon min/max values
    res@max_lat = -999.
    res@min_lat = -999.
    res@max_lon = -999.  ;-125.W
    res@min_lon = -999.  ;170.E
    ; mask using i,j values from the input data
    res@use_ij_mask     = True
    res@j_l = 18
    res@i_t = 45
    res@j_r = 153
    res@i_b = 123
    ; set a threshold to mask values above a specified elevation
    res@use_elev_mask = True
    res@elev_mask_hgt = 500.
    ; mask by land - land points only (landmask)
    res@use_land_mask = False
    ; mask by ocean - ocean points only (inverted landmask)
    res@use_ocean_mask = False
  end if
  if (x .eq. "CMIP6-n_pacific") then
    ; set the domain title and plotting map region
    res@title = "CMIP6/ERA5 - North Pacific"
    res@map = "ease_nh50km_n_pacific"
    ; mask using lat/lon min/max ranges
    res@use_latlon_mask = True
    ; set the lat/lon min/max values
    res@max_lat = 72.
    res@min_lat = 42.
    res@max_lon = 235.  ;-125.W
    res@min_lon = 140.  ;140.E
    ; mask using i,j values from the input data
    res@use_ij_mask     = False
    ; set a threshold to mask values above a specified elevation
    res@use_elev_mask = True
    res@elev_mask_hgt = 500.
    ; mask by land - land points only (landmask)
    res@use_land_mask = False
    ; mask by ocean - ocean points only (inverted landmask)
    res@use_ocean_mask = False
  end if
  if (x .eq. "CMIP6-n_pacific_old") then
    ; set the domain title and plotting map region
    res@title = "CMIP6/ERA5 - North Pacific"
    res@map = "ease_nh50km_n_pacific"
    ; mask using lat/lon min/max ranges
    res@use_latlon_mask = True
    ; set the lat/lon min/max values
    res@max_lat = 70.
    res@min_lat = 42.
    res@max_lon = 230.  ;-130.W
    res@min_lon = 140.  ;140.E
    ; mask using i,j values from the input data
    res@use_ij_mask     = False
    ; set a threshold to mask values above a specified elevation
    res@use_elev_mask = True
    res@elev_mask_hgt = 500.
    ; mask by land - land points only (landmask)
    res@use_land_mask = False
    ; mask by ocean - ocean points only (inverted landmask)
    res@use_ocean_mask = False
  end if
  if (x .eq. "CMIP6-n_atlantic") then
    ; set the domain title and plotting map region
    res@title = "CMIP6/ERA5 - North Atlantic"
    res@map = "ease_nh50km_n_atlantic"
    ; mask using lat/lon min/max ranges
    res@use_latlon_mask = True
    ; set the lat/lon min/max values
    res@max_lat = 80.
    res@min_lat = 52.
    res@max_lon = 55.  ;15.E
    res@min_lon = -60. ;60.W
    ; mask using i,j values from the input data
    res@use_ij_mask     = False
    ; set a threshold to mask values above a specified elevation
    res@use_elev_mask = True
    res@elev_mask_hgt = 500.
    ; mask by land - land points only (landmask)
    res@use_land_mask = False
    ; mask by ocean - ocean points only (inverted landmask)
    res@use_ocean_mask = False
  end if
  if (x .eq. "nordic_seas") then
    ; set the domain title and plotting map region
    res@title = "Nordic Seas"
    res@map = "nordic_seas"
    ; mask using lat/lon min/max ranges
    res@use_latlon_mask = True
    ; set the lat/lon min/max values
    res@min_lat = 55.
    res@max_lat = 83.
    res@min_lon = -45.   ;45.W
    res@max_lon =  30.   ;30.E
    ; set a threshold to mask values above a specified elevation
    res@use_elev_mask = False
    res@elev_mask_hgt = 10.
    ; mask by land - land points only (landmask)
    res@use_land_mask = False
    ; mask by ocean - ocean points only (inverted landmask)
    res@use_ocean_mask = True
  end if
  ; pan_arctic - from RASM work
  if (x .eq. "AK") then
    ; set the domain title and plotting map region
    res@title = "Alaska"
    res@map = "alaska_som"
    ; mask using lat/lon min/max ranges
    res@use_latlon_mask = True
    ; set the lat/lon min/max values
    res@max_lat = 80.
    res@min_lat = 50.
    res@max_lon = 235.  ;-125.W
    res@min_lon = 170.  ;170.E
    ; set a threshold to mask values above a specified elevation
    res@use_elev_mask = False
    ; mask by land - land points only (landmask)
    res@use_land_mask = False
    ; mask by ocean - ocean points only (inverted landmask)
    res@use_ocean_mask = False
  end if
  if (x .eq. "AK-slp") then
    ; set the domain title and plotting map region
    res@title = "Alaska"
    res@map = "alaska_som"
    ; mask using lat/lon min/max ranges
    res@use_latlon_mask = True
    ; set the lat/lon min/max values
    res@max_lat = 80.
    res@min_lat = 50.
    res@max_lon = 235.  ;-125.W
    res@min_lon = 170.  ;170.E
    ; set a threshold to mask values above a specified elevation
    res@use_elev_mask = True
    res@elev_mask_hgt = 500.
    ; mask by land - land points only (landmask)
    res@use_land_mask = False
    ; mask by ocean - ocean points only (inverted landmask)
    res@use_ocean_mask = False
  end if
  if (x .eq. "NSA-large") then
    ; set the domain title and plotting map region
    res@title = "Alaska"
    res@map = "kara_alaska_1"
    ; mask using lat/lon min/max ranges
    res@use_latlon_mask = False
    ; set the lat/lon min/max values
    res@max_lat = -999.
    res@min_lat = -999.
    res@max_lon = -999.
    res@min_lon = -999.
    ; mask using i,j values from the input data
    res@use_ij_mask     = True
    res@j_l = 100
    res@i_t = 150
    res@j_r = 100 + 130
    res@i_b = 150 + 130
    ; set a threshold to mask values above a specified elevation
    res@use_elev_mask = True
    res@elev_mask_hgt = 500.
    ; mask by land - land points only (landmask)
    res@use_land_mask = False
    ; mask by ocean - ocean points only (inverted landmask)
    res@use_ocean_mask = False
  end if
  if (x .eq. "NSA-small") then
    ; set the domain title and plotting map region
    res@title = "Alaska"
    res@map = "kara_alaska_1"
    ; mask using lat/lon min/max ranges
    res@use_latlon_mask = False
    ; set the lat/lon min/max values
    res@max_lat = -999.
    res@min_lat = -999.
    res@max_lon = -999.  ;-125.W
    res@min_lon = -999.  ;170.E
    ; mask using i,j values from the input data
    res@use_ij_mask     = True
    res@j_l = 135
    res@i_t = 180
    res@j_r = 135 + 75
    res@i_b = 180 + 75
    ; set a threshold to mask values above a specified elevation
    res@use_elev_mask = True
    res@elev_mask_hgt = 500.
    ; mask by land - land points only (landmask)
    res@use_land_mask = False
    ; mask by ocean - ocean points only (inverted landmask)
    res@use_ocean_mask = False
  end if
  if (x .eq. "GrARCSIX") then
    ; set the domain title and plotting map region
    res@title = "Greenland ARCSIX"
    res@map = "amy_greenland_1"
    ; mask using lat/lon min/max ranges
    res@use_latlon_mask = True
    ; set the lat/lon min/max values
    res@max_lat = 90.
    res@min_lat = 72.
    res@max_lon = 10.
    res@min_lon = -90.
    ; mask using i,j values from the input data
    res@use_ij_mask     = False
    ; set a threshold to mask values above a specified elevation
    res@use_elev_mask = False
    ;res@elev_mask_hgt = 500.
    ; mask by land - land points only (landmask)
    res@use_land_mask = False
    ; mask by ocean - ocean points only (inverted landmask)
    res@use_ocean_mask = False
  end if
  if (x .eq. "CW") then  ; slightly modified from slp for Z850
    ; set the domain title and plotting map region
    res@title = "Canada West"  
    res@map = "canada_west_som"
    ; mask using lat/lon min/max ranges
    res@use_latlon_mask = True
    ; set the lat/lon min/max values
    res@max_lat = 78
    res@min_lat = 52
    res@max_lon = 260.  ;-100.W
    res@min_lon = 185.  ;-175.W
    ; set a threshold to mask values above a specified elevation
    res@use_elev_mask = False
    ; mask by land - land points only (landmask)
    res@use_land_mask = False
    ; mask by ocean - ocean points only (inverted landmask)
    res@use_ocean_mask = False
  end if
  if (x .eq. "CW-slp") then
    ; set the domain title and plotting map region
    res@title = "Canada West"  
    res@map = "canada_west_circ"
    ; mask using lat/lon min/max ranges
    res@use_latlon_mask = True
    ; set the lat/lon min/max values
    res@max_lat = 81
    res@min_lat = 52
    res@max_lon = 265.  ;-95.W
    res@min_lon = 200.  ;-160.W
    ; set a threshold to mask values above a specified elevation
    res@use_elev_mask = True
    res@elev_mask_hgt = 500.
    ; mask by land - land points only (landmask)
    res@use_land_mask = False
    ; mask by ocean - ocean points only (inverted landmask)
    res@use_ocean_mask = False
  end if
  if (x .eq. "CA") then
    ; set the domain title and plotting map region
    res@title = "Canada Archipelago"  
    res@map = "canada_arch_som"
    ; mask using lat/lon min/max ranges
    res@use_latlon_mask = True
    ; set the lat/lon min/max values
    res@max_lat = 87.
    res@min_lat = 59.
    res@max_lon = 308.  ;-52.W
    res@min_lon = 203.  ;-157.W
    ; set a threshold to mask values above a specified elevation
    res@use_elev_mask = False
    ; mask by land - land points only (landmask)
    res@use_land_mask = False
    ; mask by ocean - ocean points only (inverted landmask)
    res@use_ocean_mask = False
  end if
  if (x .eq. "CA-slp") then
    ; set the domain title and plotting map region
    res@title = "Canada Archipelago"  
    res@map = "canada_arch_som"
    ; mask using lat/lon min/max ranges
    res@use_latlon_mask = True
    ; set the lat/lon min/max values
    res@max_lat = 87.
    res@min_lat = 59.
    res@max_lon = 308.  ;-52.W
    res@min_lon = 203.  ;-157.W
    ; set a threshold to mask values above a specified elevation
    res@use_elev_mask = True
    res@elev_mask_hgt = 500.
    ; mask by land - land points only (landmask)
    res@use_land_mask = False
    ; mask by ocean - ocean points only (inverted landmask)
    res@use_ocean_mask = False
  end if
  if (x .eq. "NAA") then
    ; set the domain title and plotting map region
    res@title = "North American Arctic"  
    res@map = "n_american_arctic_som"
    ; mask using lat/lon min/max ranges
    res@use_latlon_mask = True
    ; set the lat/lon min/max values
    res@max_lat = 90.
    res@min_lat = 50.
    res@max_lon = 310.  ;-50.W
    res@min_lon = 180.  ;-180.W
    ; set a threshold to mask values above a specified elevation
    res@use_elev_mask = False
    ; mask by land - land points only (landmask)
    res@use_land_mask = False
    ; mask by ocean - ocean points only (inverted landmask)
    res@use_ocean_mask = False
  end if
  if (x .eq. "NAA-slp") then
    ; set the domain title and plotting map region
    res@title = "North American Arctic"  
    res@map = "n_american_arctic_som"
    ; mask using lat/lon min/max ranges
    res@use_latlon_mask = True
    ; set the lat/lon min/max values
    res@max_lat = 90.
    res@min_lat = 50.
    res@max_lon = 310.  ;-50.W
    res@min_lon = 180.  ;-180.W
    ; set a threshold to mask values above a specified elevation
    res@use_elev_mask = True
    res@elev_mask_hgt = 500.
    ; mask by land - land points only (landmask)
    res@use_land_mask = False
    ; mask by ocean - ocean points only (inverted landmask)
    res@use_ocean_mask = False
  end if
  ; West Antarctica - for Amundsen Sea study
  if (x .eq. "amundsen_sea-std") then
    ; set the domain title and plotting map region
    res@title = "Amundsen Sea - Standard"  
    res@map = "amundsen_sea-std"
    ; mask using lat/lon min/max ranges
    res@use_latlon_mask = True
    ; set the lat/lon min/max values
    res@max_lat = -60.  ;60.S
    res@min_lat = -80.  ;80.S
    res@max_lon = 285.  ;75.W
    res@min_lon = 225.  ;135.W
    ; set a threshold to mask values above a specified elevation
    res@use_elev_mask = False
    ; mask by land - land points only (landmask)
    res@use_land_mask = False
    ; mask by ocean - ocean points only (inverted landmask)
    res@use_ocean_mask = False
  end if
  if (x .eq. "amundsen_sea-std-ocn") then
    ; set the domain title and plotting map region
    res@title = "Amundsen Sea - Standard"  
    res@map = "amundsen_sea-std-ocn"
    ; mask using lat/lon min/max ranges
    res@use_latlon_mask = True
    ; set the lat/lon min/max values
    res@max_lat = -60.  ;60.S
    res@min_lat = -75.  ;75.S
    res@max_lon = 285.  ;75.W
    res@min_lon = 225.  ;135.W
    ; set a threshold to mask values above a specified elevation
    res@use_elev_mask = True
    res@elev_mask_hgt = 10.
    ; mask by land - land points only (landmask)
    res@use_land_mask = False
    ; mask by ocean - ocean points only (inverted landmask)
    res@use_ocean_mask = False
  end if
  if (x .eq. "amundsen_sea-sm") then
    ; set the domain title and plotting map region
    res@title = "Amundsen Sea - Small"  
    res@map = "amundsen_sea-sm"
    ; mask using lat/lon min/max ranges
    res@use_latlon_mask = True
    ; set the lat/lon min/max values
    res@max_lat = -65.  ;65.S
    res@min_lat = -80.  ;80.S
    res@max_lon = 275.  ;85.W
    res@min_lon = 235.  ;125.W
    ; set a threshold to mask values above a specified elevation
    res@use_elev_mask = False
    ; mask by land - land points only (landmask)
    res@use_land_mask = False
    ; mask by ocean - ocean points only (inverted landmask)
    res@use_ocean_mask = False
  end if
  if (x .eq. "amundsen_sea-sm-ocn") then
    ; set the domain title and plotting map region
    res@title = "Amundsen Sea - Small"  
    res@map = "amundsen_sea-sm-ocn"
    ; mask using lat/lon min/max ranges
    res@use_latlon_mask = True
    ; set the lat/lon min/max values
    res@max_lat = -65.  ;65.S
    res@min_lat = -75.  ;75.S
    res@max_lon = 275.  ;85.W
    res@min_lon = 235.  ;125.W
    ; set a threshold to mask values above a specified elevation
    res@use_elev_mask = True
    res@elev_mask_hgt = 10.
    ; mask by land - land points only (landmask)
    res@use_land_mask = False
    ; mask by ocean - ocean points only (inverted landmask)
    res@use_ocean_mask = False
  end if
  if (x .eq. "amundsen_sea-lrg") then
    ; set the domain title and plotting map region
    res@title = "Amundsen Sea - Large"  
    res@map = "amundsen_sea-lrg"
    ; mask using lat/lon min/max ranges
    res@use_latlon_mask = True
    ; set the lat/lon min/max values
    res@max_lat = -60.  ;60.S
    res@min_lat = -80.  ;80.S
    res@max_lon = 290.  ;70.W
    res@min_lon = 195.  ;165.W
    ; set a threshold to mask values above a specified elevation
    res@use_elev_mask = False
    ; mask by land - land points only (landmask)
    res@use_land_mask = False
    ; mask by ocean - ocean points only (inverted landmask)
    res@use_ocean_mask = False
  end if
  if (x .eq. "rs_polynya") then
    ; set the domain title and plotting map region
    res@title = "Ross Sea Polyna"  
    res@map = "rs_polynya-som"
    ; mask using lat/lon min/max ranges
    res@use_latlon_mask = True
    ; set the lat/lon min/max values
    res@max_lat = -76.  ;76.S
    res@min_lat = -79.  ;79.S
    res@max_lon = 181.  ;179.W
    res@min_lon = 165.  ;165.E
    ; set a threshold to mask values above a specified elevation
    res@use_elev_mask = False
    ; mask by land - land points only (landmask)
    res@use_land_mask = False
    ; mask by ocean - ocean points only (inverted landmask)
    res@use_ocean_mask = False
  end if
end
