#!/usr/bin/env python

# Plot land-use over the UK

import os
import sys
import numpy as np

import iris
import iris.analysis

import matplotlib
from matplotlib.backends.backend_agg import FigureCanvasAgg as FigureCanvas
from matplotlib.figure import Figure

import cmocean

# Define the region to plot
latMin = -0.6
latMax = 0.6
lonMin = -.375
lonMax = .425
pole_latitude = 35
pole_longitude = 175
aspect = (lonMax - lonMin) / (latMax - latMin)

fig = Figure(
    figsize=(24, 36),  # Width, Height (inches)
    dpi=300,
    facecolor=(0.5, 0.5, 0.5, 1),
    edgecolor=None,
    linewidth=0.0,
    frameon=False,
    subplotpars=None,
    tight_layout=None,
)
canvas = FigureCanvas(fig)
font = {"family": "sans-serif", "sans-serif": "Arial", "weight": "normal", "size": 16}
matplotlib.rc("font", **font)
axb = fig.add_axes([0, 0, 1, 1])

# Map with background
ax_map = fig.add_axes([0.0, 0.0, 1.0, 1.0], facecolor="white")
ax_map.set_axis_off()
ax_map.set_ylim(latMin, latMax)
ax_map.set_xlim(lonMin, lonMax)
ax_map.set_aspect("auto")

# Make a dummy iris Cube for plotting.
# Makes a cube in equirectangular projection.
# Takes resolution, plot range, and pole location
#  (all in degrees) as arguments, returns an
#  iris cube.
def plot_cube(
    resolution,
    xmin=-10,
    xmax=10,
    ymin=-10,
    ymax=10,
    pole_latitude=35,
    pole_longitude=180,
    npg_longitude=0,
):

    cs = iris.coord_systems.RotatedGeogCS(pole_latitude, pole_longitude, npg_longitude)
    lat_values = np.arange(ymin, ymax + resolution, resolution)
    latitude = iris.coords.DimCoord(
        lat_values, standard_name="latitude", units="degrees_north", coord_system=cs
    )
    lon_values = np.arange(xmin, xmax + resolution, resolution)
    longitude = iris.coords.DimCoord(
        lon_values, standard_name="longitude", units="degrees_east", coord_system=cs
    )
    dummy_data = np.zeros((len(lat_values), len(lon_values)))
    plot_cube = iris.cube.Cube(
        dummy_data, dim_coords_and_dims=[(latitude, 0), (longitude, 1)]
    )
    return plot_cube


# Turn a grey colourmap into a colour ramp
def recolourMap(col):
    gcm = cmocean.cm.gray
    nm = []
    for fr in np.linspace(0, 1, 20):
        gc = gcm(fr)
        nc = (
            col[0] + (1 - col[0]) * (gc[0]),
            col[1] + (1 - col[1]) * (gc[1]),
            col[2] + (1 - col[2]) * (gc[2]),
            gc[3],
        )
        nm.append(nc)
    return matplotlib.colors.ListedColormap(nm)


coord_s = iris.coord_systems.GeogCS(iris.fileformats.pp.EARTH_RADIUS)
orog = iris.load_cube(
    "%s/rivers/ETOPO1_Ice_g_gmt4.grd" % os.getenv("SCRATCH"),
    iris.Constraint(latitude=lambda cell: 45 < cell < 65)
    & iris.Constraint(longitude=lambda cell: -15 < cell < 5),
)
orog.coord("latitude").coord_system = coord_s
orog.coord("longitude").coord_system = coord_s
pc = plot_cube(0.0002, lonMin, lonMax, latMin, latMax, pole_latitude, pole_longitude)
orog = orog.regrid(pc, iris.analysis.Linear())
omax = orog.data.max()
lats = orog.coord("latitude").points
lons = orog.coord("longitude").points
mask_img = ax_map.pcolorfast(
    lons,
    lats,
    orog.data + np.random.uniform(0.0, 10.0, orog.data.shape),
    cmap=cmocean.cm.gray,
    vmin=-10,
    vmax=omax,
    alpha=1.0,
    zorder=20,
)
# Get sea from the land cover data
lct = iris.load_cube(
    "/scratch/hadpb/rivers/PROBAV_LC100_global_v3.0.1_2019-nrt_Discrete-Classification-map_EPSG-4326.nc",
    iris.Constraint(latitude=lambda cell: 45 < cell < 65)
    & iris.Constraint(longitude=lambda cell: -15 < cell < 5),
)
lct.data[(lct.data == 200) | (lct.data == 80) | (lct.data == 90)] = 0
lct.data[lct.data != 0] = 1
lct.coord("latitude").coord_system = coord_s
lct.coord("longitude").coord_system = coord_s
lcr = lct.regrid(pc, iris.analysis.Nearest())
osea = orog.copy()
osea.data[osea.data >0] = 0
osea.data[osea.data <-200] = -200
osea.data=np.sqrt(osea.data*-1)*-1

sea_img = ax_map.pcolorfast(
    lons,
    lats,
    np.ma.masked_array(
        osea.data + np.random.uniform(0.0, 10, osea.data.shape), lcr.data
    ),
    cmap=recolourMap([0, 0, 0.5]),
    vmax=20,
    alpha=1.0,
    zorder=40,
)

# Maximise the land orography contrast
orog.data[lcr.data == 0] = 0
orog.data[orog.data < 0] = 0
orog.data=np.sqrt(orog.data)
omax = orog.data.max()*1.1

# Get forest
lct = iris.load_cube(
    "/scratch/hadpb/rivers/PROBAV_LC100_global_v3.0.1_2019-nrt_Discrete-Classification-map_EPSG-4326.nc",
    iris.Constraint(latitude=lambda cell: 45 < cell < 65)
    & iris.Constraint(longitude=lambda cell: -15 < cell < 5),
)
# Various forest types
lct.data[(lct.data >= 111) & (lct.data <= 126)] = 0
lct.data[lct.data != 0] = 1
lct.coord("latitude").coord_system = coord_s
lct.coord("longitude").coord_system = coord_s
lcr = lct.regrid(pc, iris.analysis.Nearest())
wtr_img = ax_map.pcolorfast(
    lons,
    lats,
    np.ma.masked_array(
        orog.data + np.random.uniform(0.0, 3.0, orog.data.shape), lcr.data
    ),
    cmap=recolourMap([0, 0.55, 0]),
    vmin=0,
    vmax=omax,
    alpha=1.0,
    zorder=40,
)

# Get grassland/shrubland
lct = iris.load_cube(
    "/scratch/hadpb/rivers/PROBAV_LC100_global_v3.0.1_2019-nrt_Discrete-Classification-map_EPSG-4326.nc",
    iris.Constraint(latitude=lambda cell: 45 < cell < 65)
    & iris.Constraint(longitude=lambda cell: -15 < cell < 5),
)
lct.data[(lct.data == 20) | (lct.data == 30)] = 0
lct.data[lct.data != 0] = 1
lct.coord("latitude").coord_system = coord_s
lct.coord("longitude").coord_system = coord_s
lcr = lct.regrid(pc, iris.analysis.Nearest())
wtr_img = ax_map.pcolorfast(
    lons,
    lats,
    np.ma.masked_array(
        orog.data + np.random.uniform(0.0, omax / 4, orog.data.shape), lcr.data
    ),
    cmap=recolourMap([0.5, 1, 0]),
    vmin=0,
    vmax=omax,
    alpha=1.0,
    zorder=40,
)

# Get cropland
lct = iris.load_cube(
    "/scratch/hadpb/rivers/PROBAV_LC100_global_v3.0.1_2019-nrt_Discrete-Classification-map_EPSG-4326.nc",
    iris.Constraint(latitude=lambda cell: 45 < cell < 65)
    & iris.Constraint(longitude=lambda cell: -15 < cell < 5),
)
lct.data[lct.data == 40] = 0
lct.data[lct.data != 0] = 1
lct.coord("latitude").coord_system = coord_s
lct.coord("longitude").coord_system = coord_s
lcr = lct.regrid(pc, iris.analysis.Nearest())
wtr_img = ax_map.pcolorfast(
    lons,
    lats,
    np.ma.masked_array(
        orog.data + np.random.uniform(0.0, omax / 4, orog.data.shape), lcr.data
    ),
    cmap=recolourMap([0.85, 0.85, 0]),
    vmin=0,
    vmax=omax,
    alpha=1.0,
    zorder=40,
)

# Get built-up areas
lct = iris.load_cube(
    "/scratch/hadpb/rivers/PROBAV_LC100_global_v3.0.1_2019-nrt_Discrete-Classification-map_EPSG-4326.nc",
    iris.Constraint(latitude=lambda cell: 45 < cell < 65)
    & iris.Constraint(longitude=lambda cell: -15 < cell < 5),
)
lct.data[lct.data == 50] = 1
lct.data[lct.data != 1] = 0
lct.coord("latitude").coord_system = coord_s
lct.coord("longitude").coord_system = coord_s
lcr = lct.regrid(pc, iris.analysis.Nearest())

built_img = ax_map.pcolorfast(
    lons,
    lats,
    lcr.data,
    cmap=matplotlib.colors.ListedColormap(((0.5, 0.5, 1.0, 0), (1.0, 0.0, 0.0, 1))),
    vmin=0,
    vmax=1,
    alpha=1.0,
    zorder=50,
)

# Output as png
fig.savefig("HR.png")
