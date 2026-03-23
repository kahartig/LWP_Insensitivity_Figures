;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; plot_som_nodes.ncl
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; -NCL script that creates plots of SOMs for Antarctica
;
; -This program requires NCL 6.1
;
;  COMMAND SYNTAX:
;  -ncl plot_som_nodes.ncl
;  -There are a number of default values for file names, paths, and plot
;   settings that can be invoked at the command line when starting the 
;   program.  Not all of these options are covered here.  They can be 
;   identified in the code in a if then block with:  if(.not.isvar())
;   Variables that can be set:
;     path_ex, file_ex, path_out, prefix_out, suffix_out
;     date_file, region, plot_ext (T/F), plot_ext_type, 
;     path_som, path_vis, file_som, file_vis, file_dates
;
;  NOTES:
;  -Any of the default plotting values defined by polarPlotSettings can be
;   modified after the procedure is called.
;
;  INPUT:  SOM output file
;
;
;  CREATOR:  Mark Seefeldt - 2014-06
; 
;  RELEASE NOTES:
;    1.0 - 2013-11-06
;      -initial release
;    1.1 - 2014-04-25
;      -added capability for North American Arctic (full domain) SOM region
;    1.2 - 2014-06-04
;      -modified from plot_som_extremes.ncl for the Amundsen Sea project
;    1.3 - 2014-07-09
;      -generalized the program to work with more regions
;      -added the use of:  polar_som_info.ncl to load in the SOM domain info
;      -made changes to file naming and plot titling
;    1.3.1 - 2014-12-11
;      -minor changes to make the code more clean and consistent with others
;
;
;  TODO:
;    KARA: toggle lon360 based on domain extent
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; load in the libraries
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "/home/khartig/alaskan_som/define_domain/polar_som_info.ncl"
load "/home/khartig/alaskan_som/define_domain/polar_plotting.ncl"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; start the main program
begin
  ; set the path/file input/output defaults and values
  ;  -geo file
  if (.not.isvar("path_geo")) then
    path_geo = "/data/khartig/ERA5_1hr/ease_25km/hourly/2000/"
  end if
  if (.not.isvar("file_geo")) then
    file_geo = "era5-ease_25km-20000101.nc"
  end if
  ; -SOM file
  if (.not.isvar("path_som")) then
    path_som = "/data/khartig/alaskan_som/som_v2-4x3/cod/"
  end if
  if (.not.isvar("file_som")) then
    file_som = "psl_anom-a0.02_rlen50000_r2.cod" ;;; HERE
  end if
  ; -output file
  if (.not.isvar("path_out")) then
    path_out = "/home/khartig/alaskan_som/plot_som_output/4x3/"
  end if    
  if (.not.isvar("prefix_out"))
    prefix_out = "rank4b_nodes" ;;; HERE
  end if
  if (.not.isvar("suffix_out")) then
    suffix_out = ""
  end if
  ; set the plot title prefix and suffix
  if (.not.isvar("title_prefix")) then
    title_prefix = ""
  end if
  if (.not.isvar("title_suffix")) then
    title_suffix = " - SOM nodes"
  end if
  ; set any flags/parameters for creating the plot
  if (.not.isvar("dom")) then   ; SOM domain
    dom = "NSA-large"
  end if
  if (.not.isvar("var")) then  ; variable
    var = "psl_anom"
  end if
  ; -additional plotting settings
  som_zero_based    = False     ; use zero-based node naming for labels
  plot_node_freq    = False     ; plot the node frequency in the upper-right
  plot_title_detail = False     ; create a plot title with all details
  file_name_detail  = False     ; create a filename with plot details
  use_som_filename  = False     ; use the SOM filename in title and file_out
  rotate_wind       = True     ; rotate winds from grid to true (WRF)
  wind_uni          = True     ; if plotting winds, use uniform vector length
  curly_vector      = False     ; plot curly vectors for winds
  file_type         = "png"     ; initial file output type ;;; "ps"
  convert_ps        = False     ; create a png file from the ps
  clean_ps          = False     ; delete the ps file after creating the png file
  ; -set the node frequencies (if using plot_node_freq)
  node_freq = (/9.51,6.18,10.07,8.96,4.65,7.50,3.40,9.44,12.15,5.49,15.14,7.50/)
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; retrieve the SOM domain information
  ;  -create the info resource
  info  = True
  ;  -call the procedure
  polarSOMdomain(dom, info)
  ; determine if lon should be 0 to 360 or -180 to 180
  use_lon360 = True
  if (info@use_latlon_mask).and.(info@min_lon.lt.0.).and.(info@max_lon.ge.0) then
    use_lon360 = False
  end if
  ; set the variable text for the title
  if (var .eq. "psl_anom") then
    var_txt = "Sea Level Pressure Anomaly"
  else
    if (var .eq. "wind_10m") then
      var_txt = "Winds at 10 m"
    else
      if (var .eq. "wind_e04") then
        var_txt = "Winds at 4th Lowest Level"
      else
        if (var .eq. "Z500_anom") then
          var_txt = "500 hPa Geopotential Height Anomaly"
        else
          print ("var must be set to:  psl_anom, wind_10m, or Z500_anom")
          exit
        end if
      end if
    end if
  end if
  ; create the file name based on the settings
  if (use_som_filename) then
    file_info = str_split_by_length(file_som,strlen(file_som)-4)
    file_out = file_info(0)
  else
    if (file_name_detail) then
      file_out = prefix_out+var(vr)+"-"+simul_out(sm)+"-1989_2007-"+  \
                 seasons_txt(se)+"-"+subdomain(sd)+"-"+  \
                 nx_node+"x"+ny_node+suffix_out
    else
      file_out = prefix_out+suffix_out
    end if
  end if
  print("file: "+file_out)
  ; set the path/file variables
  path_file_out = path_out+file_out
  ; create the panel title
  if (use_som_filename) then
    plot_title = var_txt+" - "+info@title+" - "+file_out
  else
    plot_title = title_prefix+var_txt+" - "+info@title+title_suffix
  end if
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; -begin the plotting
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; open and read the geo file
  f_geo = addfile(path_geo+file_geo,"r")
  ; -read in the lat, lon, Z_sfc, and landmask
;  lat2d = f_geo->XLAT_M(0,:,:)
;  lon2d = f_geo->XLONG_M(0,:,:)
;  Z_sfc2d = f_geo->HGT_M(0,:,:)
;  landmask = f_geo->LANDMASK(0,:,:)
  ; lat2d = f_geo->lat
  ; lon2d = f_geo->lon
  ; Z_sfc2d = f_geo->Z_sfc
  ; landmask = f_geo->LandMask(0,:,:)
  lat2d = f_geo->lat
  lon2d = f_geo->lon
  Z_sfc2d = f_geo->orog
  landmask = f_geo->sftlf
  ; -close the geo file
  delete(f_geo)
  ; determine the dimensions and total size
  dims = dimsizes(lat2d)
  n_sn = dims(0)       ; nx_grid
  n_we = dims(1)       ; ny_grid
  n_tot = n_sn * n_we  ; ncol
  ; create a lon for 0 to 360
  if use_lon360 then
    lon360 = where(lon2d.lt.0., lon2d+360., lon2d)
  else
    lon360 = lon2d
  end if
  ; determine the indices for the 2d data files
  ; Note:  Using Z_sfc to find the indices.
  ; -mask by lat/lon, if selected
  if (info@use_latlon_mask) then
    latlon_mask = where((lat2d.ge.info@min_lat .and.  \
                         lat2d.le.info@max_lat .and.  \
                         lon360.ge.info@min_lon .and.  \
                         lon360.le.info@max_lon),1,0)
    Z_sfc = mask(Z_sfc2d,latlon_mask.eq.1,True)
  else if (info@use_ij_mask) then
    ; -define the i,j mask
    ij_mask = new((/n_sn,n_we/),float)
    ij_mask = 0
    ij_mask(info@j_l:info@j_r,info@i_b:info@i_t) = 1
    ; -create the lat,lon,orog arrays
    Z_sfc = mask(Z_sfc2d,ij_mask.eq.1,True)
  else
    Z_sfc = Z_sfc2d
  end if
  end if
  ; mask by elevation, if selected
  if (info@use_elev_mask) then
    elev_mask = where((Z_sfc2d .lt. info@elev_mask_hgt),1,0)
    Z_sfc = mask(Z_sfc,elev_mask.eq.1,True)
    delete(elev_mask)
  end if
  ; mask by land, if selected
  if (info@use_land_mask) then
    Z_sfc = mask(Z_sfc,landmask.eq.1,True)
  end if
  ; mask by ocean, if selected
  if (info@use_ocean_mask) then
    Z_sfc = mask(Z_sfc,landmask.eq.0,True)
  end if
  ; -create a one-dimensional array of results
  Z_sfc1d = ndtooned(Z_sfc)
  ; -determine the indices
  data_ind = ind(.not.ismissing(Z_sfc1d))
	; -delete all that was used to get the indexes
	delete([/Z_sfc,Z_sfc1d,landmask,lon360/])
  ; open and read the SOM file
  ; -read in the header into to retrieve number of columns
  som_header = readAsciiHead(path_som+file_som,1)
  npts_som = stringtoint(str_get_field(som_header,1," "))
  nx_node = stringtoint(str_get_field(som_header,3," "))
  ny_node = stringtoint(str_get_field(som_header,4," "))
  ; -read in the som data (skipping the header)
  som_in = readAsciiTable(path_som+file_som,npts_som,"float",1)
  ; determine the number of nodes
  nnode = nx_node * ny_node
  ; read in the SOM data
  if (var .eq. "wind_10m" .or. var .eq. "wind_e04") then
    ; set the number of points to half (wind = u, v)
    npts = npts_som/2
    ; create the u, v arrays
    u1d = new((/nnode,n_tot/),float)
    v1d = new((/nnode,n_tot/),float)
    ; assign SOM data
    do n = 0, nnode-1
      u1d(n,data_ind) = som_in(n,0:npts-1)
      v1d(n,data_ind) = som_in(n,npts:npts_som-1)
    end do
  else
    ; set the number of points
    npts = npts_som
    ; create the data1d array
    data1d = new((/nnode,n_tot/),float)
    ; assign SOM data
    do n = 0, nnode-1
      data1d(n,data_ind) = som_in(n,:)
    end do
  end if
  ; set the contour and geophysical line thickness based on number of nodes
  if (nnode .gt. 40 .and. nnode .lt. 100) then
    line_thick = 0.75
  else
    if (nnode .ge. 100) then
      line_thick = 0.5
    else
      line_thick = 1.
    end if
  end if
  ; initiate the creation of the panel plot
  wks = gsn_open_wks(file_type,path_file_out)
  ; -create the graphic variables to be plotted in the panel
  plots = new(nnode,graphic)
  oplots = new(nnode,graphic)
  ; -create the resource variables
  res  = True  ; primary plot resource
  ores = True  ; overlay plot resource
  pres = True  ; panel plot resource
  ; plot resources
  ; -default settings for projection
  polarMapSettings(info@map,res)
  ; -custom settings for plot
  res@mpGeophysicalLineColor       = "gray30"
  res@mpGeophysicalLineThicknessF  = line_thick*2.
  res@mpDataBaseVersion            = "MediumRes"
;  res@mpDataResolution             = "Coarse"
  res@mpDataSetName                = "Earth..4"
  res@mpOutlineBoundarySets        = "National"
  res@mpNationalLineColor          = "gray30"
  res@mpGridAndLimbOn              = False
  res@mpGridLineColor              = "black"
  res@mpFillColor                  = "gray60"
  res@mpPerimLineColor             = "black"
  res@mpPerimLineThicknessF        = line_thick + 0.5
  ; -retrieve the default plot settings
  if (var .eq. "psl_anom") then
    polarPlotSettings("slp_anom-_48_48",res,ores)
  else
    if (var .eq. "wind_10m") then
      polarPlotSettings("ws-0_20",res,ores)
    else
      if (var .eq. "wind_e04") then
        polarPlotSettings("ws-0_30",res,ores)
      else
        if (var .eq. "Z500_anom") then
          polarPlotSettings("Z_anom-_300_300",res,ores)
        else
          print("var is incorrectly set")
          exit
        end if
      end if
    end if
  end if
  ; -custom parameters for each plot
  res@cnLowLabelsOn                = True
  res@cnLowLabelBackgroundColor    = -1
  res@cnHighLabelsOn               = True
  res@cnHighLabelBackgroundColor   = -1
  res@lbLabelBarOn                 = False
  res@gsnLeftStringFontHeightF     = 0.04
  res@gsnRightStringFontHeightF    = res@gsnLeftStringFontHeightF
  res@cnMissingValFillColor        = -1
  ores@cnLineThicknessF            = line_thick
  ores@cnLineLabelsOn              = True
  ores@cnLineLabelInterval         = 1
  ores@cnInfoLabelOn               = False
  ores@cnMissingValFillColor       = -1
  ; -set the general resource attributes for all plots
  res@gsnMaximize                  = False  ;per NCL instructions for paneling
  res@gsnDraw                      = False
  res@gsnFrame                     = False
  ores@gsnDraw                     = False
  ores@gsnFrame                    = False
  ; loop through the nodes to create the SOM panels
  do i = 0, nx_node-1
    do j = 0, ny_node-1
      ; set the node number
      som_node = i + (j*nx_node)
      ; set the node labels
      if som_zero_based then
        label_i = i
        label_j = j
      else
        label_i = i+1
        label_j = j+1
      end if
      ; set the data to be plotted
      if (var .eq. "wind_10m" .or. var .eq. "wind_e04") then
        u = onedtond(u1d(som_node,:),(/n_sn,n_we/))
        v = onedtond(v1d(som_node,:),(/n_sn,n_we/))
        ; create wind speed
        data = sqrt(u^2 + v^2)
      else
        data = onedtond(data1d(som_node,:),(/n_sn,n_we/))
      end if
      ; set the node data attributes and coordinates
      data@lat2d = lat2d
      data@lon2d = lon2d
      if (plot_node_freq) then
        data@units = "("+sprintf("%4.1f",node_freq(som_node))+"%)"
      else
        data@units = ""                             ; top-right label
      end if
      data@long_name = "["+label_i+","+label_j+"]"  ; top-left label
      ; create the plot, overplot, and overlay the two
      plots(som_node) = gsn_csm_contour_map(wks,data,res)
      oplots(som_node) = gsn_csm_contour(wks,data,ores)
      overlay(plots(som_node),oplots(som_node))
      if (var .eq. "wind_10m" .or. var .eq. "wind_e04") then
        if (rotate_wind) then
          uv_tr = wrf_uvmet(u, v, lat2d, lon2d, 180, 1)
          u = (/uv_tr(0,:,:)/)
          v = (/uv_tr(1,:,:)/)
          delete(uv_tr)
        end if  
        if (wind_uni) then
          u0 = u
          v0 = v
          wd = wind_direction(u0,v0,1)
          dim = dimsizes(u0)
          ws = new(dim,"float",0)
          ws = 5.0
          uv = wind_component(ws,wd,0)
          u = uv(0,:,:)
          v = uv(1,:,:)
        end if
        u@lat2d = lat2d
        u@lon2d = lon2d
        v@lat2d = lat2d
        v@lon2d = lon2d
        vres                         = True
        ; set the vector sizes based on number of nodes
        if (nnode .gt. 40 .and. nnode .lt. 100) then
          vres@vcRefLengthF            = 0.035
          vres@vcMinDistanceF          = 0.04
          vres@vcLineArrowHeadMinSizeF = 0.015
          vres@vcLineArrowHeadMaxSizeF = 0.03
        else
          if (nnode .ge. 100) then
          else
            vres@vcRefLengthF            = 0.030
            vres@vcMinDistanceF          = 0.03
            vres@vcLineArrowHeadMinSizeF = 0.01
            vres@vcLineArrowHeadMaxSizeF = 0.025
          end if
        end if
        ; set additional vector plot resources
        vres@vcRefMagnitudeF         = 5.0
        vres@vcMonoLineArrowColor    = True
        vres@vcLineArrowColor        = "black"
        vres@vcLineArrowThicknessF   = 1.
        if (curly_vector) then
          vres@vcGlyphStyle            = "CurlyVector"
        else 
          vres@vcGlyphStyle            = "LineArrow"
        end if 
        vres@gsnDraw                 = False
        vres@gsnFrame                = False
        vres@gsnRightString          = ""
        vres@gsnLeftString           = ""
        vres@tiXAxisString           = ""
        vres@tiYAxisString           = ""
        vres@vcRefAnnoOn             = False
        vplot = gsn_csm_vector(wks,u,v,vres)
        overlay(plots(som_node),vplot)
      end if
    end do
  end do
  ; finalize the panel plotting
  pres@txString                    = plot_title
  pres@txFontHeightF               = 0.015
  pres@gsnPaperOrientation         = "landscape"
  pres@gsnMaximize                 = True
  pres@gsnPanelYWhiteSpacePercent  = 1
  pres@gsnPanelXWhiteSpacePercent  = 1
  pres@gsnPanelLabelBar            = True
  pres@lbLabelFontHeightF          = 0.011
  pres@lbTitleString               = "hPa"
  pres@lbTitlePosition             = "right"
  pres@lbTitleFontHeightF          = 0.011
  pres@lbTitleJust                 = "CenterLeft"
  pres@lbTitleDirection            = "Across"
  if (var .eq. "psl_anom") then
    pres@lbTitleString             = "hPa"
  end if
  if (var .eq. "Z500_anom") then
    pres@lbTitleString             = "m"
  end if
  if (var .eq. "wind_10m" .or. var .eq. "wind_e04") then
    pres@lbTitleString             = "m s~S~-1~N~"
  end if
  ; create the panel plot
  gsn_panel(wks,plots,(/ny_node,nx_node/),pres)             
  ; create a png from the ps file
  if (file_type .eq. "ps" .and. convert_ps) then
    ; -close the graphic
    delete(wks)
    ; -convert from the ps file
    system("convert -trim -border 20 -bordercolor white -density 300 "+  \ ;;; density was 600
           path_file_out+".ps "+path_file_out+".png") ;;; removed just before first path: "-rotate -90 "+
    ; -remove the ps file, if selected
    if (clean_ps) then
      system("rm "+path_file_out+".ps")
    end if
  end if
end
