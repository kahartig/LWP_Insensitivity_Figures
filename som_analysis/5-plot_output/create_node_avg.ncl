;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; create_node_avg.ncl
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; -NCL script that creates SOM node averaged values from netcdf input files.
; -The user is able to select the variables to be included in the output file(s)
; -The node averaged values can be outputted as a single file or a file for
;  each node.
; -An option is included in the single file output to include a fictitious
;  time variable allowing the CF compliant netcdf file to be used in 
;  analysis programs, including IDV.
; -This version of the script is specified to work with E3SM-Arctic output data
;  and the Nordic Seas project.
;
;  COMMAND SYNTAX:  ncl create_node_avg.ncl
;   1. Set the values for number of nodes and the output file specifications.
;   2. Set the input/output file/path information.
;   3. Select (set to True) the variables that are to be node averaged.
;   4. Run the script:  >ncl create_node_avg.ncl
;
;  INPUT:  SOM date and vis files, original SOM input files
;
;  OUTPUT: a netcdf file for each node or a single file for all nodes
;
;  CREATOR:  Matt Higgins - 2008-10 (original)
;            Melissa Nigro - 2011-08
;            Alice DuVivier - 2012-04
;            Melissa Nigro, Alice DuVivier - 2013-06
;            Mark Seefeldt - 2013-07
; 
;  RELEASE NOTES:
;    2.0 - 2013-07-30
;      -initial release by Seefeldt (needed to start somewhere w/ver.#)
;    2.1 - 2013-09-19
;      -re-wrote averaging part of script to use looping and string variables
;      -removed sub-procedure calcAvgVar
;    2.2 - 2014-07-16
;      -added ability for daily dates file input
;      -included additional variables from ERA-Interim files
;       (netcdf files created with:  extract_regrid_erai.ncl)
;      -added an error check to see if variable is included in input file
;      -added SOM domain masking for the anomaly calculations
;      -added ability to create a single netcdf file with ncrcat
;      -additional small fixes, tweaks, clean-ups, and adjustments
;    2.2.1 - 2014-12-10
;      -rename from make_node_avg.ncl to create_node_avg.ncl
;    2.3 - 2024-12-18
;      -resuscitated the script for 10 years of inactivity and modified for
;       E3SM-Arctic and the Nordic Seas project
;    2.3.1 - 2025-04-29
;      -add ability to create average of all times slices (create_all_avg)
;      -add new 2d field: rds = rlds + rsds
;      
;
;  TODO:
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; load in the libraries
; load "/home/asolomon/greenland_arcsix_som/define_domain/polar_som_info.ncl" ; not needed unless masking SOM domain
load "/home/asolomon/greenland_arcsix_som/plot_som_output/readDailyFiles.ncl"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; start the main program
begin
  ; set the path/file input/output defaults and values
  ;  -vis file (required by all)
  if (.not.isvar("path_vis")) then
    path_vis = "/data/khartig/alaskan_som/som_v2-4x3/"
  end if
  if (.not.isvar("file_vis")) then
    file_vis = "psl_anom_4x3_best.vis"
  end if
  ;  -dates file (required by 1, 2, 4)
  if (.not.isvar("path_dates")) then
    path_dates = "/data/khartig/alaskan_som/input_data/"
  end if
  if (.not.isvar("file_dates")) then
    file_dates = "ERA5-EASE25km.AlaskaNSA.2000-2024_Nov-Mar.6hr.txt" ; NEED to also include daily version?
  end if
  ;  -path and suffix for input nc files (required by 1, 4)
  if (.not.isvar("path_nc")) then
    path_nc = "/cassanostorage/group/era5/EASE2_N25km/6hr/"
  end if
  if (.not.isvar("prefix_nc")) then
    prefix_nc = "era5-EASE2_N25km-"
  end if
  if (.not.isvar("suffix_nc")) then
    suffix_nc = ".nc"
  end if
  ;  -output files (required by all)
  if (.not.isvar("path_out")) then
    path_out = "/data/khartig/alaskan_som/som_v2-4x3/"
  end if
  if (.not.isvar("prefix_out"))
    prefix_out = "psl_anom-4x3_node_avg"
  end if
  if (.not.isvar("suffix_out")) then
    suffix_out = ".nc"
  end if
  ;  -geo files (only for anom. calc. w/ use_som_masking = T and use_geo = T) 
  if (.not.isvar("path_geo")) then
    path_geo = "/cassanostorage/group/era5/EASE2_N25km/6hr/200005/"
  end if
  if (.not.isvar("file_geo")) then
    file_geo = "era5-EASE2_N25km-20000501.nc"
  end if
  ; set the SOM domain (only necessary for SOM masking with anomaly calc.)
  if (.not.isvar("dom")) then   ; SOM domain
    dom = "NSA-large"
  end if
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; additional options
  som_zero_based    = False     ; use zero-based node naming for labels
  use_som_mask      = False     ; anomaly calculations: mask data based on SOM
  use_geo           = False     ; extract the geo from the geogrid.exe file (T)
                               ;  or using the netcdf input file (False)
  ; set options for the output file(s)
  outVar            = True     ; include variance in the output file
  outSingleFile     = True     ; create a single netcdf file for all nodes
  cleanNodeFile     = False    ; delete the indiv. node files (outSingleFile)
  outTime           = True     ; include a time dimension in the output
  TimeUnits = "days since 1900-01-01 00:00:00"
  ; Note:  Obviously, there is no time value for the node averaged results
  ;        as it is averaged over a discontinuous series of time slices.  The
  ;        inclusion of a time dimension is used to act as a dimension to 
  ;        serve as a netcdf record through which files can be combined.
  ;        The value outTime must be selected if outSingleFile is selected.
  incl_label = True
  freq_type = "All"
  create_all_avg = True        ; create average for all time slices (not by node)
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; set the netcdf file global attributes
  fileAtt                = True
  fileAtt@creation_date  =  systemfunc("date")
  fileAtt@institution = "University of Colorado at Boulder - CIRES"
  fileAtt@created_by = "Mark Seefeldt - mark.seefeldt@colorado.edu"
  fileAtt@notes = "Created with NCL script:  create_node_avg.ncl v2.3.1"
  fileAtt@Conventions    = "CF 1.6, Standard Name Table v19"
  fileAtt@title          = prefix_out+"-i_j"+suffix_out
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; Note:  -Some of the variables are available in both WRF generated output
  ;        and in ERA-Interim generated output and some are only in one of
  ;        the two.  If the variable is only in one of the two, it is 
  ;        specified below (WRF / ERA-I or W / E).
  ;        -Later, in the node averaging section, this program will check to
  ;        see if the variable is present in the source netcdf files.  If it
  ;        is present, the average will be created, if not, the variable will
  ;        be skipped. 
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; two-dimensional fields
  avg2d                   = True
  avg2d@psl               = True
  avg2d@ps                = False
  avg2d@ts                = True      ; temperature at the surface
  avg2d@tabot             = True      ; temperature at lowest model level
  avg2d@uabot             = True      ; u-wind at lowest model level
  avg2d@vabot             = True      ; v-wind at lowest model level
  avg2d@Windbot           = True      ; wind speed at lowest model level *calc
  avg2d@husbot            = True      ; specific humidity at lowest model level
  avg2d@zgbot             = False      ; geopotential height of lowest model level
  avg2d@pr                = False      ; precipitation
  avg2d@rsds              = True      ; SW radiation, downward, at the surface
  avg2d@rss               = True      ; SW radiation, net, at the surface
  avg2d@rsus              = False      ; SW radiation, upward, at the surface *calc
  avg2d@rlds              = True      ; LW radiation, downward, at the surface
  avg2d@rls               = True      ; LW radiation, net, at the surface
  avg2d@rlus              = False      ; ??
  avg2d@rds               = False      ; LW+SW radiation, downward, at the surface
  avg2d@hfss              = True      ; sensible heat at the surface
  avg2d@hfls              = True      ; latent heat at the surface
  avg2d@hfts              = False      ; ??
  avg2d@siconc            = True      ; sea ice concentration
  avg2d@prw               = True      ; sea ice thickness
  avg2d@clwvi             = True      ; ??
  avg2d@clivi             = True      ; ??
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; two-dimensional fields - anomaly
  avg2dAnom               = False
  avg2dAnom@ps            = False      ;pressure at the surface
  avg2dAnom@ts            = False      ;temperature at the surface
  avg2dAnom@psl           = False      ;sea-level pressure
  avg2dAnom@tas           = False      ;temperature at 2m
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; three-dimensional upper-level (pressure levels) meteorology variables
  avgPL                   = True
  avgPL@zg                = True      ;geopotential height - pressure
  avgPL@ta                = True      ;temperature - pressure
  avgPL@tdp               = False      ;dewpoint temperature - pressure
  avgPL@hus               = True      ;specific humidity - pressure
  avgPL@hur               = False      ;relative humidity - pressure
  avgPL@ua                = False      ;u wind - pressure (ERA-I)
  avgPL@va                = False      ;v wind - pressure (ERA-I)
  avgPL@wa                = False      ;vertical wind - pressure
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; three-dimensional anomaly calculations
  avgPLAnom               = False
  avgPLAnom@zg            = False      ;geopotential height - pressure
  avgPLAnom@ta            = False      ;temperature - pressure
  avgPLAnom@hus           = False      ;specific humidity - pressure
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; set the arrays of variables
  ;  Note: -The initial array is the list of variables used internally to this
  ;        program.  The _in array is the names of the variables in the input
  ;        files.  The _out array is the names of the variables in the averaged
  ;        output files.  The _var array is the names of the variable variances
  ;        in the output file.
  ;        -It is possible/likely that the first three arrays are the same.
  ;        The different arrays are provided in case the variable names
  ;        in the input files are not the same and/or the desired variable
  ;        names in the output file are different.
  ;        -The _var array should be the _out array with '_var' appended.
  ;        -The initial array needs to match the options that are selected
  ;        above.  The order does not matter, although the order of all
  ;        four arrays needs to be the same.
  ;  -2d
  var2d =   (/"psl", "ps", "ts", "tabot", "uabot",  \
              "vabot", "Windbot", "husbot", "zgbot", "pr",  \
              "rsds", "rss", "rsus", "rlds", "rls", \
              "rlus", "rds", "hfss", "hfls", "hfts", \
              "siconc", "prw", "clwvi", "clivi"/)
  var2d_in  = var2d
  var2d_out = var2d
  var2d_var = (/"psl_var", "ps_var", "ts_var", "tabot_var", "uabot_var",  \
                "vabot_var", "Windbot_var", "husbot_var", "zgbot_var", "pr_var",  \
                "rsds_var", "rss_var", "rsus_var", "rlds_var", "rls_var", \
                "rlus_var", "rds_var", "hfss_var", "hfls_var", "hfts_var",   \
                "siconc_var", "prw_var","clwvi_var","clivi_var"/)
  n2d = dimsizes(var2d)
  ;  -2d anomaly
  anom2d =   (/"ps", "ts", "psl", "tas"/)
  anom2d_in  = anom2d
  anom2d_out = anom2d
  anom2d_var = (/"ps_var", "ts_var", "psl_var", "tas_var"/)
  nanom2d = dimsizes(anom2d)
  ;  -3d Pressure levels
  varPL =     (/"zg","ta","tdp","hus","hur",  \
                "ua","va","wa"/)
  varPL_in =  varPL
  varPL_out = varPL
  varPL_var = (/"zg_var","ta_var","tdp_var","hus_var","hur_var",  \
                "ua_var","va_var","wa_var"/)
  nPL = dimsizes(varPL)
  ;  -pressure level  anomaly
  anomPL =   (/"ps", "ts", "psl", "tas"/)
  anomPL_in  = anomPL
  anomPL_out = anomPL
  anomPL_var = (/"ps_var", "ts_var", "psl_var", "tas_var"/)
  nanomPL = dimsizes(anomPL)
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; read the vis file
  ; Note: the vis file is created by the som_pak software listing the
  ;       node that is mapped to each corresponding line in the dates file
  visfile = path_vis+file_vis
  ; -read in the header into to retrieve number of columns
  vis_header = readAsciiHead(path_vis+file_vis,1)
  nx_node = stringtoint(str_get_field(vis_header,3," "))
  ny_node = stringtoint(str_get_field(vis_header,4," "))
  ; -read in the vis file table
  vis = readAsciiTable(visfile,3,"integer",1)         ; skip the first row
  nvis = dimsizes(vis)
  ; read the dates file and create arrays for variables
  ; Note: the dates file is a list of yyyymmddhh for every entry in the 
  ;       SOM input file
  ; The format of the dates file, as well as the associated input files
  ; varies by user.  Select the dates file type for correct use.
  ; Note:  If one is adding a new method, the key end result is the array
  ;        nc_file that is a list of all files corresponding to the order
  ;        in the vis file.

  ; read the dates files
  dates = ndtooned(readAsciiTable(path_dates+file_dates,1,"string",0))
  ndates = dimsizes(dates)
  ; -create string arrays for year, month, and day
  yyyy = str_get_cols(dates,0,3)
  mm = str_get_cols(dates,4,5)
  dd = str_get_cols(dates,6,7)
  ; -read in the label with the dates file, if present/selected
  if incl_label then
    lbl = str_get_cols(dates,9,12)
  end if
  ; -create values yyyymm, yyyymmdd based on array
  yyyymm = yyyy+mm
  yyyymmdd = yyyymm+dd
  ;yyyymmddhh = yyyymmdd+hh
  ; -create integer values representing the date
  yr = stringtoint(yyyy)
  mo = stringtoint(mm)
  dd = stringtoint(dd)
  ;dy = new(ndates,integer)
  ;dy = 1
  hr = new(ndates,integer)
  hr = 0
  mn = new(ndates,integer)
  mn = 0
  sc = new(ndates,integer)
  sc = 0
  ; the number of lines of the vis file must equal that of the dates file
  if (ndates .ne. nvis(0)) then
    print("The number of lines in the dates file does not match")
    print("the number of lines in the vis file.")
    print("Exiting")
    break
  end if
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; open the netcdf file
  nc_file = path_geo+"/"+file_geo
  print("nc_file: "+nc_file)
  f_nc = addfile(nc_file,"r")
  ; -read the lat, lon, orog, sftlf
  lat_nc = f_nc->lat
  lon_nc = f_nc->lon
  orog_nc = f_nc->orog
  sftlf_nc = f_nc->sftlf
  ; -determine the x and y dimensions
  dims = dimsizes(lat_nc)
  n_y = dims(0)
  n_x = dims(1)
  ; -create a time array and set to the first time of the nc file
  ;  Note: this is a fictitious time used for CF-compliance, if needed
  time = new(1,"double",0)
  ; -set the attributes and dimensions
  time@long_name = "Time"
  time@standard_name = "time"
  time@_FillValue = default_fillvalue(typeof(time))
  time!0 = "time"
  time&time = time
  time(0) = f_nc->time(0)
  ; -currently, there are no pressure-level fields, adding a dummy pressure field
  pressure = (/9999,999,99,9/)
;  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  ; create a mask for the SOM domain based on lat/lon, elev, land, ocean
;  ; Note: this mask only needs to be created once, using the first node
;  if ((avg2dAnom .or. avg3dAnom) .and. use_som_mask .and. \
;       j .eq. 0 .and. i .eq. 0) then
;    ; retrieve the SOM domain information
;    ;  -create the info resource
;    info  = True
;    ;  -call the procedure
;    polarSOMdomain(dom, info)
;    ; use the geo file, if selected, otherwise use the input data file
;    if (use_geo) then
;      ; open and read the geo file
;      f_geo = addfile(path_geo+file_geo,"r")
;      ; -read in the lat, lon, Z_sfc, and landmask
;      lat2d = f_geo->XLAT_M(0,:,:)
;      lon2d = f_geo->XLONG_M(0,:,:)
;      Z_sfc2d = f_geo->HGT_M(0,:,:)
;      landmask = f_geo->LANDMASK(0,:,:)
;      ; -close the geo file
;      delete(f_geo)
;    else
;      ; -read in the lat, lon, Z_sfc, and landmask
;      lat2d = node_file[0]->lat
;      lon2d = node_file[0]->lon
;      Z_sfc2d = node_file[0]->Z_sfc
;      landmask = node_file[0]->LandMask  
;    end if
;    ; create a lon for 0 to 360
;    lon360 = where(lon2d.lt.0., lon2d+360., lon2d)
;    ; determine the dimensions and total size
;    dims = dimsizes(lat2d)
;    n_sn = dims(0)       ; nx_grid
;    n_we = dims(1)       ; ny_grid
;    ; create som_mask array
;    som_mask = new((/n_sn,n_we/),integer)
;    som_mask = 1
;    ; -mask by lat/lon, if selected
;    if (info@use_latlon_mask) then
;      som_mask = where((lat2d.ge.info@min_lat .and.  \
;                        lat2d.le.info@max_lat .and.  \
;                        lon360.ge.info@min_lon .and.  \
;                        lon360.le.info@max_lon),som_mask,0)
;    end if
;    ; mask by elevation, if selected
;    if (info@use_elev_mask) then
;      som_mask = where((Z_sfc2d .lt. info@elev_mask_hgt),som_mask,0)
;    end if
;    ; mask by land, if selected
;    if (info@use_land_mask) then
;      som_mask = where((landmask .eq. 1),som_mask,0)
;    end if
;    ; mask by ocean, if selected
;    if (info@use_ocean_mask) then
;      som_mask = where((landmask .eq. 0),som_mask,0)
;    end if
;  end if
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; calculate the node averages
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; determine the number of nodes
  nnode = nx_node * ny_node
  ; set the counters to check for errors
  check_file = 0
  ; start the node counter
  n = 0
  ; set the initial string for cat'ing the files together
  cat_file = ""
  ; create file information for avg of all times, if selected
  if create_all_avg then
    ; create the output file, if it is an output file for each node
    path_file_out = path_out+prefix_out+".all"+suffix_out
    ;  -check to see if file is present, if so, delete the previous file
    if isfilepresent(path_file_out) then
      system ("rm "+path_file_out)
    end if
    ;  -create the file
    f_all = addfile(path_file_out,"c")
    ;  -modify global attributes
    fileAtt_all = fileAtt
    fileAtt_all@title = "field average for all time slices"
    ; create the global attributes
    fileattdef(f_all, fileAtt_all)
    ; set time to be the unlimited record variable, if selected
    if (outTime) then
      filedimdef(f_all,"time",-1,True)
    end if
    ; create fields to establish/verify the node labels
    som_i_all = -9
    som_j_all = -9
    ;  -add the time dimension, if using time
    if (outTime) then
      f_all->time = time
      som_i_all!0 = "time"
      som_i_all&time = time
      som_j_all!0 = "time"
      som_j_all&time = time
    end if
    ; send the pressure variable to the output file, if using pressure levels
    if (avgPL .or. avgPLAnom) then
      f_all->pressure = pressure
    end if
    ; write the SOM labels to the file
    f_all->som_i = som_i_all
    f_all->som_j = som_j_all
    ; add the static fields
    f_all->lat = lat_nc
    f_all->lon = lon_nc
    f_all->orog = orog_nc
    f_all->sftlf = sftlf_nc
    ; determine the dates for all
    if (str_upper(freq_type) .eq. "ALL_LOW") then
      dateind_all = ind((  \
          (lbl .eq. "0101" .and. (((mo .eq. 1 .or. mo .eq. 2 .or.  \
                                  mo .eq. 3 .or. mo .eq. 4) .and. \
          (yr.eq.1983 .or. yr.eq.1988 .or. yr.eq.1989 .or. yr.eq.1990 .or. \
           yr.eq.1991 .or. yr.eq.1992 .or. yr.eq.1994 .or. yr.eq.1995 .or. \
           yr.eq.1996 .or. yr.eq.1997 .or. yr.eq.1998 .or. yr.eq.2001 .or. \
           yr.eq.2002 .or. yr.eq.2004 .or. yr.eq.2005 .or. yr.eq.2006 .or. \
           yr.eq.2007 .or. yr.eq.2008 .or. yr.eq.2014))  \
                         .or.   ((mo .eq. 9 .or. mo .eq. 10 .or.  \
                                  mo .eq. 11 .or. mo .eq. 12) .and.  \
          (yr.eq.1982 .or. yr.eq.1987 .or. yr.eq.1988 .or. yr.eq.1989 .or. \
           yr.eq.1990 .or. yr.eq.1991 .or. yr.eq.1993 .or. yr.eq.1994 .or. \
           yr.eq.1995 .or. yr.eq.1996 .or. yr.eq.1997 .or. yr.eq.2000 .or. \
           yr.eq.2001 .or. yr.eq.2003 .or. yr.eq.2004 .or. yr.eq.2005 .or. \
           yr.eq.2006 .or. yr.eq.2007 .or. yr.eq.2013)))) .or.  \
          (lbl .eq. "0151" .and. (((mo .eq. 1 .or. mo .eq. 2 .or.  \
                                  mo .eq. 3 .or. mo .eq. 4) .and. \
          (yr.eq.1950 .or. yr.eq.1951 .or. yr.eq.1959 .or. yr.eq.1964 .or. \
           yr.eq.1973 .or. yr.eq.1975 .or. yr.eq.1987 .or. yr.eq.1988 .or. \
           yr.eq.1989 .or. yr.eq.1990))  \
                         .or.   ((mo .eq. 9 .or. mo .eq. 10 .or.  \
                                  mo .eq. 11 .or. mo .eq. 12) .and.  \
          (yr.eq.1949 .or. yr.eq.1950 .or. yr.eq.1958 .or. yr.eq.1963 .or. \
           yr.eq.1972 .or. yr.eq.1974 .or. yr.eq.1986 .or. yr.eq.1987 .or. \
           yr.eq.1988 .or. yr.eq.1989)))) .or.  \
          (lbl .eq. "0201" .and. (((mo .eq. 1 .or. mo .eq. 2 .or.  \
                                    mo .eq. 3 .or. mo .eq. 4) .and. \
          (yr.eq.1958 .or. yr.eq.1960 .or. yr.eq.1988 .or. yr.eq.1989))  \
                         .or.   ((mo .eq. 9 .or. mo .eq. 10 .or.  \
                                  mo .eq. 11 .or. mo .eq. 12) .and.  \
          (yr.eq.1957 .or. yr.eq.1959 .or. yr.eq.1987 .or. yr.eq.1988)))) .or. \
          (lbl .eq. "0251" .and. (((mo .eq. 1 .or. mo .eq. 2 .or.  \
                                  mo .eq. 3 .or. mo .eq. 4) .and. \
          (yr.eq.1991 .or. yr.eq.1995 .or. yr.eq.1996 .or. yr.eq.1997 .or. \
           yr.eq.1998 .or. yr.eq.1999 .or. yr.eq.2000 .or. yr.eq.2002 .or. \
           yr.eq.2003 .or. yr.eq.2004 .or. yr.eq.2009 .or. yr.eq.2010))  \
                         .or.   ((mo .eq. 9 .or. mo .eq. 10 .or.  \
                                  mo .eq. 11 .or. mo .eq. 12) .and.  \
          (yr.eq.1990 .or. yr.eq.1994 .or. yr.eq.1995 .or. yr.eq.1996 .or. \
           yr.eq.1997 .or. yr.eq.1998 .or. yr.eq.1999 .or. yr.eq.2001 .or. \
           yr.eq.2002 .or. yr.eq.2003 .or. yr.eq.2008 .or. yr.eq.2009)))) .or.  \
          (lbl .eq. "0301" .and. (((mo .eq. 1 .or. mo .eq. 2 .or.  \
                                  mo .eq. 3 .or. mo .eq. 4) .and. \
          (yr.eq.1961 .or. yr.eq.1966 .or. yr.eq.1968 .or. yr.eq.1972))  \
                         .or.   ((mo .eq. 9 .or. mo .eq. 10 .or.  \
                                  mo .eq. 11 .or. mo .eq. 12) .and.  \
          (yr.eq.1960 .or. yr.eq.1965 .or. yr.eq.1967 .or. yr.eq.1971))))))
    else if (str_upper(freq_type) .eq. "ALL_HIGH") then
      dateind_all = ind((  \
          (lbl .eq. "0101" .and. (((mo .eq. 1 .or. mo .eq. 2 .or.  \
                                  mo .eq. 3 .or. mo .eq. 4) .and. \
          (yr.eq.1950 .or. yr.eq.1954 .or. yr.eq.1959 .or. yr.eq.1962 .or. \
           yr.eq.1963 .or. yr.eq.1964 .or. yr.eq.1966 .or. yr.eq.1968))  \
                         .or.   ((mo .eq. 9 .or. mo .eq. 10 .or.  \
                                  mo .eq. 11 .or. mo .eq. 12) .and.  \
          (yr.eq.1949 .or. yr.eq.1953 .or. yr.eq.1958 .or. yr.eq.1961 .or. \
           yr.eq.1962 .or. yr.eq.1963 .or. yr.eq.1965 .or. yr.eq.1967)))) .or.  \
          (lbl .eq. "0151" .and. (((mo .eq. 1 .or. mo .eq. 2 .or.  \
                                  mo .eq. 3 .or. mo .eq. 4) .and. \
          (yr.eq.2007 .or. yr.eq.2009 .or. yr.eq.2013 .or. yr.eq.2014))  \
                         .or.   ((mo .eq. 9 .or. mo .eq. 10 .or.  \
                                  mo .eq. 11 .or. mo .eq. 12) .and.  \
          (yr.eq.2006 .or. yr.eq.2008 .or. yr.eq.2012 .or. yr.eq.2013)))) .or.  \
          (lbl .eq. "0201" .and. (((mo .eq. 1 .or. mo .eq. 2 .or.  \
                                  mo .eq. 3 .or. mo .eq. 4) .and. \
          (yr.eq.1986 .or. yr.eq.1987 .or. yr.eq.1998 .or. yr.eq.1999 .or. \
           yr.eq.2000 .or. yr.eq.2001 .or. yr.eq.2002 .or. yr.eq.2007 .or. \
           yr.eq.2008 .or. yr.eq.2009 .or. yr.eq.2010 .or. yr.eq.2011 .or. \
           yr.eq.2012 .or. yr.eq.2013 .or. yr.eq.2014))  \
                         .or.   ((mo .eq. 9 .or. mo .eq. 10 .or.  \
                                  mo .eq. 11 .or. mo .eq. 12) .and.  \
          (yr.eq.1985 .or. yr.eq.1986 .or. yr.eq.1997 .or. yr.eq.1998 .or. \
           yr.eq.1999 .or. yr.eq.2000 .or. yr.eq.2001 .or. yr.eq.2006 .or. \
           yr.eq.2007 .or. yr.eq.2008 .or. yr.eq.2009 .or. yr.eq.2010 .or. \
           yr.eq.2011 .or. yr.eq.2012 .or. yr.eq.2013)))) .or. \
          (lbl .eq. "0251" .and. (((mo .eq. 1 .or. mo .eq. 2 .or.  \
                                  mo .eq. 3 .or. mo .eq. 4) .and. \
          (yr.eq.1966 .or. yr.eq.1968 .or. yr.eq.1969 .or. yr.eq.1970 .or. \
           yr.eq.1971 .or. yr.eq.1972 .or. yr.eq.1973 .or. yr.eq.1974 .or. \
           yr.eq.1987 .or. yr.eq.1988))  \
                         .or.   ((mo .eq. 9 .or. mo .eq. 10 .or.  \
                                  mo .eq. 11 .or. mo .eq. 12) .and.  \
          (yr.eq.1965 .or. yr.eq.1967 .or. yr.eq.1968 .or. yr.eq.1969 .or. \
           yr.eq.1970 .or. yr.eq.1971 .or. yr.eq.1972 .or. yr.eq.1973 .or. \
           yr.eq.1986 .or. yr.eq.1987)))) .or.  \
          (lbl .eq. "0301" .and. (((mo .eq. 1 .or. mo .eq. 2 .or.  \
                                  mo .eq. 3 .or. mo .eq. 4) .and. \
          (yr.eq.1985 .or. yr.eq.1989 .or. yr.eq.1990 .or. yr.eq.1993 .or. \
           yr.eq.1994 .or. yr.eq.1995 .or. yr.eq.1996 .or. yr.eq.1997 .or. \
           yr.eq.1998 .or. yr.eq.2000 .or. yr.eq.2009 .or. yr.eq.2010))  \
                         .or.   ((mo .eq. 9 .or. mo .eq. 10 .or.  \
                                  mo .eq. 11 .or. mo .eq. 12) .and.  \
          (yr.eq.1984 .or. yr.eq.1988 .or. yr.eq.1989 .or. yr.eq.1992 .or. \
           yr.eq.1993 .or. yr.eq.1994 .or. yr.eq.1995 .or. yr.eq.1996 .or. \
           yr.eq.1997 .or. yr.eq.1999 .or. yr.eq.2008 .or. yr.eq.2009))))))
    else
     ; select all time slices
      dateind_all = ind(.not.ismissing(vis(:,0)))
    end if
    end if
    ; print a report on the number of time slices creating the all average
    print("all average # of time slices: "+dimsizes(dateind_all))
  end if
  ; loop through each node
  do j = 0, ny_node - 1
    do i = 0, nx_node - 1
;amy  do j = 2,2 
;amy    do i = 4,4 
      ; set the node labels
      if som_zero_based then
        label_i = i
        label_j = j
      else
        label_i = i+1
        label_j = j+1
      end if
      ; create the output file, if it is an output file for each node
      path_file_out = path_out+prefix_out+"."+label_i+"_"+label_j+suffix_out
      ;  -check to see if file is present, if so, delete the previous file
      if isfilepresent(path_file_out) then
        system ("rm "+path_file_out)
      end if
      ;  -add to the cat_file variable for cat'ing the files together
      cat_file = cat_file+" "+path_file_out
      ;  -create the file
      f_avg = addfile(path_file_out,"c")
      ; create the global attributes
      fileattdef(f_avg, fileAtt)
      ; set time to be the unlimited record variable, if selected
      if (outTime) then
        filedimdef(f_avg,"time",-1,True)
      end if      
      ; create fields to establish/verify the node labels
      som_i = label_i
      som_j = label_j
      ;  -add the time dimension, if using time
      if (outTime) then
        time = time + 1.
        f_avg->time = time
        som_i!0 = "time"
        som_i&time = time
        som_j!0 = "time"
        som_j&time = time
      end if
      ; send the pressure variable to the output file, if using pressure levels
      if (avgPL .or. avgPLAnom) then
        f_avg->pressure = pressure
      end if
      ; write the SOM labels to the file
      f_avg->som_i = som_i
      f_avg->som_j = som_j
      ; add the static fields
      f_avg->lat = lat_nc
      f_avg->lon = lon_nc
      f_avg->orog = orog_nc
      f_avg->sftlf = sftlf_nc
      ; determine the dates for current node
      if (str_upper(freq_type) .eq. "ALL_LOW") then
        dateind = ind((vis(:,0).eq.i) .and. (vis(:,1).eq.j) .and. (  \
            (lbl .eq. "0101" .and. (((mo .eq. 1 .or. mo .eq. 2 .or.  \
                                    mo .eq. 3 .or. mo .eq. 4) .and. \
            (yr.eq.1983 .or. yr.eq.1988 .or. yr.eq.1989 .or. yr.eq.1990 .or. \
             yr.eq.1991 .or. yr.eq.1992 .or. yr.eq.1994 .or. yr.eq.1995 .or. \
             yr.eq.1996 .or. yr.eq.1997 .or. yr.eq.1998 .or. yr.eq.2001 .or. \
             yr.eq.2002 .or. yr.eq.2004 .or. yr.eq.2005 .or. yr.eq.2006 .or. \
             yr.eq.2007 .or. yr.eq.2008 .or. yr.eq.2014))  \
                           .or.   ((mo .eq. 9 .or. mo .eq. 10 .or.  \
                                    mo .eq. 11 .or. mo .eq. 12) .and.  \
            (yr.eq.1982 .or. yr.eq.1987 .or. yr.eq.1988 .or. yr.eq.1989 .or. \
             yr.eq.1990 .or. yr.eq.1991 .or. yr.eq.1993 .or. yr.eq.1994 .or. \
             yr.eq.1995 .or. yr.eq.1996 .or. yr.eq.1997 .or. yr.eq.2000 .or. \
             yr.eq.2001 .or. yr.eq.2003 .or. yr.eq.2004 .or. yr.eq.2005 .or. \
             yr.eq.2006 .or. yr.eq.2007 .or. yr.eq.2013)))) .or.  \
            (lbl .eq. "0151" .and. (((mo .eq. 1 .or. mo .eq. 2 .or.  \
                                    mo .eq. 3 .or. mo .eq. 4) .and. \
            (yr.eq.1950 .or. yr.eq.1951 .or. yr.eq.1959 .or. yr.eq.1964 .or. \
             yr.eq.1973 .or. yr.eq.1975 .or. yr.eq.1987 .or. yr.eq.1988 .or. \
             yr.eq.1989 .or. yr.eq.1990))  \
                           .or.   ((mo .eq. 9 .or. mo .eq. 10 .or.  \
                                    mo .eq. 11 .or. mo .eq. 12) .and.  \
            (yr.eq.1949 .or. yr.eq.1950 .or. yr.eq.1958 .or. yr.eq.1963 .or. \
             yr.eq.1972 .or. yr.eq.1974 .or. yr.eq.1986 .or. yr.eq.1987 .or. \
             yr.eq.1988 .or. yr.eq.1989)))) .or.  \
            (lbl .eq. "0201" .and. (((mo .eq. 1 .or. mo .eq. 2 .or.  \
                                      mo .eq. 3 .or. mo .eq. 4) .and. \
            (yr.eq.1958 .or. yr.eq.1960 .or. yr.eq.1988 .or. yr.eq.1989))  \
                           .or.   ((mo .eq. 9 .or. mo .eq. 10 .or.  \
                                    mo .eq. 11 .or. mo .eq. 12) .and.  \
            (yr.eq.1957 .or. yr.eq.1959 .or. yr.eq.1987 .or. yr.eq.1988)))) .or. \
            (lbl .eq. "0251" .and. (((mo .eq. 1 .or. mo .eq. 2 .or.  \
                                    mo .eq. 3 .or. mo .eq. 4) .and. \
            (yr.eq.1991 .or. yr.eq.1995 .or. yr.eq.1996 .or. yr.eq.1997 .or. \
             yr.eq.1998 .or. yr.eq.1999 .or. yr.eq.2000 .or. yr.eq.2002 .or. \
             yr.eq.2003 .or. yr.eq.2004 .or. yr.eq.2009 .or. yr.eq.2010))  \
                           .or.   ((mo .eq. 9 .or. mo .eq. 10 .or.  \
                                    mo .eq. 11 .or. mo .eq. 12) .and.  \
            (yr.eq.1990 .or. yr.eq.1994 .or. yr.eq.1995 .or. yr.eq.1996 .or. \
             yr.eq.1997 .or. yr.eq.1998 .or. yr.eq.1999 .or. yr.eq.2001 .or. \
             yr.eq.2002 .or. yr.eq.2003 .or. yr.eq.2008 .or. yr.eq.2009)))) .or.  \
            (lbl .eq. "0301" .and. (((mo .eq. 1 .or. mo .eq. 2 .or.  \
                                    mo .eq. 3 .or. mo .eq. 4) .and. \
            (yr.eq.1961 .or. yr.eq.1966 .or. yr.eq.1968 .or. yr.eq.1972))  \
                           .or.   ((mo .eq. 9 .or. mo .eq. 10 .or.  \
                                    mo .eq. 11 .or. mo .eq. 12) .and.  \
            (yr.eq.1960 .or. yr.eq.1965 .or. yr.eq.1967 .or. yr.eq.1971))))))
      else if (str_upper(freq_type) .eq. "ALL_HIGH") then
        dateind = ind((vis(:,0).eq.i) .and. (vis(:,1).eq.j) .and. (  \
            (lbl .eq. "0101" .and. (((mo .eq. 1 .or. mo .eq. 2 .or.  \
                                    mo .eq. 3 .or. mo .eq. 4) .and. \
            (yr.eq.1950 .or. yr.eq.1954 .or. yr.eq.1959 .or. yr.eq.1962 .or. \
             yr.eq.1963 .or. yr.eq.1964 .or. yr.eq.1966 .or. yr.eq.1968))  \
                           .or.   ((mo .eq. 9 .or. mo .eq. 10 .or.  \
                                    mo .eq. 11 .or. mo .eq. 12) .and.  \
            (yr.eq.1949 .or. yr.eq.1953 .or. yr.eq.1958 .or. yr.eq.1961 .or. \
             yr.eq.1962 .or. yr.eq.1963 .or. yr.eq.1965 .or. yr.eq.1967)))) .or.  \
            (lbl .eq. "0151" .and. (((mo .eq. 1 .or. mo .eq. 2 .or.  \
                                    mo .eq. 3 .or. mo .eq. 4) .and. \
            (yr.eq.2007 .or. yr.eq.2009 .or. yr.eq.2013 .or. yr.eq.2014))  \
                           .or.   ((mo .eq. 9 .or. mo .eq. 10 .or.  \
                                    mo .eq. 11 .or. mo .eq. 12) .and.  \
            (yr.eq.2006 .or. yr.eq.2008 .or. yr.eq.2012 .or. yr.eq.2013)))) .or.  \
            (lbl .eq. "0201" .and. (((mo .eq. 1 .or. mo .eq. 2 .or.  \
                                    mo .eq. 3 .or. mo .eq. 4) .and. \
            (yr.eq.1986 .or. yr.eq.1987 .or. yr.eq.1998 .or. yr.eq.1999 .or. \
             yr.eq.2000 .or. yr.eq.2001 .or. yr.eq.2002 .or. yr.eq.2007 .or. \
             yr.eq.2008 .or. yr.eq.2009 .or. yr.eq.2010 .or. yr.eq.2011 .or. \
             yr.eq.2012 .or. yr.eq.2013 .or. yr.eq.2014))  \
                           .or.   ((mo .eq. 9 .or. mo .eq. 10 .or.  \
                                    mo .eq. 11 .or. mo .eq. 12) .and.  \
            (yr.eq.1985 .or. yr.eq.1986 .or. yr.eq.1997 .or. yr.eq.1998 .or. \
             yr.eq.1999 .or. yr.eq.2000 .or. yr.eq.2001 .or. yr.eq.2006 .or. \
             yr.eq.2007 .or. yr.eq.2008 .or. yr.eq.2009 .or. yr.eq.2010 .or. \
             yr.eq.2011 .or. yr.eq.2012 .or. yr.eq.2013)))) .or. \
            (lbl .eq. "0251" .and. (((mo .eq. 1 .or. mo .eq. 2 .or.  \
                                    mo .eq. 3 .or. mo .eq. 4) .and. \
            (yr.eq.1966 .or. yr.eq.1968 .or. yr.eq.1969 .or. yr.eq.1970 .or. \
             yr.eq.1971 .or. yr.eq.1972 .or. yr.eq.1973 .or. yr.eq.1974 .or. \
             yr.eq.1987 .or. yr.eq.1988))  \
                           .or.   ((mo .eq. 9 .or. mo .eq. 10 .or.  \
                                    mo .eq. 11 .or. mo .eq. 12) .and.  \
            (yr.eq.1965 .or. yr.eq.1967 .or. yr.eq.1968 .or. yr.eq.1969 .or. \
             yr.eq.1970 .or. yr.eq.1971 .or. yr.eq.1972 .or. yr.eq.1973 .or. \
             yr.eq.1986 .or. yr.eq.1987)))) .or.  \
            (lbl .eq. "0301" .and. (((mo .eq. 1 .or. mo .eq. 2 .or.  \
                                    mo .eq. 3 .or. mo .eq. 4) .and. \
            (yr.eq.1985 .or. yr.eq.1989 .or. yr.eq.1990 .or. yr.eq.1993 .or. \
             yr.eq.1994 .or. yr.eq.1995 .or. yr.eq.1996 .or. yr.eq.1997 .or. \
             yr.eq.1998 .or. yr.eq.2000 .or. yr.eq.2009 .or. yr.eq.2010))  \
                           .or.   ((mo .eq. 9 .or. mo .eq. 10 .or.  \
                                    mo .eq. 11 .or. mo .eq. 12) .and.  \
            (yr.eq.1984 .or. yr.eq.1988 .or. yr.eq.1989 .or. yr.eq.1992 .or. \
             yr.eq.1993 .or. yr.eq.1994 .or. yr.eq.1995 .or. yr.eq.1996 .or. \
             yr.eq.1997 .or. yr.eq.1999 .or. yr.eq.2008 .or. yr.eq.2009))))))
      else
        dateind = ind((vis(:,0).eq.i) .and. (vis(:,1).eq.j))
      end if
      end if
      ; print the info for the current node
      print("node: "+label_i+","+label_j+"   # of time slices: "+dimsizes(dateind))
      ; verify that there are time slices mapped to this node
      if (all(ismissing(dateind))) then
        print("  There are no time slices mapped to this node.")
      end if
      print(  "  file_out: "+prefix_out+"."+label_i+"_"+label_j+suffix_out)
      ; output the average and variance (if selected) for each selected variable
      ;  -two-dimensional variables
      if (avg2d) then
        ; loop through the list of variables
        do m = 0, n2d-1
          ; check to see if variable is to be included and present in file
          ; Note:  The check on the variable being present is only done on the
          ;        first file.  The assumption is that all of the input nc
          ;        files have the same variables.
          if avg2d@$var2d(m)$ then
            print("  field: "+var2d(m))
            nstr = strlen(var2d(m))
            if (str_get_cols(var2d(m),nstr-3,nstr-1).eq."bot") then
              var2 = str_get_cols(var2d(m),0,nstr-4)
            end if
            if (var2d(m) .eq. "Windbot") then
;              u_in = f_nc->uabot(dateind,:,:)
;              v_in = f_nc->vabot(dateind,:,:)
               u_in = readDailyFiles(path_nc,prefix_nc,dates,dateind,n_y,n_x,"uabot")
               v_in = readDailyFiles(path_nc,prefix_nc,dates,dateind,n_y,n_x,"vabot")
               data_in = sqrt(u_in^2 + v_in^2)
              ;data_in@coordinates = u_in@coordinates
              ;data_in!0 = "time"                    ; set the time atts and dims
              ;data_in&time = time
              ;data_in!1 = "y"
              ;data_in!2 = "x"
              data_in@units = "m/s"
              data_in@long_name = "Lowest model level wind speed"
              ;printVarSummary(data_in)
              delete([/u_in,v_in/])
              ; all average
              if (i .eq. 0 .and. j .eq. 0 .and. create_all_avg) then
;                u_in = f_nc->uabot(dateind_all,:,:)
;                v_in = f_nc->vabot(dateind_all,:,:)
                 u_in = readDailyFiles(path_nc,prefix_nc,dates,dateind_all,n_y,n_x,"uabot")
                 v_in = readDailyFiles(path_nc,prefix_nc,dates,dateind_all,n_y,n_x,"vabot")
                data_all = sqrt(u_in^2 + v_in^2)
                data_all@units = "m/s"
                data_all@long_name = "Lowest model level wind speed"
                delete([/u_in,v_in/])
              end if
            else if (var2d(m) .eq. "rsus") then
              
            else if (var2d(m) .eq. "rlus") then
              
            else if (var2d(m) .eq. "hfts") then
;              hfss = f_nc->hfss(dateind,:,:)
;              hfls = f_nc->hfss(dateind,:,:)
              hfss = readDailyFiles(path_nc,prefix_nc,dates,dateind,n_y,n_x,"hfss")
              hfls = readDailyFiles(path_nc,prefix_nc,dates,dateind,n_y,n_x,"hfls")
              data_in = hfss + hfls
              ;data_in@coordinates = "lon lat"
              data_in@units = "W/m2"
              data_in@long_name = "Surface turbulent heat flux (hfss+hfls)"
              delete([/hfss,hfls/])
              ; all average
              if (i .eq. 0 .and. j .eq. 0 .and. create_all_avg) then
;;                hfss = f_nc->hfss(dateind_all,:,:)
;;                hfls = f_nc->hfss(dateind_all,:,:)
                hfss = readDailyFiles(path_nc,prefix_nc,dates,dateind_all,n_y,n_x,"hfss")
                hfls = readDailyFiles(path_nc,prefix_nc,dates,dateind_all,n_y,n_x,"hfls")
                data_all = hfss + hfls
                ;data_all@coordinates = "lon lat"
                data_all@units = "W/m2"
                data_all@long_name = "Surface turbulent heat flux (hfss+hfls)"
                delete([/hfss,hfls/])
              end if
            else if (var2d(m) .eq. "rds") then
;;              rlds = f_nc->rlds(dateind,:,:)
;;              rsds = f_nc->rsds(dateind,:,:)
              rlds = readDailyFiles(path_nc,prefix_nc,dates,dateind,n_y,n_x,"rlds")
              rsds = readDailyFiles(path_nc,prefix_nc,dates,dateind,n_y,n_x,"rsds")
              data_in = rlds + rsds
              ;data_in@coordinates = "lon lat"
              data_in@units = "W/m2"
              data_in@long_name = "Total downward radiation (rlds+rsds)"
              delete([/rlds,rsds/])
              ; all average
              if (i .eq. 0 .and. j .eq. 0 .and. create_all_avg) then
;                rlds = f_nc->rlds(dateind_all,:,:)
;                rsds = f_nc->rsds(dateind_all,:,:)
                rlds = readDailyFiles(path_nc,prefix_nc,dates,dateind_all,n_y,n_x,"rlds")
                rsds = readDailyFiles(path_nc,prefix_nc,dates,dateind_all,n_y,n_x,"rsds")
                data_all = rlds + rsds
                ;data_in@coordinates = "lon lat"
                data_all@units = "W/m2"
                data_all@long_name = "Total downward radiation (rlds+rsds)"
                delete([/rlds,rsds/])
              end if
            else if (isfilevar(f_nc, var2d_in(m)).or.isfilevar(f_nc, var2)) then
;              data_in = f_nc->$var2d_in(m)$(dateind,:,:)     ; read in the data
               data_in = readDailyFiles(path_nc,prefix_nc,dates,dateind,n_y,n_x,var2d_in(m))
              ;printVarSummary(data_in)
              ; all average
              if (i .eq. 0 .and. j .eq. 0 .and. create_all_avg) then
;                data_all = f_nc->$var2d_in(m)$(dateind_all,:,:)     ; read in the data
                data_all = readDailyFiles(path_nc,prefix_nc,dates,dateind_all,n_y,n_x,var2d_in(m))
              end if
            else
              ; send an error message if variable is not included in input file
              print("Error: variable "+var2d_in(m)+" is not in the netcdf input file.")
              continue
            end if
            end if
            end if
            end if
            end if
            end if
            data_avg = dim_avg_n_Wrap(data_in,0)        ; calculate the average of x
            data_var = dim_variance_n_Wrap(data_in,0)   ; calculate the variance of x
            if (outTime) then                 ; check to include time variable
              avg_out = new((/1,n_y,n_x/),"float",0)  ; create new average array  
              avg_out(0,:,:) = data_avg                   ; set the new array
              avg_out!0 = "time"                    ; set the time atts and dims
              avg_out&time = time
              var_out = new((/1,n_y,n_x/),"float",0)  ; create new variance array
              var_out(0,:,:) = data_var                 ; set the new array
              var_out!0 = "time"                  ; set the time atts and dims
              var_out&time = time
            else
              avg_out = data_avg
              var_out = data_var
            end if
            ; set the _FillValue attributes
            avg_out@_FillValue = default_fillvalue("float")
            var_out@_FillValue = default_fillvalue("float")
            ; write the average and variance to the output file
            f_avg->$var2d_out(m)$ = avg_out
            if (outVar) then
              f_avg->$var2d_var(m)$ = var_out
            end if
            ; delete the tmp variables
            delete([/data_in,data_avg,data_var,avg_out,var_out/])
            ; calculate average and varibiltity for all time slices (not by node)
            if (i .eq. 0 .and. j .eq. 0 .and. create_all_avg) then
              data_avg_all = dim_avg_n_Wrap(data_all,0)        ; calculate the average of x
              data_var_all = dim_variance_n_Wrap(data_all,0)   ; calculate the variance of x
              if (outTime) then                 ; check to include time variable
                avg_out_all = new((/1,n_y,n_x/),"float",0)  ; create new average array  
                avg_out_all(0,:,:) = data_avg_all                 ; set the new array
                avg_out_all!0 = "time"                    ; set the time atts and dims
                avg_out_all&time = time
                var_out_all = new((/1,n_y,n_x/),"float",0)  ; create new variance array
                var_out_all(0,:,:) = data_var_all                 ; set the new array
                var_out_all!0 = "time"                  ; set the time atts and dims
                var_out_all&time = time
              else
                avg_out_all = data_avg_all
                var_out_all = data_var_all
              end if
              ; set the _FillValue attributes
              avg_out_all@_FillValue = default_fillvalue("float")
              var_out_all@_FillValue = default_fillvalue("float")
              ; write the average and variance to the output file
              f_all->$var2d_out(m)$ = avg_out_all
              if (outVar) then
                f_all->$var2d_var(m)$ = var_out_all
              end if
              ; delete the tmp variables
              delete([/data_all,data_avg_all,data_var_all,avg_out_all,var_out_all/])
            end if
          end if
        end do
      end if 
;      ; three-dimensional upper-level (pressure levels) meteorology variables
;      if (avgPL) then
;        ; loop through the list of variables
;        do m = 0, nPres-1
;          ; check to see if variable is to be included
;          if (avgPL@$Pres(m)$ .and.  \
;              isfilevar(node_file[0], Pres_in(m))) then
;            x = node_file[:]->$Pres_in(m)$        ; read in the data
;            s = dimsizes(x)                   ; determine size of dimensions
;            if (outTime) then                 ; check to include time variable
;              a0 = dim_avg_n_Wrap(x,0)        ; calculate the average of x
;              a = new((/1,s(1),s(2),s(3)/),"float",0) ; create new average array  
;              a(0,:,:,:) = a0                   ; set the new array
;              a!0 = "time"                    ; set the time atts and dims
;              a&time = time
;              a@_FillValue = 1e20
;              delete(a0)                      ; delete the tmp variable
;              if (outVar) then
;                v0 = dim_variance_n_Wrap(x,0)   ; calculate the variance of x            
;                v = new((/1,s(1),s(2),s(3)/),"float",0) ; create new variance
;                v(0,:,:,:) = v0                 ; set the new array
;                v!0 = "time"                  ; set the time atts and dims
;                v&time = time
;                v@_FillValue = 1e20
;                delete(v0)                    ; delete the tmp variable
;              end if
;            else
;              a = dim_avg_n_Wrap(x,0)         ; calculate the average of x
;              if (outVar) then
;                v = dim_variance_n_Wrap(x,0)  ; calculate the variance of x
;              end if
;            end if
;            ; write the average and variance to the output file
;            f_avg->$Pres_out(m)$ = a
;            if (outVar) then
;              f_avg->$Pres_var(m)$ = v
;              delete(v)
;            end if
;            ; delete the tmp variables
;            delete([/x,s,a/])
;          else
;            ; send an error message if variable is not included in input file
;            if (avgPL@$Pres(m)$ .and.  \
;                .not.isfilevar(node_file[0], Pres_in(m))) then
;              print("Error: the selected variable "+Pres_in(m)+" is not "+  \
;                    "included in the netcdf input file.")
;            end if
;          end if
;        end do
;      end if
;      ; two-dimensional anomaly calculations
;      if (avg2dAnom) then
;        ; loop through the list of variables
;        do m = 0, nAnom2d-1
;          ; check to see if variable is to be included
;          if (avg2dAnom@$Anom2d(m)$ .and.  \
;              isfilevar(node_file[0], Anom2d_in(m))) then
;            x = node_file[:]->$Anom2d_in(m)$     ; read in the data
;            s = dimsizes(x)                   ; determine size of dimensions
;            ; calculate the anomaly - creating a new temporary array
;            x1 = new(s,"float",0)             ; create the tmp anomaly array
;            copy_VarCoords(x, x1)             ; copy the coordinates
;            copy_VarAtts(x, x1)               ; copy the attributes
;            do l = 0, s(0) - 1  ; loop through each time
;              x0 = x(l,:,:)
;              if (use_som_mask) then          ; mask the data based on the SOM
;                x0 = mask(x0,som_mask.eq.1,True)
;              end if
;              x1(l,:,:) = x0 - avg(x0)        ; calculate anomaly
;              ;x1(l,:,:) = x(l,:,:) - avg(x(l,:,:))  ; calculate anomaly
;            end do
;            x = x1                            ; set the anomaly to x
;            if (outTime) then                 ; check to include time variable
;              a0 = dim_avg_n_Wrap(x,0)        ; calculate the average of x
;              a = new((/1,s(1),s(2)/),"float",0)  ; create new average array  
;              a(0,:,:) = a0                   ; set the new array
;              a!0 = "time"                    ; set the time atts and dims
;              a&time = time
;              a@_FillValue = 1e20
;              delete(a0)                      ; delete the tmp variable
;              if (outVar) then
;                v0 = dim_variance_n_Wrap(x,0)   ; calculate the variance of x            
;                v = new((/1,s(1),s(2)/),"float",0)  ; create new variance array
;                v(0,:,:) = v0                 ; set the new array
;                v!0 = "time"                  ; set the time atts and dims
;                v&time = time
;                v@_FillValue = 1e20
;                delete(v0)                    ; delete the tmp variable
;              end if
;            else
;              a = dim_avg_n_Wrap(x,0)         ; calculate the average of x
;              if (outVar) then
;                v = dim_variance_n_Wrap(x,0)  ; calculate the variance of x
;              end if
;            end if
;            ; write the average and variance to the output file
;            f_avg->$Anom2d_out(m)$ = a
;            if (outVar) then
;              f_avg->$Anom2d_var(m)$ = v
;              delete(v)
;            end if
;            ; delete the tmp variables
;            delete([/x,x1,s,a/])
;          else
;            ; send an error message if variable is not included in input file
;            if (avg2dAnom@$Anom2d(m)$ .and.  \
;                .not.isfilevar(node_file[0], Anom2d_in(m))) then
;              print("Error: the selected variable "+Anom2d_in(m)+" is not "+  \
;                    "included in the netcdf input file.")
;            end if
;          end if
;        end do
;      end if
;      ; three-dimensional anomaly calculations
;      if (avg3dAnom) then
;        ; loop through the list of variables
;        do m = 0, nAnom3d-1
;          ; check to see if variable is to be included
;          if (avg3dAnom@$Anom3d(m)$ .and.  \
;              isfilevar(node_file[0], Anom3d_in(m))) then
;            x = node_file[:]->$Anom3d_in(m)$        ; read in the data
;            s = dimsizes(x)                   ; determine size of dimensions
;            ; calculate the anomaly - creating a new temporary array
;            x1 = new(s,"float",0)             ; create the tmp anomaly array
;            copy_VarCoords(x, x1)             ; copy the coordinates
;            copy_VarAtts(x, x1)               ; copy the attributes
;            do l = 0, s(0) - 1  ; loop through each time
;              do k = 0, s(1) - 1  ; loop through each level
;                x0 = x(l,k,:,:)
;                if (use_som_mask) then        ; mask the data based on the SOM
;                  x0 = mask(x0,som_mask.eq.1,True)
;                end if
;                x1(l,k,:,:) = x0 - avg(x0)    ; calculate anomaly
;                ;x1(l,k,:,:) = x(l,k,:,:) - avg(x(l,k,:,:))  ; calculate anomaly
;              end do
;            end do
;            x = x1                            ; set the anomaly to x
;            if (outTime) then                 ; check to include time variable
;              a0 = dim_avg_n_Wrap(x,0)        ; calculate the average of x
;              a = new((/1,s(1),s(2),s(3)/),"float",0) ; create new average array  
;              a(0,:,:,:) = a0                   ; set the new array
;              a!0 = "time"                    ; set the time atts and dims
;              a&time = time
;              a@_FillValue = 1e20
;              delete(a0)                      ; delete the tmp variable
;              if (outVar) then
;                v0 = dim_variance_n_Wrap(x,0)   ; calculate the variance of x            
;                v = new((/1,s(1),s(2),s(3)/),"float",0) ; create new variance
;                v(0,:,:,:) = v0                 ; set the new array
;                v!0 = "time"                  ; set the time atts and dims
;                v&time = time
;                v@_FillValue = 1e20
;                delete(v0)                    ; delete the tmp variable
;              end if
;            else
;              a = dim_avg_n_Wrap(x,0)         ; calculate the average of x
;              if (outVar) then
;                v = dim_variance_n_Wrap(x,0)  ; calculate the variance of x
;              end if
;            end if
;            ; write the average and variance to the output file
;            f_avg->$Anom3d_out(m)$ = a
;            if (outVar) then
;              f_avg->$Anom3d_var(m)$ = v
;              delete(v)
;            end if
;            ; delete the tmp variables
;            delete([/x,x1,s,a/])
;          else
;            ; send an error message if variable is not included in input file
;            if (avg3dAnom@$Anom3d(m)$ .and.  \
;                .not.isfilevar(node_file[0], Anom3d_in(m))) then
;              print("Error: the selected variable "+Anom3d_in(m)+" is not "+  \
;                    "included in the netcdf input file.")
;            end if
;          end if
;        end do
;      end if
      ; increase the node counter (zero based)
      n = n + 1
      ; delete the variables to use again for the next node
      delete([/dateind,som_i,som_j/])
    end do
  end do
  ; cat the individual files together using ncrcat, if selected
  if (outSingleFile) then
    ; set the file name
    file_cat = prefix_out+"."+nx_node+"x"+ny_node+suffix_out
    ;  -check to see if the directory is present, if not, create it
    if isfilepresent(path_out+file_cat) then
      system ("rm "+path_out+file_cat)
    end if
    ; use ncrcat to concatenate the daily files into an annual file
    system ("ncrcat "+cat_file+" "+path_out+file_cat)
    ; edit the global file attributes for simplicity
    system ("ncatted -a title,global,d,c, "+path_out+file_cat)
    system ("ncatted -a history,global,d,c, "+path_out+file_cat)
    ; remove the individual node files, if selected
    if (cleanNodeFile) then
      system ("rm "+cat_file)
    end if
  end if
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; end the main program
end