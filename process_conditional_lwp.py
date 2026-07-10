import numpy as np
import xarray as xr
import pandas as pd
import time as timer
import os

# Data directories
long_data_dir = '/Users/kaha4750/OneDrive - UCB-O365/Documents/Arctic_Clouds_Project/ARM_NSA_Data/categorization_2000-2023'
short_data_dir = '/Users/kaha4750/OneDrive - UCB-O365/Documents/Arctic_Clouds_Project/ARM_NSA_Data/categorization_2011-2023'
remote_data_dir = '/Volumes/Seagate/ARM_NSA_Data'
SAVE_DIR = '/Users/kaha4750/OneDrive - UCB-O365/Documents/Arctic_Clouds_Project/ARM_NSA_Data/categorization_2011-2023/processed_datasets'

# Set up sonde information
sonde_dir = os.path.join(short_data_dir, 'sondes')
sonde_filenames = np.loadtxt(os.path.join(sonde_dir, 'filenames.txt'), dtype=str)

# Set timeframe
# full KAZR
start_date = '2011-11-12'
end_date = '2023-12-31'
winter_months = [1, 2, 3, 11, 12]
start_year = int(start_date[:4])
end_year = int(end_date[:4])
shared_timeframe = slice(start_date, end_date)

# Load Microwave Radiometer
mwr_dir = os.path.join(long_data_dir, 'mwrret')
mwr_filenames = np.loadtxt(os.path.join(mwr_dir, 'mwrret_filenames.txt'), dtype=str)
mwr_files = []
for fn in mwr_filenames:
    fn_year = int(fn[24:28])
    fn_month = int(fn[28:30])
    if (fn_year >= start_year) and (fn_year <= end_year) and (fn_month in winter_months):
        nc = xr.open_dataset(os.path.join(mwr_dir, fn))
        mwr_files.append(nc)
mwr_ds = xr.concat(mwr_files, 'time') # combined dataset

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
kazrge_load_dir = os.path.join(remote_data_dir, 'kazrge')

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

# Parameters
s2n_threshold = -13 # signal-to-noise greater than this is 'signal', less than is noise; Matt uses -14
clearsky_ceil = 10000 # ignore anything above this height when determining if sky is clear
shared_height = np.arange(105., 17000., 30) # 105 so that lowest level interpolation is not extrapolation; preserves more values

# Set up
save_filename = os.path.join(SAVE_DIR, 'processed_conditional_lwp.nc')
keep_vars = ['reflectivity', 's2n'] # for radar

# Run on all sondes
tic = timer.perf_counter()
all_lwp_hourlys = []
for fn in sonde_filenames:
    # Get date of sonde launch
    sonde_fn_pieces = fn.split('.')
    sd = sonde_fn_pieces[2]
    st = sonde_fn_pieces[3]
    sonde_datetime = pd.Timestamp('{}-{}-{}T{}:{}:00'.format(sd[:4], sd[4:6], sd[6:8], st[:2], st[2:4]))
    hours_around_launch = slice(sonde_datetime - pd.Timedelta(hours=1), sonde_datetime + pd.Timedelta(hours=1))
    iswinter = sonde_datetime.month in winter_months

    # Get the surrounding hours of LWP data
    lwp_da = mwr_ds['be_lwp'].sel(time=hours_around_launch)
    islwpdata = len(lwp_da.time) > 0

    # Get the surrounding hours of KAZR data
    isinkazrge = True # initialize
    if (sonde_datetime >= first_datastream.date_span[0]) and (sonde_datetime <= first_datastream.date_span[-1]):
        dstream = first_datastream
    elif (sonde_datetime >= second_datastream.date_span[0]) and (sonde_datetime <= second_datastream.date_span[-1]):
        dstream = second_datastream
    elif (sonde_datetime >= third_datastream.date_span[0]) and (sonde_datetime <= third_datastream.date_span[-1]):
        dstream = third_datastream
    else:
        isinkazrge = False
    # Many if-statements below; only calculate LWP conditional average if both radar and MWR data are present
    # otherwise, store nothing for that datetime in all_lwp_hourlys, which will become NaN when reindexed to sondes
    if iswinter and islwpdata:
        if isinkazrge:
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
                radar_ds = kazrge_data[keep_vars].sel(time=hours_around_launch) # only keep the variables that are needed
                if len(radar_ds.time) > 0:
                    # Signal to noise filter
                    valid_signal = radar_ds['s2n'] > s2n_threshold
                    radar_ds['reflectivity'] = radar_ds['reflectivity'].where(valid_signal, np.nan)
            
                    # Get clearsky fraction
                    clear_trop = (~valid_signal).sel(height=slice(None, clearsky_ceil))
                    nheight = len(clear_trop.height)
                    radar_ds['frac_clearsky'] = clear_trop.sum('height') / nheight # fraction of clear cells between surface and clearsky_ceil
    
                    # Resample both to common timestep
                    lwp_1min = lwp_da.resample(time='1min').mean('time')
                    clearsky_1min = radar_ds['frac_clearsky'].resample(time='1min').mean('time')
                    
                    # When clear sky, replace LWP with NaN
                    clearsky_likelwp = clearsky_1min.reindex_like(lwp_1min, method='nearest', tolerance=np.timedelta64(20, 's'))
                    lwp_conditional_1min = lwp_1min.where(clearsky_likelwp <= 0.99, np.nan)
                    
                    # Resample to hourly
                    lwp_hourly = lwp_conditional_1min.resample(time='1h', label='left').mean(dim='time', skipna=True)
    
                    # Store to list
                    all_lwp_hourlys.append(lwp_hourly)
                    nstored = len(all_lwp_hourlys)
                    if (nstored % 100) == 0: # output time every 100 profiles
                        lil_toc = timer.perf_counter()
                        print('{} sondes finished; {:.2f} min so far'.format(nstored, (lil_toc - tic) / 60))
        else:
            print('No radar data for sonde time: {}'.format(sonde_datetime))
toc = timer.perf_counter()
print('Time elapsed: {:.2f} min'.format((toc - tic)/60))

# Concat LWPs
combined_lwp = xr.concat(all_lwp_hourlys, dim='time').drop_duplicates('time')

# Reindex to during sondes
cloud_duringsondes = xr.open_dataset(os.path.join(SAVE_DIR, 'processed_cloud.nc'))
lwp_duringsondes = combined_lwp.reindex(time=cloud_duringsondes.time, method='nearest', tolerance=pd.Timedelta(hours=1))

# Save to file
lwp_duringsondes.to_netcdf(save_filename)
print('Saved to file:')
print('  ', save_filename)