#!/usr/bin/env python
# coding: utf-8
# Intake all datasets for NSA, perform QC checks, align with sonde launch times, and save to local files

import numpy as np
import xarray as xr
import pandas as pd
import time as timer
import os
import datetime
from collections import Counter # for counting number of occurences of a list of strings (wind direction)

import metpy.calc as mpcalc
from metpy.units import units

def check_bad_date(year=None, month=None, day=None,
                   valid_years=np.arange(2000, 2024+1), valid_months=np.arange(1, 12+1), valid_days=np.arange(1, 31+1)):
    if year is not None:
        if year not in valid_years:
            raise ValueError('Bad year {}; should be in valid_years'.format(year))
    if month is not None:
        if month not in valid_months:
            raise ValueError('Bad month {}; should be in valid_months'.format(month))
    if day is not None:
        if day not in valid_days:
            raise ValueError('Bad day {}; should be in valid_days'.format(day))
    return

# Set where to save processed files
SAVE_DIR = '/Users/kaha4750/OneDrive - UCB-O365/Documents/Arctic_Clouds_Project/ARM_NSA_Data/categorization_2011-2023/processed_datasets'


# Load data
long_data_dir = '/Users/kaha4750/OneDrive - UCB-O365/Documents/Arctic_Clouds_Project/ARM_NSA_Data/categorization_2000-2023'
short_data_dir = '/Users/kaha4750/OneDrive - UCB-O365/Documents/Arctic_Clouds_Project/ARM_NSA_Data/categorization_2011-2023'
# remote_data_dir = '/Volumes/Seagate/ARM_NSA_Data'

# Set timeframe
# full KAZR
start_date = '2011-11-12'
end_date = '2023-12-31'
winter_months = [1, 2, 3, 11, 12]
start_year = int(start_date[:4])
end_year = int(end_date[:4])
shared_timeframe = slice(start_date, end_date)


# Cloud radar
# KAZR restricted to sondes (already QC'd)
kazr_dir = os.path.join(short_data_dir, 'kazrge_during_sondes')
kazr1 = xr.open_dataset(os.path.join(kazr_dir, 'nsakazrge.20111112-20140207.nc'))
kazr2 = xr.open_dataset(os.path.join(kazr_dir, 'nsakazrge.20140208-20191027.nc'))
kazr3 = xr.open_dataset(os.path.join(kazr_dir, 'nsakazrge.20191028-20231231.nc'))
cloud_kazr = xr.concat([kazr1, kazr2, kazr3], dim='time').sel(height=slice(150, None)) # drop first few radar bins
# change height dimension from int -> float (so I can use NaNs later)
cloud_kazr['height'] = ('height', cloud_kazr.height.values.astype('float64'))
# mask out values with insufficient returns per hour
mask_vars = ['reflectivity', 'velocity']
for var in mask_vars:
    cloud_kazr = cloud_kazr.rename({var: 'unmasked_'+var})
    cloud_kazr[var] = cloud_kazr['unmasked_'+var].where(cloud_kazr['frac_valid_returns'] > 0.5, np.nan)
cloud_ds = cloud_kazr



# Atm and cloud moisture
mwr_dir = os.path.join(long_data_dir, 'mwrret')
mwr_filenames = np.loadtxt(os.path.join(mwr_dir, 'mwrret_filenames.txt'), dtype=str)
mwr_files = []
for fn in mwr_filenames:
    fn_year = int(fn[24:28])
    fn_month = int(fn[28:30])
    check_bad_date(fn_year, fn_month)
    if (fn_year >= start_year) and (fn_year <= end_year) and (fn_month in winter_months):
        nc = xr.open_dataset(os.path.join(mwr_dir, fn))
        mwr_files.append(nc)
mwr_ds = xr.concat(mwr_files, 'time') # combined dataset

# Surface radiation
qcrad_ds = xr.open_dataset(os.path.join(long_data_dir, 'nsaqcrad1longC1.c2.20030920.000000..20230819.000000.custom.cdf'))

# Surface meteorology
# files include all variables instead of the ones I requested, so leave unneeded vars out
armbeatm_filenames = np.loadtxt(os.path.join(long_data_dir, 'armbeatm_filenames.txt'), dtype=str)
varname_map = {'T_sfc': 'temperature_sfc', 'p_sfc': 'pressure_sfc', 'prec_sfc': 'precip_rate_sfc'}
armbe1_dropvars = ['time_frac', 'p_bounds', 'z_bounds', 'z10', 'u_sfc', 'v_sfc', 'rh_sfc',
                  'T_p', 'T_z', 'Td_z', 'Td_p', 'rh_p', 'rh_z', 'u_p', 'u_z', 'v_p', 'v_z', 'lat', 'lon',
                   'p', 'z', 'z2']
armbe2_dropvars = ['pressure_bounds', 'height_bounds', 'height_10m', 'height_2m', 'u_wind_sfc', 'v_wind_sfc', 'relative_humidity_sfc',
                   'sensible_heat_flux_baebbr', 'latent_heat_flux_baebbr', 'temperature_p', 'temperature_h', 'dewpoint_p', 'dewpoint_h',
                   'u_wind_p', 'u_wind_h', 'v_wind_p', 'v_wind_h', 'relative_humidity_p', 'relative_humidity_h', 'u_wind_nwp_p',
                   'v_wind_nwp_p', 'omega_nwp_p', 'temperature_nwp_p', 'relative_humidity_nwp_p', 'lat', 'lon', 'alt',
                   'pressure', 'height']
armbe_dropvars = armbe1_dropvars + armbe2_dropvars
armbeatm_files_raw = [xr.open_dataset(os.path.join(long_data_dir, file), drop_variables=armbe_dropvars) for file in armbeatm_filenames]
armbeatm_files = []
for da in armbeatm_files_raw:
    if any(name in da.data_vars.keys() for name in varname_map.keys()):
        da_r = da.rename(varname_map)
    else:
        da_r = da
    armbeatm_files.append(da_r)
armbeatm_ds = xr.concat(armbeatm_files, 'time') # combined dataset
# 'time' dim is centered on hourly bins, but I want left edge of hourly intervals for consistency with other datasets in use
armbeatm_ds = armbeatm_ds.assign_coords(time=(armbeatm_ds.time_bounds.isel(range=0, bound=0))) # replace 'time' with left edge of time intervals

# Ceilometer
ceil_dir = os.path.join(long_data_dir, 'ceil')
ceil_filenames = np.loadtxt(os.path.join(ceil_dir, 'ceil_filenames.txt'), dtype=str)
ceil_dropvars = ['alt', 'alt_highest_signal']
ceil_files = []
for fn in ceil_filenames:
    fn_year = int(fn[13:17])
    fn_month = int(fn[17:19])
    check_bad_date(fn_year, fn_month)
    if (fn_year >= start_year) and (fn_year <= end_year) and (fn_month in winter_months):
        nc = xr.open_dataset(os.path.join(ceil_dir, fn), drop_variables=ceil_dropvars)
        ceil_files.append(nc)
ceil_ds = xr.concat(ceil_files, 'time') # combined dataset

# Sondes
sonde_ds = xr.open_dataset(os.path.join(short_data_dir, 'sondes', 'nsasondewnpnC1.20110101-20231231.nc'))


# Pull out winter
cloud_winter = cloud_ds
water_winter = mwr_ds.isel(time=mwr_ds.time.dt.month.isin(winter_months)).sel(time=shared_timeframe)
rad_winter = qcrad_ds.isel(time=qcrad_ds.time.dt.month.isin(winter_months)).sel(time=shared_timeframe)
meteo_winter = armbeatm_ds.isel(time=armbeatm_ds.time.dt.month.isin(winter_months)).sel(time=shared_timeframe)
ceil_winter = ceil_ds.isel(time=ceil_ds.time.dt.month.isin(winter_months)).sel(time=shared_timeframe)
sonde_winter = sonde_ds.isel(time=sonde_ds.time.dt.month.isin(winter_months)).sel(time=shared_timeframe)


# Quality control
cloud_qc = cloud_winter # no QC; these files already QC'd
water_qc = water_winter
rad_qc = rad_winter
meteo_qc = meteo_winter
ceil_qc = ceil_winter
sonde_qc = sonde_winter # no QC; these files already QC'd

rad_qcvars = (rad_qc, ['BestEstimate_down_short_hemisp', 'down_long_hemisp', 'up_long_hemisp', 'up_short_hemisp'])
rad_aqcvars = (rad_qc, ['down_long_hemisp', 'up_long_hemisp', 'up_short_hemisp'])
ceil_qcvars = (ceil_qc, ['first_cbh', 'second_cbh', 'third_cbh'])
# regular QC
qcset = rad_qcvars
ds, qclist = qcset
for var in qclist:
    if var in ds.data_vars:
        qc_var = 'qc_' + var
        ds[var] = ds[var].where(ds[qc_var] == 0, np.nan)
# special handling for ceilometer
qcset = ceil_qcvars
ds, qclist = qcset
for var in qclist:
    if var in ds.data_vars:
        qc_var = 'qc_' + var
        ds[var] = ds[var].where(np.logical_or(ds[qc_var] == 0, ds[qc_var] == 1), np.nan)
        ds[var] = ds[var].where(ds[qc_var] != 1, np.inf) # 'missing value' = no cloud detected -> infinity
# ancillary QC
ds, qclist = rad_aqcvars
for var in qclist:
    qc_var = 'aqc_' + var
    ds[var] = ds[var].where(ds[qc_var] == 0, np.nan)

# Replace "Incorrect" (-9999) values with NaN
# pretty sure none of my data has this flag, so difficult to confirm this works...
for ds in [water_qc, rad_qc, meteo_qc, ceil_qc, sonde_qc]: # removed cloud_qc
    for var in ds.data_vars:
        if 'time' not in var:
            ds[var] = ds[var].where(ds[var] != -9999., np.nan)

# Filter out "Suspect" time periods
# determined thru Data Discovery interface

# surface radiation
var = 'BestEstimate_down_short_hemisp'
good_times = pd.DatetimeIndex(rad_qc['time'].values) < datetime.datetime(2020, 11, 9)
rad_qc[var] = rad_qc[var].where(good_times, np.nan)

# ceilometer
suspect_vars = ['first_cbh', 'second_cbh', 'third_cbh']
pd_time = pd.DatetimeIndex(ceil_qc['time'].values)
suspect_1 = (pd_time >= datetime.datetime(2006, 5, 2)) & (pd_time <= datetime.datetime(2010, 6, 17))
suspect_2 = (pd_time >= datetime.datetime(2013, 12, 28)) & (pd_time <= datetime.datetime(2014, 2, 26))
suspect_3 = (pd_time >= datetime.datetime(2017, 3, 19)) & (pd_time <= datetime.datetime(2017, 9, 5))
good_times = ~suspect_1 & ~suspect_2 & ~suspect_3
for var in suspect_vars:
    ceil_qc[var] = ceil_qc[var].where(good_times, np.nan)

# Drop variables used in QC; no longer needed
# KAZR
dropped = [var for var in cloud_qc.data_vars if 'unmasked' in var]
print('\ndropping:')
print(dropped)
cloud_qc = cloud_qc.drop_vars(dropped, errors='ignore')
# Water
dropped = [var for var in water_qc.data_vars if 'qc' in var]
print('\ndropping:')
print(dropped)
water_qc = water_qc.drop_vars(dropped, errors='ignore')
# Radiation
dropped = [var for var in rad_qc.data_vars if 'qc' in var]
print('\ndropping:')
print(dropped)
rad_qc = rad_qc.drop_vars(dropped, errors='ignore')
# Ceilometer
dropped = [var for var in ceil_qc.data_vars if 'qc' in var]
print('\ndropping:')
print(dropped)
ceil_qc = ceil_qc.drop_vars(dropped, errors='ignore')


# Hourly data
# resample to hourly
# xarray generates a full year of hourly timestamps, so also limit back to shared time and winter-only
tic = timer.perf_counter()
water_hourly = water_qc.resample(time='1h', label='left').mean(dim='time', skipna=True)
rad_hourly = rad_qc.resample(time='1h', label='left').mean(dim='time', skipna=True)
meteo_hourly = meteo_qc.resample(time='1h', label='left').mean(dim='time', skipna=True)
ceil_hourly = ceil_qc.resample(time='1h', label='left').median(dim='time', skipna=True) # median to handle np.inf when no cloud is detected
toc = timer.perf_counter()
print('Time: {:.2f} min'.format((toc - tic)/60))

# Sonde-matching time coordinate
cloud_duringsondes = cloud_ds.sel(time=shared_timeframe)
water_duringsondes = water_hourly.reindex(time=cloud_duringsondes.time, method='nearest', tolerance=pd.Timedelta(hours=1))
rad_duringsondes = rad_hourly.reindex(time=cloud_duringsondes.time, method='nearest', tolerance=pd.Timedelta(hours=1))
meteo_duringsondes = meteo_hourly.reindex(time=cloud_duringsondes.time, method='nearest', tolerance=pd.Timedelta(hours=1))
ceil_duringsondes = ceil_hourly.reindex(time=cloud_duringsondes.time, method='nearest', tolerance=pd.Timedelta(hours=1))
sonde_duringsondes = sonde_qc.reindex(time=cloud_duringsondes.time, method='nearest', tolerance=pd.Timedelta(hours=1))


# Add variables to sondes

# RH_ice
def calc_psat(T, phase):
    if phase == 'liquid':
        a_1 = 611.21
        a_3 = 17.502
        a_4 = 32.19
    elif phase == 'ice':
        a_1 = 611.21
        a_3 = 22.587
        a_4 = -0.7
    else:
        raise ValueError('Invalid phase {}'.format(phase))
    if np.any(T < 150):
        raise ValueError('Temperature should be in Kelvin')
    p_sat = a_1 * np.exp(a_3 * (T - 273.16) / (T - a_4))
    return p_sat
def calc_RHi(RHw, ps_liq, ps_ice):
    RH_ice = RHw * (ps_liq / ps_ice)
    return RH_ice
rh = sonde_duringsondes['rh']
t = sonde_duringsondes['tdry']
sonde_duringsondes['rh_i'] = calc_RHi(rh, calc_psat(t + 273.16, 'liquid'), calc_psat(t + 273.16, 'ice'))

# Equivalent potential temperature
# note that metpy will save theta_e as a pint.Quantity inside xarray, not np.array
p = sonde_duringsondes['pres']
dp = mpcalc.dewpoint_from_relative_humidity(t * units.degC, rh * units.percent)
sonde_duringsondes['theta_e'] = mpcalc.equivalent_potential_temperature(p * units.hPa, t * units.degC, dp).metpy.dequantify()

# Wind direction string
deg = sonde_duringsondes['deg']
wind = mpcalc.angle_to_direction(deg * units.deg, level=2)
sonde_duringsondes['wind_direction'] = xr.DataArray(wind, dims=deg.dims, coords=deg.coords)

# Specific humidity
sonde_duringsondes['q'] = mpcalc.specific_humidity_from_dewpoint(p * units.hPa, dp).metpy.dequantify()



# Add variables to radar
# $$
# IWC = a Z_e^b
# $$
# where $a \approx 0.1$ in winter (varies from 0.05 in summer to 0.1 in winter, annual average 0.07), $b=0.63$, and $Z_e$ is the radar reflectivity in $mm^6/m^3$. To convert from dBZ to $Z_e$, $Z_e=10^{dBZ/10}$. IWC is in g/m$^3$.
# IWC = a Z^b
# b = 0.63
# a varies seasonally from ~0.05 (summer) to ~0.1 (winter) with an annual average of ~0.07
a_iwc = 0.1
b_iwc = 0.63
Z_e = 10**(cloud_duringsondes['reflectivity'] / 10) # convert dBZ to mm^6/m^3
cloud_duringsondes['iwc'] = a_iwc * (Z_e**b_iwc)
cloud_duringsondes['iwp'] = cloud_duringsondes['iwc'].fillna(0).integrate(coord='height')

# Add variables to MWR
# variability of LWP
lwp_std = water_qc['be_lwp'].resample(time='1h', label='left').std(dim='time', skipna=True)
std_duringsondes = lwp_std.reindex_like(cloud_duringsondes.time, method='nearest', tolerance=pd.Timedelta(hours=1))
water_duringsondes['lwp_std'] = std_duringsondes


# Save processed datasets to files
cloud_duringsondes.to_netcdf(os.path.join(SAVE_DIR, 'processed_cloud.nc'))
water_duringsondes.to_netcdf(os.path.join(SAVE_DIR, 'processed_water.nc'))
rad_duringsondes.to_netcdf(os.path.join(SAVE_DIR, 'processed_rad.nc'))
meteo_duringsondes.to_netcdf(os.path.join(SAVE_DIR, 'processed_meteo.nc'))
ceil_duringsondes.to_netcdf(os.path.join(SAVE_DIR, 'processed_ceil.nc'))
sonde_duringsondes.to_netcdf(os.path.join(SAVE_DIR, 'processed_sonde.nc'))
