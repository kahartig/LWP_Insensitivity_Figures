;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; plot_polar_map_sample.ncl
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; -NCL script that creates a basic plot to evaluate the projection settings.
;  
;  NOTES:
;  -Any of the default plotting values defined by polarMapSettings can be
;   modified after the procedure is called.
;
;  -This program requires NCL 6.1
;
;  INPUT:  
;
;
;  CREATOR:  Mark Seefeldt - 2013-10
; 
;  RELEASE NOTES:
;    1.0 - 2013-10-09 (initial release)
;    1.1 - 2013-11-01
;      -changed name to from plot_polar_map_sample.ncl to plot_map_domain.ncl
;      -use the geo file for plotting
;      -include topography in the plotting
;      -added the capability to plot model grid points
;      -added the capability to plot domains for Arctic Extremes project
;   1.2 - 2020-01-25
;      -removed Arctic Extremes project (regions, extreme points, etc.)
;
;  TODO:
;    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; load in the libraries
load "polar_som_info.ncl" ; include full path at front if needed
load "polar_plotting.ncl" ; include full path at front if needed
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; start the main program
begin
  ; set the input/output variables
  path_geo = "/data/khartig/ERA5_1hr/ease_25km/hourly/2000/"
  file_geo =  "era5-ease_25km-20000101.nc"
  path_out = "/home/khartig/alaskan_som/file_formatting/development/"
  file_out = "alaska_NSA-large_latlon"
  ; set additional plotting parameters
  map_reg        = "kara_alaska_1"
  ; map_reg        = "alaska_circ"
  som_dom        = "NSA-large"
  plot_model_pts = False
  plot_som_box   = True
  plot_nocolfill = False
  plot_no_topo   = False
  ; -additional plotting settings
  file_type         = "ps"     ; initial file output type
  convert_ps        = True     ; create a png file from the ps
  clean_ps          = True     ; delete the ps file after creating the png file
  rotate_png        = False    ; rotate the png
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; open the data file
  f_geo = addfile(path_geo+file_geo,"r")
  lat2d = f_geo->lat
  lon2d = f_geo->lon
  Z_sfc = f_geo->orog
  landmask = f_geo->sftlf
  ; -mask out the non-land points
  ;Z_sfc = mask(Z_sfc,landmask,1)
  ; -set the attributes
  lon2d@long_name = "Longitude"
  lon2d@standard_name = "longitude"
  lon2d@units = "degrees_east"
  lat2d@long_name = "Latitude"
  lat2d@standard_name = "latitude"
  lat2d@units = "degrees_north"
  Z_sfc@long_name = "Terrain Height"
  Z_sfc@standard_name = "height"
  Z_sfc@units = "m"
  Z_sfc@_FillValue = 1e20
  ; -set the lat2d and lon2d values
  Z_sfc@lat2d = lat2d
  Z_sfc@lon2d = lon2d
  ; open the graphics workstation
  path_file_out = path_out+file_out
  wks = gsn_open_wks(file_type,path_file_out)
  print(" file_out: "+file_out)
  ; declare resource variables for plotting
  res = True
  ores = True
  mres = True
  lres = True
  tres = True
  ; map resources
  ; -default settings for projection
  polarMapSettings(map_reg,res)
  ; -set additional resource attributes
  res@mpGeophysicalLineColor       = "black"
  res@mpGeophysicalLineThicknessF  = 2.
  res@mpFillOn                     = False
  res@mpDataBaseVersion            = "MediumRes"
  res@mpDataResolution             = "Coarse"
  res@mpNationalLineColor          = "black"
  res@mpUSStateLineColor           = "black"
  res@mpOutlineBoundarySets        = "National"
  res@mpNationalLineColor          = "black"
  res@mpGridAndLimbOn              = "True"
  res@mpGridLineColor              = "black"
  res@mpGridLatSpacingF            = 1
  res@mpGridLonSpacingF            = 5
  ; set the general resource attributes for all plots
  res@gsnMaximize                  = True
  res@gsnDraw                      = False
  res@gsnFrame                     = False
  ores@gsnDraw                     = False
  ores@gsnFrame                    = False
  ; -set the resources for topography contouring
  polarPlotSettings("Z_sfc-0_3200",res,ores)
  ; -remove the colorfill contour options, if selected
  if (plot_nocolfill) then
    res@cnFillOn                    = False
    res@cnLinesOn                   = True
  end if
  if (plot_no_topo) then
    res@cnFillOn                    = False
    ores@cnLinesOn                  = False
    Z_sfc@units                     = ""
    Z_sfc@long_name                 = ""
  end if
  ; -fill in missing values outside of plot range (ensures valid plotting)
  Z_sfc = where(Z_sfc.ge.0. .and. Z_sfc.le.3300., Z_sfc, Z_sfc@_FillValue)
  ; draw the plot
  plot = gsn_csm_contour_map(wks,Z_sfc,res)
  oplot = gsn_csm_contour(wks,Z_sfc,ores)
  overlay(plot,oplot)
  ; plot the model grid points, if selected
  if (plot_model_pts) then
    ; set the resources for the markers
    mres@gsMarkerIndex             = 16
    mres@gsMarkerSizeF             = 1.5
    mres@gsMarkerColor             = (/"black"/)
    ; determine the dimensions
    d = dimsizes(lat2d)
    n_mpts_i = d(0)
    n_mpts_j = d(1)
    n_mpts = n_mpts_i * n_mpts_j
    ;n_mpts = 122*200
    ; create the dummy array for the markers
    mpts=new(n_mpts,graphic)
    ; create a counter for extreme points
    n_pt = 0
    ; loop through the i, j dimensions
    do i = 0, n_mpts_i-1, 5
      do j = 0, n_mpts_j-1, 5
        ; plot the point
        mpts(n_pt) = gsn_add_polymarker(wks,plot,lon2d(i,j),lat2d(i,j),mres)
        ; increase the counter
        n_pt = n_pt + 1
      end do
    end do
  end if
  if (plot_som_box) then
    ;  -create the info resource
    info  = True
    ; retrieve the SOM info
    polarSOMdomain(som_dom, info)
    ; set the resources for the SOM domain
    lres@gsLineColor       = "red"
    lres@gsLineThicknessF  = 3.
    tres@txFontColor = lres@gsLineColor
    ; -draw the lines defining the region
    if info@use_ij_mask then
      i_b = info@i_t
      i_e = info@i_b
      j_b = info@j_l
      j_e = info@j_r
      i_lns=new((i_e-i_b)*2,graphic)
      j_lns=new((j_e-j_b)*2,graphic)
      i_pt = 0
      j_pt = 0
      do i = i_b, i_e-1
        i_lns(i_pt) = gsn_add_polyline(wks,plot,(/lon2d(j_b,i),lon2d(j_b,i+1)/),  \
                                       (/lat2d(j_b,i),lat2d(j_b,i+1)/),lres)
        i_lns(i_pt+1) = gsn_add_polyline(wks,plot,(/lon2d(j_e,i),lon2d(j_e,i+1)/),  \
                                       (/lat2d(j_e,i),lat2d(j_e,i+1)/),lres)
        i_pt = i_pt+2
      end do
      do j = j_b, j_e-1
        j_lns(j_pt) = gsn_add_polyline(wks,plot,(/lon2d(j,i_b),lon2d(j+1,i_b)/),  \
                                       (/lat2d(j,i_b),lat2d(j+1,i_b)/),lres)
        j_lns(j_pt+1) = gsn_add_polyline(wks,plot,(/lon2d(j,i_e),lon2d(j+1,i_e)/),  \
                                       (/lat2d(j,i_e),lat2d(j+1,i_e)/),lres)
        j_pt = j_pt+2
      end do
      ;ln50  = gsn_add_polyline(wks,plot,(/lon2d(info@j_l,info@i_t),lon2d(info@j_r,info@i_t)/),  \
      ;                                  (/lat2d(info@j_l,info@i_t),lat2d(info@j_r,info@i_t)/),lres)
      ;ln51  = gsn_add_polyline(wks,plot,(/lon2d(info@j_r,info@i_t),lon2d(info@j_r,info@i_b)/),  \
      ;                                  (/lat2d(info@j_r,info@i_t),lat2d(info@j_r,info@i_b)/),lres)
      ;ln52  = gsn_add_polyline(wks,plot,(/lon2d(info@j_r,info@i_b),lon2d(info@j_l,info@i_b)/),  \
      ;                                  (/lat2d(info@j_r,info@i_b),lat2d(info@j_l,info@i_b)/),lres)
      ;ln53  = gsn_add_polyline(wks,plot,(/lon2d(info@j_l,info@i_b),lon2d(info@j_l,info@i_t)/),  \
      ;                                  (/lat2d(info@j_l,info@i_b),lat2d(info@j_l,info@i_t)/),lres)
    else if info@use_latlon_mask then
      ln50  = gsn_add_polyline(wks,plot,(/info@max_lon,info@max_lon/),  \
                                        (/info@max_lat,info@min_lat/),lres)
      ln51  = gsn_add_polyline(wks,plot,(/info@min_lon,info@min_lon/),  \
                                        (/info@max_lat,info@min_lat/),lres)
      ln52  = gsn_add_polyline(wks,plot,(/info@min_lon,info@max_lon/),  \
                                        (/info@max_lat,info@max_lat/),lres)
      ln53  = gsn_add_polyline(wks,plot,(/info@min_lon,info@max_lon/),  \
                                        (/info@min_lat,info@min_lat/),lres)
    end if
    end if
  end if
  ; create the plot
  draw(plot)
  frame(wks)
  ; create a png from the ps file
  if (file_type .eq. "ps" .and. convert_ps) then
    ; -close the graphic
    delete(wks)
    if rotate_png then
      ; -convert from the ps file
      system("convert -trim -border 20 -bordercolor white -density 300 "+  \
             "-rotate -90 "+path_file_out+".ps "+path_file_out+".png")
    else
      ; -convert from the ps file
      system("convert -trim -border 20 -bordercolor white -density 300 "+  \
             path_file_out+".ps "+path_file_out+".png")
    end if
    ; -remove the ps file, if selected
    if (clean_ps) then
      system("rm "+path_file_out+".ps")
    end if
  end if
end

