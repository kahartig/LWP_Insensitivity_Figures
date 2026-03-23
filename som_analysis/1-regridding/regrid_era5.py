######################################################################
# regrid_era5.py
######################################################################
# -Python script for the regridding of ERA5 reanalysis files to a 
#  specified domain, typically by WRF
#
#  NOTES:
#    -uses the TOML file: regrid_era5_settings.toml
#
#  INPUT:
#    -ERA5 reanalysis files
#    -destination lat/lon domain, typically a geo_em.d01.nc file
#
#  OUTPUT:
#    -regridded netCDF file with ERA5 data on a specified domain
#
#  CREATOR:  Mark Seefeldt - 2023-08
#
#  RELEASE NOTES:
#    1.0 - 2024-04-28 (initial release)
#    1.1 - 2024-07-18
#        -add capacity for regridding pressure-level data
#    1.1.1 - 2025-01-20
#        -fix bugs and improve processing of pressure-level data
#        -fix additional bugs and tweaks that have been discovered
#    1.2 - 2025-03-08
#        -overhaul the ordering of the code to work with coords and dims
#        -overhaul the coding to handle hr and mo data in the same sequencing
#        -add handling of hourly data
#        -added working with EASE grids, and no regridding but extract a lat,lon slice
#        -added the ability to use compressin in creating the nc file
#
ver_txt = 'v1.2'  # code version, to be included as a global attribute
######################################################################
#  TODO:
#
#   -figure out setting dims for pressure-level from 'level' to 'plev' or 'pressure'
#   -are more coords than lat and lon to be specified, should time and pressure
#    also be specified?
#   -figure out the correct way to handle NaN values and _FillValue with the nc
#    nc file and in using the python or NCL
#   -add unit conversion check between ERA5 data and flds_gen_info units
#   -add unit conversion to units_alt
#
######################################################################
# load in the python modules
import os
import sys
import calendar
import datetime as dt
from dateutil.relativedelta import relativedelta
import tomllib
import numpy as np
import pandas as pd
import xarray as xr
import xesmf as xe
from cftime import date2num
import metpy.calc as mpcalc
import metpy.units as mpunits
#from matplotlib.dates import DateFormatter
import netCDF4 as nc
#from pprint import pprint
######################################################################
######################################################################
# set the toml file names either from command line or default value
if len(sys.argv) == 1:
  f_toml = 'regrid_era5_run.toml'
  print('No toml file specified, settings read from file: '+f_toml)
  override_dates = False
elif len(sys.argv) == 2:
  f_toml = sys.argv[1]
  override_dates = False
elif len(sys.argv) == 6:
  f_toml = sys.argv[1]
  yr_b = int(sys.argv[2])
  mo_b = int(sys.argv[3])
  dy_b = 1
  yr_e = int(sys.argv[4])
  mo_e = int(sys.argv[5])
  dy_e = calendar.monthrange(yr_e,mo_e)[1]
  override_dates = True
elif len(sys.argv) == 8:
  f_toml = sys.argv[1]
  yr_b = int(sys.argv[2])
  mo_b = int(sys.argv[3])
  dy_b = int(sys.argv[4])
  yr_e = int(sys.argv[5])
  mo_e = int(sys.argv[6])
  dy_e = int(sys.argv[7])
  override_dates = True
else:
  print ('Command line options: ')
  print ('  file.toml')
  print ('  file.toml yr_b mo_b yr_e mo_e')
  print ('  file.toml yr_b mo_b dy_b yr_e mo_e dy_e')
  exit()
# load the configuration details for fields - general
print(f_toml)
with open(f_toml, 'rb') as f_config:
  config_in: dict = tomllib.load(f_config)
config = config_in['settings']
# settings for regridding
# -set the computer system being used - options: casper, haboob
system = config['system']
# -set the beginning and ending year, month, day
dt_b = config['dt_beg']  # beginning date and time
dt_e = config['dt_end']  # ending date and time
if override_dates:
  dt_b = f'{yr_b}-{mo_b}-{dy_b}'
  dt_e = f'{yr_e}-{mo_e}-{dy_e}'
  print('toml file dates being overwritten to: {dt_b} to {dt_e}')
# -set the time resolution of ERA5 data
e5_time = config['time_int']
hourly_int = config['hourly_int']
# -create an array of the pressure levels to be used
plev           = np.array(config['plev'], dtype=float)
#plev         = config['plev']
# -domain regridding info - something needs to be provided, even if using latlon
dom_name       = config['dom_name']
dom_name_txt   = config['dom_name_txt']
dom_type       = config['dom_type']
file_dom       = config['dom_file']
# -lat/lon ranges - something needs to be provided, even if regridding and not using
lat_rng        = config['lat_rng']
lon_rng        = config['lon_rng']
lon_360_to_180 = config['lon_360_to_180']
# -paths for input/output - based on the selected system
path_dom       = config[system]['path_dom']
path_in        = config[system]['path_e5']
path_out       = config[system]['path_out']+'/'+dom_name
file_pre       = config['file_pre']
nc_compression = config['nc_compression']
# create the prefix for the output filenames
file_out_pre = file_pre+dom_name+'-'
# read the dict of flags for the available fields
flds_fl = config_in['flds_fl']
# additional settings not yet included in the toml file
cftime_units = 'hours since 1900-01-01 00:00:00'
cftime_cal = 'standard'
######################################################################
# -load the configuration details for fields - general
with open('flds_gen_info.toml', 'rb') as f_gen:
  flds_gen_info: dict = tomllib.load(f_gen)
flds_gen = flds_gen_info['flds']
# -set the subdirectory and daterange for the time resolution
#  -load the configuration details for fields - ERA5
if e5_time == 'hr':
  path_out = path_out+'/hourly'
  daterange = pd.date_range(dt_b, dt_e, freq='D')
  path_ds = 'd633000'
  with open('info_ds633.0.toml', 'rb') as f_e5:
    info_e5: dict = tomllib.load(f_e5)
elif e5_time == 'mo':
  path_out = path_out+'/monthly'
  daterange = pd.date_range(dt_b, dt_e, freq='MS')
  path_ds = 'd633001'
  with open('info_ds633.1.toml', 'rb') as f_e5:
    info_e5: dict = tomllib.load(f_e5)
# create an array of ERA5 fields
flds_e5 = info_e5['flds']
######################################################################
# create regridding files - dependent on regridding selection
if dom_type == 'wrf_geo':
  # load the lat, lon fields for the destination domain
  path_file_dom = path_dom+'/'+file_dom
  # open the data source for the domain
  # Note: decode_timedelta can be removed in a future version of xarray
  ds_dom = xr.open_dataset(path_file_dom, decode_timedelta=False)
  # create an xr DataArray from the domain file with specified coordinates, and lat, lon arrays
  regrid_dom  = xr.DataArray(ds_dom.LANDMASK.isel(Time=0).values, dims=['south_north','west_east'], 
                             coords = {"lat":(('south_north','west_east'),
                                              ds_dom.CLAT.isel(Time=0).values),
                                       "lon":(('south_north','west_east'),
                                              ds_dom.CLONG.isel(Time=0).values)})
  da_lat = xr.DataArray(ds_dom.CLAT.isel(Time=0).values, dims=['south_north','west_east'],
                        attrs = {'standard_name':'latitude',
                                 'long_name':'Latitude',
                                 'units':'degrees_north'})
  #da_lat.drop_attrs('_FillValue')
  #del da_lat.attrs['_FillValue']
  da_lon = xr.DataArray(ds_dom.CLONG.isel(Time=0).values, dims=['south_north','west_east'],
                        attrs = {'standard_name':'longitude',
                                 'long_name':'Longitude',
                                 'units':'degrees_east'})
  #del da_lon.attrs['_FillValue']
elif dom_type == 'EASE':
  # load the lat, lon fields for the destination domain
  path_file_dom = path_dom+'/'+file_dom
  # open the data source for the domain
  ds_dom = xr.open_dataset(path_file_dom)
  #print(ds_dom)
  # create an xr DataArray from the domain file with specified coordinates, and lat, lon arrays
  row = ds_dom['row']
  col = ds_dom['col']
  ds_dom['lat2d'].assign_attrs({'_FillValue': -999.})
  print(ds_dom['lat2d'])
  print(ds_dom['lat2d'].values)
  regrid_dom  = xr.DataArray(np.zeros((len(row),len(col))), dims=['row','col'], 
                             coords = {"lat":(('row','col'),ds_dom.lat2d.values),
                                       "lon":(('row','col'),ds_dom.lon2d.values)})
  print(regrid_dom)
  da_lat = xr.DataArray(ds_dom.lat2d.values, dims=['row','col'],
                        attrs = {'standard_name':'latitude',
                                 'long_name':'Latitude',
                                 'units':'degrees_north',
                                 '_FillValue': -999.99})
  da_lon = xr.DataArray(ds_dom.lon2d.values, dims=['row','col'],
                        attrs = {'standard_name':'longitude',
                                 'long_name':'Longitude',
                                 'units':'degrees_east',
                                 '_FillValue': -999.99})
elif dom_type == 'EASE2':
  # load the lat, lon fields for the destination domain
  path_file_dom = path_dom+'/'+file_dom
  # open the data source for the domain
  ds_dom = xr.open_dataset(path_file_dom)
  print(ds_dom)
  # create an xr DataArray from the domain file with specified coordinates, and lat, lon arrays
  y = ds_dom['y']
  x = ds_dom['x']
  print(ds_dom['latitude'].values)
  regrid_dom  = xr.DataArray(np.zeros((len(y),len(x))), dims=['south_north','west_east'], 
                             coords = {"lat":(('south_north','west_east'),ds_dom.latitude.values),
                                       "lon":(('south_north','west_east'),ds_dom.longitude.values)})
  print(regrid_dom)
  da_lat = xr.DataArray(ds_dom.latitude.values, dims=['south_north','west_east'],
                        attrs = {'standard_name':'latitude',
                                 'long_name':'Latitude',
                                 'units':'degrees_north',
                                 '_FillValue': -999})
  da_lon = xr.DataArray(ds_dom.longitude.values, dims=['south_north','west_east'],
                        attrs = {'standard_name':'longitude',
                                 'long_name':'Longitude',
                                 'units':'degrees_east',
                                 '_FillValue': -999})
# regrid the invariant date, including creating the mapping file from e5 to destination
# -create the path and file names - read invariant data from d633000 directory
path_file_orog   = path_in+'/d633000/'+flds_e5['orog']['prefix']+'/197901/'+  \
                flds_e5['orog']['prefix']+'.'+flds_e5['orog']['long']+  \
                '.ll025sc.1979010100_1979010100.nc'
path_file_sftlf  = path_in+'/d633000/'+flds_e5['sftlf']['prefix']+'/197901/'+  \
                flds_e5['sftlf']['prefix']+'.'+flds_e5['sftlf']['long']+  \
                '.ll025sc.1979010100_1979010100.nc'
# read the E5 xarray dataset
ds_orog  = xr.open_dataset(path_file_orog)
ds_sftlf = xr.open_dataset(path_file_sftlf)
# rename the lat/lon coordinates to the expected values
ds_orog  = ds_orog.rename({"longitude": "lon", "latitude": "lat"})
ds_sftlf = ds_sftlf.rename({"longitude": "lon", "latitude": "lat"})
if dom_type == 'latlon':
  # reverse the latitude array and index
  ds_orog=ds_orog.reindex(lat=list(reversed(ds_orog['lat'])))
  ds_sftlf=ds_sftlf.reindex(lat=list(reversed(ds_orog['lat'])))
  # convert longitude to -180 to 180, if selected
  if lon_360_to_180:
    ds_orog = ds_orog.assign_coords(lon=(((ds_orog.lon + 180) % 360) - 180))
    ds_orog = ds_orog.roll(lon=int(len(ds_orog['lon']) / 2), roll_coords=True)
    ds_sftlf = ds_sftlf.assign_coords(lon=(((ds_sftlf.lon + 180) % 360) - 180))
    ds_sftlf = ds_sftlf.roll(lon=int(len(ds_sftlf['lon']) / 2), roll_coords=True)
  # create the lat, lon data arrays from the orog ERA5 file
  da_lat = xr.DataArray(ds_orog['lat'].values, dims=['lat'],
                        coords = {'lat':ds_orog['lat'].values},
                        attrs = {'standard_name':'latitude',
                                 'long_name':'Latitude',
                                 'units':'degrees_north'})
  da_lon = xr.DataArray(ds_orog['lon'].values, dims=['lon'],
                        coords = {'lon':ds_orog['lon'].values},
                        attrs = {'standard_name':'longitude',
                                 'long_name':'Longitude',
                                 'units':'degrees_east'})
  # create the orog and sftlf data array by selecting lat, lon bounds
  da_orog = xr.DataArray(ds_orog[flds_e5['orog']['shrt']][0,:,:].drop_vars('time').values,
                         name = 'orog', dims=['lat','lon'],
                         coords = {'lat':da_lat.data,
                                   'lon':da_lon.data})
  #da_orog  = ds_orog[flds_e5['orog']['shrt']][0,:,:].drop_vars('time')
  da_sftlf = xr.DataArray(ds_sftlf[flds_e5['sftlf']['shrt']][0,:,:].drop_vars('time').values,
                          name = 'sftlf', dims=['lat','lon'],
                          coords = {'lat':da_lat.data,
                                    'lon':da_lon.data})
  #da_sftlf = ds_sftlf[flds_e5['sftlf']['shrt']][0,:,:].drop_vars('time')
  da_lat = da_lat.sel(lat=slice(lat_rng[0],lat_rng[1]))
  da_lon = da_lon.sel(lon=slice(lon_rng[0],lon_rng[1]))
  da_orog  = da_orog.sel(lat=slice(lat_rng[0],lat_rng[1]), lon=slice(lon_rng[0],lon_rng[1]))
  da_sftlf = da_sftlf.sel(lat=slice(lat_rng[0],lat_rng[1]), lon=slice(lon_rng[0],lon_rng[1]))
  #print(da_orog)
else:
  # set the data to be regridded
  da_orog = ds_orog[flds_e5['orog']['shrt']]
  # create the mapping file from the e5 domain to the destination domain, if not done yet
  regridder = xe.Regridder(da_orog, regrid_dom, "bilinear", periodic=True)
  # regrid the e5 data to the destination domain; remove the time dim and coord for invariant data
  da_orog = regridder(da_orog)[0,:,:].drop_vars('time')
  da_orog.name = 'orog'
  # regrid the landmask data
  da_sftlf = ds_sftlf[flds_e5['sftlf']['shrt']]
  # regrid the e5 data to the destination domain; remove the time dim and coord for invariant data
  da_sftlf = regridder(da_sftlf)[0,:,:].drop_vars('time')
  da_sftlf.name = 'sftlf'
print(f"  orog     | units - src: {ds_orog[flds_e5['orog']['shrt']].attrs['units']:12}  \
        dst: {flds_gen['orog']['units']:12}")
# convert geopotential to geopotential height
da_orog = da_orog/9.80665  # Earth's graviational acceleration for ERA5
# initial versions of this script had questions w/ _FillValues set, deliberate alternative
da_orog.fillna(nc.default_fillvals['f4'])
da_orog.attrs = {'standard_name': flds_gen['orog']['standard_name'],
                'long_name': flds_gen['orog']['long_name'],
                'units': flds_gen['orog']['units'],
                '_FillValue': nc.default_fillvals['f4']}
print(f"  sftlf    | units - src: {ds_sftlf[flds_e5['sftlf']['shrt']].attrs['units']:12}  \
        dst: {flds_gen['sftlf']['units']:12}")
# initial versions of this script had questions w/ _FillValues set, deliberate alternative
da_sftlf.fillna(nc.default_fillvals['f4'])
da_sftlf.attrs = {'standard_name': flds_gen['sftlf']['standard_name'],
                  'long_name': flds_gen['sftlf']['long_name'],
                  'units': flds_gen['sftlf']['units'],
                  '_FillValue': nc.default_fillvals['f4']}
del(ds_orog,ds_sftlf)
######################################################################
# determine if need to create a pres field and dimension
# Note: there is likley a function to do this but needed to push forward
plev_init = False
for fld in flds_e5:
  if flds_fl[fld] and (flds_e5[fld]['prefix'] == 'e5.moda.an.pl' or
                             flds_e5[fld]['prefix'] == 'e5.oper.an.pl'):
    plev_init = True
# if there is a pl field, create pressure data array
if plev_init:
  da_pres = xr.DataArray(plev, name='pressure', dims=['pressure'],
                         coords = {'pressure':plev},
                         attrs = {'standard_name':'air_pressure',
                                  'long_name':'Pressure Level',
                                  'units':'hPa',
                                  'positive':'down'})
  # delete _FillValue attribute as pres is a dimension
  #del da_pres.attrs['positive'] # correct syntax for 'positive'
  #da_pres.drop_attrs(['_FillValue'])
######################################################################
# loop through the range of dates
for single_date in daterange:
  print(single_date)
  yyyy = single_date.strftime("%Y")
  yyyymm = single_date.strftime("%Y%m")
  yyyymmdd = single_date.strftime("%Y%m%d")
  dd_b = '01'
  dd_e = str(single_date.days_in_month)
  date_prev_mo = single_date + relativedelta(months=-1)
  yyyymm_prev = date_prev_mo.strftime("%Y%m")
  date_next_mo = single_date + relativedelta(months=+1)
  yyyymm_next = date_next_mo.strftime("%Y%m")
  # different set of processing depending on hourly or monthly files
  if e5_time == 'hr':
    # source info for global attributes
    source_info = 'ERA5 data files from: https://rda.ucar.edu/datasets/d633000/'
    # create the file out name
    file_out = file_out_pre+yyyymmdd+'.nc'
    # create a range of hours for the selected day
    dyhr_b = dt.datetime(single_date.year, single_date.month, single_date.day, 0)
    dyhr_e = dt.datetime(single_date.year, single_date.month, single_date.day, 23)
    # Note: the selected hours can be change to say 3 hours with freq='3h'
    hourrange = pd.date_range(dyhr_b, dyhr_e, freq=hourly_int)
    # Note: an array pd.date_range crashes cftime.date2num, it works with xr.cftime_range
    hourrange_cf = xr.cftime_range(dyhr_b, dyhr_e, freq=hourly_int, calendar='standard')
    # create an array of CF datetimes
    time_cf = date2num(hourrange_cf, cftime_units, cftime_cal)
    # create the da_time data array in CFtime with attributes
    da_time = xr.DataArray(time_cf, name='time', dims=['time'],
                            coords = {'time':time_cf},
                            attrs = {'standard_name':'time',
                                     'long_name':'Time',
                                     'units':cftime_units,
                                     'calendar':cftime_cal})
  elif e5_time == 'mo':
    # source info for global attributes
    source_info = 'ERA5 data files from: https://rda.ucar.edu/datasets/d633001/'
    # create the file out name
    file_out = file_out_pre+yyyymm+'.nc'
    # create an array of CF datetimes
    time_cf = date2num(single_date, cftime_units, cftime_cal)
    #print(time1)
    #time_cf = [time1]
    #print(time_cf)
    # create the da_time data array in CFtime with attributes
    da_time = xr.DataArray([time_cf], name='time', dims=['time'],
                            coords = {'time':[time_cf]},
                            attrs = {'standard_name':'time',
                                    'long_name':'Time',
                                    'units':cftime_units,
                                    'calendar':cftime_cal})
  # create the initial dataset
  if plev_init:
    ds = xr.Dataset(data_vars={'time':da_time, 'lat':da_lat, 'lon':da_lon, 'pressure':da_pres, 
                                'orog':da_orog, 'sftlf':da_sftlf})
  else:
    ds = xr.Dataset(data_vars={'time':da_time, 'lat':da_lat, 'lon':da_lon, 
                                'orog':da_orog, 'sftlf':da_sftlf})
  # loop through the fields
  for fld in flds_e5:
    if flds_fl[fld]:
      if flds_e5[fld]['prefix'] == 'e5.oper.an.pl':
        # create the path and filename for the data file
        if (fld == 'ua' or fld == 'va'):
          file_in = flds_e5[fld]['prefix']+'.'+flds_e5[fld]['long']+'.ll025uv.'+  \
                    yyyymmdd+'00_'+yyyymmdd+'23.nc'
        else:
          file_in = flds_e5[fld]['prefix']+'.'+flds_e5[fld]['long']+'.ll025sc.'+  \
                    yyyymmdd+'00_'+yyyymmdd+'23.nc'
        path_file_in  = path_in+'/'+path_ds+'/'+flds_e5[fld]['prefix']+'/'+yyyymm+'/'+file_in
        # read the E5 xarray dataset
        ds_e5 = xr.open_dataset(path_file_in)
        # rename the lat/lon coordinates to the expected values
        ds_e5 = ds_e5.rename({"longitude": "lon", "latitude": "lat"})
        # retrieve the data array
        da_e5 = ds_e5[flds_e5[fld]['shrt']].sel(time=hourrange).sel(level=plev)
      elif flds_e5[fld]['prefix'] == 'e5.oper.an.sfc':
        # create the path and filename for the data file
        file_in = flds_e5[fld]['prefix']+'.'+flds_e5[fld]['long']+'.ll025sc.'+  \
                  yyyymm+dd_b+'00_'+yyyymm+dd_e+'23.nc'
        path_file_in  = path_in+'/'+path_ds+'/'+flds_e5[fld]['prefix']+'/'+yyyymm+'/'+file_in
        # read the E5 xarray dataset
        ds_e5 = xr.open_dataset(path_file_in)
        # rename the lat/lon coordinates to the expected values
        ds_e5 = ds_e5.rename({"longitude": "lon", "latitude": "lat"})
        # retrieve the data array
        da_e5 = ds_e5[flds_e5[fld]['shrt']].sel(time=hourrange)
      elif (flds_e5[fld]['prefix'] == 'e5.oper.fc.sfc.meanflux' or
            flds_e5[fld]['prefix'] == 'e5.oper.fc.sfc.instan'):
        # create the path and filename for the data file - dependent on day
        # -next read the E5 xrray dataset
        if single_date.day == 1:
          file_in1 = flds_e5[fld]['prefix']+'.'+flds_e5[fld]['long']+'.ll025sc.'+  \
                    yyyymm_prev+'1606_'+yyyymm+'0106.nc'
          path_file_in1  = path_in+'/'+path_ds+'/'+flds_e5[fld]['prefix']+'/'+yyyymm_prev+'/'+file_in1
          file_in2 = flds_e5[fld]['prefix']+'.'+flds_e5[fld]['long']+'.ll025sc.'+  \
                    yyyymm+'0106_'+yyyymm+'1606.nc'
          path_file_in2  = path_in+'/'+path_ds+'/'+flds_e5[fld]['prefix']+'/'+yyyymm+'/'+file_in2
          ds_e5 = xr.open_mfdataset([path_file_in1, path_file_in2])
        elif single_date.day > 1 and single_date.day <= 15:
          file_in = flds_e5[fld]['prefix']+'.'+flds_e5[fld]['long']+'.ll025sc.'+  \
                    yyyymm+'0106_'+yyyymm+'1606.nc'
          path_file_in  = path_in+'/'+path_ds+'/'+flds_e5[fld]['prefix']+'/'+yyyymm+'/'+file_in
          ds_e5 = xr.open_dataset(path_file_in)
        elif single_date.day == 16:
          file_in1 = flds_e5[fld]['prefix']+'.'+flds_e5[fld]['long']+'.ll025sc.'+  \
                    yyyymm+'0106_'+yyyymm+'1606.nc'
          path_file_in1  = path_in+'/'+path_ds+'/'+flds_e5[fld]['prefix']+'/'+yyyymm+'/'+file_in1
          file_in2 = flds_e5[fld]['prefix']+'.'+flds_e5[fld]['long']+'.ll025sc.'+  \
                    yyyymm+'1606_'+yyyymm_next+'0106.nc'
          path_file_in2  = path_in+'/'+path_ds+'/'+flds_e5[fld]['prefix']+'/'+yyyymm+'/'+file_in2
          ds_e5 = xr.open_mfdataset([path_file_in1, path_file_in2])
        elif single_date.day > 16:
          file_in = flds_e5[fld]['prefix']+'.'+flds_e5[fld]['long']+'.ll025sc.'+  \
                    yyyymm+'1606_'+yyyymm_next+'0106.nc'
          path_file_in  = path_in+'/'+path_ds+'/'+flds_e5[fld]['prefix']+'/'+yyyymm+'/'+file_in
          ds_e5 = xr.open_dataset(path_file_in)
          # read the E5 xarray dataset
          ds_e5 = xr.open_dataset(path_file_in)
        # rename the lat/lon coordinates to the expected values
        ds_e5 = ds_e5.rename({"longitude": "lon", "latitude": "lat"})
        # stack the dataset to a new dim that is a combo of forecast_initial_time and forecast_hour
        ds_e5 = ds_e5.stack(fcst_combo=("forecast_initial_time", "forecast_hour"))
        # create a new time variable that is the sum of forecast_initial_time and forecast_hour
        time_new = ds_e5['forecast_initial_time'].values +  \
                   pd.to_timedelta(ds_e5['forecast_hour'], unit='h')
        # Note: the ds_e5 indexes, dims, and coords messed with me, could only create new array
        # create a new data array with clean dims, coords, and attrs
        da_tmp = xr.DataArray(ds_e5[flds_e5[fld]['shrt']].values, name = flds_e5[fld]['shrt'],
                              dims=['lat','lon','time'],
                              coords = {'time':time_new,
                                        'lat':ds_e5['lat'],
                                        'lon':ds_e5['lon']},
                              attrs = {'short_name':ds_e5[flds_e5[fld]['shrt']].attrs['short_name'],
                                       'long_name':ds_e5[flds_e5[fld]['shrt']].attrs['long_name'],
                                       'units':ds_e5[flds_e5[fld]['shrt']].attrs['units']})
        # re-order the dims and select the hours matching hourrange
        da_e5 = da_tmp.transpose('time','lat','lon').sel(time=hourrange)
        # delete the work
        del da_tmp
        #print(da_e5)
        #print(da_e5['time'].to_pandas().to_string())
      elif (flds_e5[fld]['prefix'] == 'e5.moda.an.pl' or
            flds_e5[fld]['prefix'] == 'e5.moda.an.sfc' or
            flds_e5[fld]['prefix'] == 'e5.moda.fc.sfc.meanflux' or
            flds_e5[fld]['prefix'] == 'e5.moda.fc.sfc.instan'):
        # create the path and filename for the data file
        if (fld == 'ua' or fld == 'va'):
          file_in = flds_e5[fld]['prefix']+'.'+flds_e5[fld]['long']+'.ll025uv.'+  \
                    yyyy+'010100_'+yyyy+'120100.nc'
        else:
          file_in = flds_e5[fld]['prefix']+'.'+flds_e5[fld]['long']+'.ll025sc.'+  \
                    yyyy+'010100_'+yyyy+'120100.nc'
        path_file_in  = path_in+'/'+path_ds+'/'+flds_e5[fld]['prefix']+'/'+yyyy+'/'+file_in
        # read the E5 xarray dataset
        ds_e5 = xr.open_dataset(path_file_in)
        # rename the lat/lon coordinates to the expected values
        ds_e5 = ds_e5.rename({"longitude": "lon", "latitude": "lat"})
        # retrieve the data array
        da_e5 = ds_e5[flds_e5[fld]['shrt']].sel(time=single_date.strftime("%Y-%m"))
        # check if plev processing, if so select pressure levels
        if flds_e5[fld]['prefix'] == 'e5.moda.an.pl':
          da_e5 = da_e5.sel(level=plev)
      # continue the processing for all data types
      # review and modify units if needed
      print(f"  {fld:8} | units - src: {da_e5.attrs['units']:12}dst: {flds_gen[fld]['units']:12}")
      if fld == 'zg':  # convert geopotential to geopotential height
        da_e5 = da_e5/9.80665  # Earth's graviational acceleration for ERA5
        da_e5.attrs = {'units':'m'}
      elif da_e5.attrs['units'] == 'm s**-1':  # rename units for speed
        da_e5.attrs = {'units':'m s-1'}
      elif da_e5.attrs['units'] == 'kg kg**-1':  # rename units humidity
        da_e5.attrs = {'units':'kg kg-1'}
      elif da_e5.attrs['units'] == 'W m**-2':  # rename units for fluxes
        da_e5.attrs = {'units':'W m-2'}
      elif da_e5.attrs['units'] == 'kg m**-2':  # rename units for mass conc
        da_e5.attrs = {'units':'kg m-2'}
      elif da_e5.attrs['units'] == 'kg m**-2 s**-1':  # rename units for mass fluxes
        da_e5.attrs = {'units':'kg m-2 s-1'}
      elif da_e5.attrs['units'] == 'N m**-2':  # rename units for stress
        da_e5.attrs = {'units':'N m-2'}
      # read the units
      units_e5 = da_e5.attrs['units']
      if dom_type == 'latlon':
        # reverse the latitude array and index
        da_e5=da_e5.reindex(lat=list(reversed(ds_e5['lat'])))
        # convert longitude to -180 to 180, if selected
        if lon_360_to_180:
          da_e5 = da_e5.assign_coords(lon=(((ds_e5.lon + 180) % 360) - 180))
          da_e5 = da_e5.roll(lon=int(len(ds_e5['lon']) / 2), roll_coords=True)
        # extract the data from the lat,lon slice
        da_regrid = da_e5.sel(lat=slice(lat_rng[0],lat_rng[1]), lon=slice(lon_rng[0],lon_rng[1]))
        # create the data array for the field
        if (flds_e5[fld]['prefix'] == 'e5.moda.an.pl' or
            flds_e5[fld]['prefix'] == 'e5.oper.an.pl'):
          da_fld = xr.DataArray(da_regrid.values, name = fld,
                                dims=['time','pressure','lat','lon'],
                                coords = {'lat':da_lat.data,
                                          'lon':da_lon.data})
        else:
          da_fld = xr.DataArray(da_regrid.values, name = fld,
                                dims=['time','lat','lon'],
                                coords = {'lat':da_lat.data,
                                          'lon':da_lon.data})
        #print(da_fld)
      else:
        # regrid the e5 data to the destination domain
        da_regrid = regridder(da_e5)
        # create the data array for the field
        if (flds_e5[fld]['prefix'] == 'e5.moda.an.pl' or
            flds_e5[fld]['prefix'] == 'e5.oper.an.pl'):
          da_fld = xr.DataArray(da_regrid.values, name = fld,
                                dims=['time','pressure','south_north','west_east'],
                                coords = {'lat':(('south_north','west_east'),da_lat.data),
                                          'lon':(('south_north','west_east'),da_lon.data)})
        else:
          da_fld = xr.DataArray(da_regrid.values, name = fld,
                                dims=['time','south_north','west_east'],
                                coords = {'lat':(('south_north','west_east'),da_lat.data),
                                          'lon':(('south_north','west_east'),da_lon.data)})
      # initial versions of this script had questions w/ _FillValues set, deliberate alternative
      da_fld.fillna(nc.default_fillvals['f4'])
      # set the attributes
      if (flds_e5[fld]['prefix'] == 'e5.moda.fc.sfc.meanflux' or
          flds_e5[fld]['prefix'] == 'e5.oper.fc.sfc.meanflux'):
        da_fld.attrs = {'standard_name': flds_gen[fld]['standard_name'],
                        'long_name': 'Mean '+flds_gen[fld]['long_name'],
                        'units':  units_e5,
                        '_FillValue':nc.default_fillvals['f4']}
      else:
        da_fld.attrs = {'standard_name': flds_gen[fld]['standard_name'],
                        'long_name': flds_gen[fld]['long_name'],
                        'units': units_e5,
                        '_FillValue':nc.default_fillvals['f4']}
      # merge the data array to the dataset
      ds = xr.merge([ds, da_fld])
      # delete the variables used in the regridding
      del ds_e5, da_e5, da_fld
  # add the global attributes to the xarray dataset, to be written to nc file
  ds.attrs = {'Conventions': "CF-1.12, Standard Name Table v84",
              'institution': "University of Colorado Boulder - CIRES",
              'created_by': "Mark Seefeldt - mark.seefeldt@colorado.edu",
              'history': "Created with python script: regrid_era5.py "+ver_txt,
              'comment': "Regridded using xESMF to the "+dom_name_txt+" grid",
              'source': source_info,
              'title': file_out,
              'creation_date': dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC"),
              }
  # write the data to a netCDF file
  path_out_yr = path_out + '/' + single_date.strftime("%Y")
  os.makedirs(path_out_yr, exist_ok=True)
  path_file_out = path_out_yr+'/'+file_out
  print(  '  file: '+path_file_out)
  if nc_compression:
    comp = {'zlib':True, 'complevel':5}
    encoding = {var: comp for var in ds.data_vars}
    ds.to_netcdf(path_file_out, unlimited_dims='time', encoding=encoding)
  else:
    ds.to_netcdf(path_file_out, unlimited_dims='time')
  del ds
  

  # Questions:
    # -add a units conversion from e5 to flds_gen_info.toml units or units_alt
    # -can't figure out a way to delete attribute: _FillValue for lat, lon, pressure
    #   see da_pres above as an example - this might be something that xarray adds
    #   automatically when writing the nc file
    # -If doing multi-hour intervals, it might even work to take the means of multiple
    #   hours something like:
    #   sel(time=slice('2001-01-01','2018-01-01')).groupby('time.month').mean('time')
    # -are the lat lon variables supposed to have coordinates of lon, lat? - ans.: no
    #  Based on CF sec. 5.2 - and the example given there, lon, lat do not include coords
