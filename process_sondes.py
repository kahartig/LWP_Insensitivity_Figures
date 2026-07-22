#!/usr/bin/env python
# coding: utf-8
# Script to take in soundings from nsasondewnpnC1.b1 datastream and convert to launch time vs height coordinates

import numpy as np
import xarray as xr
import pandas as pd
import os
import datetime
import time as timer

import matplotlib.pyplot as plt
import matplotlib as mpl # custom colormaps
import matplotlib.dates as mdates # format datetime axes

from metpy.calc import dewpoint_from_relative_humidity, equivalent_potential_temperature
from metpy.units import units


# Load data
sonde_dir = '/Users/kaha4750/Documents/Arctic_Clouds_Project/ARM_NSA_Data/categorization_2011-2023/sondes'
sonde_filenames = np.loadtxt(os.path.join(sonde_dir, 'filenames.txt'), dtype=str)
sonde_dropvars = ('base_time', 'time_offset', 'dp', 'qc_dp', 'u_wind', 'qc_u_wind',
                 'v_wind', 'qc_v_wind', 'wstat', 'asc', 'qc_asc', 'lat', 'lon')
msl2agl = -8 # sonde heights are relative to MSL; subtract 8 m to convert to AGL


# Loop over all (winter) sonde files
winter_months = [1, 2, 3, 11, 12]
common_height = np.arange(0, 15000, step=5)
qcvars = ['pres', 'tdry', 'rh', 'wspd', 'deg']
drop_afterqc = ['qc_' + var for var in qcvars] + ['qc_time', 'alt']

tic = timer.perf_counter()
sonde_list = []
for fn in sonde_filenames:
    # get datetime of sonde launch
    sonde_fn_pieces = fn.split('.')
    sd = sonde_fn_pieces[2]
    st = sonde_fn_pieces[3]
    sonde_datetime = pd.Timestamp('{}-{}-{}T{}:{}:00'.format(sd[:4], sd[4:6], sd[6:8], st[:2], st[2:4]))
    if sonde_datetime.month in winter_months:
        # open sonde file
        ds = xr.open_dataset(os.path.join(sonde_dir, fn)).drop_vars(sonde_dropvars)
        # check if sonde has data
        if ds['alt'].max('time') < 1000:
            print('Empty/short {} (max alt {:.2f}); skipping...'.format(fn, ds['alt'].max('time')))
        else:
            # replace 'time' dim with 'height'
            ds = ds.assign_coords({'height': ds['alt'] + msl2agl}).swap_dims({'time': 'height'}).drop_vars('time')
            # deal with non-monotonic heights
            is_monotonic = np.all(np.diff(ds.height) > 0)
            if not is_monotonic:
                ds = ds.drop_duplicates('height', keep='last')
                ds = ds.sortby('height')
            # add back the launch time
            ds['time'] = xr.DataArray(sonde_datetime, dims=(), coords=())
            # QC checks
            for var in qcvars:
                qc_var = 'qc_' + var
                ds[var] = ds[var].where(ds[qc_var] == 0, np.nan)
            # replace "Incorrect" with NaN
            for var in ds.data_vars:
                if 'time' not in var:
                    ds[var] = ds[var].where(ds[var] != -9999., np.nan)
            # interpolate onto common height levels
            ds_sameheight = ds.drop_vars(drop_afterqc, errors='ignore').interp(height=common_height, method='linear', assume_sorted=True)
            sonde_list.append(ds_sameheight)
        
toc = timer.perf_counter()
print('Time: {} min'.format((toc - tic)/60))


# In[23]:


# Concat along time and save
all_sondes = xr.concat(sonde_list, dim='time')
save_fn = os.path.join(sonde_dir, 'nsasondewnpnC1.20110101-20231231.nc')
all_sondes.to_netcdf(save_fn)
print(save_fn)