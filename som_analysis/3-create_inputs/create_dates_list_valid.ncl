;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; create_dates_list_valid.ncl
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; -NCL script that creates a text file with a the lists of dates
;  corresponding to the data in input files for creating SOMs using 
;  the som_pak software.
; -The dates list corresponds to the input files/filenames that are
;  used in created the SOM input file.
; -This version works with valid time files, such as reanalyses, rather
;  than forecast times, such as with AMPS.
;
;  COMMAND SYNTAX:
;  -The program can be run with the defaults:
;     ncl create_dates_list_valid.ncl
;
;  INPUT:
;  -
;
;  OUTPUT:
;  -The output is a single text file.  Each line is a date or a portion of a 
;   filename matching the corresponding line in the SOM input file.
;
;  CREATOR:  Mark Seefeldt - 2014-05
;
; 
;  RELEASE NOTES:
;    1.0 - 2014-05-29 - initial release
;    1.1.0 - 2024-09-10
;          - added flag to skip months based on season
;
;  TODO:
;    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; load in the libraries
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_string.ncl"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; start the main program
begin
  ; set the output path/filename
  path_dates = "/data/khartig/alaskan_som/input_data/"
  file_dates = "ERA5-EASE25km.AlaskaNSA.2000-2024_Nov-Mar.6hr.txt"
  ; default general inputs
  yr_b = 2000
  yr_e = 2024
  mo_b = 1
  mo_e = 12
  ; set the interval for the dates: hourly, daily, monthly
  dates_int = "hourly"
  ; interval for hourly files
  hr_int = 6
  ; create a SOM file based on season or select months
  ; options: cold = JFM,OND; warm = AMJJAS; CFR_wind = JFMA,OND; nordic = JFMA,SOND
  use_season = True
  season = "novmar"
  ; set the time units 
  TimeUnits = "hours since 1900-01-01 00:00:00"
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; determine the number of datetimes in the list
  ; -initialize the counter
  n_times = 0.
  ; -loop through the years, months, days, hours
  do y = yr_b, yr_e
    do m = mo_b, mo_e
      if (use_season .and. season .eq. "cold" .and.  \
          (m .eq. 4 .or. m .eq. 5 .or. m .eq. 6 .or.  \
           m .eq. 7 .or. m .eq. 8 .or. m .eq. 9)) then
        continue
      else if (use_season .and. season .eq. "warm" .and.  \
          (m .eq. 1 .or. m .eq. 2 .or. m .eq. 3 .or.  \
           m .eq. 10 .or. m .eq. 11 .or. m .eq. 12)) then
        continue
      else if (use_season .and. season .eq. "CFR_wind" .and.  \
          (m .eq. 5 .or. m .eq. 6 .or. m .eq. 7 .or.  \
           m .eq. 8 .or. m .eq. 9)) then
        continue
      else if (use_season .and. season .eq. "nordic" .and.  \
          (m .eq. 5 .or. m .eq. 6 .or. m .eq. 7 .or. m .eq. 8)) then \
        continue
      else if (use_season .and. season .eq. "novmar" .and.  \
          (m .eq. 4 .or. m .eq. 5 .or. m .eq. 6 .or. \
           m .eq. 7 .or. m .eq. 8 .or. m .eq. 9 .or. m .eq. 10)) then \
        continue
      end if
      end if
      end if
      end if
      end if
      if dates_int .eq. "monthly" then
        n_times = n_times + 1
      else if dates_int .eq. "daily" then
        n_times = n_times + days_in_month(y, m)
      else if dates_int .eq. "hourly" then
        n_times = n_times + (days_in_month(y, m))*(24/hr_int)
      end if
      end if
      end if
    end do  
  end do
  ;else
  ;  n_days = greg2jul(yr_e,mo_e,dy_e,0)-greg2jul(yr_b,mo_b,dy_b,0)+1
  ;end if
  print("n_times: "+n_times)
  ; determine the number of times based days, and hours if selected
  ;if (dates_int .eq. "daily") then
  ;  n_times = n_days
  ;else if (dates_int .eq. "hourly") then
  ;  n_times = n_days*(24/hr_int)
  ;end if
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; create the dateslist array
  dateslist = new(toint(n_times),string)
  ; initiate the counters
  n = 0
  ; loop through the years, months, days, hours
  do y = yr_b, yr_e
    do m = mo_b, mo_e
      if (use_season .and. season .eq. "cold" .and.  \
          (m .eq. 4 .or. m .eq. 5 .or. m .eq. 6 .or.  \
           m .eq. 7 .or. m .eq. 8 .or. m .eq. 9)) then
        continue
      else if (use_season .and. season .eq. "warm" .and.  \
          (m .eq. 1 .or. m .eq. 2 .or. m .eq. 3 .or.  \
           m .eq. 10 .or. m .eq. 11 .or. m .eq. 12)) then
        continue
      else if (use_season .and. season .eq. "CFR_wind" .and.  \
          (m .eq. 5 .or. m .eq. 6 .or. m .eq. 7 .or.  \
           m .eq. 8 .or. m .eq. 9)) then
        continue
      else if (use_season .and. season .eq. "nordic" .and.  \
          (m .eq. 5 .or. m .eq. 6 .or. m .eq. 7 .or. m .eq. 8)) then \
        continue
      else if (use_season .and. season .eq. "novmar" .and.  \
          (m .eq. 4 .or. m .eq. 5 .or. m .eq. 6 .or. \
           m .eq. 7 .or. m .eq. 8 .or. m .eq. 9 .or. m .eq. 10)) then \
        continue
      end if
      end if
      end if
      end if
      end if
      if dates_int .eq. "monthly" then
        ; set the array
        dateslist(n) = sprinti("%04d",y)+sprinti("%02d",m)
        ; increase the counter
        n = n + 1   
      else if (dates_int .eq. "daily" .or. dates_int .eq. "hourly") then
        do d = 1, days_in_month(y, m)
          if (dates_int .eq. "daily") then
              ; set the value and attributes for the time
              time = cd_inv_calendar(y, m, d, 0, 0, 0, TimeUnits, 0)
              ; create a values for yyyymmdd
              yyyymmdd = cd_string(time, "%Y%N%D")
              ; set the array
              dateslist(n) = yyyymmdd
              ; increase the counter
              n = n + 1   
          else if (dates_int .eq. "hourly") then
            do h = 0, 23, hr_int
              ; set the value and attributes for the time
              time = cd_inv_calendar(y, m, d, h, 0, 0, TimeUnits, 0)
              ; create a values for yyyymmddhh
              yyyymmddhh = cd_string(time, "%Y%N%D%H")
              dateslist(n) = yyyymmddhh
              ; increase the counter
              n = n + 1
            end do
          end if
          end if
        end do
      end if
      end if
    end do  
  end do
  ; write out the dateslist file
  asciiwrite(path_dates+file_dates, dateslist)
  print(path_dates+file_dates) ; KARA
end