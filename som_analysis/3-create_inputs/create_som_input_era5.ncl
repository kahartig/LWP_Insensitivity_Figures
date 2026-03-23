;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; create_som_input.ncl
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; -NCL script that creates text input files for creating SOMs using 
;  the som_pak software.
;
;  COMMAND SYNTAX:
;  -The program can be run with the defaults:
;     ncl create_som_input_ant.ncl
;
;  INPUT:
;  -The program uses a text file with a list of dates to determine the
;   time slices that will make up the SOM input file.
;  -The program is designed to netcdf input files from either wrfout_to_cf.ncl,
;   extract_regrid_erai.ncl, or create_era_day.ncl.  However, it should be able
;   to be used with similar netcdf files.
;
;  OUTPUT:
;  -The output is a single text file.  The first line indicates the vector
;   length for each subsequent line.  The number of lines corresponds to the
;   number of input time slices.
;  -The program also creates a latlon file with latitude, longitude, and 
;   elevation in three separate lines corresponding to the data vectors.
;
;  CREATOR:  Mark Seefeldt - 2013-07
;  -Based on the series of IDL programs:  create_som_slp_anom.pro
;  -Also based on extract_cordex_subdomin.ncl by Matt Higgins.
; 
;  RELEASE NOTES:
;    1.0 - 2013-11-14
;      -initial release
;    1.1 - 2014-05-25
;      -modified the original release to work with some Antarctic SOMs
;      -added a few more vertical levels for T and Z
;      -added u_10m as an option
;    1.2 - 2014-07-09
;      -added a new procedure:  polarSOMdomain (residing in: polar_som_info.ncl)
;        -this procedure defines the different settings for a given SOM
;         (e.g. use_landmask, lat/lon ranges, use_elev_mask, etc.)
;    1.3 - 2024-09-17
;      -added capability to create SOMs of binary(0/1) extreme points
;      -added additional fields to be passed at the command prompt 
;       for running from a csh script
;      -added auto-creating of output file name to include extreme and elev mask settings
;      -added the ability to thin input data using stride specification
;      -added additional diagnostic info after completing
;       (ex: such as min, max values in data and Nan checking)
;      -added sfcWind as a calculated field for variable of interest
;       Note: the lat, lon, Z_sfc, data, u, v variables needed to have
;             _FillValue set for the CONUS404 data, these lines should
;             probably be removed in later versions
;    1.3.1 - 2025-04-21
;      -added the abililty to process multiple time slices (hours) in a input
;       nc data file - uses hr_b, hr_e, stride_hr
;
;  TODO:
;    KARA: toggle lon360 based on domain extent
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; load in the libraries
load "polar_som_info.ncl"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; start the main program
begin
  ; set the variable of interest
  if (.not.isvar("var")) then
    var = "psl"
  end if
  ; calc_anom needs to be a logical var, meanwhile it is passed as a string
  if (.not.isvar("anom")) then
    calc_anom = True ; removes seasonal cycle
  else
    if anom .eq. "True" then
      calc_anom = True
    else
      calc_anom = False
    end if
  end if
  ; set other constants and flags for processing
  if (.not.isvar("domain")) then
    domain = "NSA-large"
  end if
  ; set the variables for input/output paths and files
  if (.not.isvar("path_in")) then
    path_in = "/data/khartig/ERA5_1hr/ease_25km/hourly/"
  end if
  if (.not.isvar("path_geo")) then
    path_geo = "/data2/seefeldm/w_ant/domain/"
  end if
  if (.not.isvar("path_dates")) then
    path_dates = "/data/khartig/alaskan_som/input_data/"
  end if
  if (.not.isvar("path_out")) then
    path_out = "/data/khartig/alaskan_som/input_data/"
  end if
  if (.not.isvar("prefix_in")) then
    prefix_in = "era5-ease_25km-"
  end if
  if (.not.isvar("suffix_in")) then
    suffix_in = ".nc"
  end if
  if (.not.isvar("file_geo")) then
    file_geo = "geo_em.d01.nc"
  end if
  if (.not.isvar("file_dates")) then
    file_dates = "ERA5-EASE25km.AlaskaNSA.2000-2024_Nov-Mar.daily.txt"
  end if
  ; the dates files is a daily (yyyymmdd) (True) file vs with hours (yyyymmddhh)
  if (.not.isvar("dates_dy")) then
    dates_daily = True
  else
    if dates_dy .eq. "True" then
      dates_daily = True
    else
      dates_daily = False
    end if
  end if
  if (.not.isvar("prefix_out")) then
    prefix_out = "ERA5_AlaskaNSA-large_"
  end if
  if (.not.isvar("suffix_out")) then
    suffix_out = "_Nov-Mar_2000-2024.txt"
  end if
  if (.not.isvar("stride_input")) then ; i/j stride for skipping spatial points
    stride_in = 1
  else
    stride_in = toint(stride_input)
  end if
  ; setting for looping through hours in a single time file
  ;  Note: if the nc file only has one time per file, set hr_b = 0, hr_e = 0
  hr_b = 0
  hr_e = 23
  stride_hr = 6
  ; extract the geo from the geogrid.exe geo file (True) or using data file
  use_geo = False
  ; create lat/lon/Z_sfc output files matching that of the SOM input file
  output_latlon = True
  ; create input file of binary - extreme (1) and not extreme (0)
  if (.not.isvar("ext_set")) then
    set_ext = False
  else
    if ext_set .eq. "True" then
      set_ext = True
    else
      set_ext = False
    end if
  end if
  if (.not.isvar("ext_thres"))
    ext_thres   = 18.
  end if
  if (.not.isvar("ext_n_thres"))
    ext_n_thres   = 88.
  end if
  ; verify that there are no NaN values in output
  check_missing = True
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; retrieve the SOM domain information
  ;  -create the info resource
  info  = True
  ;  -call the procedure
  polarSOMdomain(domain, info)
  ; determine if lon should be 0 to 360 or -180 to 180
  use_lon360 = True
  if (info@use_latlon_mask).and.(info@min_lon.lt.0.).and.(info@max_lon.ge.0) then
    use_lon360 = False
  end if
  ; read the dates lists
  dateslist = ndtooned(readAsciiTable(path_dates+file_dates,1,"string",0))
  ndates = dimsizes(dateslist)
  data_min = new((/2,ndates/),float)
  data_max = new((/2,ndates/),float)
  ; loop through the dates
  do n = 0, ndates - 1
    ; set the date from the dates lists, open the input file
    if (dates_daily) then
      yyyymmdd = dateslist(n)
      yyyymm = str_get_cols(yyyymmdd,0,5)
      yyyy = str_get_cols(yyyymmdd,0,3)
      f = addfile(path_in+yyyy+"/"+prefix_in+yyyymmdd+suffix_in,"r")
      print("yyyymmdd: "+yyyymmdd)
    else
      yyyymmddhh = dateslist(n)
      yyyymm = str_get_cols(yyyymmddhh,0,5)
      yyyymmdd = str_get_cols(yyyymmddhh,0,7)
      hh = str_get_cols(yyyymmddhh,8,9)
      f = addfile(path_in+yyyymm+"/"+prefix_in+yyyymmdd+"_"+hh+suffix_in,"r")
      ;f = addfile(path_in+yyyymm+"/"+prefix_in+yyyymmddhh+suffix_in,"r")
    end if
    do h = hr_b, hr_e, stride_hr
      ; retrieve the data
      ; -check to see if it is an upper-level value
      if (var .eq. "Z925" .or. var .eq. "Z850" .or. var .eq. "Z700" .or.  \
          var .eq. "Z500" .or. var .eq. "Z300" .or. var .eq. "Z200" .or.  \
          var .eq. "T925" .or. var .eq. "T850" .or. var .eq. "T700" .or.  \
          var .eq. "T500" .or. var .eq. "T300" .or. var .eq. "T200") then
        ; -determine the variable to be plotted
        typ = str_get_cols(var,0,0)
        lvl = stringtoint(str_get_cols(var,1,3))
        ; -retrieve the pressure level
        p = f->pressure
        ; -determine the index of the pressure level
        k = ind(p .eq. lvl)
        ; -read the data, calculations, set the attributes
        if (typ .eq. "Z") then
          data = f->Z_p(h,k,:,:)
        end if
        if (typ .eq. "T") then
          data = f->T_p(h,k,:,:)-273.15
        end if
      else
        if (var .eq. "wind_10m" .or. var .eq. "sfcWind") then
          ;u = f->u_10m(h,::stride_in,::stride_in)
          ;v = f->v_10m(h,::stride_in,::stride_in)
          ;u = f->u_gr_e(h,3,::stride_in,::stride_in)
          ;v = f->v_gr_e(h,3,::stride_in,::stride_in)
          u = f->uas(h,::stride_in,::stride_in)
          v = f->vas(h,::stride_in,::stride_in)
          u@_FillValue = default_fillvalue("float")
          v@_FillValue = default_fillvalue("float")
          if (var .eq. "sfcWind") then
            data = sqrt(u^2 + v^2)
            data@_FillValue = default_fillvalue("float")
          end if 
        else
          data = f->$var$(h,::stride_in,::stride_in)
          data@_FillValue = default_fillvalue(typeof(data))
        end if
      end if
      ; retrieve the lat/lon/Z_sfc if it is the initial date
      if (n .eq. 0) then
        if (use_geo) then
          ; -open the geo file
          f_geo = addfile(path_geo+file_geo,"r")
          ; -read in the lat, lon, Z_sfc, and landmask
          lat_in = f_geo->XLAT_M(h,::stride_in,::stride_in)
          lon_in = f_geo->XLONG_M(h,::stride_in,::stride_in)
          Z_sfc_in = f_geo->HGT_M(h,::stride_in,::stride_in)
          landmask = f_geo->LANDMASK(h,::stride_in,::stride_in)
          ; -close the geo file
          delete(f_geo)
        else
          lat_in = tofloat(f->lat(::stride_in,::stride_in))
          lat_in@_FillValue = default_fillvalue("float")
          lon_in = tofloat(f->lon(::stride_in,::stride_in))
          lon_in@_FillValue = default_fillvalue("float")
          ;Z_sfc_in = f->Z_sfc
          Z_sfc_in = f->orog(::stride_in,::stride_in)
          Z_sfc_in@_FillValue = default_fillvalue("float")
        end if
        ; determine the dimensions
        dims = dimsizes(lat_in)
        n_row = dims(0)       ; row
        n_col = dims(1)       ; col
        ; create a lon for 0 to 360
        if use_lon360 then
          lon360 = where(lon_in.lt.0., lon_in+360., lon_in)
        else
          lon360 = lon_in
        end if
        ; mask by lat/lon, if selected
        if (info@use_latlon_mask) then
          latlon_mask = where((lat_in.ge.info@min_lat .and.  \
                               lat_in.le.info@max_lat .and.  \
                               lon360.ge.info@min_lon .and.  \
                               lon360.le.info@max_lon),1,0)
          lat = mask(lat_in,latlon_mask.eq.1,True)
          lon = mask(lon_in,latlon_mask.eq.1,True)
          Z_sfc = mask(Z_sfc_in,latlon_mask.eq.1,True)
        else if (info@use_ij_mask) then
          ; -define the i,j mask
          ij_mask = new((/n_row,n_col/),float)
          ij_mask = 0
          ij_mask(info@j_l:info@j_r,info@i_b:info@i_t) = 1
          ; -create the lat,lon,orog arrays
          lat  = mask(lat_in,ij_mask.eq.1,True)
          lon  = mask(lon_in,ij_mask.eq.1,True)
          Z_sfc = mask(Z_sfc_in,ij_mask.eq.1,True)
        else
          lat = lat_in
          lon = lon_in
          Z_sfc = Z_sfc_in
        end if
        end if
        ; mask by elevation, if selected
        if (info@use_elev_mask) then
          elev_mask = where((Z_sfc_in .lt. info@elev_mask_hgt),1,0)
          lat = mask(lat,elev_mask.eq.1,True)
          lon = mask(lon,elev_mask.eq.1,True)
          Z_sfc = mask(Z_sfc,elev_mask.eq.1,True)
        end if
        ; mask by land, if selected
        if (info@use_land_mask) then
          lat = mask(lat,landmask.eq.1,True)
          lon = mask(lon,landmask.eq.1,True)
          Z_sfc = mask(Z_sfc,landmask.eq.1,True)
        end if
        ; mask by ocean, if selected
        if (info@use_ocean_mask) then
          lat = mask(lat,landmask.eq.0,True)
          lon = mask(lon,landmask.eq.0,True)
          Z_sfc = mask(Z_sfc,landmask.eq.0,True)
        end if
        ; convert the 2d arrays to 1d
        lat_1d = ndtooned(lat)
        lon_1d = ndtooned(lon)
        Z_sfc_1d = ndtooned(Z_sfc)
        ; reduce the array down to only valid points in the SOM domain
        lat_out = lat_1d(ind(.not.ismissing(lat_1d)))
        lon_out = lon_1d(ind(.not.ismissing(lon_1d)))
        Z_sfc_out = Z_sfc_1d(ind(.not.ismissing(Z_sfc_1d)))
        ; determine the total number of points in each vector
        npts = dimsizes(lat_out)
        ; set the lat, lon, and Z_sfc to an array
        latlon_out = new((/3,npts/),"float")
        latlon_out(0,:) = lat_out
        latlon_out(1,:) = lon_out
        latlon_out(2,:) = Z_sfc_out
        ; create the output array
        if (var .eq. "wind_10m") then
          ; set a new number of points
          uvpts = 2*npts
          data_out = new((/ndates,uvpts/),typeof(u))
        else
          data_out = new((/ndates,npts/),typeof(data))
          if set_ext then
            dates_ext = new(ndates,string)
            n_no_ext = 0
          end if
        end if
      end if
      ; convert units, if needed
      if (var .eq. "psl") then
        data = data/100.  ; convert slp from Pa to hPa
      end if
      if (var .eq. "wind_10m") then
        ; set a new number of points
        uvpts = 2*npts
        ; mask by lat/lon, if selected
        if (info@use_latlon_mask) then
          u = mask(u,latlon_mask.eq.1,True)
          v = mask(v,latlon_mask.eq.1,True)
        end if
        ; mask by elevation, if selected
        if (info@use_elev_mask) then
          u = mask(u,elev_mask.eq.1,True)
          v = mask(v,elev_mask.eq.1,True)
        end if
        ; mask by landmask, if selected
        if (info@use_land_mask) then
          u = mask(u,landmask.eq.1,True)
          v = mask(v,landmask.eq.1,True)
        end if
        ; mask by ocean, if selected
        if (info@use_ocean_mask) then
          u = mask(u,landmask.eq.0,True)
          v = mask(v,landmask.eq.0,True)
        end if
        ; determine the total number of points in each vector
        data_pts = num(.not.(ismissing(u)))
        ; verify that the number of points is equal
        if (data_pts .ne. npts) then
          print("The number of data points does not match that of lat/lon points.")
          exit
        end if
        ; convert the 2d array to 1d
        u_1d = ndtooned(u)
        v_1d = ndtooned(v)
        ; reduce the array down to only valid points in the SOM domain
        u_som = u_1d(ind(.not.ismissing(u_1d)))
        v_som = v_1d(ind(.not.ismissing(v_1d)))
        ; calculate the anomaly, if selected
        if (calc_anom) then
          u_som = u_som - avg(u_som)
          v_som = v_som - avg(v_som)
        end if
        ; set the data to the output array
        data_out(n,0:npts-1) = u_som
        data_out(n,npts:uvpts-1) = v_som
        ; delete all variables from the processing
        delete([/u,v,data_pts,u_1d,v_1d,u_som,v_som/])   
      else
        ; mask by lat/lon, if selected
        if (info@use_latlon_mask) then
          data = mask(data,latlon_mask.eq.1,True)
        end if
        ; mask by i,j, if selected
        if (info@use_ij_mask) then
          data = mask(data,ij_mask.eq.1,True)
        end if
        ; mask by elevation, if selected
        if (info@use_elev_mask) then
          data = mask(data,elev_mask.eq.1,True)
        end if
        ; mask by landmask, if selected
        if (info@use_land_mask) then
          data = mask(data,landmask.eq.1,True)
        end if
        ; mask by ocean, if selected
        if (info@use_ocean_mask) then
          data = mask(data,landmask.eq.0,True)
        end if
        ; determine the total number of points in each vector
        data_pts = num(.not.(ismissing(data)))
        ; verify that the number of points is equal
        if (data_pts .ne. npts) then
          print("The number of data points does not match that of lat/lon points.")
          exit
        end if
        ; convert the 2d array to 1d
        data_1d = ndtooned(data)
        ; reduce the array down to only valid points in the SOM domain
        data_som = data_1d(ind(.not.ismissing(data_1d)))
        data_min(0,n) = tofloat(min(data_som))
        data_max(0,n) = tofloat(max(data_som))
        ; calculate the anomaly, if selected
        if (calc_anom) then
          data_som = data_som - avg(data_som)
          data_min(1,n) = tofloat(min(data_som))
          data_max(1,n) = tofloat(max(data_som))
        end if
        if (set_ext)
          ; set a binary flag if the sfcWind is greater than threshold
          data_ext = where(data_som .ge. ext_thres, 1, 0)
          ; count the number of extreme points
          n_ext_pts = sum(data_ext)
          if (n_ext_pts .ge. ext_n_thres) then
            ; set the data to the output array
            ; -verify that there are no missing values
            if (check_missing) then
              if (any(ismissing(data_ext))) then
                print("A missing value is in the output data at date: "+dateslist(n))
                exit
              end if
            end if
            ; greater than 1 extreme point, set to data array
            data_out(n-n_no_ext,:) = data_ext
            ; start creating a new dates array matching to exteme occurrences
            if (dates_daily) then
              dates_ext(n-n_no_ext) = yyyymmdd
            else
              dates_ext(n-n_no_ext) = yyyymmddhh
            end if
            ; delete the work     
            delete([/data_ext,n_ext_pts/])
          else
            ; no extreme points, increase counter of number of no extreme pts
            n_no_ext = n_no_ext + 1
          end if
        else
          ; set the data to the output array
          if (check_missing) then
            if (any(ismissing(data_som))) then
              print("A missing value is in the output data at date: "+dateslist(n))
              exit
            end if
          end if
          data_out(n,:) = data_som
        end if
        ; delete all variables from the processing
        delete([/data,data_pts,data_1d,data_som/])
      end if
    end do
  end do
  printVarSummary(data_out)
  print("Absolute:")
  print("  Min: "+min(data_min(0,:)))
  print("  Max: "+max(data_max(0,:)))
  if (calc_anom) then
    print("Anomaly:")
    print("  Min: "+min(data_min(1,:)))
    print("  Max: "+max(data_max(1,:)))
  end if
  ; if using set extremes, output a summary of number of dates removed
  if (set_ext)
    print("Total number of dates:        "+ndates)
    print("Number of dates w/o extremes: "+n_no_ext)
    print("Number of dates in output:    "+(ndates-n_no_ext))
  end if
  ; create the output format string
  if (var .eq. "wind_10m") then
    format_out = uvpts+"f12.4"
  else if (var .eq. "sfcWind" .and. set_ext) then
    format_out = npts+"f5.2"
  else
    format_out = npts+"f8.2"
  end if
  end if
  ; create the output file name
  file_out = prefix_out+var
  if (calc_anom) then
    file_out = file_out+"_anom"
  end if
  if (info@use_elev_mask) then
    file_out = file_out+"_"+info@elev_mask_hgt+"m"
  end if
  if (set_ext) then
    file_out = file_out+"_ext"
  end if
  file_out = file_out+suffix_out
  path_file_out = path_out+file_out
  ; create the options variable and attribute for creating the output
  opt         = True
  opt@fout    = path_file_out
  if (var .eq. "wind_10m") then
    opt@title   = uvpts+""
  else  
    opt@title   = npts+""
  end if
  if (set_ext) then
    ; create new array condensed to only the number of dates w/extremes
    data_ext_out = data_out(0:ndates-n_no_ext-1,:)
    ; create the SOM output file
    write_matrix(data_ext_out, format_out, opt)
    ; create a new dates files based on extremes
    dates_out = str_get_cols(file_dates, 0, -5)+"-ext.txt"
    asciiwrite(path_dates+dates_out,  \
               dates_ext(0:ndates-n_no_ext-1))
  else
    ; create the SOM output file
    write_matrix(data_out, format_out, opt)
  end if
  ; output the lat/lon/Z_sfc files
  if (output_latlon) then
    opt@fout    = path_out+prefix_out+"latlon"+suffix_out
    opt@title   = npts+"   line1: lat, line2: lon, line3: Z_sfc"
    ; create the SOM output file
    write_matrix(latlon_out, format_out, opt)
  end if
end
