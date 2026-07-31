#!/usr/bin/env python
# coding: utf-8
# Generate all plots for paper from processed and aligned datasets

import numpy as np
import xarray as xr
import pandas as pd
import time as timer
import os
import datetime
from collections import Counter # for counting number of occurences of a list of strings (wind direction)
import scipy.stats as stats # for pearsonr
from scipy.stats import ks_2samp # for Kolmogorov-Smirnov

import metpy.calc as mpcalc
from metpy.units import units

import seaborn as sns
import matplotlib.pyplot as plt
from matplotlib.ticker import FormatStrFormatter # for formatting axis ticks
from matplotlib.patches import Patch # for custom legend patches
from matplotlib.patches import Rectangle # for drawing rectangles on plot
from matplotlib.path import Path # for defining polygon patch based on outline
from matplotlib.patches import PathPatch # for defining polygon patch based on outline
import matplotlib.style as mstyle
from matplotlib.colors import BoundaryNorm # for discrete colorbar in pcolormesh
from matplotlib.colors import Normalize # for linear norms
from matplotlib.ticker import MaxNLocator # for discrete colorbar in pcolormesh
from matplotlib.lines import Line2D # for custom legends
import cartopy.crs as ccrs
import cartopy.feature as cfeature
from cartopy.util import add_cyclic_point

LOAD_DIR = '/Users/kaha4750/OneDrive - UCB-O365/Documents/Arctic_Clouds_Project/ARM_NSA_Data/categorization_2011-2023/processed_datasets'
SAVE_DIR = '/Users/kaha4750/OneDrive - UCB-O365/Documents/My Papers/LWP Insensitive to Meteo Winter2025/Figures'
APPENDIX_SAVE_DIR = '/Users/kaha4750/OneDrive - UCB-O365/Documents/My Papers/LWP Insensitive to Meteo Winter2025/Supplemental_Figures'
master_som_dir = '/Users/kaha4750/Library/CloudStorage/OneDrive-UCB-O365/Documents/Arctic_Clouds_Project/Alaskan_SOM'

# Load datasets
cloud_data = xr.open_dataset(os.path.join(LOAD_DIR, 'processed_cloud.nc'))
water_data = xr.open_dataset(os.path.join(LOAD_DIR, 'processed_water.nc'))
rad_data = xr.open_dataset(os.path.join(LOAD_DIR, 'processed_rad.nc'))
meteo_data = xr.open_dataset(os.path.join(LOAD_DIR, 'processed_meteo.nc'))
ceil_data = xr.open_dataset(os.path.join(LOAD_DIR, 'processed_ceil.nc'))
sonde_data = xr.open_dataset(os.path.join(LOAD_DIR, 'processed_sonde.nc'))


### Define cloud boundaries ###

def length_contiguous_blocks2D(arr):
    '''Get length of all contiguous blocks of True and False along second axis and return mask of those lengths'''
    full_result = np.zeros(arr.shape, dtype=int)
    arr_bounds = np.diff(arr, axis=1) != 0
    for i in range(arr.shape[0]):
        lst = arr[i, :]
        boundaries = arr_bounds[i, :]
        indices = np.where(boundaries)[0] + 1  # Indices where the change happens
        indices = np.concatenate(([0], indices, [len(lst)])) # Add the start (0) and end (len(lst)) to the indices for slicing
        result = np.repeat(np.diff(indices), indices[1:] - indices[:-1])
        full_result[i, :] = result
    return full_result

def fill_height_gaps(condition, min_gap):
    '''Fill all False sections < min_gap m deep with True, then fill remaining True sections < min_gap m deep with False'''
    dh = np.mean(np.diff(condition.height))
    block_length_m = dh * length_contiguous_blocks2D(condition)
    # fill all False sections < 100 m deep with True
    condition_fillFalse = condition.where((block_length_m >= min_gap) & (~condition), True)
    block_length_m = dh * length_contiguous_blocks2D(condition_fillFalse)
    # fill remaining True sections < 100 m with False
    condition_fillboth = condition_fillFalse.where((block_length_m >= min_gap) & (condition_fillFalse), False)
    return condition_fillboth

def identify_layer_boundaries(condition_da, nlayers):
    '''
    Given a boolean mask condition_da with 'height' and 'time' coordinates, return two arrays: base_heights stores the height
    at the base of each True layer (of any length) and top_heights stores the height at the top of each True layer. Both have
    dimensions ('layer', 'time').
    nlayers is used to initialize the 'layer' dimension; an error is raised if any profile has more than nlayers identified.
    If a True layer extends to the top of the 'height' dimension, top height is recorded as the closest height coord <= max(height).
    If there is no True layer in a given timestep, all base_heights and top_heights for that time will be np.nan.
    '''
    height_coord = condition_da.height
    len_time = len(condition_da.time)
    false_pad = np.full((len_time, 1), False)
    padded_detection = np.concatenate([false_pad, condition_da, false_pad], axis=condition_da.get_axis_num('height')).astype(int)
    diff = np.diff(padded_detection, axis=condition_da.get_axis_num('height'))
    # Loop through each time's profile
    base_heights = -1 * np.ones([len_time, nlayers]) # [time, layer number]
    top_heights = -1 * np.ones([len_time, nlayers]) # [time, layer number]
    for tidx in range(len_time):
        col_diff = diff[tidx, :]
        layer_bases = np.argwhere(col_diff > 0)
        layer_tops = np.argwhere(col_diff < 0) - 1 # subtract one so idx is on the final in-cloud height instead of just above it
        if len(layer_bases) != len(layer_tops):
            raise ValueError('Different number of layer tops ({}) and bases ({}) at tidx={}'.format(len(layer_tops), len(layer_bases), tidx))
        valid_base_heights = height_coord.isel(height=layer_bases.squeeze(axis=-1)).astype(float)
        valid_top_heights = height_coord.isel(height=layer_tops.squeeze(axis=-1)).astype(float)
        # store base and top heights
        if len(valid_base_heights) > nlayers:
            raise ValueError('nlayers ({}) is too small for number of layers detected ({}) at tidx={}'.format(nlayers, len(valid_base_heights), tidx))
        else:
            pad_width = nlayers - len(valid_base_heights)
            padded_bases = np.pad(valid_base_heights, (0, pad_width), constant_values=np.nan)
            padded_tops = np.pad(valid_top_heights, (0, pad_width), constant_values=np.nan)
        base_heights[tidx, :] = padded_bases
        top_heights[tidx, :] = padded_tops
    # Convert to DataArrays
    base_heights = xr.DataArray(base_heights, dims=('time', 'layer'),
                                coords={'time': ('time', condition_da.time.data),
                                        'layer': ('layer', np.arange(1, nlayers+1))})
    top_heights = xr.DataArray(top_heights, dims=('time', 'layer'),
                               coords={'time': ('time', condition_da.time.data),
                                       'layer': ('layer', np.arange(1, nlayers+1))})
    return base_heights, top_heights


# Generate masks and fill gaps
# Radar-based cloud mask
cld_valid = ~np.isnan(cloud_data['reflectivity'])
arscl_mask = fill_height_gaps(cld_valid, 100)

# Define cloud mask
cld_mask = arscl_mask

# Determine base and top height of each layer
trop_cutoff = 12000
condition_da = cld_mask.sel(height=slice(None, trop_cutoff))
cloud_base_heights, cloud_top_heights = identify_layer_boundaries(condition_da, 10)


# Typical number of layers
num_radar_layers = (~np.isnan(cloud_base_heights)).sum('layer')

# Define clear sky
clearsky_trop = cloud_data['frac_clearsky']
no_clouds_radar = num_radar_layers < 1
clear_sky = np.logical_and(clearsky_trop > 0.99, no_clouds_radar)
ntimes = len(cloud_data.time)
print('Clear sky: {:.2f} %'.format(100 * np.sum(clear_sky).item()/ntimes))


### Define saturated layer boundaries ###

# Define a saturation threshold w.r.t water
sat_thresh = 95 # percent
saturated_mask = sonde_data['rh'] > sat_thresh

# Calculate the total depth (in troposphere) that is saturated w.r.t water
# integration method is inclusive of top and bottom bounds; a cloud from 100 to 110 m has a depth of 15, not 10
saturated_depth = saturated_mask.sel(height=slice(0, trop_cutoff)).astype(int).integrate('height')

# Determine base and top height of each saturated layer
condition = fill_height_gaps(saturated_mask, 30).sel(height=slice(None, trop_cutoff))
rhw_base_heights, rhw_top_heights = identify_layer_boundaries(condition, 12)


# Typical number of layers
num_rhw_layers = (~np.isnan(rhw_base_heights)).sum('layer')


### Load SOMs ###

# SOM details
ny_node = 4
nx_node = 3
n_nodes = nx_node * ny_node
som_dir = os.path.join(master_som_dir, 'Finished_SOMs/som_v2-{}x{}'.format(ny_node, nx_node))
som_node_patterns_fn = os.path.join(som_dir, 'psl_anom_{}x{}_best.cod'.format(ny_node, nx_node))
som_node2datetime_fn = os.path.join(som_dir, 'map_node2datetime_{}x{}.nc'.format(ny_node, nx_node))
# SOM domain (from polar_som_info.ncl)
use_ij_mask = True
j_l = 100
i_t = 150
j_r = 100 + 130
i_b = 150 + 130
# Terrain height (read directly from EASE data file)
use_elev_mask = True
elev_mask_hgt = 500.
# Map node index to row/column index
ij2node = {(i, j): i * ny_node + (j + 1) for i in range(nx_node) for j in range(ny_node)}
node2ij = {n: x for x,n in ij2node.items()}

# Sample EASE file with terrain height, lat, lon needed to plot SOM nodes
ease_dir = os.path.join(master_som_dir, 'Check_input_data')
ease_file = os.path.join(ease_dir, 'era5-ease_25km-20000101.nc')
ease_data = xr.open_dataset(ease_file)
Z_sfc2d = ease_data['orog']


# Line up SOM node index with sonde time dimension
som_node_idx = xr.open_dataarray(som_node2datetime_fn)
som_node = som_node_idx.reindex_like(cloud_data.time, method='nearest',
                                     tolerance=pd.Timedelta(hours=2), fill_value=np.nan)


### Shared plot properties ###

# Color cycle
colorblind = dict(zip(['dark blue', 'gold', 'dark green', 'rust', 'dusty pink', 'brown', 'light pink', 'grey', 'yellow', 'light blue'],
                      ['#0173b2', '#de8f05', '#029e73', '#d55e00', '#cc78bc', '#ca9161', '#fbafe4', '#949494', '#ece133', '#56b4e9']))
COLOR = colorblind

# SOM color cycle
cmap = plt.cm.Paired
som_colors = {}
for nidx in range(n_nodes):
    node = nidx + 1
    som_colors[node] = cmap(nidx/(n_nodes-1))

# Height coordinates
M2KM = 1/1000.


### Define LWP dataframe: <10, 10-40, 40+ ###

# Define cloud base properties
z_cloud = rhw_base_heights.sel(layer=1).drop_vars('layer') # first saturated layer base height
cb_temperature = sonde_data['tdry'].interp(height=z_cloud, method='linear').drop_vars('height')
cb_moisture = sonde_data['q'].interp(height=z_cloud, method='linear').drop_vars('height') * 1000 # in g/kg

# LWP
lwp = water_data['be_lwp']

# IWP
iwp = cloud_data['iwp']

# Saturated Depth
satdepth = saturated_depth

# Combine and convert to pandas
master_ds = xr.merge([cb_temperature.rename('Temperature'),
                      cb_moisture.rename('Sp Humidity'),
                      z_cloud.rename('First Saturated Base Height'),
                      lwp.rename('LWP'),
                      clear_sky.rename('is Clear Sky'),
                      num_rhw_layers.rename('Layers'),
                      satdepth.rename('Saturated Depth'),
                      iwp.rename('IWP')])
master_df = master_ds.to_dataframe()

# Define LWP state
master_df['LWP Category'] = 'Undefined' # initialize
low_label = r'Indeterminate, <10 g m$^{-2}$'
mid_label = r'Semi-transparent, 10$-$40 g m$^{-2}$'
high_label = r'Opaque, >40 g m$^{-2}$'
# based on LWP value
master_df.loc[master_df['LWP'] < 10, 'LWP Category'] = low_label
master_df.loc[np.logical_and(master_df['LWP'] >= 10, master_df['LWP'] <= 40), 'LWP Category'] = mid_label
master_df.loc[master_df['LWP'] > 40, 'LWP Category'] = high_label
# exclude values outside case
master_df.loc[master_df['Layers'] == 0, 'LWP Category'] = 'No layers'
master_df.loc[master_df['Layers'] > 1, 'LWP Category'] = 'Multi-layer'
master_df.loc[np.isnan(master_df['LWP']), 'LWP Category'] = 'No LWP Data' # note some of these are clear sky
master_df.loc[master_df['is Clear Sky'], 'LWP Category'] = 'Clear sky'
# color scheme
lwp_colors = {low_label: sns.color_palette('colorblind')[7], 
              mid_label: sns.color_palette('colorblind')[9],
              high_label: sns.color_palette('colorblind')[0]}
lwp_order = [low_label, mid_label, high_label]

# Define sub-dataframe of just valid LWP categories
lwp_df = master_df.loc[master_df['LWP Category'].isin(lwp_order)]
# confirm size matches expected
valid_categories = np.logical_and.reduce([~clear_sky, ~np.isnan(water_data['be_lwp']), num_rhw_layers == 1])
if len(lwp_df) != np.sum(valid_categories):
    raise ValueError('DataFrame length {} does not match expected length {}'.format(len(lwp_df), np.sum(valid_categories)))

# Also define as boolean masks for more general use
lwp_cats = {low_label: (master_df['LWP Category'] == low_label).values, 
            mid_label: (master_df['LWP Category'] == mid_label).values,
            high_label: (master_df['LWP Category'] == high_label).values}


### Wind direction categories, all ###
z_wind = 500
winddir_fixed_z = sonde_data['deg'].sel(height=z_wind, method='nearest')

# Wind direction categories
northerly_wind = np.logical_or(winddir_fixed_z > 360-45, winddir_fixed_z < 45).values
easterly_wind = np.logical_and(winddir_fixed_z > 90-45, winddir_fixed_z < 90+45).values
southerly_wind = np.logical_and(winddir_fixed_z > 180-45, winddir_fixed_z < 180+45).values
westerly_wind = np.logical_and(winddir_fixed_z > 270-45, winddir_fixed_z < 270+45).values
wind_cats = {'Southward': northerly_wind, 'Westward': easterly_wind,
             'Northward': southerly_wind, 'Eastward': westerly_wind}
wind_colors = {'Southward': COLOR['dark blue'], 'Westward': COLOR['dusty pink'],
               'Northward': COLOR['dark green'], 'Eastward': COLOR['gold']}

####################
### Main Figures ###
####################

### Occurrence of cloud liquid ###

# Define states

# Sonde
sonde_saturated = num_rhw_layers > 0
rh_in_trop = sonde_data['rh'].sel(height=slice(0, trop_cutoff))
sonde_valid = (np.isnan(rh_in_trop).sum('height') / len(rh_in_trop.height)) < 0.1 # less than 10% nan
# Ceilometer
nan_ceil = np.isnan(ceil_data['first_cbh'])
inf_ceil = np.isinf(ceil_data['first_cbh'])
ceil_detected = np.logical_and(~nan_ceil, ~inf_ceil)
ceil_valid = ~nan_ceil
# LWP
lwp = water_data['be_lwp']
lwp_valid = ~np.isnan(water_data['be_lwp'])

# Sonde + Radar co-located
min_layer = 30
# sonde
satradar_thresh = 95
radar_base = cloud_data.height.isel(height=0)
sat_mask = (sonde_data['rh'] > satradar_thresh).sel(height=slice(radar_base, trop_cutoff))
rhw_mask_highres = fill_height_gaps(sat_mask, min_layer)
# radar
cld_valid = ~np.isnan(cloud_data['reflectivity'])
# cld_valid = ~np.isnan(cloud_data['unmasked_reflectivity'])
radar_mask = fill_height_gaps(cld_valid, min_layer)
radar_mask_highres = radar_mask.astype(int).interp_like(rhw_mask_highres) > 0.5
radar_valid = np.logical_or(clear_sky, num_radar_layers > 0)
# combined
saturated_and_radar = np.logical_and(rhw_mask_highres, radar_mask_highres).any('height')
satradar_valid = np.logical_and(radar_valid, sonde_valid)

# Check % NaN for each instrument
print('Valid radar: ',np.sum(radar_valid).item())
print('Valid sonde: ',np.sum(sonde_valid).item())
print('Valid ceil: ',np.sum(ceil_valid).item())
print('Valid LWP: ',np.sum(lwp_valid).item())
print('Simultaneously valid radar + sonde: ',np.sum(satradar_valid).item())
all_valid = np.logical_and.reduce([radar_valid, sonde_valid, ceil_valid, lwp_valid, satradar_valid])
print('Simultaneously all instruments: ',np.sum(all_valid).item(), '\n')

# Plot only when all instruments have valid readings
ntimes = np.sum(all_valid).item()
barht = 0.8
subbarfrac = 0.33 # fraction of barht reserved for sub-bar
kw = {'MWR': {'zorder': 2},
      'Ceilometer': {'color': COLOR['rust'], 'zorder': 2},
      'Sonde + Radar': {'zorder': 2},
      'Sonde': {'zorder': 2}}
bar_ticks = {'MWR': 1 + 0.5*barht - 0.5*(1-subbarfrac)*barht,
             'MWR with saturated layers': 1 - 0.5*barht + 0.5*subbarfrac*barht,
             'Ceilometer': 2,
             'Sonde + Radar': 3,
             'Sonde visible to radar': 4 - 0.5*barht + 0.5*subbarfrac*barht,
             'Sonde': 4 + 0.5*barht - 0.5*(1-subbarfrac)*barht}

fig, ax = plt.subplots(1, 1, figsize=(8, 6))

# Sonde
label = 'Sonde'
ypos = bar_ticks[label]
rh_thresh = [99, 98, 97, 96, 95] # reverse order necessary
cmap = sns.light_palette(COLOR['dark blue'], as_cmap=True)
alphas = np.linspace(0.2, 1, len(rh_thresh))[::-1]
base = 0
base_onradar = 0
offset = 0.18
for idx,thresh in enumerate(rh_thresh):
    mask = (sonde_data['rh'] > thresh).sel(height=slice(0, trop_cutoff))
    filled_mask = fill_height_gaps(mask, min_layer)
    issaturated = filled_mask.any('height')
    condition = np.logical_and(issaturated, all_valid)
    counts = 100 * np.sum(condition) / ntimes
    counts_above_last = counts - base
    bc = ax.barh(ypos, counts_above_last, (1-subbarfrac)*barht, left=base, color=cmap(alphas[idx]), **kw[label])
    annote = '{:.0f}%'.format(thresh) if thresh < 99 else 'RH>{:.0f}%'.format(thresh)
    ax.annotate(annote, xy=(counts, ypos+offset), color='black', va='center', ha='right')
    base = base + counts_above_last
    # repeat using radar base
    mask = (sonde_data['rh'] > thresh).sel(height=slice(radar_base, trop_cutoff))
    filled_mask = fill_height_gaps(mask, min_layer)
    issaturated = filled_mask.any('height')
    condition = np.logical_and(issaturated, all_valid)
    counts_onradar = 100 * np.sum(condition) / ntimes
    counts_above_last = counts_onradar - base_onradar
    bc = ax.barh(bar_ticks['Sonde visible to radar'], counts_above_last, subbarfrac*barht, left=base_onradar, color=cmap(alphas[idx]), **kw[label])
    base_onradar = base_onradar + counts_above_last
    offset = offset - 0.1

# Sonde+Radar
label = 'Sonde + Radar'
ypos = bar_ticks[label]
cld_present = ~np.isnan(cloud_data['unmasked_reflectivity'])
frac_valid_thresh = [0.5, 0.1]
cmap = sns.light_palette(COLOR['dark green'], as_cmap=True)
alphas = np.linspace(0.2, 1, len(frac_valid_thresh))[::-1]
base = 0
offset = 0.18
for idx,frac in enumerate(frac_valid_thresh):
    cld_valid = cld_present.where(cloud_data['frac_valid_returns'] > frac, False)
    radar_mask = fill_height_gaps(cld_valid, min_layer)
    radar_mask_highres = radar_mask.astype(int).interp_like(rhw_mask_highres) > 0.5
    saturated_and_radar = np.logical_and(rhw_mask_highres, radar_mask_highres).any('height')
    condition = np.logical_and(all_valid, saturated_and_radar)
    counts = 100 * np.sum(condition) / ntimes
    counts_above_last = counts - base
    bc = ax.barh(ypos, counts_above_last, barht, left=base, color=cmap(alphas[idx]), **kw[label])
    if idx == 0:
        txt = 't>{:.0f}%'.format(100*frac)
    else:
        txt = '>{:.0f}%'.format(100*frac)
    ax.annotate(txt, xy=(counts, ypos+offset), color='black', va='center', ha='right')
    base = base + counts_above_last
    offset = offset - 0.3

# Ceilometer
label = 'Ceilometer'
ypos = bar_ticks[label]
condition = np.logical_and(all_valid, ceil_detected)
counts = 100 * np.sum(condition) / ntimes
bc = ax.barh(ypos, counts, barht, **kw[label])

# MWR stacks
label = 'MWR'
ypos = bar_ticks[label]
mwr_bounds = [40, 30, 20, 10, 0, -10]
cmap = sns.light_palette(COLOR['gold'], as_cmap=True)
alphas = np.linspace(0.1, 1, len(mwr_bounds))[::-1]
base = 0
base_withsat = 0
for idx,left in enumerate(mwr_bounds):
    if idx == 0:
        annote = r'>{:d} g m$^{{-2}}$'.format(left)
        condition = np.logical_and(all_valid, lwp > left)
    else:
        right = mwr_bounds[idx-1]
        annote = '{:d}\nto\n{:d}'.format(left, right)
        condition = np.logical_and.reduce([all_valid, lwp > left, lwp <= right])
    counts = 100 * np.sum(condition) / ntimes
    bars = ax.barh(ypos, counts, (1-subbarfrac)*barht, left=base, color=cmap(alphas[idx]), **kw[label])
    ax.bar_label(bars, labels=[annote,], label_type='center')
    base = base + counts
    # repeat for MWR+saturated
    if idx == 0:
        condition = np.logical_and.reduce([all_valid, lwp > left, num_rhw_layers > 0])
    else:
        right = mwr_bounds[idx-1]
        condition = np.logical_and.reduce([all_valid, lwp > left, lwp <= right, num_rhw_layers > 0])
    counts = 100 * np.sum(condition) / ntimes
    bars = ax.barh(bar_ticks['MWR with saturated layers'], counts, subbarfrac*barht, left=base_withsat, color=cmap(alphas[idx]), **kw[label])
    base_withsat = base_withsat + counts

# Format
ax.set(title='Liquid Cloud Occurrence by Instrument', xlabel='Percent', xlim=(0, 100))
ax.grid(which='major', axis='x', zorder=1)
ax.set_yticks(list(bar_ticks.values()), list(bar_ticks.keys()))

# Save
save_filename = os.path.join(SAVE_DIR, 'fig01.pdf')
print('Save figure to:')
print('  ', save_filename)
plt.savefig(save_filename, bbox_inches='tight')
# plt.show()


### T-q jointplot ###

# Calculate adiabatic LWP (Matt's version)
T_range = (-20, -10)
tsubset_df = lwp_df[np.logical_and(lwp_df['Temperature'] >= T_range[0], lwp_df['Temperature'] <= T_range[1])]
print('Number of points in temperature subset for LWP vs Saturated Depth: {}'.format(len(tsubset_df)))
sat_layer_base = tsubset_df['First Saturated Base Height'].values

# set characteristic cloud properties
base_temperatures = np.array([-20, -10])
pressure = np.nanmedian(sonde_data['pres'].sel(time=tsubset_df.index.values).sel(height=sat_layer_base, method='nearest').values) * 100 # Pa
mixrat = np.nanmedian(sonde_data['q'].sel(time=tsubset_df.index.values).sel(height=sat_layer_base, method='nearest').values) # kg/kg
temperature = base_temperatures + 273.15 # K
dz = 5
z = np.arange(0, 1500, dz) # m
z_da = xr.DataArray(z, dims=('sat_depth',), coords={'sat_depth': ('sat_depth', z)})

# Constants
kg2g = 1000 # convert kg to g
g = 9.80665 # m/s2
L_w = 2.52e6 # m2/s2
c_p = 1004.0 # m2/s2-K
R_v = 461.5 # J/kg-K
R_a = 287.1 # J/kg-K
rho_d = pressure / (temperature * R_a) # kg/m3; for dry air; rho = p / (T * R_specific) for ideal gas
rho_v = rho_d * mixrat # kg/m3; for water vapor

A_1 = (g / temperature) * ((L_w / (c_p * R_v * temperature)) - (1 / R_a))
A_2 = (1 / rho_v) + (L_w**2 / (c_p * R_v * temperature**2 * rho_d))
A1_da = xr.DataArray(A_1, dims=('base_temp',), coords={'base_temp': ('base_temp', base_temperatures)})
A2_da = xr.DataArray(A_2, dims=('base_temp',), coords={'base_temp': ('base_temp', base_temperatures)})
adiabatic_lwp = (A1_da / A2_da) * (z_da**2) * kg2g

# Jointplot with three KDEs

tmosaic = 'AAAAA.....;BBBBBCDDDD;BBBBBCDDDD;BBBBBCDDDD;BBBBBCDDDD;BBBBBCDDDD'
bmosaic = 'A'

fig = plt.figure(figsize=(10, 10), layout='constrained')
top, bottom = fig.subfigures(nrows=2, ncols=1, height_ratios=[1, 0.6])
top_axd = top.subplot_mosaic(tmosaic)
bot_ax = bottom.subplots(1,1)

# Jointplot
ax = top_axd['B']
# Calculate Clausius-Clapeyron line
p = sonde_data['pres'].interp(height=z_cloud, method='linear').mean('time') * units.hPa
t = np.linspace(-40, 0, 100) * units.degC
qsat = mpcalc.saturation_mixing_ratio(p, t).to('g/kg')
# Setup
joint_kwargs = {'linewidths': 2.5}
marginal_kwargs = {'linewidth': 3, 'common_norm': True}
# common_norm=True scales by total across all plots, like counts
# common_norm=False scales each plot individually, like density
xlims = (-45, 5)
ylims = (-0.25, 3.5)
lev = [0.1, 0.4, 0.7] # originally lev=4
ax.plot(t, qsat, ls='--', c='black', label='100% RH')
ax.axvspan(T_range[0], T_range[1], color='grey', alpha=0.1, label='Panel (b) range')
extra_legend = ax.legend(loc='upper left', bbox_to_anchor=(0, 0.7))
sns.kdeplot(data=lwp_df, x='Temperature', y='Sp Humidity', ax=ax,
            hue='LWP Category', hue_order=lwp_order, palette=lwp_colors,
            levels=lev, **joint_kwargs)
sns.move_legend(ax, "upper left", bbox_to_anchor=(0, 0.94)) # make room for panel label
ax.add_artist(extra_legend)
ax.set(xlabel=r'Cloud Base Temperature ($^{\circ}$C)', ylabel='Cloud Base Specific Humidity (g kg$^{-1}$)', xlim=xlims, ylim=ylims)
sns.despine(ax=ax)

# Temperature Marginal
ax = top_axd['A']
sns.kdeplot(data=lwp_df, x='Temperature', hue='LWP Category',
            hue_order=lwp_order, palette=lwp_colors, legend=False, ax=ax, **marginal_kwargs)
ax.axvspan(T_range[0], T_range[1], color='grey', alpha=0.1)
ax.set(xlim=xlims, yticks=[], ylabel=None, xticklabels=[], xlabel=None)
ax.set_title('(a)', y=1.0, x=0.018, pad=-15, loc='left', bbox=dict(facecolor='whitesmoke', edgecolor='white'))
sns.despine(ax=ax, left=True)

# SpHumidity Marginal
ax = top_axd['C']
sns.kdeplot(data=lwp_df, y='Sp Humidity', hue='LWP Category',
            hue_order=lwp_order, palette=lwp_colors, legend=False, ax=ax, **marginal_kwargs)
ax.set(ylim=ylims, xticks=[], xlabel=None, yticklabels=[], ylabel=None)
sns.despine(ax=ax, bottom=True)

# LWP vs SatDepth
ax = top_axd['D']
tsubset_df = lwp_df[np.logical_and(lwp_df['Temperature'] >= T_range[0], lwp_df['Temperature'] <=  T_range[1])]
# get median LWP at each saturated depth bin
sd_edges = np.arange(0, 700, 48)
sd_centers = (sd_edges[:-1] + sd_edges[1:]) / 2
med_lwp = np.zeros(len(sd_centers))
for idx in range(len(sd_edges) - 1):
    left = sd_edges[idx]
    right = sd_edges[idx+1]
    in_bin = np.logical_and(tsubset_df['Saturated Depth'] >= left, tsubset_df['Saturated Depth'] < right)
    lwp_values = tsubset_df['LWP'][in_bin]
    med_lwp[idx] = np.nanmedian(lwp_values)
# plot
hp = sns.histplot(tsubset_df, x='Saturated Depth', y='LWP', ax=ax,
                  bins=(30, 20), cbar=True, cbar_kws={'label': 'Counts', 'shrink': 0.6})
hp.fill_between(adiabatic_lwp.sat_depth, adiabatic_lwp[0, :], adiabatic_lwp[1, :], color='grey', alpha=0.7, label='Adiabatic LWP')
hp.plot(sd_centers, med_lwp, ls='--', color=COLOR['grey'], lw=3, label='Median LWP')
ax.set(title=r'Spread in LWP for Temperatures -20 to -10$^{\circ}$C', xlabel='Saturated Depth (m)', ylabel='Liquid Water Path (g m$^{-2}$)',
       xlim=(0, 1000), ylim=(-20, 250))
ax.text(-0.25, 1.02, '(b)', transform=ax.transAxes, fontsize=12, bbox=dict(facecolor='whitesmoke', edgecolor='white'))
for spine in ax.spines.values():
    spine.set(edgecolor='grey', alpha=0.5, lw=2)
ax.legend()

# LWP occurrence by T bin
ax = bot_ax
# Set up T ranges
bin_width = 5
bin_edges = np.arange(-40, 0+1, bin_width)
bins = [(i, i+bin_width) for i in bin_edges[:-1]]
mid_bin_pos = bin_edges[:-1] + (bin_width / 2)
# define base and test variables
df = lwp_df
cat_col = 'LWP Category'
cat_labels = lwp_order # defines cases in df[cat_col]
ntotal = len(df)
bin_label = 'Temperature' # to access a column in df_by_cat DataFrames
# Pre-generate counts per bin
lwp_counts = {label: np.zeros(len(bins)) for label in cat_labels}
for idx,t_bin in enumerate(bins):
    for name in cat_labels:
        df_cat = df.loc[df[cat_col] == name]
        df_in_bin = df_cat.loc[np.logical_and(df_cat[bin_label] >= t_bin[0], df_cat[bin_label] < t_bin[1])]
        lwp_counts[name][idx] = len(df_in_bin)
total_per_bin = np.sum(np.array([lwp_counts[key] for key in cat_labels]), axis=0)
width = 2
bottom = np.zeros(len(bins))
for name, count in lwp_counts.items():
    # name = mid_label
    # count = lwp_counts[name]
    frac = 100 * count/total_per_bin
    p = ax.bar(mid_bin_pos, frac, width, label=name, color=lwp_colors[name], bottom=bottom)
    frac_labels = ['{:.0f}%'.format(f) for f in frac]
    ax.bar_label(p, labels=frac_labels, label_type='center', color='black', fontsize=9)
    bottom += frac
# add counts per bin along top
for idx in range(len(total_per_bin)):
    ax.text(mid_bin_pos[idx], 103, '{:.0f}'.format(total_per_bin[idx]), ha='center', color='grey')
ax.text(-0.5, 103, 'Counts\nper bin', ha='center', color='grey')
# format
ax.set_xticks(bin_edges)
ax.set(title='LWP Occurrence in Temperature Bins\n', ylabel='Percent of T range', xlabel=r'Cloud Base Temperature ($^{\circ}$C)')
ax.text(0.01, 1.04, '(c)', transform=ax.transAxes, fontsize=12, bbox=dict(facecolor='whitesmoke', edgecolor='white'))
ax.legend()

# Save
save_filename = os.path.join(SAVE_DIR, 'fig02.pdf')
print('Save figure to:')
print('  ', save_filename)
plt.savefig(save_filename, bbox_inches='tight')
# plt.show()


### Cloud water by PWV percentile ###


# Cloud water by PWV percentile
da1 = cloud_data['iwp']
da1_name = 'IWP'
da2 = water_data['be_lwp']
da2_name = 'LWP'
bin_value_da = water_data['be_pwv']

# bins in percentiles
percentile_width = 10
percentiles = np.arange(0, 100+percentile_width, percentile_width)
percentile_bins = [(i, i+percentile_width) for i in percentiles[:-1]]
mid_bin_percent = percentiles[:-1] + (percentile_width / 2)
# convert bins to value
values_at_percentile = np.nanpercentile(bin_value_da, percentiles)

# Store values
da1_in_bin = []
da2_in_bin = []
print('Counts per PWV percentile bin:')
for pbin in percentile_bins:
    low, high = np.nanpercentile(bin_value_da, pbin)
    in_bin = np.logical_and(bin_value_da > low, bin_value_da < high)
    # first DA
    values = da1[in_bin]
    da1_in_bin.append(values[~np.isnan(values)])
    # second DA
    values = da2[in_bin]
    da2_in_bin.append(values[~np.isnan(values)])
    print('  {}: ice {}, liquid {}'.format(pbin, len(da1_in_bin[-1]), len(da2_in_bin[-1])))

# Plot
da1_props = {'boxprops': dict(linewidth=2, color=COLOR['light blue']),
             'whiskerprops': dict(linewidth=2, color=COLOR['light blue']),
             'capprops': dict(linewidth=2, color=COLOR['light blue']),
             'medianprops': dict(linewidth=2, color=COLOR['light blue'])}
da2_props = {'boxprops': dict(linewidth=2, color=COLOR['dark blue']),
             'whiskerprops': dict(linewidth=2, color=COLOR['dark blue']),
             'capprops': dict(linewidth=2, color=COLOR['dark blue']),
             'medianprops': dict(linewidth=2, color=COLOR['dark blue'])}
fig, ax = plt.subplots(1, 1, figsize=(8, 6))
# IWP
ax.boxplot(da1_in_bin, positions=mid_bin_percent-2, showfliers=False, widths=2,
           whis=(10, 90), label=da1_name, zorder=2, **da1_props)
# LWP
ax.boxplot(da2_in_bin, positions=mid_bin_percent+2, showfliers=False, widths=2,
           whis=(10, 90), label=da2_name, zorder=2, **da2_props)
# format
ax.axhline(10, color='grey', lw=1, zorder=1)
ax.text(102, 10, '10 g m$^{-2}$', color='grey', va='center')
ax.axhline(40, color='grey', lw=1, zorder=1)
ax.text(102, 40, '40 g m$^{-2}$', color='grey', va='center')
ax.set_xticks(percentiles, labels=percentiles)
ax.set(title='Cloud Water by PWV Percentile', xlabel='PWV Percentile Bins', ylabel='Water Path (g m$^{-2}$)',
      xlim=(0, 100), ylim=(-10, 650))
highest_iwp_whisker = np.nanpercentile(da1_in_bin[-1], 90)
ax.text(95-2, 655, r'$\uparrow$ {:.0f} g m$^{{-2}}$'.format(highest_iwp_whisker), color='grey', ha='center')
ax.legend()

# Save
save_filename = os.path.join(SAVE_DIR, 'fig03.pdf')
print('Save figure to:')
print('  ', save_filename)
plt.savefig(save_filename, bbox_inches='tight')
# plt.show()


### Wind direction: meteo and cloud properties ###

# All wind directions
upper_layout = 'AB;CC'
lower_layout = 'EF'
profile_top = 6000 # m
p_thresh = 0.05 # for Kolmogorov-Smirnov

fig = plt.figure(figsize=(10, 11), layout='constrained')
top, bottom = fig.subfigures(nrows=2, ncols=1, height_ratios=[1, 0.4])
top_left, top_right = top.subfigures(nrows=1, ncols=2)
tl_axd = top_left.subplot_mosaic(upper_layout)
tr_axd = top_right.subplot_mosaic(upper_layout)
bot_axd = bottom.subplot_mosaic(lower_layout)
sf_map = {'Westward': tl_axd, 'Eastward': tl_axd, 'Southward': tr_axd, 'Northward': tr_axd}

# Temperature
pos = 'A'
da = sonde_data['tdry'].sel(height=slice(0, profile_top))
for name, condition in wind_cats.items():
    state = da[condition]
    ax = sf_map[name][pos]
    ax.plot(state.median('time'), state.height*M2KM, color=wind_colors[name], lw=3, label=name, zorder=4)
    ax.fill_betweenx(state.height*M2KM, np.nanpercentile(state, 25, axis=0),
                     np.nanpercentile(state, 75, axis=0), color=wind_colors[name], alpha=0.2, zorder=3)
tl_axd[pos].text(0.05, 0.94, '(a)', transform=tl_axd[pos].transAxes, fontsize=12, bbox=dict(facecolor='whitesmoke', edgecolor='white'), zorder=5)
tr_axd[pos].text(0.05, 0.94, '(c)', transform=tr_axd[pos].transAxes, fontsize=12, bbox=dict(facecolor='whitesmoke', edgecolor='white'), zorder=5)
for ax in [tl_axd[pos], tr_axd[pos]]:
    ax.plot(da.median('time'), da.height*M2KM, color='black', alpha=0.7, ls='--', lw=1.5, zorder=4, label='2011-2023\nwinter median')
    ax.set(title=r'Temperature ($^\circ$C)', ylabel='Height (km)', ylim=(0, profile_top*M2KM), xlim=(-45, 0))
    ax.set_xticks([-40, -30, -20, -10, 0])
    ax.legend(bbox_to_anchor=[0.01, 0.93], loc='upper left')


# Sp Humidity
pos = 'B'
da = sonde_data['q'].sel(height=slice(0, profile_top)) * 1000 # in g/kg
for name, condition in wind_cats.items():
    state = da[condition]
    ax = sf_map[name][pos]
    ax.plot(state.median('time'), state.height*M2KM, color=wind_colors[name], lw=3, label=name)
    ax.fill_betweenx(state.height*M2KM, np.nanpercentile(state, 25, axis=0),
                     np.nanpercentile(state, 75, axis=0), color=wind_colors[name], alpha=0.2)
for ax in [tl_axd[pos], tr_axd[pos]]:
    ax.plot(da.median('time'), da.height*M2KM, color='black', alpha=0.7, ls='--', lw=1.5, zorder=5)
    ax.set(title='Specific Humidity (g kg-1)', ylim=(0, profile_top*M2KM), xlim=(0, 2))
    ax.set_yticks([])
    ax.set_xticks([0, 0.5, 1, 1.5])
tl_axd[pos].text(0.05, 0.94, '(b)', transform=tl_axd[pos].transAxes, fontsize=12, bbox=dict(facecolor='whitesmoke', edgecolor='white'), zorder=5)
tr_axd[pos].text(0.05, 0.94, '(d)', transform=tr_axd[pos].transAxes, fontsize=12, bbox=dict(facecolor='whitesmoke', edgecolor='white'), zorder=5)


# Cloud fraction
pos = 'C'
frac_clear = {}
frac_noliq = {}
da = cld_mask.sel(height=slice(18, profile_top))
for name, condition in wind_cats.items():
    state = da[condition].astype(int)
    ax = sf_map[name][pos]
    ax.plot(state.sum('time')/len(state.time), state.height*M2KM, color=wind_colors[name], lw=3, ls='--',
            label=name+', radar hydrometeors')
    frac_clear[name] = (np.sum(np.logical_and(condition, clear_sky)) / np.sum(condition)).item()
for ax in [tl_axd[pos], tr_axd[pos]]:
    # Climatology
    ax.plot(da.astype(int).sum('time')/len(da.time), da.height*M2KM, color='black', alpha=0.7,
            ls='--', lw=1.5, zorder=5)
frac_clear['Climatology'] = (np.sum(clear_sky) / len(sonde_data.time)).item()
# Saturation
da = sonde_data['rh'].sel(height=slice(18, profile_top)) >= 95 # water; lots of NaNs below 18m
for name, condition in wind_cats.items():
    state = da[condition].astype(int)
    ax = sf_map[name][pos]
    ax.plot(state.sum('time')/len(state.time), state.height*M2KM, color=wind_colors[name],
            lw=2, label=name+r', RH$_{water}>$95%')
    frac_noliq[name] = (np.sum(np.logical_and(condition, num_rhw_layers == 0)) / np.sum(condition)).item()
for ax in [tl_axd[pos], tr_axd[pos]]:
    # Climatology
    ax.plot(da.astype(int).sum('time')/len(da.time), da.height*M2KM, color='black', alpha=0.7,
            ls='-', lw=1, zorder=5)
frac_noliq['Climatology'] = (np.sum(num_rhw_layers == 0) / len(sonde_data.time)).item()
# Text box for % clear/liquid
txt_xpos = {'Climatology': 0.5, 'Westward': 0.6, 'Eastward': 0.7, 'Southward': 0.6, 'Northward': 0.7}
for ax in [tl_axd[pos], tr_axd[pos]]:
    name = 'Climatology'
    txt = ax.text(0.5, 3, 'Clear sky (radar):')
    ax.text(txt_xpos[name], 2.5, '{:.0f}%'.format(100*frac_clear[name]), color='black')
for name in wind_cats.keys():
    ax = sf_map[name][pos]
    ax.text(txt_xpos[name], 2.5, '{:.0f}%'.format(100*frac_clear[name]), color=wind_colors[name])
for ax in [tl_axd[pos], tr_axd[pos]]:
    name = 'Climatology'
    txt = ax.text(0.5, 2, 'No liquid clouds (sonde):')
    ax.text(txt_xpos[name], 1.5, '{:.0f}%'.format(100*frac_noliq[name]), color='black')
for name in wind_cats.keys():
    ax = sf_map[name][pos]
    ax.text(txt_xpos[name], 1.5, '{:.0f}%'.format(100*frac_noliq[name]), color=wind_colors[name])
# format
for ax in [tl_axd[pos], tr_axd[pos]]:
    ax.set(title='Cloud Fraction', xlim=(0, 1), ylabel='Height (km)', ylim=(0, profile_top*M2KM))
    ax.legend(loc='upper right')
tl_axd[pos].text(0.01, 1.04, '(e)', transform=tl_axd[pos].transAxes, fontsize=12, bbox=dict(facecolor='whitesmoke', edgecolor='white'))
tr_axd[pos].text(0.01, 1.04, '(f)', transform=tr_axd[pos].transAxes, fontsize=12, bbox=dict(facecolor='whitesmoke', edgecolor='white'))

# LWP (excludes clear sky cases)
ax = bot_axd['E']
da = water_data['be_lwp']
pos = [5, 10, 15, 20, 25]
# for climatology
idx = -1
prop = {'boxprops': dict(linewidth=1.5, color='black', alpha=0.7, linestyle='--'),
        'whiskerprops': dict(linewidth=1.5, color='black', alpha=0.7, linestyle='--'),
        'capprops': dict(linewidth=1.5, color='black', alpha=0.7, linestyle='--'),
        'medianprops': dict(linewidth=1.5, color='black', alpha=0.7, linestyle='--')}
clim_values = [da[np.logical_and(~clear_sky, ~np.isnan(da))],]
ax.boxplot(clim_values, positions=[pos[idx],], showfliers=False, widths=3,
           whis=(10, 90), zorder=2, **prop)
# by wind category
idx = 0
labels = []
for name, condition in wind_cats.items():
    values = [da[np.logical_and.reduce([condition, ~clear_sky, ~np.isnan(da)])],]
    # K-S test for significance
    kstest = ks_2samp(values[0], clim_values[0], nan_policy='omit')
    if kstest.pvalue < p_thresh:
        lw = 3
        labels.append(name+'*')
    else:
        lw = 1
        labels.append(name)
    # properties
    prop = {'boxprops': dict(linewidth=lw, color=wind_colors[name]),
            'whiskerprops': dict(linewidth=lw, color=wind_colors[name]),
            'capprops': dict(linewidth=lw, color=wind_colors[name]),
            'medianprops': dict(linewidth=lw, color=wind_colors[name])}
    # values
    ax.boxplot(values, positions=[pos[idx],], showfliers=False, widths=3,
               whis=(10, 90), zorder=2, **prop)
    idx = idx + 1
# formatting
labels = labels + ['2011-2023\nwinters',]
# stagger every other label
labels[1] = '\n'+labels[1]
labels[3] = '\n'+labels[3]
ax.set_xticks(pos, labels=labels)
ax.axhline(0, color='grey', lw=1, zorder=1)
ax.set(title='Liquid Water Path', ylabel='Water Path (g m$^{-2}$)')
ax.text(0.01, 1.05, '(g)', transform=ax.transAxes, fontsize=12, bbox=dict(facecolor='whitesmoke', edgecolor='white'))

# IWP (excludes clear sky cases)
ax = bot_axd['F']
da = cloud_data['iwp']
pos = [5, 10, 15, 20, 25]
# for climatology
idx = -1
prop = {'boxprops': dict(linewidth=1.5, color='black', alpha=0.7, linestyle='--'),
        'whiskerprops': dict(linewidth=1.5, color='black', alpha=0.7, linestyle='--'),
        'capprops': dict(linewidth=1.5, color='black', alpha=0.7, linestyle='--'),
        'medianprops': dict(linewidth=1.5, color='black', alpha=0.7, linestyle='--')}
clim_values = [da[np.logical_and(~clear_sky, ~np.isnan(da))],]
ax.boxplot(clim_values, positions=[pos[idx],], showfliers=False, widths=3,
           whis=(10, 90), zorder=2, **prop)
# by wind category
idx = 0
labels = []
for name, condition in wind_cats.items():
    values = [da[np.logical_and.reduce([condition, ~clear_sky, ~np.isnan(da)])],]
    # K-S test for significance
    kstest = ks_2samp(values[0], clim_values[0], nan_policy='omit')
    if kstest.pvalue < p_thresh:
        lw = 3
        labels.append(name+'*')
    else:
        lw = 1
        labels.append(name)
    # properties
    prop = {'boxprops': dict(linewidth=lw, color=wind_colors[name]),
            'whiskerprops': dict(linewidth=lw, color=wind_colors[name]),
            'capprops': dict(linewidth=lw, color=wind_colors[name]),
            'medianprops': dict(linewidth=lw, color=wind_colors[name])}
    # plot
    ax.boxplot(values, positions=[pos[idx],], showfliers=False, widths=3,
               whis=(10, 90), zorder=2, **prop)
    idx = idx + 1
# formatting
labels = labels + ['2011-2023\nwinters',]
# stagger every other label
labels[1] = '\n'+labels[1]
labels[3] = '\n'+labels[3]
ax.set_xticks(pos, labels=labels)
ax.axhline(0, color='grey', lw=1, zorder=1)
ax.set(title='Ice Water Path')
ax.text(0.01, 1.05, '(h)', transform=ax.transAxes, fontsize=12, bbox=dict(facecolor='whitesmoke', edgecolor='white'))

# Save
save_filename = os.path.join(SAVE_DIR, 'fig04.pdf')
print('Save figure to:')
print('  ', save_filename)
plt.savefig(save_filename, bbox_inches='tight')
# plt.show()


### Wind roses by SOM node ###

# Define mask for domain and elevation
mask_spatial = np.zeros(ease_data.lat.shape).astype(bool) # initialize
if use_ij_mask:
    mask_spatial[j_l:j_r+1, i_t:i_b+1] = True
if use_elev_mask:
    mask_spatial[Z_sfc2d > elev_mask_hgt] = False

# Read SOM node patterns into structured format
# Load SOM data
som_data = np.loadtxt(som_node_patterns_fn, skiprows=1)
n_nodes, n_pts = som_data.shape
# Define shape as [nodes, x-dim, y-dim]
final_shape = sum(((n_nodes,), ease_data.lat.shape), ()) # concats tuples
# Broadcast mask over all nodes
mask_3d = np.tile(mask_spatial, (n_nodes, 1, 1))
# Assign values from SOM nodes in 1-D
node_patterns = np.zeros(final_shape) # initialize
flat_nodes = node_patterns.flatten()
flat_mask = mask_3d.flatten()
flat_nodes[flat_mask] = som_data.flatten()
# Reshape and make masked array for plotting
masked_nodes = np.ma.array(flat_nodes.reshape(final_shape), mask=~mask_3d)


# Wind roses by relative frequency
# adjust projection so N on pattern lines up with N on wind roses
ak_proj_wind = ccrs.LambertAzimuthalEqualArea(central_longitude=360-156, central_latitude=71)
ak_extent_wind = [205-30, 205+30, 50, 84]

# set up for wind roses
sorted_keys = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW']#, 'UND']
theta = np.linspace(0.0, 2*np.pi, len(sorted_keys), endpoint=False)
z_wind = 500
# dir_at_z = sonde_data['deg'].sel(height=z_wind, method='nearest')
# spd_at_z = sonde_data['wspd'].sel(height=z_wind, method='nearest')
heading = sonde_data['wind_direction'].sel(height=z_wind, method='nearest')
da = heading.where(~np.isnan(z_wind), 'UND') # fix because .sel returns a value even when height=NaN

fig, axs = plt.subplots(nx_node, ny_node, figsize=(10, 8), subplot_kw={'projection': ak_proj_wind}, layout='constrained')
# format all axes
for ax in axs.flatten():
    ax.set_extent(ak_extent_wind, crs=ccrs.PlateCarree()) # Plate Carree for lat/lon
    ax.add_feature(cfeature.COASTLINE, edgecolor='black', linewidth=1, zorder=3)
    ax.add_feature(cfeature.LAND, facecolor='lightgrey', zorder=1)
    # ax.gridlines()
# SOM node patterns
mag = np.max(np.abs(masked_nodes))
levels = MaxNLocator(nbins=20).tick_values(-mag, mag)
cmap = plt.colormaps['RdBu_r']
norm = BoundaryNorm(levels, ncolors=cmap.N, clip=True)
node_idx = 0
node_letters = np.array([['a', 'b', 'c', 'd'],['e', 'f', 'g', 'h'],['i', 'j', 'k', 'l']])
for i in range(nx_node):
    for j in range(ny_node):
        ax = axs[i, j]
        node_label = 'Node [{}, {}]'.format(j+1, i+1)
        pc = ax.pcolormesh(ease_data.lon, ease_data.lat, masked_nodes[node_idx, :, :], cmap=cmap, norm=norm,
                           transform=ccrs.PlateCarree(), zorder=2)
        ax.set_title(node_label, loc='left')
        ax.text(0.03, 0.92, '({})'.format(node_letters[i, j]), transform=ax.transAxes, fontsize=10, bbox=dict(facecolor='whitesmoke', edgecolor='lightgrey'), zorder=5)
        node_idx += 1
cb = fig.colorbar(pc, ax=axs[-1, :], label="hPa", shrink=0.4, orientation="horizontal")

# Wind roses
node_idx = 0
for i in range(nx_node):
    for j in range(ny_node):
        ax = axs[i, j]
        condition = som_node == (node_idx + 1) # som_node is 1-indexed
        # inset
        iax = ax.inset_axes([.35, .42, .3, .3], polar=True)
        iax.set_theta_zero_location('N') # theta=0 at the top
        iax.set_theta_direction(-1) # theta increasing clockwise
        iax.set_xticks(ticks=theta, labels=sorted_keys, fontsize=10)
        iax.set_yticks(ticks=[100, 200, 300, 400])
        # iax.set_ylim((0, 350))
        iax.set_yticklabels([])
        # plot
        counts_dict = Counter(da[condition].values) # dict of number of times each key (wind direction) appears in list
        counts_per_bin = [counts_dict[i] for i in sorted_keys] # total counts
        frac_per_bin = [100*counts_dict[i]/np.sum(condition) for i in sorted_keys] # as fraction of values in that node
        iax.bar(theta, counts_per_bin, width=2*np.pi/len(theta),
                lw=2, edgecolor='black', fill=False, zorder=2)
        # node frequency and count
        nfrac = 100 * np.sum(condition) / len(som_node) # based on NSA data window (2011-2023), not full SOM data (2000-2024)
        ncount = np.sum(condition)
        ax.annotate('{:.0f}%\nN={:.0f}'.format(nfrac, ncount), xy=(0.96, 0.96), xycoords='axes fraction',
                    ha='right', va='top',
                    fontsize=11, bbox=dict(boxstyle="square", fc='lightgrey', ec='grey', lw=2))
        node_idx += 1
# fig.suptitle('SLP anomaly pattern by SOM node\nand corresponding {:.0f} m wind direction at NSA'.format(z_wind))

# Save
save_filename = os.path.join(SAVE_DIR, 'fig05.png')
print('Save figure to:')
print('  ', save_filename)
plt.savefig(save_filename, bbox_inches='tight', dpi=300)
# plt.show()


### T/q profiles by SOM node ###

# T and q anomalies
da_T = sonde_data['tdry'] - sonde_data['tdry'].mean('time')
da_q = (sonde_data['q'] - sonde_data['q'].mean('time')) * 1000 # in g/kg
ticks_T = [-10, -5, 0, 5, 10]
ticks_q = [-1, -0.5, 0, 0.5, 1]

fig, axs = plt.subplots(nx_node, ny_node, figsize=(10, 9), layout='constrained')
fig.get_layout_engine().set(hspace=0.05) # add vertical space
node_letters = np.array([['a', 'b', 'c', 'd'],['e', 'f', 'g', 'h'],['i', 'j', 'k', 'l']])
for i in range(nx_node):
    for j in range(ny_node):
        ax = axs[i, j]
        node = ij2node[(i, j)]
        node_label = 'Node [{}, {}]'.format(j+1, i+1)
        condition = som_node == node # som_node is 1-indexed
        # Format
        ax.set(ylim=(0, 6), xlim=(-15, 15))
        ax.set_title(node_label, loc='left')
        ax.axvline(0, color='grey', lw=1)
        ax.text(0.03, 0.92, '({})'.format(node_letters[i, j]), transform=ax.transAxes, fontsize=10,
                bbox=dict(facecolor='whitesmoke', edgecolor='white'), zorder=5)
        # Temperature
        c = COLOR['gold']
        state = da_T[condition]
        ln1 = ax.plot(state.median('time'), state.height*M2KM, color=c, lw=3, label='Temperature,\nmedian')
        ln2 = ax.fill_betweenx(state.height*M2KM, np.nanpercentile(state, 25, axis=0),
                               np.nanpercentile(state, 75, axis=0), color=COLOR['gold'], alpha=0.2,
                               label='25$^{th}$ to 75$^{th}$\npercentile')
        # set tick/label colors
        ax.set_xticks(ticks_T)
        ax.spines['bottom'].set_color(c)
        ax.xaxis.label.set_color(c)
        ax.tick_params(axis='x', colors=c)
        # Sp Humidity
        c = COLOR['dark blue']
        ax2 = ax.twiny()
        state = da_q[condition]
        ln3 = ax2.plot(state.median('time'), state.height*M2KM, color=c, lw=3, label='Specific Humidity,\nmedian')
        ln4 = ax2.fill_betweenx(state.height*M2KM, np.nanpercentile(state, 25, axis=0),
                                np.nanpercentile(state, 75, axis=0), color=COLOR['dark blue'], alpha=0.2,
                               label='25$^{th}$ to 75$^{th}$\npercentile')
        ax2.set(xlim=(-1.5, 1.5))
        # set tick/label colors
        ax2.set_xticks(ticks_q)
        ax2.spines['top'].set_color(c)
        ax2.spines['bottom'].set_color(COLOR['gold'])
        ax2.xaxis.label.set_color(c)
        ax2.tick_params(axis='x', colors=c)
axs[1, 0].set(ylabel='Height (km)')
fig.text(0.5, -0.02, 'Specific Humidity (g kg$^{-1}$)', color=COLOR['dark blue'], ha='center', fontsize=12)
fig.text(0.5, -0.05, r'Temperature ($^{\circ}$C)', color=COLOR['gold'], ha='center', fontsize=12)
# fig.suptitle('Temperature and Specific Humidity Anomalies\nby SOM node', fontsize=18)
# combined legend
lns = ln1 + [ln2,] + ln3 + [ln4,]
labs = [l.get_label() for l in lns]
fig.legend(lns, labs, loc='lower left', bbox_to_anchor=(0.035, -0.09), ncols=2, fontsize=9)

# Save
save_filename = os.path.join(SAVE_DIR, 'fig06.pdf')
print('Save figure to:')
print('  ', save_filename)
plt.savefig(save_filename, bbox_inches='tight')
# plt.show()


### Cloud water by SOM node ###

class CloudWaterSOM:
    def __init__(self, da, color, label, units, ylim, axid):
        self.da = da
        self.color = color
        self.label = label
        self.units = units
        self.ylim = ylim
        self.axid = axid


# Box and whisker, LWP and IWP and PWV
LWP_params = CloudWaterSOM(water_data['be_lwp'], COLOR['dark blue'], 'LWP', 'g m$^{-2}$', (0, 160), 'A')
IWP_params = CloudWaterSOM(cloud_data['iwp'], COLOR['light blue'], 'IWP', 'g m$^{-2}$', (0, 1200), 'B')
PWV_params = CloudWaterSOM(water_data['be_pwv'], COLOR['dark green'], 'PWV', 'cm', (0, 1.2), 'C')
nintervals = 4

# Kolmogorov-Smirnov test
p_thresh = 0.05

# separate spacing w/i mosaics
mosaic_kw={'wspace': 0, 'hspace': 0}

fig = plt.figure(figsize=(10, 8), layout='constrained')
axs = fig.subfigures(nrows=nx_node, ncols=ny_node+1) # extra column for y-axis ticks
fig.get_layout_engine().set(wspace=0.07, hspace=0.07)
node_letters = np.array([['a', 'b', 'c', 'd'],['e', 'f', 'g', 'h'],['i', 'j', 'k', 'l']])
for i in range(nx_node):
    for j in range(ny_node):
        axd = axs[i, j+1].subplot_mosaic('ABC', gridspec_kw=mosaic_kw) # offset j to leave first column empty
        node = ij2node[(i, j)]
        # Ax title
        node_label = 'Node [{}, {}]'.format(j+1, i+1)
        axs[i, j+1].suptitle(node_label) # offset j to leave first column empty
        for params in [LWP_params, IWP_params, PWV_params]:
            ax = axd[params.axid]
            da = params.da
            l = params.label
            c = params.color
            pos = 1
            ybot = params.ylim[0] - 0.05*params.ylim[1] # shift bottom limit below 0
            ax.set(ylim=(ybot, params.ylim[1]))
            node_props = {
                'whiskerprops': {'linewidth': 2, 'color': c},
                'medianprops': {'linewidth': 2, 'color': c},
                'boxprops': {'facecolor': 'white', 'edgecolor': c, 'linewidth': 2},
                'capprops': {'color': c, 'linewidth': 2}
            }
            clim_props = {
                'whiskerprops': {'linewidth': 0.8, 'color': 'black'},
                'medianprops': {'linewidth': 0.8, 'color': 'black'},
                'boxprops': {'facecolor': 'white', 'edgecolor': 'black', 'linewidth': 0.8},
                'capprops': {'color': 'black', 'linewidth': 0.8}
            }
            # Node values
            node_condition = som_node == node # som_node is 1-indexed
            condition = np.logical_and(node_condition, ~clear_sky)
            state = da[condition]
            ax.boxplot(state[~np.isnan(state)], showfliers=False, positions=[pos],# tick_labels=[l], 
                       widths=0.3, whis=(10, 90), patch_artist=True, **node_props)
            # Climatology
            clim = da[~clear_sky]
            ax.boxplot(clim[~np.isnan(clim)], showfliers=False, positions=[pos+0.35],# tick_labels=[l+'\nClimatology'],
                       whis=(10, 90), patch_artist=True, **clim_props)
            # ticklabels
            ax.set_xticks([])
            ax.tick_params(axis='y', which='both', left=False)
            yticks = np.linspace(params.ylim[0], params.ylim[1], nintervals+1) # make sure this matches ticks set at end
            ax.set_yticks(yticks, ['']*len(yticks)) # visible tick markers but invisible tick labels
            ax.grid(True, axis='y')
            # check significance w/ K-S test
            kstest = ks_2samp(state, clim, nan_policy='omit')
            if kstest.pvalue < p_thresh:
                for spine in ax.spines.values():
                    spine.set(edgecolor=c, lw=2)
            else:
                ax.spines[['top', 'bottom', 'left', 'right']].set_visible(False)
        # custom legend
        custom_lines = [Line2D([0], [0], color=LWP_params.color, lw=3),
                        Line2D([0], [0], color=IWP_params.color, lw=3),
                        Line2D([0], [0], color=PWV_params.color, lw=3),
                        Line2D([0], [0], color='black', lw=1)]
        axs[1, 0].legend(custom_lines, ['LWP', 'IWP', 'PWV', '2011-2023 winters'], loc='center right', fontsize=14)#, loc=(0.05, 0.68))
        # shade semi-transparent for LWP
        axd['A'].axhspan(0, 40, color='black', alpha=0.07)
        # add panel label
        axd['A'].text(0.1, 0.92, '({})'.format(node_letters[i, j]), transform=axd['A'].transAxes, fontsize=10,
                      bbox=dict(facecolor='whitesmoke', edgecolor='white'), zorder=5)
# move yaxis ticks and labels
axfig = axs[0, 0]
ax = axfig.subplots(1, 1, gridspec_kw=mosaic_kw)
axfig.suptitle(' ', fontsize=8) # align top of spine with other plots
ax.set_xticks([])
ax.spines[['bottom', 'left', 'top']].set_visible(False) # keep y-axis only
LWP_yticks = np.linspace(LWP_params.ylim[0], LWP_params.ylim[1], nintervals+1).astype(int)
IWP_yticks = np.linspace(IWP_params.ylim[0], IWP_params.ylim[1], nintervals+1).astype(int)
PWV_yticks = np.linspace(PWV_params.ylim[0], PWV_params.ylim[1], nintervals+1)
# right-most: PWV
ax.set_ylim(LWP_params.ylim[0] - 0.05*LWP_params.ylim[1], LWP_params.ylim[1]) # align bottom with other axes
ax.set_yticks(LWP_yticks, labels=['{:.1f}'.format(t) for t in PWV_yticks])
ax.yaxis.tick_right()
ax.tick_params(axis='y', direction='in', pad=-27)
ax.yaxis.set_label_position("right")
ylabel = '{}\n({})'.format(PWV_params.label, PWV_params.units)
axfig.text(0.85, 1.07, ylabel, color=PWV_params.color, transform=ax.transAxes)
ax.tick_params(axis='y', colors=PWV_params.color)
# middle: IWP
sec = ax.secondary_yaxis(location=0.5)
sec.set_yticks(LWP_yticks, labels=IWP_yticks)
sec.spines['right'].set_visible(False) # hide spine
sec.tick_params(axis='y', length=0) # hide tick marks
ylabel = '  {}  \n({})'.format(IWP_params.label, IWP_params.units)
axfig.text(0.5, 1.07, ylabel, color=IWP_params.color, transform=ax.transAxes)
sec.tick_params(axis='y', colors=IWP_params.color)
# left-most: LWP
thi = ax.secondary_yaxis(location=0.2)
thi.set_yticks(LWP_yticks, labels=LWP_yticks)
thi.spines['right'].set_visible(False) # hide spine
thi.spines['left'].set_visible(False) # hide spine
thi.tick_params(axis='y', length=0) # hide tick marks
ylabel = '  {}  \n({})'.format(LWP_params.label, LWP_params.units)
axfig.text(0.2, 1.07, ylabel, color=LWP_params.color, transform=ax.transAxes)
thi.tick_params(axis='y', direction='in', pad=-25, colors=LWP_params.color)
# other formatting
# fig.suptitle('Atmo Moisture by SOM node')
# Save
save_filename = os.path.join(SAVE_DIR, 'fig07.pdf')
print('Save figure to:')
print('  ', save_filename)
plt.savefig(save_filename, bbox_inches='tight')
# plt.show()

############################
### Supplemental Figures ###
############################


### Instrument inter-comparison ###

# RH (and median value) at ceilometer first cbh
# First cbh distribution, ceil vs sonde
# LWP distribution during clear sky
save_filename = os.path.join(APPENDIX_SAVE_DIR, 'a01.pdf')

fig = plt.figure(figsize=(5, 9), layout='constrained')
axd = fig.subplot_mosaic('A;B;C')

# RH at ceil base
ax = axd['A']
RHw_at_ceil = sonde_data['rh'].interp(height=ceil_data['first_cbh'], method='linear')[~clear_sky]
mean_val = np.nanmean(RHw_at_ceil)
median_val = np.nanmedian(RHw_at_ceil)
print('RH at ceilometer first cloud base height:')
print('  Mean RH_w: {:.2f} %'.format(mean_val))
print('  Median RH_w: {:.2f} %'.format(median_val))
_ = ax.hist(RHw_at_ceil, np.arange(0, 115, 5), color=COLOR['grey'], edgecolor='white')
ax.axvline(mean_val, lw=2, ls='--', color=COLOR['dark blue'], label='Mean')
ax.axvline(median_val, lw=2, color=COLOR['dark blue'], label='Median')
ax.text(mean_val-2, 1100, '{:.0f}%'.format(mean_val), ha='right', color=COLOR['dark blue'])
ax.text(median_val+3, 1100, '{:.0f}%'.format(median_val), ha='left', color=COLOR['dark blue'])
# _ = ax.hist(sonde_data['rh_i'].isel(height=-1), 20)
# _ = ax.hist(max_radar_height, 20)
ax.set(xlabel='RH_w (%)', ylabel='Counts', title='RH$_{water}$ when at first ceilometer cloud base')
ax.text(0.02, 0.9, '(a)', transform=ax.transAxes, fontsize=12, bbox=dict(facecolor='whitesmoke', edgecolor='white'))

# Ceil vs sonde first cbh
ax = axd['B']
da1 = ceil_data['first_cbh']*M2KM
da2 = rhw_base_heights.sel(layer=1)*M2KM
b = np.arange(0, 6, 0.2)
_ = ax.hist(da1, b, density=False, histtype='step', color=COLOR['rust'], lw=3,
            label='Ceilometer, first cloud base height', zorder=2)
_ = ax.hist(da2, b, density=False, histtype='step', color=COLOR['dark blue'], lw=3,
            label='Sonde, first saturated layer height', zorder=1)
ax.set(xlabel='Height (km)', ylabel='Counts', title='First cloud base height: Ceilometer vs Radiosonde')
ax.text(0.02, 0.9, '(b)', transform=ax.transAxes, fontsize=12, bbox=dict(facecolor='whitesmoke', edgecolor='white', alpha=0.85))
ax.legend()

# LWP during clear sky
ax = axd['C']
da = water_data['be_lwp'][clear_sky]
_ = ax.hist(da, np.arange(-25, 25, 2), color=COLOR['grey'], edgecolor='white', zorder=2)
ax.grid(True, which='major', axis='x', zorder=1)
ax.set(xlabel='Liquid Water Path (g m$^{-2}$)', ylabel='Counts', title='LWP during clear sky conditions', xlim=(-25, 25))
ax.text(0.02, 0.9, '(c)', transform=ax.transAxes, fontsize=12, bbox=dict(facecolor='whitesmoke', edgecolor='white'))
print('LWP during clear sky:')
print('  mean {:.2f}, st dev {:.2f}'.format(da.mean('time'), da.std('time')))

# Save
print('Save figure to:')
print('  ', save_filename)
plt.savefig(save_filename, bbox_inches='tight')
# plt.show()


### DownLW vs LWP, mark LWP categories ###

save_filename = os.path.join(APPENDIX_SAVE_DIR, 'a02.pdf')
da1 = water_data['be_lwp']
da2 = rad_data['down_long_hemisp']
da_color = water_data['be_pwv']
all_valid = np.logical_and.reduce([~np.isnan(da1), ~np.isnan(da2), ~np.isnan(da_color)])

fig, ax = plt.subplots(1, 1)
# Thin
case = np.logical_and.reduce([all_valid, da1 < 10])
ax.scatter(da1[case], da2[case], color=lwp_colors[low_label])
t = ax.text(-7, 310, 'Indeterminate', ha='center', fontsize=12)
t.set_bbox(dict(facecolor='white', alpha=0.8, edgecolor=lwp_colors[low_label], lw=2))
# Semi-transparent
case = np.logical_and.reduce([all_valid, da1 >= 10, da1 <= 40])
ax.scatter(da1[case], da2[case], color=lwp_colors[mid_label])
t = ax.text(25, 290, 'Semi-transparent', ha='center', fontsize=12)
t.set_bbox(dict(facecolor='white', alpha=0.8, edgecolor=lwp_colors[mid_label], lw=2))
# Opaque
case = np.logical_and.reduce([all_valid, da1 > 40])
ax.scatter(da1[case], da2[case], color=lwp_colors[high_label])
t = ax.text(70, 310, 'Opaque', ha='center', fontsize=12)
t.set_bbox(dict(facecolor='white', alpha=0.8, edgecolor=lwp_colors[high_label], lw=2))
# format
ax.set(title='Downwelling LW vs LWP in winter at NSA', xlabel='LWP (g m$^{-2}$)', ylabel='Downwelling LW (W m$^{-2}$)',
       xlim=(-22, 100), ylim=(110, 330))
print('Save to:')
print('  ', save_filename)
plt.savefig(save_filename, bbox_inches='tight')
# plt.show()


### Grid of sigdiff for PWV cloud water distributions ###

save_filename = os.path.join(APPENDIX_SAVE_DIR, 'a05.pdf')
p_thresh = 0.05

# Store IWP/LWP distributions by PWV percentile
da1 = cloud_data['iwp']
da1_name = 'IWP'
da2 = water_data['be_lwp']
da2_name = 'LWP'
bin_value_da = water_data['be_pwv']
# bins in percentiles
percentile_width = 10
percentiles = np.arange(0, 100+percentile_width, percentile_width)
percentile_bins = [(i, i+percentile_width) for i in percentiles[:-1]]
# convert bins to value
values_at_percentile = np.nanpercentile(bin_value_da, percentiles)
# store values
da1_in_bin = []
da2_in_bin = []
for pbin in percentile_bins:
    low, high = np.nanpercentile(bin_value_da, pbin)
    in_bin = np.logical_and(bin_value_da > low, bin_value_da < high)
    # first DA
    values = da1[in_bin]
    da1_in_bin.append(values[~np.isnan(values)])
    # second DA
    values = da2[in_bin]
    da2_in_bin.append(values[~np.isnan(values)])

# Set up plot
binned_da = {'IWP': da1_in_bin, 'LWP': da2_in_bin}
sigdiff = {'IWP': 2 * np.ones((len(da1_in_bin), len(da1_in_bin))),
           'LWP': 2 * np.ones((len(da2_in_bin), len(da2_in_bin)))}
for label,da_in_bin in binned_da.items():
    for first_idx,first_distr in enumerate(da_in_bin):
        for second_idx,sec_distr in enumerate(da_in_bin):
            kstest_da1 = ks_2samp(first_distr, sec_distr, nan_policy='omit')
            if kstest_da1.pvalue < p_thresh:
                # significant difference
                sigdiff[label][first_idx, second_idx] = 1
            else:
                sigdiff[label][first_idx, second_idx] = 0
legend_elements = [Patch(facecolor='black', edgecolor='grey', label='Significantly Different'),
                   Patch(facecolor='white', edgecolor='grey', label='Indistinguishable'),
                   Patch(facecolor='white', edgecolor='grey', hatch='//', label='1-to-1 Line')]
# grey out symmetric side
stair_path = []
for x in np.arange(0, 100, 10):
    stair_path.append([x, x])
    stair_path.append([x+10, x])
full_path = Path(stair_path + [[100, 0], [0, 0]])

fig, axs = plt.subplots(1, 2, figsize=(10, 5), layout='constrained')
fig.suptitle('Significant differences between cloud water distributions\namong 10-percentile PWV bins', y=1.15)
fig.legend(handles=legend_elements, fontsize=11)

ax = axs[0]
pc = ax.pcolormesh(mid_bin_percent, mid_bin_percent, np.tril(sigdiff['IWP']), shading='nearest', cmap='Greys')
for ledge, redge in percentile_bins:
    ax.axhline(ledge, color='grey')
    ax.axvline(ledge, color='grey')
ax.set(title='For Ice Water Path Distributions', xlabel='PWV percentile bin', ylabel='PWV percentile bin')
ax.set_xticks(percentiles, labels=percentiles)
ax.set_yticks(percentiles, labels=percentiles)
ax.xaxis.tick_top()
ax.xaxis.set_label_position('top') 
# mark 1-1 line
for i in percentiles[:-1]:
    ax.add_patch(
        Rectangle((i, i), percentile_width, percentile_width,
            facecolor='none', edgecolor='grey', hatch='//', linewidth=0, zorder=3)
    )
patch = PathPatch(full_path, facecolor='grey', edgecolor='grey', zorder=10)
ax.add_patch(patch)
ax.text(0.02, 1.1, '(a)', transform=ax.transAxes, fontsize=12, bbox=dict(facecolor='whitesmoke', edgecolor='white'))

ax = axs[1]
pc = ax.pcolormesh(mid_bin_percent, mid_bin_percent, np.tril(sigdiff['LWP']), shading='nearest', cmap='Greys')
for ledge, redge in percentile_bins:
    ax.axhline(ledge, color='grey')
    ax.axvline(ledge, color='grey')
ax.set(title='For Liquid Water Path Distributions', xlabel='PWV percentile bin', ylabel='PWV percentile bin')
ax.set_xticks(percentiles, labels=percentiles)
ax.set_yticks(percentiles, labels=percentiles)
ax.xaxis.tick_top()
ax.xaxis.set_label_position('top')
# mark 1-1 line
for i in percentiles[:-1]:
    ax.add_patch(
        Rectangle((i, i), percentile_width, percentile_width,
            facecolor='none', edgecolor='grey', hatch='//', linewidth=0, zorder=3)
    )
patch = PathPatch(full_path, facecolor='grey', edgecolor='grey', zorder=10)
ax.add_patch(patch)
ax.text(0.02, 1.1, '(b)', transform=ax.transAxes, fontsize=12, bbox=dict(facecolor='whitesmoke', edgecolor='white'))

print('Save to:')
print('  ', save_filename)
plt.savefig(save_filename, bbox_inches='tight')
# plt.show()


### LWP vs SatDepth colored by IWP w/i saturated layers

save_filename = os.path.join(APPENDIX_SAVE_DIR, 'a04.pdf')
T_range = (-20, -10)
tsubset_df = lwp_df[np.logical_and(lwp_df['Temperature'] >= T_range[0], lwp_df['Temperature'] <= T_range[1])]

# Calculate adiabatic LWP (Matt's version)
sat_layer_base = tsubset_df['First Saturated Base Height'].values
# set characteristic cloud properties
base_temperatures = np.array([-20, -10])
pressure = np.nanmedian(sonde_data['pres'].sel(time=tsubset_df.index.values).sel(height=sat_layer_base, method='nearest').values) * 100 # Pa
mixrat = np.nanmedian(sonde_data['q'].sel(time=tsubset_df.index.values).sel(height=sat_layer_base, method='nearest').values) # kg/kg
temperature = base_temperatures + 273.15 # K
dz = 5
z = np.arange(0, 1500, dz) # m
z_da = xr.DataArray(z, dims=('sat_depth',), coords={'sat_depth': ('sat_depth', z)})
# Constants
kg2g = 1000 # convert kg to g
g = 9.80665 # m/s2
L_w = 2.52e6 # m2/s2
c_p = 1004.0 # m2/s2-K
R_v = 461.5 # J/kg-K
R_a = 287.1 # J/kg-K
rho_d = pressure / (temperature * R_a) # kg/m3; for dry air; rho = p / (T * R_specific) for ideal gas
rho_v = rho_d * mixrat # kg/m3; for water vapor
# LWP_adiabatic
A_1 = (g / temperature) * ((L_w / (c_p * R_v * temperature)) - (1 / R_a))
A_2 = (1 / rho_v) + (L_w**2 / (c_p * R_v * temperature**2 * rho_d))
A1_da = xr.DataArray(A_1, dims=('base_temp',), coords={'base_temp': ('base_temp', base_temperatures)})
A2_da = xr.DataArray(A_2, dims=('base_temp',), coords={'base_temp': ('base_temp', base_temperatures)})
adiabatic_lwp = (A1_da / A2_da) * (z_da**2) * kg2g

# IWP within liquid layer
liquid_base = rhw_base_heights.sel(layer=1)
liquid_top = rhw_top_heights.sel(layer=1)
radar_in_liquid = cloud_data.where(np.logical_and(cloud_data.height >= liquid_base, cloud_data.height <= liquid_top), np.nan)
iwp_in_liquid = radar_in_liquid['iwc'].fillna(0).integrate(coord='height')

# Scatter w/ shaded LWP_adiabatic
color_by = iwp_in_liquid.sel(time=tsubset_df.index) # relies on a cell above
cm = 'Blues'

fig, ax = plt.subplots(1, 1, figsize=(6, 4), layout='constrained')
sc = ax.scatter(tsubset_df['Saturated Depth'], tsubset_df['LWP'], c=color_by, cmap=cm, vmin=0, vmax=50, edgecolor='grey', lw=0.3)
ax.fill_between(adiabatic_lwp.sat_depth, adiabatic_lwp[0, :], adiabatic_lwp[1, :], color='grey', alpha=0.7, label='Adiabatic LWP')
ax.set(title='LWP vs Saturated Depth shaded by\nice mass within saturated layer', xlabel='Saturated Depth (m)',
       ylabel='LWP (g m$^{-2}$)',
       ylim=(-20, 250))
fig.colorbar(sc, ax=ax, extend='max', label='IWP (g m$^{-2}$)')
ax.legend()
print('Save to:')
print('  ', save_filename)
plt.savefig(save_filename, bbox_inches='tight')
# plt.show()


### Total cloud water path and PWV by PWV percentile, LWP vs IWP for 90th percentile ###
save_filename = os.path.join(APPENDIX_SAVE_DIR, 'a06.pdf')
da1 = water_data['be_pwv']
da1_name = 'PWV'
da2 = cloud_data['iwp'] + water_data['be_lwp']
da2_name = 'TWP'
bin_value_da = water_data['be_pwv']

# bins in percentiles
percentile_width = 10
percentiles = np.arange(0, 100+percentile_width, percentile_width)
percentile_bins = [(i, i+percentile_width) for i in percentiles[:-1]]
mid_bin_percent = percentiles[:-1] + (percentile_width / 2)

# Store values
da1_in_bin = []
da2_in_bin = []
for pbin in percentile_bins:
    low, high = np.nanpercentile(bin_value_da, pbin)
    in_bin = np.logical_and(bin_value_da > low, bin_value_da < high)
    # first DA
    values = da1[in_bin]
    da1_in_bin.append(values[~np.isnan(values)])
    # second DA
    values = da2[in_bin]
    da2_in_bin.append(values[~np.isnan(values)])

# Plot
da1_props = {'boxprops': dict(linewidth=2, color=COLOR['dark green']),
             'whiskerprops': dict(linewidth=2, color=COLOR['dark green']),
             'capprops': dict(linewidth=2, color=COLOR['dark green']),
             'medianprops': dict(linewidth=2, color=COLOR['dark green'])}
da2_props = {'boxprops': dict(linewidth=2, color='grey'),
             'whiskerprops': dict(linewidth=2, color='grey'),
             'capprops': dict(linewidth=2, color='grey'),
             'medianprops': dict(linewidth=2, color='grey')}


fig = plt.figure(layout="constrained", figsize=(10, 3.5))
axd = fig.subplot_mosaic('ABC')
# PWV
ax = axd['A']
ax.boxplot(da1_in_bin, positions=mid_bin_percent, showfliers=False, widths=5,
           whis=(10, 90), label=da1_name, **da1_props)
# format
ax.axhline(0, color='grey', lw=1)
ax.set_xticks(percentiles, labels=percentiles)
ax.set(title='PWV\nby PWV Percentile', xlabel='PWV Percentile Bins', ylabel='Precipitable Water Vapor (cm)',
      xlim=(0, 100), ylim=(0, 1.5))
ax.text(0.04, 0.92, '(a)', transform=ax.transAxes, fontsize=12, bbox=dict(facecolor='whitesmoke', edgecolor='white'))
# TWP
ax = axd['B']
ax.boxplot(da2_in_bin, positions=mid_bin_percent, showfliers=False, widths=4,
           whis=(10, 90), label=da2_name, **da2_props)
# format
ax.axhline(0, color='grey', lw=1)
ax.set_xticks(percentiles, labels=percentiles)
ax.set(title='Total Cloud Water\nby PWV Percentile', xlabel='PWV Percentile Bins', ylabel='Cloud Water Path (g/m2)',
      xlim=(0, 100), ylim=(-10, 1000))
ax.text(0.04, 0.92, '(b)', transform=ax.transAxes, fontsize=12, bbox=dict(facecolor='whitesmoke', edgecolor='white'))
# LWP vs IWP
ax = axd['C']
da3 = cloud_data['iwp']
da3_name = 'Ice Water Path (g m$^{-2}$)'
da4 = water_data['be_lwp']
da4_name = 'Liquid Water Path (g m$^{-2}$)'
# select bin to use
pbin = (90, 100)
low, high = np.nanpercentile(bin_value_da, pbin)
in_bin = np.logical_and(bin_value_da > low, bin_value_da < high)
# first DA
values = da3[in_bin]
da3_values = values[~np.isnan(values)]
# second DA
values = da4[in_bin]
da4_values = values[~np.isnan(values)]
ax.scatter(da3_values, da4_values, color=COLOR['grey'])
ax.set(title='LWP vs IWP\nabove {}th percentile of PWV'.format(pbin[0]), xlabel=da3_name, ylabel=da4_name,
       xlim=(-50, 2500), ylim=(-20, 300))
ax.text(0.04, 0.92, '(c)', transform=ax.transAxes, fontsize=12, bbox=dict(facecolor='whitesmoke', edgecolor='white', alpha=0.9))

print('Save to:')
print('  ', save_filename)
plt.savefig(save_filename, bbox_inches='tight')
# plt.show()


### Wind direction climatology at 500 m ###
save_filename = os.path.join(APPENDIX_SAVE_DIR, 'a07.pdf')
z_wind = 500
da = sonde_data['deg'].sel(height=z_wind, method='nearest')

fig, ax = plt.subplots(1, 1, figsize=(7, 4))
b = np.arange(0, 361, 15)
_ = ax.hist(da, b, zorder=2, color='grey', alpha=0.7)
# colored bands for each direction
ax.axvspan(0, 45, color=wind_colors['Southward'], alpha=0.4, zorder=1)
ax.axvspan(360-45, 360, color=wind_colors['Southward'], alpha=0.4, zorder=1)
ax.axvspan(90-45, 90+45, color=wind_colors['Westward'], alpha=0.4, zorder=1)
ax.axvspan(180-45, 180+45, color=wind_colors['Northward'], alpha=0.4, zorder=1)
ax.axvspan(270-45, 270+45, color=wind_colors['Eastward'], alpha=0.4, zorder=1)

t = ax.text(45/2, 400, 'South-\nward', ha='center', va='top', fontsize=12)
t.set_bbox(dict(facecolor='white', alpha=0.7, edgecolor='white'))
t = ax.text(90, 400, 'Westward', ha='center', va='top', fontsize=12)
t.set_bbox(dict(facecolor='white', alpha=0.7, edgecolor='white'))
t = ax.text(180, 400, 'Northward', ha='center', va='top', fontsize=12)
t.set_bbox(dict(facecolor='white', alpha=0.7, edgecolor='white'))
t = ax.text(270, 400, 'Eastward', ha='center', va='top', fontsize=12)
t.set_bbox(dict(facecolor='white', alpha=0.7, edgecolor='white'))
t = ax.text(360-(45/2), 400, 'South-\nward', ha='center', va='top', fontsize=12)
t.set_bbox(dict(facecolor='white', alpha=0.7, edgecolor='white'))

ax.set(title='NSA wintertime wind direction at {} m'.format(z_wind), xlabel='Direction (degrees)', ylabel='Counts',
       xlim=(0, 360))
# Save
print('Save figure to:')
print('  ', save_filename)
plt.savefig(save_filename, bbox_inches='tight')
# plt.show()


### By wind direction, all showing the same subset of cases ###
# Variant: FOR LIQUID-CONTAINING CASES WITH VALID LWP AND NO CLEAR-SKY ONLY
save_filename = os.path.join(APPENDIX_SAVE_DIR, 'a08.pdf')
case = np.logical_and.reduce([num_rhw_layers > 0, ~np.isnan(water_data['be_lwp']), ~clear_sky])

upper_layout = 'AB;CC'
lower_layout = 'EF'
profile_top = 6000 # m
p_thresh = 0.05 # for Kolmogorov-Smirnov

fig = plt.figure(figsize=(10, 11), layout='constrained')
top, bottom = fig.subfigures(nrows=2, ncols=1, height_ratios=[1, 0.4])
top_left, top_right = top.subfigures(nrows=1, ncols=2)
tl_axd = top_left.subplot_mosaic(upper_layout)
tr_axd = top_right.subplot_mosaic(upper_layout)
bot_axd = bottom.subplot_mosaic(lower_layout)
sf_map = {'Westward': tl_axd, 'Eastward': tl_axd, 'Southward': tr_axd, 'Northward': tr_axd}

# Temperature
pos = 'A'
da = sonde_data['tdry'].sel(height=slice(0, profile_top))
for name, condition in wind_cats.items():
    state = da[np.logical_and(condition, case)]
    ax = sf_map[name][pos]
    ax.plot(state.median('time'), state.height*M2KM, color=wind_colors[name], lw=3, label=name)
    ax.fill_betweenx(state.height*M2KM, np.nanpercentile(state, 25, axis=0),
                     np.nanpercentile(state, 75, axis=0), color=wind_colors[name], alpha=0.2)
for ax in [tl_axd[pos], tr_axd[pos]]:
    ax.plot(da[case].median('time'), da.height*M2KM, color='black', alpha=0.7, ls='--', lw=1.5, zorder=5, label='2011-2023\nwinter median')
    ax.set(title=r'Temperature ($^\circ$C)', ylabel='Height (km)', ylim=(0, profile_top*M2KM), xlim=(-45, 0))
    ax.set_xticks([-40, -30, -20, -10, 0])
    ax.legend(bbox_to_anchor=[0.01, 0.92], loc='upper left')
tl_axd[pos].text(0.05, 0.93, '(a)', transform=tl_axd[pos].transAxes, fontsize=12, bbox=dict(facecolor='whitesmoke', edgecolor='white'), zorder=5)
tr_axd[pos].text(0.05, 0.93, '(c)', transform=tr_axd[pos].transAxes, fontsize=12, bbox=dict(facecolor='whitesmoke', edgecolor='white'), zorder=5)


# Sp Humidity
pos = 'B'
da = sonde_data['q'].sel(height=slice(0, profile_top)) * 1000 # in g/kg
for name, condition in wind_cats.items():
    state = da[np.logical_and(condition, case)]
    ax = sf_map[name][pos]
    ax.plot(state.median('time'), state.height*M2KM, color=wind_colors[name], lw=3, label=name)
    ax.fill_betweenx(state.height*M2KM, np.nanpercentile(state, 25, axis=0),
                     np.nanpercentile(state, 75, axis=0), color=wind_colors[name], alpha=0.2)
for ax in [tl_axd[pos], tr_axd[pos]]:
    ax.plot(da[case].median('time'), da.height*M2KM, color='black', alpha=0.7, ls='--', lw=1.5, zorder=5)
    ax.set(title='Specific Humidity (g kg$^{-1}$)', ylim=(0, profile_top*M2KM), xlim=(0, 2))
    ax.set_yticks([])
    ax.set_xticks([0, 0.5, 1, 1.5])
tl_axd[pos].text(0.05, 0.93, '(b)', transform=tl_axd[pos].transAxes, fontsize=12, bbox=dict(facecolor='whitesmoke', edgecolor='white'), zorder=5)
tr_axd[pos].text(0.05, 0.93, '(d)', transform=tr_axd[pos].transAxes, fontsize=12, bbox=dict(facecolor='whitesmoke', edgecolor='white'), zorder=5)


# Cloud fraction
pos = 'C'
da = cld_mask.sel(height=slice(18, profile_top))
for name, condition in wind_cats.items():
    state = da[np.logical_and(condition, case)].astype(int)
    ax = sf_map[name][pos]
    ax.plot(state.sum('time')/len(state.time), state.height*M2KM, color=wind_colors[name], lw=3, ls='--',
            label=name+', radar hydrometeors')
for ax in [tl_axd[pos], tr_axd[pos]]:
    # Climatology
    ax.plot(da[case].astype(int).sum('time')/len(da[case].time), da.height*M2KM, color='black', alpha=0.7,
            ls='--', lw=1.5, zorder=5)
# Saturation
da = sonde_data['rh'].sel(height=slice(18, profile_top)) >= 95 # water; lots of NaNs below 18m
for name, condition in wind_cats.items():
    state = da[np.logical_and(condition, case)].astype(int)
    ax = sf_map[name][pos]
    ax.plot(state.sum('time')/len(state.time), state.height*M2KM, color=wind_colors[name],
            lw=2, label=name+r', RH$_{water}>$95%')
for ax in [tl_axd[pos], tr_axd[pos]]:
    # Climatology
    ax.plot(da[case].astype(int).sum('time')/len(da[case].time), da.height*M2KM, color='black', alpha=0.7,
            ls='-', lw=1, zorder=5)
# format
for ax in [tl_axd[pos], tr_axd[pos]]:
    ax.set(title='Cloud Fraction', xlim=(0, 1), ylabel='Height (km)', ylim=(0, profile_top*M2KM))
    ax.legend(loc='upper right')
tl_axd[pos].text(0.01, 1.04, '(e)', transform=tl_axd[pos].transAxes, fontsize=12, bbox=dict(facecolor='whitesmoke', edgecolor='white'))
tr_axd[pos].text(0.01, 1.04, '(f)', transform=tr_axd[pos].transAxes, fontsize=12, bbox=dict(facecolor='whitesmoke', edgecolor='white'))

# LWP
ax = bot_axd['E']
da = water_data['be_lwp']
pos = [5, 10, 15, 20, 25]
labels = ['Southward', '\nWestward', 'Northward', '\nEastward', '2011-2023 winter mean']
# for climatology
idx = -1
prop = {'boxprops': dict(linewidth=1.5, color='black', alpha=0.7, linestyle='--'),
        'whiskerprops': dict(linewidth=1.5, color='black', alpha=0.7, linestyle='--'),
        'capprops': dict(linewidth=1.5, color='black', alpha=0.7, linestyle='--'),
        'medianprops': dict(linewidth=1.5, color='black', alpha=0.7, linestyle='--')}
clim_values = [da[case],]
ax.boxplot(clim_values, positions=[pos[idx],], showfliers=False, widths=3,
           whis=(10, 90), zorder=2, **prop)
# by wind category
idx = 0
labels = []
for name, condition in wind_cats.items():
    values = [da[np.logical_and(condition, case)],]
    # K-S test for significance
    kstest = ks_2samp(values[0], clim_values[0], nan_policy='omit')
    if kstest.pvalue < p_thresh:
        lw = 3
        labels.append(name+'*')
    else:
        lw = 1
        labels.append(name)
    # properties
    prop = {'boxprops': dict(linewidth=lw, color=wind_colors[name]),
            'whiskerprops': dict(linewidth=lw, color=wind_colors[name]),
            'capprops': dict(linewidth=lw, color=wind_colors[name]),
            'medianprops': dict(linewidth=lw, color=wind_colors[name])}
    # values
    ax.boxplot(values, positions=[pos[idx],], showfliers=False, widths=3,
               whis=(10, 90), zorder=2, **prop)
    idx = idx + 1
# formatting
labels = labels + ['2011-2023\nwinters',]
# stagger every other label
labels[1] = '\n'+labels[1]
labels[3] = '\n'+labels[3]
ax.set_xticks(pos, labels=labels)
ax.axhline(0, color='grey', lw=1, zorder=1)
ax.set(title='Liquid Water Path', ylabel='Water Path (g m$^{-2}$)')
ax.text(0.01, 1.06, '(g)', transform=ax.transAxes, fontsize=12, bbox=dict(facecolor='whitesmoke', edgecolor='white'))

# IWP
ax = bot_axd['F']
da = cloud_data['iwp']
pos = [5, 10, 15, 20, 25]
# for climatology
idx = -1
prop = {'boxprops': dict(linewidth=1.5, color='black', alpha=0.7, linestyle='--'),
        'whiskerprops': dict(linewidth=1.5, color='black', alpha=0.7, linestyle='--'),
        'capprops': dict(linewidth=1.5, color='black', alpha=0.7, linestyle='--'),
        'medianprops': dict(linewidth=1.5, color='black', alpha=0.7, linestyle='--')}
clim_values = [da[case],]
ax.boxplot(clim_values, positions=[pos[idx],], showfliers=False, widths=3,
           whis=(10, 90), zorder=2, **prop)
# by wind category
idx = 0
labels = []
for name, condition in wind_cats.items():
    values = [da[np.logical_and(condition, case)],]
    # K-S test for significance
    kstest = ks_2samp(values[0], clim_values[0], nan_policy='omit')
    if kstest.pvalue < p_thresh:
        lw = 3
        labels.append(name+'*')
    else:
        lw = 1
        labels.append(name)
    # properties
    prop = {'boxprops': dict(linewidth=lw, color=wind_colors[name]),
            'whiskerprops': dict(linewidth=lw, color=wind_colors[name]),
            'capprops': dict(linewidth=lw, color=wind_colors[name]),
            'medianprops': dict(linewidth=lw, color=wind_colors[name])}
    # plot
    ax.boxplot(values, positions=[pos[idx],], showfliers=False, widths=3,
               whis=(10, 90), zorder=2, **prop)
    idx = idx + 1
# formatting
labels = labels + ['2011-2023\nwinters',]
# stagger every other label
labels[1] = '\n'+labels[1]
labels[3] = '\n'+labels[3]
fig.suptitle('Subset of Liquid-Containing Cases:\nat least one saturated layer, LWP is not NaN, no clear-sky')
ax.set_xticks(pos, labels=labels)
ax.axhline(0, color='grey', lw=1, zorder=1)
ax.set(title='Ice Water Path')
ax.text(0.01, 1.06, '(h)', transform=ax.transAxes, fontsize=12, bbox=dict(facecolor='whitesmoke', edgecolor='white'))

# Save
print('Save figure to:')
print('  ', save_filename)
plt.savefig(save_filename, bbox_inches='tight')
# plt.show()


### Ice above vs in vs below liquid ###

save_filename = os.path.join(APPENDIX_SAVE_DIR, 'a10.pdf')
# case = num_rhw_layers == 1
case = np.ones(len(sonde_data.time)).astype(bool)
no_data = num_rhw_layers < 1 # will fill these with NaN at end
layer_case = {'A': ('LOWEST', 1), # lowest saturated layer
              'B': ('HIGHEST', num_rhw_layers.where(~no_data, 1))} # highest; if no layers, use fill, then replace with NaN

fig = plt.figure(layout="constrained", figsize=(10, 4))
axd = fig.subplot_mosaic('AB')
for axidx, tup in layer_case.items():
    ax = axd[axidx]
    name, layer_select = tup
    liquid_base = rhw_base_heights.sel(layer=layer_select)
    liquid_top = rhw_top_heights.sel(layer=layer_select)
    # EITHER lowest layer
    # liquid_base = rhw_base_heights.sel(layer=1)
    # liquid_top = rhw_top_heights.sel(layer=1)
    # OR highest layer
    # nlayer = num_rhw_layers.where(~no_data, 1) # if no layers, use fill (will replace output at end with NaN)
    # liquid_base = rhw_base_heights.sel(layer=nlayer)
    # liquid_top = rhw_top_heights.sel(layer=nlayer)
    
    radar_below_liquid = cloud_data.where(cloud_data.height < liquid_base, np.nan)
    radar_in_liquid = cloud_data.where(np.logical_and(cloud_data.height >= liquid_base, cloud_data.height <= liquid_top), np.nan)
    radar_above_liquid = cloud_data.where(cloud_data.height > liquid_top, np.nan)
    
    # Convert reflectivity to IWP
    iwp_below_liquid_init = radar_below_liquid['iwc'].fillna(0).integrate(coord='height')
    iwp_in_liquid_init = radar_in_liquid['iwc'].fillna(0).integrate(coord='height')
    iwp_above_liquid_init = radar_above_liquid['iwc'].fillna(0).integrate(coord='height')
    # get rid of values when no saturated layers are present
    iwp_below_liquid = iwp_below_liquid_init.where(~no_data, np.nan)
    iwp_in_liquid = iwp_in_liquid_init.where(~no_data, np.nan)
    iwp_above_liquid = iwp_above_liquid_init.where(~no_data, np.nan)
    
    # Plot vs PWV percentile
    da1 = iwp_below_liquid[case]
    da1_name = 'Below'
    da2 = iwp_in_liquid[case]
    da2_name = 'Inside'
    da3 = iwp_above_liquid[case]
    da3_name = 'Above'
    og_bin_value_da = water_data['be_pwv']
    bin_value_da = og_bin_value_da[case]
    # bins in percentiles
    percentile_width = 10
    percentiles = np.arange(0, 100+percentile_width, percentile_width)
    percentile_bins = [(i, i+percentile_width) for i in percentiles[:-1]]
    mid_bin_percent = percentiles[:-1] + (percentile_width / 2)
    # Store values
    da1_in_bin = []
    da2_in_bin = []
    da3_in_bin = []
    for pbin in percentile_bins:
        low, high = np.nanpercentile(og_bin_value_da, pbin)
        in_bin = np.logical_and(bin_value_da > low, bin_value_da < high)
        # first DA
        values = da1[in_bin]
        da1_in_bin.append(values[~np.isnan(values)])
        # second DA
        values = da2[in_bin]
        da2_in_bin.append(values[~np.isnan(values)])
        # third DA
        values = da3[in_bin]
        da3_in_bin.append(values[~np.isnan(values)])
    
    # Plot
    cm = plt.cm.Greys
    da1_props = {'boxprops': dict(linewidth=2, color=cm(0.3)),
                 'whiskerprops': dict(linewidth=2, color=cm(0.3)),
                 'capprops': dict(linewidth=2, color=cm(0.3)),
                 'medianprops': dict(linewidth=2, color=cm(0.3))}
    da2_props = {'boxprops': dict(linewidth=2, color=cm(0.6)),
                 'whiskerprops': dict(linewidth=2, color=cm(0.6)),
                 'capprops': dict(linewidth=2, color=cm(0.6)),
                 'medianprops': dict(linewidth=2, color=cm(0.6))}
    da3_props = {'boxprops': dict(linewidth=2, color=cm(1.0)),
                 'whiskerprops': dict(linewidth=2, color=cm(1.0)),
                 'capprops': dict(linewidth=2, color=cm(1.0)),
                 'medianprops': dict(linewidth=2, color=cm(1.0))}
    # Below
    ax.boxplot(da1_in_bin, positions=mid_bin_percent-2, showfliers=False, widths=1.5,
               whis=(10, 90), label=da1_name, **da1_props)
    # Inside
    ax.boxplot(da2_in_bin, positions=mid_bin_percent, showfliers=False, widths=1.5,
               whis=(10, 90), label=da2_name, **da2_props)
    # Above
    ax.boxplot(da3_in_bin, positions=mid_bin_percent+2, showfliers=False, widths=1.5,
               whis=(10, 90), label=da3_name, **da3_props)
    # format
    ax.axhline(0, color='grey', lw=1)
    ax.set_xticks(percentiles, labels=percentiles)
    ax.set(title='IWP above, in, and below {} saturated layer'.format(name),
           xlabel='PWV Percentile Bins', ylabel='Ice Water Path (g m$^{-2}$)',
          xlim=(0, 100), ylim=(-10, 425))
axd['A'].text(0.02, 0.93, '(a)', transform=axd['A'].transAxes, fontsize=12, bbox=dict(facecolor='whitesmoke', edgecolor='white'))
axd['A'].legend(loc='upper left', bbox_to_anchor=(0.02, 0.9))
axd['B'].text(0.02, 0.93, '(b)', transform=axd['B'].transAxes, fontsize=12, bbox=dict(facecolor='whitesmoke', edgecolor='white'))

print('Save figure to:')
print('  ', save_filename)
plt.savefig(save_filename, bbox_inches='tight')
# plt.show()



### Precip into highest liquid-containing layer ###

save_filename = os.path.join(APPENDIX_SAVE_DIR, 'a11.pdf')
offset_list = [30, 130, 230]
# offset_labels = {0: 'At liquid layer top', 90: '90 m above', 180: '180 m above'}
offset_labels = {x: '{} m above'.format(x) for x in offset_list}

# bins in percentiles
percentile_width = 10
percentiles = np.arange(0, 100+percentile_width, percentile_width)
percentile_bins = [(i, i+percentile_width) for i in percentiles[:-1]]
mid_bin_percent = percentiles[:-1] + (percentile_width / 2)
bin_value_da = water_data['be_pwv']
dh = np.mean(np.diff(cloud_data.height))

frac_by_offset = {}
for offset in offset_list:
    # Get radar value at saturated layer top
    # had to de-vectorize; something is going wrong in single-line version, too many NaNs
    nlayers = []
    nwithice = []
    for t in cloud_data.time:
        nlayer = num_rhw_layers.sel(time=t).item()
        if nlayer == 0:
            layer_count = 0
            num_with_ice = 0
        else:
            top = rhw_top_heights.sel(time=t, layer=nlayer) # highest layer
            # top = rhw_top_heights.sel(time=t, layer=1) # lowest layer
            if top < cloud_data.height.min():
                # skip if layer too low for radar to see
                layer_count = 0
                num_with_ice = 0
            else:
                layer_count = 1
                r = cloud_data['unmasked_reflectivity'].sel(time=t).sel(height=top+offset, method='ffill').item() ### NEAREST BELOW
                # r = cloud_data['unmasked_reflectivity'].sel(time=t).interp(height=top+offset).item() ### INTERP
                num_with_ice = 1 if ~np.isnan(r) else 0
        nlayers.append(layer_count)
        nwithice.append(num_with_ice)
    num_counted_layers = np.array(nlayers)
    num_with_ice = np.array(nwithice)
    # For each PWV bin, what fraction of liquid layers have ice falling in from above?
    frac_falling_ice = []
    for pbin in percentile_bins:
        low, high = np.nanpercentile(bin_value_da, pbin)
        # restrict both by bin and by whether there are any liquid layers
        in_bin = np.logical_and.reduce([bin_value_da > low, bin_value_da < high, num_rhw_layers > 0])
        nlayers_in_bin = np.sum(num_counted_layers[in_bin])
        nwithice_in_bin = np.sum(num_with_ice[in_bin])
        frac = 100 * nwithice_in_bin/nlayers_in_bin
        frac_falling_ice.append(frac)
    frac_by_offset[offset] = frac_falling_ice

fig, ax = plt.subplots(1, 1, figsize=(6, 4))
cmap = plt.cm.Greys_r
colors = cmap(np.linspace(0.1, 0.7, len(offset_list)))
for idx,offset in enumerate(offset_list):
    if idx == 0:
        print('{} m: % have ice precip:'.format(offset))
        print(['{:.2f} %'.format(x) for x in frac_by_offset[offset]])
    ax.scatter(mid_bin_percent, frac_by_offset[offset], color=colors[idx], label=offset_labels[offset])
ax.set_xticks(percentiles, labels=percentiles)
ax.set(title='What fraction of HIGHEST saturated layers have hydrometeors directly above?',
       ylim=(0, 100), xlabel='PWV percentile bin', ylabel='Percent')
ax.legend(loc='upper left')
print('Save figure to:')
print('  ', save_filename)
plt.savefig(save_filename, bbox_inches='tight')
# plt.show()


### Conditions during PWV>90th vs climatology ###

save_filename = os.path.join(APPENDIX_SAVE_DIR, 'a09.pdf')
case_da = water_data['be_pwv']
thresh = np.nanpercentile(case_da, 90)
case = case_da >= thresh

fig = plt.figure(layout="constrained", figsize=(10, 5))
axd = fig.subplot_mosaic('ABCD', sharey=True)
# Moisture
da = sonde_data['q'].sel(height=slice(0, 6000)) * 1000 # in g/kg
ax = axd['A']
ax.plot(da.median('time'), da.height*M2KM, color='black', ls='--', lw=2, label='2011-2023 winter median')
ax.fill_betweenx(da.height*M2KM, np.nanpercentile(da, 25, axis=0), np.nanpercentile(da, 75, axis=0),
                 color='black', alpha=0.2, label=r'25$^{th}$ to 75$^{th}$ percentile')
ax.plot(da[case].median('time'), da.height*M2KM, color=COLOR['dark green'], lw=2, label='PWV>90th')
ax.fill_betweenx(da.height*M2KM, np.nanpercentile(da[case], 25, axis=0), np.nanpercentile(da[case], 75, axis=0),
                 color=COLOR['dark green'], alpha=0.2, label=r'25$^{th}$ to 75$^{th}$ percentile')
ax.set(title='Moisture', ylim=(0, 6), ylabel='Height (km)', xlabel='q (g kg$^{-1}$)')
ax.legend(loc='upper left')
ax.text(0.02, 1.03, '(a)', transform=ax.transAxes, fontsize=12, bbox=dict(facecolor='whitesmoke', edgecolor='white'))

# RH
da = sonde_data['rh'].sel(height=slice(0, 6000))
ax = axd['B']
ax.plot(da.median('time'), da.height*M2KM, color='black', ls='--', lw=2, label='2011-2023 winter median')
ax.fill_betweenx(da.height*M2KM, np.nanpercentile(da, 25, axis=0), np.nanpercentile(da, 75, axis=0),
                 color='black', alpha=0.2, label=r'25$^{th}$ to 75$^{th}$ percentile')
ax.plot(da[case].median('time'), da.height*M2KM, color=COLOR['dark green'], lw=2, label='PWV>90th')
ax.fill_betweenx(da.height*M2KM, np.nanpercentile(da[case], 25, axis=0), np.nanpercentile(da[case], 75, axis=0),
                 color=COLOR['dark green'], alpha=0.2, label=r'25$^{th}$ to 75$^{th}$ percentile')
ax.set(title='Relative Humidity', ylim=(0, 6), xlim=(0, 100), xlabel='RH (%)')
ax.text(0, 1.03, '(b)', transform=ax.transAxes, fontsize=12, bbox=dict(facecolor='whitesmoke', edgecolor='white'))

# Saturated layer fraction
da = sonde_data['rh'].sel(height=slice(18, 6000)) >= 95 # water; lots of NaNs below 18m
ax = axd['C']
clim = da.astype(int)
ax.plot(clim.sum('time')/len(clim.time), clim.height*M2KM, color='black', ls='--', lw=2, label='2011-2023 winter mean')
this_case = da[case].astype(int)
ax.plot(this_case.sum('time')/len(this_case.time), this_case.height*M2KM, color=COLOR['dark green'], lw=2, label='PWV>90th')
ax.set(title='Liquid-containing\nCloud Fraction', ylim=(0, 6), xlim=(0, 1), xlabel='Fraction')
# ax.axhline(350, lw=2) # look for peak occurrence
ax.text(0, 1.03, '(c)', transform=ax.transAxes, fontsize=12, bbox=dict(facecolor='whitesmoke', edgecolor='white'))

# Cloud fraction
da = cld_mask
ax = axd['D']
clim = da.astype(int)
ax.plot(clim.sum('time')/len(clim.time), clim.height*M2KM, color='black', ls='--', lw=2, label='2011-2023 winter mean')
this_case = da[case].astype(int)
ax.plot(this_case.sum('time')/len(this_case.time), this_case.height*M2KM, color=COLOR['dark green'], lw=2, label='PWV>90th')
ax.set(title='Cloud Fraction', ylim=(0, 6), xlim=(0, 1), xlabel='Fraction')
ax.text(0.02, 1.03, '(d)', transform=ax.transAxes, fontsize=12, bbox=dict(facecolor='whitesmoke', edgecolor='white'))

# Save
print('Save figure to:')
print('  ', save_filename)
plt.savefig(save_filename, bbox_inches='tight')
# plt.show()


### LWP distributions by cloud base temperature bin ###

save_filename = os.path.join(APPENDIX_SAVE_DIR, 'a03.pdf')
# Combined LWP by cbT bins
lwp_props = dict(linewidth=2, color='black')
lwp_median = dict(linewidth=2, color='black')
# bins in T value
bin_width = 5
cbT_bin_edges = np.arange(-40, 0+bin_width, bin_width)
mid_bin_value = cbT_bin_edges[:-1] + bin_width/2
# define datasets
cb_temperature = lwp_df['Temperature']
lwp_values = lwp_df['LWP']

# Store values
da_in_bin = []
counts_per_bin = []
for bin_idx in range(len(cbT_bin_edges)-1):
    bin_left = cbT_bin_edges[bin_idx]
    bin_right = cbT_bin_edges[bin_idx+1]
    in_cbT_bin = np.logical_and(cb_temperature >= bin_left, cb_temperature < bin_right)
    # LWP
    values = lwp_values[in_cbT_bin]
    valid_values = values[~np.isnan(values)]
    da_in_bin.append(valid_values)
    counts_per_bin.append(len(valid_values))

# Set up sig diff
p_thresh = 0.05
sigdiff = 2 * np.ones((len(da_in_bin), len(da_in_bin)))
for first_idx,first_distr in enumerate(da_in_bin):
    for second_idx,sec_distr in enumerate(da_in_bin):
        kstest_da1 = ks_2samp(first_distr, sec_distr, nan_policy='omit')
        if kstest_da1.pvalue < p_thresh:
            # significant difference
            sigdiff[first_idx, second_idx] = 1
        else:
            sigdiff[first_idx, second_idx] = 0
legend_elements = [Patch(facecolor='black', edgecolor='grey', label='Significantly Different'),
                   Patch(facecolor='white', edgecolor='grey', label='Indistinguishable'),
                   Patch(facecolor='white', edgecolor='grey', hatch='//', label='1-to-1 Line')]
# grey out symmetric side
stair_path = []
for x in np.arange(cbT_bin_edges[0], cbT_bin_edges[-1] + bin_width, bin_width):
    stair_path.append([x, x])
    stair_path.append([x+bin_width, x])
full_path = Path(stair_path + [[cbT_bin_edges[-1], cbT_bin_edges[0]], [cbT_bin_edges[0], cbT_bin_edges[0]]])

# Plot
layout = 'AB'
fig = plt.figure(layout="constrained", figsize=(10, 4))
axd = fig.subplot_mosaic(layout, width_ratios=(1, 0.75))

# LWP boxplots
ax = axd['A']
ax.boxplot(da_in_bin, positions=mid_bin_value, showfliers=False, widths=1,
           whis=(10, 90), boxprops=lwp_props, medianprops=lwp_median, zorder=3)
ax.axhline(10, c=sns.color_palette('colorblind')[7], lw=2, zorder=2)
ax.text(-42, 10, '10', color=sns.color_palette('colorblind')[7])
ax.axhspan(10, 40, color=sns.color_palette('colorblind')[9], alpha=0.2, zorder=1)
ax.axhline(40, c=sns.color_palette('colorblind')[0], lw=2, zorder=2)
ax.text(-42, 40, '40', va='top', color=sns.color_palette('colorblind')[0])
ax.set(title='LWP by Cloud Base Temperature Bins\n', ylabel='Liquid Water Path (g m$^{-2}$)', xlabel=r'Cloud Base Temperature ($^{\circ}$C)',
       xlim=(cbT_bin_edges[0], cbT_bin_edges[-1]), ylim=(-10, 260))
ax.set_xticks(cbT_bin_edges, labels=cbT_bin_edges)
# add counts per bin above
for idx in range(len(counts_per_bin)):
    ax.text(mid_bin_value[idx], 265, '{:.0f}'.format(counts_per_bin[idx]), ha='center', color='grey')
ax.text(-43, 265, 'Counts\nper bin', ha='center', color='grey')

# Sig Diff matrix
ax = axd['B']
# mark 1-1 line
for i in cbT_bin_edges[:-1]:
    ax.add_patch(
        Rectangle((i, i), bin_width, bin_width,
            facecolor='none', edgecolor='grey', hatch='//', linewidth=0, zorder=3)
    )

pc = ax.pcolormesh(mid_bin_value, mid_bin_value, np.tril(sigdiff), shading='nearest', cmap='Greys', zorder=2)
for edge in cbT_bin_edges:
    ax.axhline(edge, color='grey')
    ax.axvline(edge, color='grey')
ax.set(title='Significant differences between LWP distributions\namong bins of cloud base temperature', xlabel='Cloud base temperature bin', ylabel='Cloud base temperature bin')
ax.set_xticks(cbT_bin_edges, labels=cbT_bin_edges)
ax.set_yticks(cbT_bin_edges, labels=cbT_bin_edges)
ax.xaxis.tick_top()
ax.xaxis.set_label_position('top') 
patch = PathPatch(full_path, facecolor='grey', edgecolor='grey', zorder=5)
ax.add_patch(patch)
ax.legend(handles=legend_elements, bbox_to_anchor=(0.42, 0.03))

# Save
print('Save figure to:')
print('  ', save_filename)
plt.savefig(save_filename, bbox_inches='tight')
# plt.show()
