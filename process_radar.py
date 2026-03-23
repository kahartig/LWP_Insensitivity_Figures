#!/usr/bin/env python
# coding: utf-8
# Reduce data from general mode of cloud radar KAZRGE and match to sonde launch times
# first datastream: nsakazrcorgeC1.c1 (2011 - 2014)
# second datastream: nsakazrcorgeC1.c0 (2014 - 2019)
# third datastream: nsakazrcfrcorgeC1.c0 (2019 - 2023)
# Must be run three times, once for each datastream; look for the following to change which datastream to process:
### CHANGE dstream AND save_filename HERE ###


import numpy as np
import xarray as xr
import pandas as pd
import time as timer
import os
import datetime

import matplotlib.pyplot as plt


# Restrict KAZR GE to raw sondes

# Data Locations
sonde_dir = '/Users/kaha4750/Documents/Arctic_Clouds_Project/ARM_NSA_Data/categorization_2011-2023/sondes'
kazrge_load_dir = '/Volumes/Seagate/ARM_NSA_Data/kazrge'
# flag_load_dir = '/Volumes/Seagate/ARM_NSA_Data/reflectivity_clutter_flag'
save_dir = '/Users/kaha4750/Documents/Arctic_Clouds_Project/ARM_NSA_Data/categorization_2011-2023/kazrge_during_sondes'
winter_months = [1, 2, 3, 11, 12]

# Set up sonde information
sonde_filenames = np.loadtxt(os.path.join(sonde_dir, 'filenames.txt'), dtype=str)


# Set up KAZR information class
class RadarFiles:
    '''
    Stores file name format, dates spanned, etc. for each radar datastream
    '''
    def __init__(self, filenames, load_dir, variable_name_map):
        '''
        filenames: np array of all filenames in string format
        load_dir: directory containing the files named in filenames
        variable_name_map: dict mapping from a shorthand variable name to its actual name in the files
        '''
        self.filenames = filenames
        self.load_dir = load_dir
        self.varmap = variable_name_map # Map from short name to variable name
        # Load sample files
        first_fn = os.path.join(load_dir, filenames[0])
        last_fn = os.path.join(load_dir, filenames[-1])
        first_file = xr.open_dataset(first_fn)
        last_file = xr.open_dataset(last_fn)
        # Get dates spanned by this datastream
        self.date_span = (first_file.time.values[0], last_file.time.values[-1])

    def get_closest_file(self, datestring, rename=True):
        '''
        Return the file corresponding to the YYYYMMDD date in datestring
        if rename=True, also rename variables according to self.varmap
        '''
        matches = []
        for fn in self.filenames:
            if datestring in fn:
                matches.append(fn)
        if len(matches) == 1:
            var_rename = {v: k for k, v in self.varmap.items()}
            ds = xr.open_dataset(os.path.join(self.load_dir, matches[0])).rename(var_rename)
        else:
            # if not matches: # empty list
            #     print('No file matching date {} found in datastream'.format(datestring))
            #     # raise ValueError('No file matching date {} found in datastream'.format(datestring))
            # else:
            #     print('Matches to date {} not unique: {}'.format(datestring, matches))
            #     # raise ValueError('Matches to date {} not unique: {}'.format(datestring, matches))
            ds = None
        return ds


# Store information about all KAZR GE datastreams

# nsakazrcorgeC1.c1 (2011 - 2014)
filenames1 = np.loadtxt(os.path.join(kazrge_load_dir, 'corc1_filenames.txt'), dtype=str) # 2011-2014
vmap = {'reflectivity': 'reflectivity_copol', 'velocity': 'mean_doppler_velocity_copol', 's2n': 'signal_to_noise_ratio_copol', 'height': 'range'}
first_datastream = RadarFiles(filenames1, kazrge_load_dir, vmap)

# nsakazrcorgeC1.c0 (2014 - 2019)
filenames2 = np.loadtxt(os.path.join(kazrge_load_dir, 'corc0_filenames.txt'), dtype=str) # 2014-2019
vmap = {'reflectivity': 'reflectivity_copol', 'velocity': 'mean_doppler_velocity_copol', 's2n': 'signal_to_noise_ratio_copol', 'height': 'range'}
second_datastream = RadarFiles(filenames2, kazrge_load_dir, vmap)

# nsakazrcfrcorgeC1.c0 (2019 - 2023)
filenames3 = np.loadtxt(os.path.join(kazrge_load_dir, 'cfrc0_filenames.txt'), dtype=str) # 2019-2023
vmap = {'reflectivity': 'reflectivity', 'velocity': 'mean_doppler_velocity', 's2n': 'signal_to_noise_ratio_copolar_h', 'height': 'range'}
third_datastream = RadarFiles(filenames3, kazrge_load_dir, vmap)

all_datastreams = (first_datastream, second_datastream, third_datastream)


### Run on all 2011-2023 sondes ###

# Parameters
s2n_threshold = -13 # signal-to-noise greater than this is 'signal', less than is noise; Matt uses -14
clearsky_ceil = 10000 # ignore anything above this height when determining if sky is clear
shared_height = np.arange(105., 17000., 30) # 105 so that lowest level interpolation is not extrapolation; preserves more values
keep_vars = ['reflectivity', 'velocity', 's2n']

# ds = first_datastream.get_closest_file('20131109')
# ds = second_datastream.get_closest_file('20151109')
ds = third_datastream.get_closest_file('20201109')
print(ds.time[:2], ds.time[-2:])
# print(ds.data_vars)


### CHANGE dstream AND save_filename HERE ###
# which KAZR datastream to process & save
dstream = third_datastream
save_filename = 'nsakazrge.20111112-20140207.nc' # 2011 - 2014
# save_filename = 'nsakazrge.20140208-20191027.nc' # 2014 - 2019
# save_filename = 'nsakazrge.20191028-20231231.nc' # 2019 - 2023

tic = timer.perf_counter()
all_kazrge_hourlys = []
for fn in sonde_filenames:
    # Get date of sonde launch
    sonde_fn_pieces = fn.split('.')
    sd = sonde_fn_pieces[2]
    st = sonde_fn_pieces[3]
    sonde_datetime = pd.Timestamp('{}-{}-{}T{}:{}:00'.format(sd[:4], sd[4:6], sd[6:8], st[:2], st[2:4]))
    
    # Get the following hour of KAZR data
    iswinter = sonde_datetime.month in winter_months
    isinkazrge = (sonde_datetime >= dstream.date_span[0]) and (sonde_datetime <= dstream.date_span[-1])
    if iswinter and isinkazrge:
        # Get radar data on day of sonde
        day_of = dstream.get_closest_file(sd)
        # Get next day in case hour after sonde rolls over
        day_after_sonde_time = sonde_datetime + pd.Timedelta(days=1)
        nextdate = day_after_sonde_time.strftime('%Y%m%d')
        day_after = dstream.get_closest_file(nextdate)
        if day_of is None:
            print('Missing day of {}; skipping...'.format(sonde_datetime))
        elif (sonde_datetime.hour >= 23) and (day_after is None):
            print('Missing next day of {}; skipping...'.format(sonde_datetime))
        else:
            # if hour will roll into next day, also load next day
            if sonde_datetime.hour >= 23:
                # Check if height coordinates match
                if np.allclose(day_of.height, day_after.height, equal_nan=True):
                    both_days = [day_of, day_after]
                else:
                    print('Mismatch in height between day_of {} and day_after; interpolating onto shared coordinate...'.format(sonde_datetime))
                    new_day_of = day_of.interp(height=shared_height, assume_sorted=True)
                    new_day_after = day_after.interp(height=shared_height, assume_sorted=True)
                    both_days = [new_day_of, new_day_after]
                kazrge_data = xr.concat(both_days, dim='time')
            else:
                kazrge_data = day_of
            hour_after_launch = slice(sonde_datetime, sonde_datetime + pd.Timedelta(hours=1))
            ds = kazrge_data[keep_vars].sel(time=hour_after_launch) # only keep the variables that are needed
            
            # Signal to noise filter
            qc_ds = ds
            valid_signal = qc_ds['s2n'] > s2n_threshold
            for var in ['reflectivity', 'velocity']:
                qc_ds[var] = qc_ds[var].where(valid_signal, np.nan)
    
            # Get clearsky fraction
            clear_trop = (~valid_signal).sel(height=slice(None, clearsky_ceil))
            nheight = len(clear_trop.height)
            qc_ds['frac_clearsky'] = clear_trop.sum('height') / nheight # fraction of clear cells between surface and clearsky_ceil
            
            # Resample to hourly
            hourly_data = qc_ds.mean('time')
            
            # Add fraction without NaNs (valid radar return) per hour
            nvalid = ~np.isnan(qc_ds['reflectivity']) # True if return is valid, False if not
            nsamples = nvalid.count(dim='time') # total timesteps per hour
            hourly_fracvalid = nvalid.sum(dim='time') / nsamples # fraction valid per hour
            hourly_data['frac_valid_returns'] = hourly_fracvalid

            # Interpolate onto shared height coordinate
            hourly_sharedz = hourly_data.interp(height=shared_height, assume_sorted=True)
            
            # Add launch time as dimension of length 1
            hourly_withtime = hourly_sharedz.assign_coords({"time": sonde_datetime})
            hourly_withtime = hourly_withtime.expand_dims(dim='time')

            # Store this launch in list
            all_kazrge_hourlys.append(hourly_withtime)
            nstored = len(all_kazrge_hourlys)
            if (nstored % 100) == 0: # output time every 100 profiles
                lil_toc = timer.perf_counter()
                print('{} sondes finished; {:.2f} min so far'.format(nstored, (lil_toc - tic) / 60))
toc = timer.perf_counter()
print('Time: {} min'.format((toc - tic)/60))

# concat along launch time + save
kazrge_during_sondes = xr.concat(all_kazrge_hourlys, dim='time')
len(kazrge_during_sondes.time)
save_fn = os.path.join(save_dir, save_filename)
kazrge_during_sondes.to_netcdf(save_fn)
print(save_fn)
