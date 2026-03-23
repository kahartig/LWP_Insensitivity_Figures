;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; polar_plotting.ncl
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; -Two procedures to configure and set plotting paramaters for the polar regions
;   polarMapSettings - sets different mapping paramaters
;   polarPlotSettings - sets different plotting paramaters for a range of 
;                       meteorological variables
;
;  TODO:  Redo the map projections for the Extremes SOM regions using lat/lon
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; procedure to set the map settings for different dominas/projections
procedure polarMapSettings(x:string, res:logical)
  ; x:string         -variable indicating projection/domain name
  ; res:logical      -plotting resource to set map/projection settings
begin
  ; pan_arctic - from RASM work
  if (x .eq. "pan_arctic-wr50a") then
    ; projection settings
    res@mpProjection                = "Stereographic"   ; map projection
    res@mpLimitMode                 = "Points"          ; How to zoom in on map
    res@mpCenterLonF                = -114.             ; Change center lat/lon
    res@mpCenterLatF                = 90. 
    res@mpLeftPointLatF             = 26.
    res@mpLeftPointLonF             = 156.
    res@mpRightPointLatF            = 41.
    res@mpRightPointLonF            = -24.
    res@mpTopPointLatF              = 46.8
    res@mpTopPointLonF              = 66.
    res@mpBottomPointLatF           = 45.5
    res@mpBottomPointLonF           = -114.
    ; include plotting settings since it is more unique
    res@mpGridAndLimbOn             = True              ; Turn on lat/lon grid
    res@mpGridLineThicknessF        = 0.5               ; Grid thickness
    res@mpGridLineDashPattern       = 2                 ; Change dash pattern
    res@mpGridAndLimbDrawOrder      = "PostDraw"
    res@mpGridSpacingF              = 10.
  end if
  ; pan_arctic - arctic_cyclones
  if (x .eq. "pan_arctic-arctic_cyclones") then
    ; projection settings
    res@mpProjection                = "Stereographic"  ; map projection
    res@mpLimitMode                 = "Points"         ; How to zoom in on map
    res@mpCenterLonF                = 100.             ; Change center lat/lon
    res@mpCenterLatF                = 90. 
    res@mpLeftPointLatF             = 33.
    res@mpLeftPointLonF             = 10.
    res@mpRightPointLatF            = 33.
    res@mpRightPointLonF            = -170.
    res@mpTopPointLatF              = 42.
    res@mpTopPointLonF              = -80
    res@mpBottomPointLatF           = 42.
    res@mpBottomPointLonF           = 100.
    ; include plotting settings since it is more unique
    res@mpGridAndLimbOn             = True             ; Turn on lat/lon grid
    res@mpGridLineThicknessF        = 0.5              ; Grid thickness
    res@mpGridLineDashPattern       = 2                ; Change dash pattern
    res@mpGridAndLimbDrawOrder      = "PostDraw"
    res@mpGridSpacingF              = 10.
    res@pmLabelBarHeightF           = 0.06
    res@pmLabelBarOrthogonalPosF    = 0.02
  end if
  ; EASE 50km NH - Arctic (pan-Arctic SOM)
  if (x .eq. "ease_nh50km_arctic") then
    ; projection settings
    res@mpProjection                = "Stereographic"  ; map projection
    res@mpLimitMode                 = "Points"         ; How to zoom in on map
    res@mpCenterLonF                = 0.             ; Change center lat/lon
    res@mpCenterLatF                = 90. 
    res@mpLeftPointLatF             = 50.
    res@mpLeftPointLonF             = 90.
    res@mpRightPointLatF            = 50.
    res@mpRightPointLonF            = -90.
    res@mpTopPointLatF              = 50.
    res@mpTopPointLonF              = 0.
    res@mpBottomPointLatF           = 50.
    res@mpBottomPointLonF           = 180.
    ; include plotting settings since it is more unique
    res@mpGridAndLimbOn             = True             ; Turn on lat/lon grid
    res@mpGridLineThicknessF        = 0.5              ; Grid thickness
    res@mpGridLineDashPattern       = 2                ; Change dash pattern
    res@mpGridAndLimbDrawOrder      = "PostDraw"
    res@mpGridLatSpacingF           = 10.
    res@mpGridLonSpacingF           = 30.
    res@mpGridPolarLonSpacingF      = 90.
    res@pmLabelBarHeightF           = 0.06
    res@pmLabelBarOrthogonalPosF    = 0.02
  end if
  ; EASE 50km NH - Central Arctic (c_arctic SOM)
  if (x .eq. "ease_nh50km_c_arctic") then
    ; projection settings
    res@mpProjection                = "Stereographic"  ; map projection
    res@mpLimitMode                 = "Points"         ; How to zoom in on map
    res@mpCenterLonF                = 0.             ; Change center lat/lon
    res@mpCenterLatF                = 90. 
    res@mpLeftPointLatF             = 59.8
    res@mpLeftPointLonF             = 90.
    res@mpRightPointLatF            = 57.6
    res@mpRightPointLonF            = -90.
    res@mpTopPointLatF              = 73.4
    res@mpTopPointLonF              = 0.
    res@mpBottomPointLatF           = 69.8
    res@mpBottomPointLonF           = 180.
    ; include plotting settings since it is more unique
    res@mpGridAndLimbOn             = True             ; Turn on lat/lon grid
    res@mpGridLineThicknessF        = 0.5              ; Grid thickness
    res@mpGridLineDashPattern       = 2                ; Change dash pattern
    res@mpGridAndLimbDrawOrder      = "PostDraw"
    res@mpGridLatSpacingF           = 10.
    res@mpGridLonSpacingF           = 30.
    res@mpGridPolarLonSpacingF      = 90.
    res@pmLabelBarHeightF           = 0.06
    res@pmLabelBarOrthogonalPosF    = 0.02
  end if
  if (x .eq. "ease_nh50km_n_atlantic") then
    res@mpProjection                = "Stereographic"
    res@mpLimitMode                 = "LatLon"
    res@mpMinLatF                   = 52.
    res@mpMaxLatF                   = 80.
    res@mpMinLonF                   = -60.
    res@mpMaxLonF                   = 55.
    res@mpCenterLonF                = -2.5
    res@mpCenterLatF                = 66.
    ; include plotting settings since it is more unique
    res@mpGridAndLimbOn             = True             ; Turn on lat/lon grid
    res@mpGridLineThicknessF        = 0.5              ; Grid thickness
    res@mpGridLineDashPattern       = 2                ; Change dash pattern
    res@mpGridAndLimbDrawOrder      = "PostDraw"
    res@mpGridLatSpacingF           = 10.
    res@mpGridLonSpacingF           = 30.
    res@mpGridPolarLonSpacingF      = 90.
    res@pmLabelBarHeightF           = 0.06
    res@pmLabelBarOrthogonalPosF    = 0.02
  end if
  if (x .eq. "ease_nh50km_n_pacific") then
    res@mpProjection                = "Stereographic"
    res@mpLimitMode                 = "LatLon"
    res@mpMinLatF                   = 42.
    res@mpMaxLatF                   = 72.
    res@mpMinLonF                   = 140.
    res@mpMaxLonF                   = 235.
    res@mpCenterLonF                = 187.5
    res@mpCenterLatF                = 57.
    ; include plotting settings since it is more unique
    res@mpGridAndLimbOn             = True             ; Turn on lat/lon grid
    res@mpGridLineThicknessF        = 0.5              ; Grid thickness
    res@mpGridLineDashPattern       = 2                ; Change dash pattern
    res@mpGridAndLimbDrawOrder      = "PostDraw"
    res@mpGridLatSpacingF           = 10.
    res@mpGridLonSpacingF           = 30.
    res@mpGridPolarLonSpacingF      = 90.
    res@pmLabelBarHeightF           = 0.06
    res@pmLabelBarOrthogonalPosF    = 0.02
  end if
  if (x .eq. "ease_nh50km_n_pacific_old") then
    ;res@mpProjection                = "Stereographic"
    ;res@mpLimitMode                 = "LatLon"
    ;res@mpMinLatF                   = 42.
    ;res@mpMaxLatF                   = 70.
    ;res@mpMinLonF                   = 140.
    ;res@mpMaxLonF                   = 230.
    ;res@mpCenterLonF                = 180.
    ;res@mpCenterLatF                = 90.
    res@mpLimitMode                 = "Corners"
    res@mpLeftCornerLatF            = 38.1    
    res@mpLeftCornerLonF            = 146. 
    res@mpRightCornerLatF           = 47.5  
    res@mpRightCornerLonF           = 251.
    res@mpCenterLonF                = 180.             ; Change center lat/lon
    res@mpCenterLatF                = 90. 
    ; include plotting settings since it is more unique
    res@mpGridAndLimbOn             = True             ; Turn on lat/lon grid
    res@mpGridLineThicknessF        = 0.5              ; Grid thickness
    res@mpGridLineDashPattern       = 2                ; Change dash pattern
    res@mpGridAndLimbDrawOrder      = "PostDraw"
    res@mpGridLatSpacingF           = 10.
    res@mpGridLonSpacingF           = 30.
    res@mpGridPolarLonSpacingF      = 90.
    res@pmLabelBarHeightF           = 0.06
    res@pmLabelBarOrthogonalPosF    = 0.02
  end if
  if (x .eq. "arctic-seaice") then
    res@mpProjection                = "Stereographic"
    res@mpLimitMode                 = "Corners"
    res@mpLeftCornerLatF            = 40.
    res@mpLeftCornerLonF            = -135.
    res@mpRightCornerLatF           = 40.
    res@mpRightCornerLonF           = 45.
    res@mpCenterLonF                = 0.
    res@mpCenterLatF                = 90.
    res@mpGridLatSpacingF           = 10
    res@mpGridLonSpacingF           = 15
    res@pmLabelBarHeightF           = 0.1
    res@pmLabelBarOrthogonalPosF    = -0.02
    ; additional plotting settings since
    res@mpGridAndLimbOn             = True              ; Turn on lat/lon grid
    res@mpGridLineThicknessF        = 0.5               ; Grid thickness
    res@mpGridLineDashPattern       = 2                 ; Change dash pattern
    res@mpGridAndLimbDrawOrder      = "PostDraw"
  end if
  if (x .eq. "nordic_seas") then
    res@mpProjection                = "Stereographic"
    res@mpLimitMode                 = "LatLon"
    res@mpMinLatF                   = 55.
    res@mpMaxLatF                   = 84.
    res@mpMinLonF                   = -45.
    res@mpMaxLonF                   = 15.
    res@mpCenterLonF                = -15.
    res@mpCenterLatF                = 69.
  end if
  if (x .eq. "amy_greenland_1") then
    res@mpProjection                = "Stereographic"
    res@mpLimitMode                 = "LatLon"
    res@mpMinLatF                   = 52.
    res@mpMaxLatF                   = 90.
    res@mpMinLonF                   = -60.
    res@mpMaxLonF                   = 55.
    res@mpCenterLonF                = -2.5
    res@mpCenterLatF                = 66.
  end if
  if (x .eq. "CFR_circ") then
    ;res@mpProjection                = "CylindricalEquidistant"
    res@mpProjection                 = "LambertConformal"  ; choose projection
    res@mpLambertParallel1F          = 33.0                ; two parallels
    res@mpLambertParallel2F          = 45.0
    res@mpLambertMeridianF           = -106.0               ; central meridian
    res@mpLimitMode                 = "LatLon"
    res@mpMinLatF                   = 35.
    res@mpMaxLatF                   = 44.
    res@mpMinLonF                   = -115.
    res@mpMaxLonF                   = -97.
    res@mpOutlineOn                 = True
    res@mpOutlineBoundarySets       = "GeophysicalAndUSStates"
    ;res@mpOutlineBoundarySets       = "USStates"
    end if
  ; Liz Cassano - Alaksa 1
  if (x .eq. "liz_alaska_1") then
    res@mpProjection                = "Stereographic"
    res@mpLimitMode                 = "Corners"
    res@mpLeftCornerLatF            = 50.    
    res@mpLeftCornerLonF            = 160. 
    res@mpRightCornerLatF           = 50.  
    res@mpRightCornerLonF           = -110.
    res@mpCenterLonF                = -114.
    res@mpCenterLatF                = 90.
  end if
  ; Kara Hartig - Alaska 1
  if (x .eq. "kara_alaska_1") then
    res@mpProjection                = "Stereographic"
    res@mpLimitMode                 = "Corners"
    res@mpLeftCornerLatF            = 50.    
    res@mpLeftCornerLonF            = 140. 
    res@mpRightCornerLatF           = 45.  
    res@mpRightCornerLonF           = -80.
    res@mpCenterLonF                = -114.
    res@mpCenterLatF                = 80.
  end if
  ; Alaska - circulation (Extremes)
  if (x .eq. "alaska_circ") then
    res@mpProjection                = "Stereographic"
    res@mpLimitMode                 = "Corners"
    res@mpLeftCornerLatF            = 72.    
    res@mpLeftCornerLonF            = 134. 
    res@mpRightCornerLatF           = 42.  
    res@mpRightCornerLonF           = -138.
    res@mpCenterLonF                = -160.
    res@mpCenterLatF                = 66.
  end if
  ; Alaska - SOM (Extremes)
  if (x .eq. "alaska_som") then
    res@mpProjection                = "Stereographic"
    res@mpLimitMode                 = "LatLon"
    res@mpMinLatF                   = 50.
    res@mpMaxLatF                   = 80.
    res@mpMinLonF                   = 170.
    res@mpMaxLonF                   = 235.
    res@mpCenterLonF                = 202.5
    res@mpCenterLatF                = 75.
  end if
  ; Alaska - physics/fluxes (Extremes)
  if (x .eq. "alaska_phys") then
    res@mpProjection                = "Stereographic"
    res@mpLimitMode                 = "Corners"
    res@mpLeftCornerLatF            = 70.    
    res@mpLeftCornerLonF            = 172. 
    res@mpRightCornerLatF           = 52.5  
    res@mpRightCornerLonF           = -135.
    res@mpCenterLonF                = -155.
    res@mpCenterLatF                = 64.
  end if
  ; Alaska - Arctic Impacts
  if (x .eq. "alaska_arctic_impacts") then
    res@mpProjection                = "Stereographic"
    res@mpLimitMode                 = "LatLon"
    res@mpMinLatF                   = 47.
    res@mpMaxLatF                   = 82.
    res@mpMinLonF                   = 168.
    res@mpMaxLonF                   = 232.
    res@mpCenterLonF                = 200.
    res@mpCenterLatF                = 65.
  end if
  ; Canada Archipelago - circulation (Extremes)
  if (x .eq. "canada_arch_circ") then
    res@mpProjection                = "Stereographic"
    res@mpLimitMode                 = "Corners"
    res@mpLeftCornerLatF            = 70.    
    res@mpLeftCornerLonF            = 165. 
    res@mpRightCornerLatF           = 55.  
    res@mpRightCornerLonF           = -69.
    res@mpCenterLonF                = -105.
    res@mpCenterLatF                = 73.
  end if
  ; Canada Archipelago - SOM (Extremes)
  if (x .eq. "canada_arch_som") then
    res@mpProjection                = "Stereographic"
    res@mpLimitMode                 = "LatLon"
    res@mpMinLatF                   = 59.
    res@mpMaxLatF                   = 87.
    res@mpMinLonF                   = 203.
    res@mpMaxLonF                   = 308.
    res@mpCenterLonF                = 255.5
    res@mpCenterLatF                = 73.
  end if
  ; Canada Archipelago - physics/fluxes (Extremes)
  if (x .eq. "canada_arch_phys") then
    res@mpProjection                = "Stereographic"
    res@mpLimitMode                 = "Corners"
    res@mpLeftCornerLatF            = 78.    
    res@mpLeftCornerLonF            = -160. 
    res@mpRightCornerLatF           = 60.  
    res@mpRightCornerLonF           = -64.
    res@mpCenterLonF                = -93.
    res@mpCenterLatF                = 74.
  end if
  ; Canada West - circulation (Extremes) / also includes the slp_anom SOM
  if (x .eq. "canada_west_circ") then
    res@mpProjection                = "Stereographic"
    res@mpLimitMode                 = "Corners"
    res@mpLeftCornerLatF            = 69.    
    res@mpLeftCornerLonF            = 161. 
    res@mpRightCornerLatF           = 47.5  
    res@mpRightCornerLonF           = -98.
    res@mpCenterLonF                = -127.
    res@mpCenterLatF                = 66.
  end if
  ; Canada West - SOM (Z850 / Z850_anom SOM)
  if (x .eq. "canada_west_som") then
    res@mpProjection                = "Stereographic"
    res@mpLimitMode                 = "LatLon"
    res@mpMinLatF                   = 52.
    res@mpMaxLatF                   = 78.
    res@mpMinLonF                   = 185.
    res@mpMaxLonF                   = 260.
    res@mpCenterLonF                = 222.5
    res@mpCenterLatF                = 65.
  end if
  ; Canada West - physics/fluxes (Extremes)
  if (x .eq. "canada_west_phys") then
    res@mpProjection                = "Stereographic"
    res@mpLimitMode                 = "Corners"
    res@mpLeftCornerLatF            = 72.    
    res@mpLeftCornerLonF            = -155. 
    res@mpRightCornerLatF           = 59.  
    res@mpRightCornerLonF           = -107.
    res@mpCenterLonF                = -125.
    res@mpCenterLatF                = 66.
  end if
  ; North American Arctic - SOM (Extremes)
  if (x .eq. "n_american_arctic_som") then
    res@mpProjection                = "Stereographic"
    res@mpLimitMode                 = "Corners"
    res@mpLeftCornerLatF            = 38.    
    res@mpLeftCornerLonF            = -157. 
    res@mpRightCornerLatF           = 52.  
    res@mpRightCornerLonF           = -25.
    res@mpCenterLonF                = -114.
    res@mpCenterLatF                = 90.
  end if
  if (x .eq. "pan_antarctic-lrg") then
    res@mpProjection                = "Stereographic"
    res@mpLimitMode                 = "Corners"
    res@mpLeftCornerLatF            = -47.
    res@mpLeftCornerLonF            = -45.
    res@mpRightCornerLatF           = -47.
    res@mpRightCornerLonF           = 135.
    res@mpCenterLonF                = 0.
    res@mpCenterLatF                = -90.
    res@mpGridLatSpacingF           = 5
    res@mpGridLonSpacingF           = 5
    res@pmLabelBarHeightF           = 0.1
    res@pmLabelBarOrthogonalPosF    = -0.02
  end if
  if (x .eq. "pan_antarctic-xlrg") then
    res@mpProjection                = "Stereographic"
    res@mpLimitMode                 = "Corners"
    res@mpLeftCornerLatF            = -30.
    res@mpLeftCornerLonF            = -45.
    res@mpRightCornerLatF           = -30.
    res@mpRightCornerLonF           = 135.
    res@mpCenterLonF                = 0.
    res@mpCenterLatF                = -90.
    res@mpGridLatSpacingF           = 5
    res@mpGridLonSpacingF           = 5
    res@pmLabelBarHeightF           = 0.1
    res@pmLabelBarOrthogonalPosF    = -0.02
  end if
  if (x .eq. "pan_antarctic-xxlrg") then
    res@mpProjection                = "Stereographic"
    res@mpLimitMode                 = "Corners"
    res@mpLeftCornerLatF            = -20.
    res@mpLeftCornerLonF            = -45.
    res@mpRightCornerLatF           = -20.
    res@mpRightCornerLonF           = 135.
    res@mpCenterLonF                = 0.
    res@mpCenterLatF                = -90.
    res@mpGridLatSpacingF           = 5
    res@mpGridLonSpacingF           = 5
    res@pmLabelBarHeightF           = 0.1
    res@pmLabelBarOrthogonalPosF    = -0.02
  end if
  ; AMPS - d2 - western Ross Ice Shelf / Ross Sea
  if (x .eq. "amps-w_ris") then
    res@mpProjection                = "Stereographic"
    res@mpLimitMode                 = "Corners"
    res@mpLeftCornerLatF            = -80.49  ;inner i,j = 42,4
    res@mpLeftCornerLonF            = 140.2
    res@mpRightCornerLatF           = -73.10  ;inner i,j = 110,70
    res@mpRightCornerLonF           = -169.7
    res@mpCenterLonF                = 180.
    res@mpCenterLatF                = -90.
    res@mpGridLatSpacingF           = 1
    res@mpGridLonSpacingF           = 5
    res@pmLabelBarHeightF           = 0.1
    res@pmLabelBarOrthogonalPosF    = -0.02
  end if
  ; AMPS - d3
  if (x .eq. "amps_d3") then
    res@mpProjection                = "Stereographic"
    res@mpLimitMode                 = "Corners"
    res@mpLeftCornerLatF            = -79.9
    res@mpLeftCornerLonF            = -60.
    res@mpRightCornerLatF           = -67.6  
    res@mpRightCornerLonF           = 158
    res@mpCenterLonF                = 0.
    res@mpCenterLatF                = -90.
    res@mpGridLatSpacingF           = 1
    res@mpGridLonSpacingF           = 5
    res@pmLabelBarHeightF           = 0.1
    res@pmLabelBarOrthogonalPosF    = -0.02
  end if
  ; AMPS - d5
  if (x .eq. "amps_d5") then
    res@mpProjection                = "Stereographic"
    res@mpLimitMode                 = "Corners"
    res@mpLeftCornerLatF            = -80.4
    res@mpLeftCornerLonF            = 141.
    res@mpRightCornerLatF           = -74.8  
    res@mpRightCornerLonF           = -177.8
    res@mpCenterLonF                = 180.
    res@mpCenterLatF                = -90.
    res@mpGridLatSpacingF           = 1
    res@mpGridLonSpacingF           = 5
    res@pmLabelBarHeightF           = 0.1
    res@pmLabelBarOrthogonalPosF    = -0.02
  end if
  ; West Antarctica
  if (x .eq. "west_ant") then
    res@mpProjection                = "Stereographic"
    res@mpLimitMode                 = "Corners"
    res@mpLeftCornerLatF            = -71
    res@mpLeftCornerLonF            = -80.
    res@mpRightCornerLatF           = -76  
    res@mpRightCornerLonF           = -170
    res@mpCenterLonF                = 0.
    res@mpCenterLatF                = -90.
    res@mpGridLatSpacingF           = 1
    res@mpGridLonSpacingF           = 5
    res@pmLabelBarHeightF           = 0.1
    res@pmLabelBarOrthogonalPosF    = -0.02
  end if
  ; WRF W_Ant - zoom
  if (x .eq. "wrf-w_ant") then
    res@mpProjection                = "Stereographic"
    res@mpLimitMode                 = "Corners"
    res@mpLeftCornerLatF            = -67
    res@mpLeftCornerLonF            = -150.
    res@mpRightCornerLatF           = -77  
    res@mpRightCornerLonF           = -106
    res@mpCenterLonF                = -130.
    res@mpCenterLatF                = -90.
    res@mpGridLatSpacingF           = 5
    res@mpGridLonSpacingF           = 5
  end if
  ; Ross Island region
  if (x .eq. "ross_is_reg") then
    res@mpProjection                = "Stereographic"
    res@mpLimitMode                 = "LatLon"
    res@mpMinLatF                   = -79.5
    res@mpMaxLatF                   = -76.5
    res@mpMinLonF                   = 159.
    res@mpMaxLonF                   = 174.
    res@mpCenterLonF                = 166.5
    res@mpCenterLatF                = -78.
    res@mpGridLatSpacingF           = 5
    res@mpGridLonSpacingF           = 5
    res@pmLabelBarHeightF           = 0.1
    res@pmLabelBarOrthogonalPosF    = -0.02
  end if
  ; Ross Sea Polyna
  if (x .eq. "rs_polynya-basic") then
    res@mpProjection                = "Stereographic"
    res@mpLimitMode                 = "LatLon"
    res@mpMinLatF                   = -80.
    res@mpMaxLatF                   = -75.
    res@mpMinLonF                   = 163.
    res@mpMaxLonF                   = 181.
    res@mpCenterLonF                = 172.
    res@mpCenterLatF                = -77.5
    res@mpGridLatSpacingF           = 5
    res@mpGridLonSpacingF           = 5
    res@pmLabelBarHeightF           = 0.1
    res@pmLabelBarOrthogonalPosF    = -0.02
  end if
  if (x .eq. "rs_polynya-som") then
    res@mpProjection                = "Stereographic"
    res@mpLimitMode                 = "LatLon"
    res@mpMinLatF                   = -79.
    res@mpMaxLatF                   = -76.
    res@mpMinLonF                   = 165.
    res@mpMaxLonF                   = 181.
    res@mpCenterLonF                = 172.
    res@mpCenterLatF                = -77.5
    res@mpGridLatSpacingF           = 5
    res@mpGridLonSpacingF           = 5
    res@pmLabelBarHeightF           = 0.1
    res@pmLabelBarOrthogonalPosF    = -0.02
  end if
  ; Terra Nova Bay - UAV - flight path
  if (x .eq. "uav-pgs_tnb") then
    res@mpProjection                = "Stereographic"
    res@mpLimitMode                 = "LatLon"
    res@mpMinLatF                   = -78.5
    res@mpMaxLatF                   = -74.5
    res@mpMinLonF                   = 160.
    res@mpMaxLonF                   = 170.
    res@mpCenterLonF                = 165.
    res@mpCenterLatF                = -76.5
    res@mpGridLatSpacingF           = 5
    res@mpGridLonSpacingF           = 5
    res@pmLabelBarHeightF           = 0.1
    res@pmLabelBarOrthogonalPosF    = -0.02
  end if
  if (x .eq. "uav-pgs") then
    res@mpProjection                = "Stereographic"
    res@mpLimitMode                 = "LatLon"
    res@mpMinLatF                   = -78.5
    res@mpMaxLatF                   = -77.5
    res@mpMinLonF                   = 164.
    res@mpMaxLonF                   = 168.
    res@mpCenterLonF                = 166.
    res@mpCenterLatF                = -78.0
    res@mpGridLatSpacingF           = 5
    res@mpGridLonSpacingF           = 5
    res@pmLabelBarHeightF           = 0.1
    res@pmLabelBarOrthogonalPosF    = -0.02
  end if
  if (x .eq. "uav-pgs-sm") then
    res@mpProjection                = "Stereographic"
    res@mpLimitMode                 = "LatLon"
    res@mpMinLatF                   = -78.25
    res@mpMaxLatF                   = -77.75
    res@mpMinLonF                   = 165.5
    res@mpMaxLonF                   = 167.5
    res@mpCenterLonF                = 166.5
    res@mpCenterLatF                = -78.0
    res@mpGridLatSpacingF           = 5
    res@mpGridLonSpacingF           = 5
    res@pmLabelBarHeightF           = 0.1
    res@pmLabelBarOrthogonalPosF    = -0.02
  end if
  if (x .eq. "uav-tnb") then
    res@mpProjection                = "Stereographic"
    res@mpLimitMode                 = "LatLon"
    res@mpMinLatF                   = -76.0
    res@mpMaxLatF                   = -74.5
    res@mpMinLonF                   = 162.
    res@mpMaxLonF                   = 168.
    res@mpCenterLonF                = 165.
    res@mpCenterLatF                = -75.25
    res@mpGridLatSpacingF           = 5
    res@mpGridLonSpacingF           = 5
    res@pmLabelBarHeightF           = 0.1
    res@pmLabelBarOrthogonalPosF    = -0.02
  end if
  if (x .eq. "uav-tnb-sm") then
    res@mpProjection                = "Stereographic"
    res@mpLimitMode                 = "LatLon"
    res@mpMinLatF                   = -75.5
    res@mpMaxLatF                   = -74.5
    res@mpMinLonF                   = 163.
    res@mpMaxLonF                   = 168.
    res@mpCenterLonF                = 165.5
    res@mpCenterLatF                = -75.
    res@mpGridLatSpacingF           = 5
    res@mpGridLonSpacingF           = 5
    res@pmLabelBarHeightF           = 0.1
    res@pmLabelBarOrthogonalPosF    = -0.02
  end if
  if (x .eq. "uav-ri") then
    res@mpProjection                = "Stereographic"
    res@mpLimitMode                 = "LatLon"
    res@mpMinLatF                   = -78.5
    res@mpMaxLatF                   = -77.0
    res@mpMinLonF                   = 165.
    res@mpMaxLonF                   = 173.
    res@mpCenterLonF                = 169.
    res@mpCenterLatF                = -77.75
    res@mpGridLatSpacingF           = 5
    res@mpGridLonSpacingF           = 5
    res@pmLabelBarHeightF           = 0.1
    res@pmLabelBarOrthogonalPosF    = -0.02
  end if
  if (x .eq. "amundsen_sea-std") then
    res@mpProjection                = "Stereographic"
    res@mpLimitMode                 = "LatLon"
    res@mpMinLatF                   = -80.
    res@mpMaxLatF                   = -60.
    res@mpMinLonF                   = 225.
    res@mpMaxLonF                   = 285.
    res@mpCenterLonF                = -105.
    res@mpCenterLatF                = -70.
    res@mpGridLatSpacingF           = 5
    res@mpGridLonSpacingF           = 5
    res@pmLabelBarHeightF           = 0.1
    res@pmLabelBarOrthogonalPosF    = -0.02
  end if
  if (x .eq. "amundsen_sea-std-ocn") then
    res@mpProjection                = "Stereographic"
    res@mpLimitMode                 = "LatLon"
    res@mpMinLatF                   = -75.
    res@mpMaxLatF                   = -60.
    res@mpMinLonF                   = 225.
    res@mpMaxLonF                   = 285.
    res@mpCenterLonF                = -105.
    res@mpCenterLatF                = -67.5
    res@mpGridLatSpacingF           = 5
    res@mpGridLonSpacingF           = 5
    res@pmLabelBarHeightF           = 0.1
    res@pmLabelBarOrthogonalPosF    = -0.02
  end if
  if (x .eq. "amundsen_sea-sm") then
    res@mpProjection                = "Stereographic"
    res@mpLimitMode                 = "LatLon"
    res@mpMinLatF                   = -80.5
    res@mpMaxLatF                   = -64.5
    res@mpMinLonF                   = 235.
    res@mpMaxLonF                   = 275.
    res@mpCenterLonF                = -105.
    res@mpCenterLatF                = -72.5
    res@mpGridLatSpacingF           = 5
    res@mpGridLonSpacingF           = 5
    res@pmLabelBarHeightF           = 0.1
    res@pmLabelBarOrthogonalPosF    = -0.02
  end if
  if (x .eq. "amundsen_sea-sm-ocn") then
    res@mpProjection                = "Stereographic"
    res@mpLimitMode                 = "LatLon"
    res@mpMinLatF                   = -75.5
    res@mpMaxLatF                   = -64.5
    res@mpMinLonF                   = 235.
    res@mpMaxLonF                   = 275.
    res@mpCenterLonF                = -105.
    res@mpCenterLatF                = -70.
    res@mpGridLatSpacingF           = 5
    res@mpGridLonSpacingF           = 5
    res@pmLabelBarHeightF           = 0.1
    res@pmLabelBarOrthogonalPosF    = -0.02
  end if
  if (x .eq. "amundsen_sea-lrg") then
    res@mpProjection                = "Stereographic"
    res@mpLimitMode                 = "LatLon"
    res@mpMinLatF                   = -80.5
    res@mpMaxLatF                   = -59.5
    res@mpMinLonF                   = 195.
    res@mpMaxLonF                   = 290.
    res@mpCenterLonF                = -117.5
    res@mpCenterLatF                = -70.
    res@mpGridLatSpacingF           = 5
    res@mpGridLonSpacingF           = 5
    res@pmLabelBarHeightF           = 0.1
    res@pmLabelBarOrthogonalPosF    = -0.04
  end if
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; procedure to set plot settings for a selected variable
procedure polarPlotSettings(x:string, res:logical, ores:logical)
; x:string         -plotting variable
; res:logical      -plotting resource for primary plot
; ores:logical -plotting resource for overlay plot
begin
  ; set the uniform resources attributes
  ; Note:  any of these attributes can still be set below for a given variable
  ;  -primary plot - color-filled contours
  res@cnFillOn                    = True
  res@cnLinesOn                   = False
  res@cnLineLabelsOn              = False
  res@cnInfoLabelOn               = False
  res@cnLineLabelBackgroundColor  = -1
  res@cnLevelSelectionMode        = "ManualLevels"
  ;  -overlay plot - line contours (non color-filled)
  ores@cnFillOn                   = False
  ores@cnLinesOn                  = True
  ores@cnLineLabelsOn             = False
  ores@cnInfoLabelOn              = False
  ores@cnLineLabelBackgroundColor = -1
  ores@cnLevelSelectionMode       = "ManualLevels"
  ores@gsnRightString             = ""
  ores@gsnLeftString              = ""
  ores@tiXAxisString              = ""
  ores@tiYAxisString              = ""
  ; set the contour attributes for specific variables and ranges
  if (x .eq. "x_diff-_05_05") then  ; a generic value
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = -.5
    res@cnMaxLevelValF          = .5
    res@cnLevelSpacingF         = .05
    res@cnFillPalette           = "BlueRed"
    res@cnSpanFillPalette       = True
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = .1
  end if
  if (x .eq. "x_diff-_1_1") then  ; a generic value
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = -1.
    res@cnMaxLevelValF          = 1.
    res@cnLevelSpacingF         = .05
    res@cnFillPalette           = "BlueRed"
    res@cnSpanFillPalette       = True
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = .1
  end if
  if (x .eq. "x_diff-_5_5") then  ; a generic value
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = -5.
    res@cnMaxLevelValF          = 5.
    res@cnLevelSpacingF         = .5
    res@cnFillPalette           = "BlueRed"
    res@cnSpanFillPalette       = True
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 1.
  end if
  if (x .eq. "LH-_50_50") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = -50.
    res@cnMaxLevelValF          = 50.
    res@cnLevelSpacingF         = 5.
    res@cnFillPalette           = "CBR_seq_BrOrYlWhGn_22"
    ;res@cnLevelSpacingF         = 10.
    ;res@cnFillPalette           = "CBR_seq_BrOrYlWhGn_12"
    res@cnSpanFillPalette       = True
    res@lbLabelStride           = 2
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 10.
  end if
  if (x .eq. "LH-_100_100") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = -100.
    res@cnMaxLevelValF          = 100.
    res@cnLevelSpacingF         = 10.
    res@cnFillPalette           = "CBR_seq_BrOrYlWhGn_22"
    ;res@cnLevelSpacingF         = 10.
    ;res@cnFillPalette           = "CBR_seq_BrOrYlWhGn_12"
    res@cnSpanFillPalette       = True
    res@lbLabelStride           = 2
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 20.
  end if
  if (x .eq. "LH-_75_75") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = -75.
    res@cnMaxLevelValF          = 75.
    res@cnLevelSpacingF         = 5.
    res@cnFillPalette           = "latentheat_color_table.ms"
    res@cnFillColors            = ispan(1,63,2)
    res@lbLabelStride           = 5
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 5.
  end if
  if (x .eq. "LH-_300_300") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = -300.
    res@cnMaxLevelValF          = 300.
    res@cnLevelSpacingF         = 10.
    res@cnFillPalette           = "latentheat_color_table.ms"
    res@cnFillColors            = ispan(1,62,1)
    res@lbLabelStride           = 5
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 20.
  end if
  if (x .eq. "LH-_800_800-nl") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnLevelSelectionMode    = "ExplicitLevels"
    res@cnLevels                = array_append_record(ispan(-800,-300,50),  \
                                  array_append_record(ispan(-280,-100,20),  \
                                  array_append_record(ispan(-90,100,10),  \
                                  array_append_record(ispan(120,300,20),  \
                                                      ispan(350,800,50),  \
                                                      0),0),0),0)
    res@cnMinLevelValF          = -800.  ; these settings are not used for
    res@cnMaxLevelValF          = 800.   ;  plotting, but for masking outliers
    res@cnLevelSpacingF         = 50.
    res@cnFillPalette           = "latentheat_color_table.ms"
    res@cnFillColors            = ispan(1,62,1)
    res@lbLabelStride           = 5
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnLevelSelectionMode    = "ExplicitLevels"
    ores@cnLevels                = array_append_record(ispan(-800,-300,100),  \
                                  array_append_record(ispan(-260,-100,40),  \
                                  array_append_record(ispan(-80,100,20),  \
                                  array_append_record(ispan(140,300,40),  \
                                                      ispan(400,800,100),  \
                                                      0),0),0),0)
  end if
  if (x .eq. "LW-100_400") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = 110.
    res@cnMaxLevelValF          = 400.
    res@cnLevelSpacingF         = 10.
    res@cnFillPalette           = "longwave_color_table.ms"
    res@cnFillColors            = ispan(0,60,2)
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = 100.
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 20.
  end if
  if (x .eq. "LW-0_400") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = 10.
    res@cnMaxLevelValF          = 400.
    res@cnLevelSpacingF         = 10.
    res@cnFillPalette           = "longwave_color_table.ms"
    res@cnSpanFillPalette       = True
    res@lbLabelStride           = 1
    res@cnExplicitLabelBarLabelsOn = True
    res@lbLabelStrings          =(/"","","","40","","","","80","","","","120", \
                                 "","","","160","","","","200","","","","240", \
                                 "","","","280","","","","320","","","","360", \
                                 "","","","400"/)
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = 0.
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 20.
  end if
  if (x .eq. "LW-0_600") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = 10.
    res@cnMaxLevelValF          = 600.
    res@cnLevelSpacingF         = 10.
    res@cnFillPalette           = "longwave_color_table.ms"
    res@cnFillColors            = ispan(0,60,1)
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = 0.
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 20.
  end if
  if (x .eq. "LW-_400_400") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = -400.
    res@cnMaxLevelValF          = 400.
    res@cnLevelSpacingF         = 20.
    res@cnFillPalette           = "BlueRed"
    res@cnFillColors            = ispan(4,250,6)
    res@lbLabelStride           = 5
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 40.
  end if
  if (x .eq. "LW-_200_400") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = -200.
    res@cnMaxLevelValF          = 400.
    res@cnLevelSpacingF         = 20.
    res@cnFillPalette           = "BlueRed"
    res@cnFillColors            = ispan(64,250,6)
    res@lbLabelStride           = 5
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 40.
  end if
  if (x .eq. "precip-0_10") then
    ; primary plot
    res@cnMissingValFillColor   = "white"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = 1.
    res@cnMaxLevelValF          = 10.
    res@cnLevelSpacingF         = 1.
    res@cnFillPalette           = "precip_color_table.mn"
    res@cnFillColors            = ispan(0,30,1)
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = 0.
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 1.
  end if
  if (x .eq. "precip-0_150") then
    ; primary plot
    res@cnMissingValFillColor   = "white"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = 10.
    res@cnMaxLevelValF          = 150.
    res@cnLevelSpacingF         = 5.
    res@cnFillPalette           = "precip_color_table.mn"
    res@cnFillColors            = ispan(0,30,1)
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = 0.
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 10.
  end if
  if (x .eq. "precip-0_200-nl") then
    ; primary plot
    res@cnMissingValFillColor   = "white"
    res@cnMissingValFillPattern = 0
    res@cnLevelSelectionMode    = "ExplicitLevels"
    res@cnLevels                = array_append_record(ispan(5,50,5),  \
                                  array_append_record(ispan(60,100,10),  \
                                                      ispan(120,200,20),0),0)

    res@cnMinLevelValF          = 0.     ; these settings are not used for
    res@cnMaxLevelValF          = 200.   ;  plotting, but for masking outliers
    res@cnLevelSpacingF         = 20.
    res@cnFillPalette           = "precip_color_table.mn"
    res@cnSpanFillPalette       = True
    res@lbLabelStride           = 1
    res@cnExplicitLabelBarLabelsOn = True
    res@lbLabelStrings          =(/"","10","","20","","30","","40","","50",   \
                                 "","","80","","100","","","160","","200"/)
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnLevelSelectionMode    = "ExplicitLevels"
    ores@cnLevels                = array_append_record(ispan(5,50,10),  \
                                  array_append_record(ispan(60,100,20),  \
                                                      ispan(120,200,40),0),0)
  end if
  if (x .eq. "sfc_net-_600_600") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = -600.
    res@cnMaxLevelValF          = 600.
    res@cnLevelSpacingF         = 20.
    res@cnFillPalette           = "BlueYellowRed"
    res@cnFillColors            = ispan(4,258,4)
    res@lbLabelStride           = 5
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 40.
  end if
  if (x .eq. "sfc_net-_800_800-nl") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnLevelSelectionMode    = "ExplicitLevels"
    res@cnLevels                = array_append_record(ispan(-800,-300,50),  \
                                  array_append_record(ispan(-280,-100,20),  \
                                  array_append_record(ispan(-90,100,10),  \
                                  array_append_record(ispan(120,300,20),  \
                                                      ispan(350,800,50),  \
                                                      0),0),0),0)
    res@cnMinLevelValF          = -800.  ; these settings are not used for
    res@cnMaxLevelValF          = 800.   ;  plotting, but for masking outliers
    res@cnLevelSpacingF         = 50.
    res@cnFillPalette           = "BlueYellowRed"
    res@cnFillColors            = ispan(4,258,4)
    res@lbLabelStride           = 5
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnLevelSelectionMode    = "ExplicitLevels"
    ores@cnLevels                = array_append_record(ispan(-800,-300,100),  \
                                  array_append_record(ispan(-260,-100,40),  \
                                  array_append_record(ispan(-80,100,20),  \
                                  array_append_record(ispan(140,300,40),  \
                                                      ispan(400,800,100),  \
                                                      0),0),0),0)
  end if
  if (x .eq. "SH-_300_300") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = -300.
    res@cnMaxLevelValF          = 300.
    res@cnLevelSpacingF         = 10.
    res@cnFillPalette           = "sensibleheat_color_table.mn"
    res@cnFillColors            = ispan(1,62,1)
    res@lbLabelStride           = 5
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 20.
  end if
  if (x .eq. "SH-_50_50") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = -50.
    res@cnMaxLevelValF          = 50.
    res@cnLevelSpacingF         = 5.
    res@cnFillPalette           = "CBR_seq_PuWhOr_22"
    ;res@cnLevelSpacingF         = 10.
    ;res@cnFillPalette           = "CBR_seq_PuWhOr_12"
    res@cnSpanFillPalette       = True
    res@lbLabelStride           = 2
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 10.
  end if
  if (x .eq. "SH-_100_100") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = -100.
    res@cnMaxLevelValF          = 100.
    res@cnLevelSpacingF         = 10.
    res@cnFillPalette           = "CBR_seq_PuWhOr_22"
    ;res@cnLevelSpacingF         = 10.
    ;res@cnFillPalette           = "CBR_seq_PuWhOr_12"
    res@cnSpanFillPalette       = True
    res@lbLabelStride           = 2
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 20.
  end if
  if (x .eq. "SH-_800_800-nl") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnLevelSelectionMode    = "ExplicitLevels"
    res@cnLevels                = array_append_record(ispan(-800,-300,50),  \
                                  array_append_record(ispan(-280,-100,20),  \
                                  array_append_record(ispan(-90,100,10),  \
                                  array_append_record(ispan(120,300,20),  \
                                                      ispan(350,800,50),  \
                                                      0),0),0),0)
    res@cnMinLevelValF          = -800.  ; these settings are not used for
    res@cnMaxLevelValF          = 800.   ;  plotting, but for masking outliers
    res@cnLevelSpacingF         = 50.
    res@cnFillPalette           = "sensibleheat_color_table.mn"
    res@cnFillColors            = ispan(1,62,1)
    res@lbLabelStride           = 5
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnLevelSelectionMode    = "ExplicitLevels"
    ores@cnLevels                = array_append_record(ispan(-800,-300,100),  \
                                  array_append_record(ispan(-260,-100,40),  \
                                  array_append_record(ispan(-80,100,20),  \
                                  array_append_record(ispan(140,300,40),  \
                                                      ispan(400,800,100),  \
                                                      0),0),0),0)
  end if
  if (x .eq. "p_sfc-600_1064") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = 600.
    res@cnMaxLevelValF          = 1064.
    res@cnLevelSpacingF         = 2.
    ;res@cnFillPalette           = "slp_color_table.ms"
    ;res@cnFillColors            = ispan(10,71,1)
    res@cnFillPalette           = "slp_anoms.dave"
    res@gsnSpreadColors         = True
    res@gsnSpreadColorStart     = 0
    res@gsnSpreadColorEnd       = 72
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 4.
  end if
  if (x .eq. "q_r-0_15") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = 0.
    res@cnMaxLevelValF          = 15.
    res@cnLevelSpacingF         = 0.5
    res@cnFillPalette           = "CBR_seq_BuGn_11"
    res@cnSpanFillPalette       = True
    ;res@cnFillColors            = ispan(10,71,1)
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 1.
  end if
  if (x .eq. "q_r_diff-_1_1") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = -1.
    res@cnMaxLevelValF          = 1.
    res@cnLevelSpacingF         = .1
    res@cnFillPalette           = "CBR_div_BrBG_11"
    res@cnSpanFillPalette       = True
    ; overlay plot
    ores@cnLineColor          = "black"
    ores@cnMinLevelValF       = res@cnMinLevelValF
    ores@cnMaxLevelValF       = res@cnMaxLevelValF
    ores@cnLevelSpacingF      = 0.2
  end if
  if (x .eq. "q_r_diff-_5_5") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = -5.
    res@cnMaxLevelValF          = 5.
    res@cnLevelSpacingF         = .5
    res@cnFillPalette           = "CBR_div_BrBG_11"
    res@cnSpanFillPalette       = True
    ; overlay plot
    ores@cnLineColor          = "black"
    ores@cnMinLevelValF       = res@cnMinLevelValF
    ores@cnMaxLevelValF       = res@cnMaxLevelValF
    ores@cnLevelSpacingF      = 1.
  end if
  if (x .eq. "siconc-0_1") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = 0.
    res@cnMaxLevelValF          = 1.
    res@cnLevelSpacingF         = 0.1
    res@cnFillPalette           = "CBR_seq_WhBu_11"
    res@cnSpanFillPalette       = True
    ;res@lbLabelStride           = 8
    ; overlay plot
    ores@cnLineColor          = "black"
    ores@cnMinLevelValF       = res@cnMinLevelValF
    ores@cnMaxLevelValF       = res@cnMaxLevelValF
    ores@cnLevelSpacingF      = 0.1
  end if
  if (x .eq. "sithick-0_8") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = 0.
    res@cnMaxLevelValF          = 8.
    res@cnLevelSpacingF         = 1.
    res@cnFillPalette           = "CBR_seq_WhRdPu_9"
    res@cnSpanFillPalette       = True
    ;res@lbLabelStride           = 8
    ; overlay plot
    ores@cnLineColor          = "black"
    ores@cnMinLevelValF       = res@cnMinLevelValF
    ores@cnMaxLevelValF       = res@cnMaxLevelValF
    ores@cnLevelSpacingF      = 1.
  end if
  if (x .eq. "slp-920_1040") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = 920.
    res@cnMaxLevelValF          = 1040.
    res@cnLevelSpacingF         = 2.
    res@cnFillPalette           = "slp_color_table.ms"
    res@cnFillColors            = ispan(10,71,1)
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 4.
  end if
  if (x .eq. "slp-920_1064") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = 920.
    res@cnMaxLevelValF          = 1064.
    res@cnLevelSpacingF         = 2.
    ;res@cnFillPalette           = "slp_color_table.ms"
    ;res@cnFillColors            = ispan(10,71,1)
    res@cnFillPalette           = "slp_anoms.dave"
    res@gsnSpreadColors         = True
    res@gsnSpreadColorStart     = 0
    res@gsnSpreadColorEnd       = 72
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 4.
  end if
  if (x .eq. "slp-940_1048") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = 940.
    res@cnMaxLevelValF          = 1048.
    res@cnLevelSpacingF         = 2.
    res@cnFillPalette           = "slp_color_table.ms"
    res@cnFillColors            = ispan(10,65,1)
    res@lbLabelStride           = 8
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 4.
  end if
  if (x .eq. "slp-980_1044") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = 980.
    res@cnMaxLevelValF          = 1044.
    res@cnLevelSpacingF         = 2.
    res@cnFillPalette           = "slp_color_table.ms"
    res@cnFillColors            = ispan(30,64,1)
    res@lbLabelStride           = 4
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 4.
  end if
  if (x .eq. "slp-940_1060") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = 940.
    res@cnMaxLevelValF          = 1060.
    res@cnLevelSpacingF         = 2.
    res@cnFillPalette           = "slp_color_table.ms"
    res@cnFillColors            = ispan(10,71,1)
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 4.
  end if
  if (x .eq. "slp_anom-_30_30") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = -30.
    res@cnMaxLevelValF          = 30.
    res@cnLevelSpacingF         = 2.
    res@cnFillPalette           = "slp_anom_color_table.ms"
    res@cnFillColors            = ispan(18,80,2)
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 4.
  end if
  if (x .eq. "slp_anom-_24_24") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = -24.
    res@cnMaxLevelValF          = 24.
    res@cnLevelSpacingF         = 2.
    res@cnFillPalette           = "slp_anom_color_table.ms"
    res@cnFillColors            = ispan(24,74,2)
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 4.
  end if
  if (x .eq. "slp_anom-_48_48") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = -48.
    res@cnMaxLevelValF          = 48.
    res@cnLevelSpacingF         = 2.
    res@cnFillPalette           = "slp_anom_color_table.ms"
    res@cnFillColors            = ispan(0,98,2)
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 4.
  end if
  if (x .eq. "slp_diff-_5_5") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = -5.
    res@cnMaxLevelValF          = 5.
    res@cnLevelSpacingF         = 0.5
    res@cnFillPalette           = "CBR_seq_BuWhRd_22"
    res@cnSpanFillPalette       = True
    res@lbLabelStride           = 2
    ;res@cnLevelSpacingF         = .1
    ;res@cnFillPalette           = "MPL_bwr"
    ;res@cnSpanFillPalette       = True
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 1.
    ;ores@cnLevelSpacingF        = .2
  end if
  if (x .eq. "slp_diff-_10_10") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = -10.
    res@cnMaxLevelValF          = 10.
    res@cnLevelSpacingF         = 1.
    res@cnFillPalette           = "CBR_seq_BuWhRd_22"
    res@cnSpanFillPalette       = True
    res@lbLabelStride           = 1
    ;res@cnLevelSpacingF         = .5
    ;res@cnFillPalette           = "MPL_bwr"
    ;res@cnSpanFillPalette       = True
    ;res@lbLabelStride           = 4
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 1.
  end if
  if (x .eq. "SW-_50_50") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = -50.
    res@cnMaxLevelValF          = 50.
    res@cnLevelSpacingF         = 5.
    res@cnFillPalette           = "temp_diff_18lev"
    res@cnSpanFillPalette       = True
    res@lbLabelStride           = 2
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 5.
  end if
  if (x .eq. "SW-_100_100") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = -100.
    res@cnMaxLevelValF          = 100.
    res@cnLevelSpacingF         = 5.
    res@cnFillPalette           = "temp_diff_18lev"
    res@cnSpanFillPalette       = True
    res@lbLabelStride           = 4
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 1.
  end if
  if (x .eq. "SW-0_300") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = 10.
    res@cnMaxLevelValF          = 300.
    res@cnLevelSpacingF         = 10.
    res@cnFillPalette           = "shortwave_color_table.mn"
    res@cnFillColors            = ispan(0,60,2)
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = 0.
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 20.
  end if
  if (x .eq. "SW-0_400") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = 10.
    res@cnMaxLevelValF          = 400.
    res@cnLevelSpacingF         = 10.
    res@cnFillPalette           = "shortwave_color_table.mn"
    res@cnSpanFillPalette       = True
    res@lbLabelStride           = 1
    res@cnExplicitLabelBarLabelsOn = True
    res@lbLabelStrings          =(/"","","","40","","","","80","","","","120", \
                                 "","","","160","","","","200","","","","240", \
                                 "","","","280","","","","320","","","","360", \
                                 "","","","400"/)
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = 0.
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 20.
  end if
  if (x .eq. "SW-0_600") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = 10.
    res@cnMaxLevelValF          = 600.
    res@cnLevelSpacingF         = 10.
    res@cnFillPalette           = "shortwave_color_table.mn"
    res@cnFillColors            = ispan(0,60,1)
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = 0.
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 20.
  end if
  if (x .eq. "T-_68_40") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = -68.
    res@cnMaxLevelValF          = 40.
    res@cnLevelSpacingF         = 2.
    res@cnFillPalette           = "temp_color_table.65.ms"
    res@cnFillColors            = ispan(9,64,1)
    res@lbLabelStride           = 4
    ; overlay plot
    ores@cnLineColor          = "black"
    ores@cnMinLevelValF       = res@cnMinLevelValF
    ores@cnMaxLevelValF       = res@cnMaxLevelValF
    ores@cnLevelSpacingF      = 4.
  end if
  if (x .eq. "T-_60_20") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = -60.
    res@cnMaxLevelValF          = 20.
    res@cnLevelSpacingF         = 2.
    ;res@cnFillPalette           = "temp_color_table.65.ms"
    ;res@cnFillColors            = ispan(9,64,1)
    res@cnFillPalette           = "temp64_anoms.dave"
    res@gsnSpreadColors         = True
    res@gsnSpreadColorStart     = 0
    res@gsnSpreadColorEnd       = 63
    res@lbLabelStride           = 4
    ; overlay plot
    ores@cnLineColor          = "black"
    ores@cnMinLevelValF       = res@cnMinLevelValF
    ores@cnMaxLevelValF       = res@cnMaxLevelValF
    ores@cnLevelSpacingF      = 4.
  end if
  if (x .eq. "T-_60_30") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = -60.
    res@cnMaxLevelValF          = 30.
    res@cnLevelSpacingF         = 2.
    res@cnFillPalette           = "temp_color_table.53.ms"
    res@cnFillColors            = ispan(3,49,1)
    res@lbLabelStride           = 4
    ; overlay plot
    ores@cnLineColor          = "black"
    ores@cnMinLevelValF       = res@cnMinLevelValF
    ores@cnMaxLevelValF       = res@cnMaxLevelValF
    ores@cnLevelSpacingF      = 4.
  end if
  if (x .eq. "T_diff-_5_5") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = -5.
    res@cnMaxLevelValF          = 5.
    res@cnLevelSpacingF         = 0.5
    res@cnFillPalette           = "CBR_seq_PuBuWhOrRd_22"
    res@cnSpanFillPalette       = True
    ;res@cnFillPalette           = "cmp_b2r.ms"
;    ;res@cnFillPalette           = "MPL_RdBu"
    ;res@cnSpanFillPalette       = True
    res@lbLabelStride           = 2
    ; overlay plot
    ores@cnLineColor          = "black"
    ores@cnMinLevelValF       = res@cnMinLevelValF
    ores@cnMaxLevelValF       = res@cnMaxLevelValF
    ores@cnLevelSpacingF      = 1.
  end if
  if (x .eq. "T_diff-_8_8") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = -8.
    res@cnMaxLevelValF          = 8.
    res@cnLevelSpacingF         = .5
    res@cnFillPalette           = "cmp_b2r.ms"
    res@cnSpanFillPalette       = True
    ; overlay plot
    ores@cnLineColor          = "black"
    ores@cnMinLevelValF       = res@cnMinLevelValF
    ores@cnMaxLevelValF       = res@cnMaxLevelValF
    ores@cnLevelSpacingF      = 1.
  end if
  if (x .eq. "T_diff-_10_10") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = -10.
    res@cnMaxLevelValF          = 10.
    res@cnLevelSpacingF         = 1.
    res@cnFillPalette           = "CBR_seq_PuBuWhOrRd_22"
    res@cnSpanFillPalette       = True
    ;res@cnLevelSpacingF         = .5
    ;res@cnFillPalette           = "cmp_b2r.ms"
;   ; res@cnFillPalette           = "MPL_RdBu"
    ;res@cnSpanFillPalette       = True
    res@lbLabelStride           = 2
    ; overlay plot
    ores@cnLineColor          = "black"
    ores@cnMinLevelValF       = res@cnMinLevelValF
    ores@cnMaxLevelValF       = res@cnMaxLevelValF
    ores@cnLevelSpacingF      = 1.
  end if
  if (x .eq. "T_diff-_20_20") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = -20.
    res@cnMaxLevelValF          = 20.
    res@cnLevelSpacingF         = 0.5
    res@cnFillPalette           = "cmp_b2r.ms"
    res@cnSpanFillPalette       = True
    res@lbLabelStride           = 4
    ; overlay plot
    ores@cnLineColor          = "black"
    ores@cnMinLevelValF       = res@cnMinLevelValF
    ores@cnMaxLevelValF       = res@cnMaxLevelValF
    ores@cnLevelSpacingF      = 1.
  end if
  if (x .eq. "TCW-0_20") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = 1.
    res@cnMaxLevelValF          = 20.
    res@cnLevelSpacingF         = 1.
    res@cnFillPalette           = "WhiteBlue"
    res@cnFillColors            = ispan(19,229,10)
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = 0.
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 2.
  end if
  if (x .eq. "TCW-0_40") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = 2.
    res@cnMaxLevelValF          = 40.
    res@cnLevelSpacingF         = 2.
    res@cnFillPalette           = "WhiteBlue"
    res@cnFillColors            = ispan(19,229,10)
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = 0.
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 4.
  end if
  if (x .eq. "TCWC-0_2") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = .1
    res@cnMaxLevelValF          = 2.
    res@cnLevelSpacingF         = .1
    res@cnFillPalette           = "WhiteBlue"
    res@cnFillColors            = ispan(19,229,10)
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = 0.
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = .2
  end if
  if (x .eq. "w-_1-1") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = -1.
    res@cnMaxLevelValF          = 1.
    res@cnLevelSpacingF         = 0.02
    res@cnFillPalette           = "cmp_b2r"
    res@cnSpanFillPalette       = True
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 0.04  
  end if
  if (x .eq. "ws-0_15") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = 0.5
    res@cnMaxLevelValF          = 15.
    res@cnLevelSpacingF         = 0.5
    res@cnFillPalette           = "wind_color_table.mn"
    res@cnSpanFillPalette       = True
    ;res@cnFillColors            = ispan(0,30,1)
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = 0.
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 1.
  end if
  if (x .eq. "ws-0_20") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = 0.5
    res@cnMaxLevelValF          = 20.
    res@cnLevelSpacingF         = 0.5
    res@cnFillPalette           = "wind_color_table.mn"
    res@cnSpanFillPalette       = True
    ;res@cnFillColors            = ispan(0,30,1)
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = 0.
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 1.
  end if
  if (x .eq. "ws-0_30") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = 1.25
    res@cnMaxLevelValF          = 30.
    res@cnLevelSpacingF         = 1.25
    res@cnFillPalette           = "wind_color_table.mn"
    res@cnFillColors            = ispan(0,50,2)
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = 0.
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 2.5
  end if
  if (x .eq. "ws_diff-_10_10") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = -10.
    res@cnMaxLevelValF          = 10.
    res@cnLevelSpacingF         = 1.
    res@cnFillPalette           = "CBR_seq_PuBuWhYlOrRd_22"
    ;res@cnLevelSpacingF         = 2.
    ;res@cnFillPalette           = "CBR_seq_PuBuWhYlOrRd_12"
    res@cnSpanFillPalette       = True
    ; overlay plot
    ores@cnLineColor          = "black"
    ores@cnMinLevelValF       = res@cnMinLevelValF
    ores@cnMaxLevelValF       = res@cnMaxLevelValF
    ores@cnLevelSpacingF      = 2.
  end if
  if (x .eq. "Z-0_840") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = 0.
    res@cnMaxLevelValF          = 840.
    res@cnLevelSpacingF         = 15.
    res@cnFillPalette           = "geopotential_color_table.mn"
    res@cnFillColors            = ispan(1,58,1)
    res@lbLabelStride           = 8
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 30.
  end if
  if (x .eq. "Z-720_1560") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = 720.
    res@cnMaxLevelValF          = 1560.
    res@cnLevelSpacingF         = 15.
    res@cnFillPalette           = "geopotential_color_table.mn"
    res@cnFillColors            = ispan(1,58,1)
    res@lbLabelStride           = 8
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 30.
  end if
  if (x .eq. "Z-810_1650") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = 810.
    res@cnMaxLevelValF          = 1650.
    res@cnLevelSpacingF         = 15.
    res@cnFillPalette           = "geopotential_color_table.mn"
    res@cnFillColors            = ispan(1,58,1)
    res@lbLabelStride           = 8
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 30.
  end if
  if (x .eq. "Z-900_1680") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = 900.
    res@cnMaxLevelValF          = 1680.
    res@cnLevelSpacingF         = 15.
    res@cnFillPalette           = "geopotential_color_table.mn"
    res@cnFillColors            = ispan(5,58,1)
    res@lbLabelStride           = 5
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 30.
  end if
  if (x .eq. "Z-1020_1860") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = 1050.
    res@cnMaxLevelValF          = 1830.
    res@cnLevelSpacingF         = 30.
    res@cnFillPalette           = "geopotential_color_table.mn"
    res@cnFillColors            = ispan(5,62,2)
    res@lbLabelStride           = 8
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 60.
  end if
  if (x .eq. "Z-2160_3000") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = 2160.
    res@cnMaxLevelValF          = 3000.
    res@cnLevelSpacingF         = 15.
    res@cnFillPalette           = "geopotential_color_table.mn"
    res@cnFillColors            = ispan(1,58,1)
    res@lbLabelStride           = 8
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 30.
  end if
  if (x .eq. "Z-2340_3180") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = 2340.
    res@cnMaxLevelValF          = 3180.
    res@cnLevelSpacingF         = 30.
    res@cnFillPalette           = "geopotential_color_table.mn"
    res@cnFillColors            = ispan(1,62,2)
    res@lbLabelStride           = 8
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 60.
  end if
  if (x .eq. "Z-2460_3300") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = 2460.
    res@cnMaxLevelValF          = 3300.
    res@cnLevelSpacingF         = 30.
    res@cnFillPalette           = "geopotential_color_table.mn"
    res@cnFillColors            = ispan(1,62,2)
    res@lbLabelStride           = 8
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 60.
  end if
  if (x .eq. "Z-4320_6000") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = 4320.
    res@cnMaxLevelValF          = 6000.
    res@cnLevelSpacingF         = 30.
    res@cnFillPalette           = "geopotential_color_table.mn"
    res@cnFillColors            = ispan(1,58,1)
    res@lbLabelStride           = 8
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 60.
  end if
  if (x .eq. "Z-4620_6300") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = 4620.
    res@cnMaxLevelValF          = 6300.
    res@cnLevelSpacingF         = 30.
    res@cnFillPalette           = "geopotential_color_table.mn"
    res@cnFillColors            = ispan(1,58,1)
    res@lbLabelStride           = 8
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 60.
  end if
  if (x .eq. "Z-7500_10860") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = 7500.
    res@cnMaxLevelValF          = 10860.
    res@cnLevelSpacingF         = 60.
    res@cnFillPalette           = "geopotential_color_table.mn"
    res@cnFillColors            = ispan(1,58,1)
    res@lbLabelStride           = 8
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 120.
  end if
  if (x .eq. "Z_anom-_150_150") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = -150.
    res@cnMaxLevelValF          = 150.
    res@cnLevelSpacingF         = 7.5
    res@cnFillPalette           = "geopotential_color_table_som.ms"
    res@cnSpanFillPalette       = True
    ;res@cnFillColors            = ispan(8,49,1)
    res@lbLabelStride           = 8
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 15.
  end if
  if (x .eq. "Z_anom-_180_180") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = -180.
    res@cnMaxLevelValF          = 180.
    res@cnLevelSpacingF         = 15
    res@cnFillPalette           = "geopotential_color_table_som.ms"
    ;res@cnFillPalette           = "CBR_div_RdBu_10"
    ;res@cnSpanFillPalette       = True
    res@cnFillColors            = ispan(4,54,2)
    res@lbLabelStride           = 4
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 30.
  end if
  if (x .eq. "Z_anom-_300_300") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = -300.
    res@cnMaxLevelValF          = 300.
    res@cnLevelSpacingF         = 15.
    res@cnFillPalette           = "geopotential_color_table_som.ms"
    res@cnSpanFillPalette       = True
    ;res@cnFillColors            = ispan(8,49,1)
    res@lbLabelStride           = 5
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 30.
  end if
  if (x .eq. "Z_diff-_20_20") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = -20.
    res@cnMaxLevelValF          = 20.
    res@cnLevelSpacingF         = 0.5
    res@cnFillPalette           = "BlueRed"
    res@cnSpanFillPalette       = True
    ; overlay plot
    ores@cnLineColor          = "black"
    ores@cnMinLevelValF       = res@cnMinLevelValF
    ores@cnMaxLevelValF       = res@cnMaxLevelValF
    ores@cnLevelSpacingF      = 1.
  end if
  if (x .eq. "Z_diff-_100_100") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = -100.
    res@cnMaxLevelValF          = 100.
    res@cnLevelSpacingF         = 5.
    res@cnFillPalette           = "geopotential_color_table_diff.ms"
    res@gsnSpreadColors         = True
    res@gsnSpreadColorStart     = 4
    res@gsnSpreadColorEnd       = 53
    res@lbLabelStride           = 4
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = res@cnMinLevelValF
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 10.
  end if
  if (x .eq. "Z_sfc-0_3200") then
    ; primary plot
    res@cnMissingValFillColor   = "CornflowerBlue"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = 0.
    res@cnMaxLevelValF          = 3200.
    res@cnLevelSpacingF         = 100.
    res@cnFillPalette           = "Terrain"
    res@cnSpanFillPalette       = True
;    res@cnFillColors            = ispan(0,60,2)
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = 0.
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 200.
  end if
  if (x .eq. "Z_sfc-0_3200-ice") then
    ; primary plot
    res@cnMissingValFillColor   = "white"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = 0.
    res@cnMaxLevelValF          = 3200.
    res@cnLevelSpacingF         = 100.
    res@cnFillPalette           = "Terrain_ice"
    ;res@cnSpanFillPalette       = True
    res@cnFillColors            = ispan(0,99,3)
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = 0.
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 200.
  end if
  if (x .eq. "Z_sfc-0_4000") then
    ; primary plot
    res@cnMissingValFillColor   = "CornflowerBlue"
    res@cnMissingValFillPattern = 0
    res@cnMinLevelValF          = 0.
    res@cnMaxLevelValF          = 4000.
    res@cnLevelSpacingF         = 100.
    res@cnFillPalette           = "Terrain"
    res@cnSpanFillPalette       = True
    res@lbLabelStride           = 5
;    res@cnFillColors            = ispan(0,60,2)
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnMinLevelValF         = 0.
    ores@cnMaxLevelValF         = res@cnMaxLevelValF
    ores@cnLevelSpacingF        = 500.
  end if
  if (x .eq. "Z_sfc_diff-_2000_2000") then
    ; primary plot
    res@cnMissingValFillColor   = "gray85"
    res@cnMissingValFillPattern = 0
    res@cnLevelSelectionMode    = "ExplicitLevels"
    res@cnLevels                = array_append_record(ispan(-1000,-100,100),  \
                                  array_append_record(ispan(-90,-10,10),  \
                                  array_append_record(ispan(-9,9,1),  \
                                  array_append_record(ispan(10,90,10),  \
                                                      ispan(100,1000,100),  \
                                                      0),0),0),0)
    res@cnMinLevelValF          = -1000.  ; these settings are not used for
    res@cnMaxLevelValF          = 1000.   ;  plotting, but for masking outliers
    res@cnLevelSpacingF         = 200.
    res@cnFillPalette           = "ncl_default"
    res@cnSpanFillPalette       = True
    ; overlay plot
    ores@cnLineColor            = "black"
    ores@cnLevelSelectionMode   = "ExplicitLevels"
    ores@cnLevels               = array_append_record(ispan(-1000,-100,100),  \
                                  array_append_record(ispan(-90,-10,10),  \
                                  array_append_record(ispan(-9,9,1),  \
                                  array_append_record(ispan(10,90,10),  \
                                                      ispan(100,1000,100),  \
                                                      0),0),0),0)
  end if
end
