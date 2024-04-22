#!/usr/bin/env python

# Plot a vertical format orography map of the Yangtze catchment

import os
import sys
import numpy as np

import iris
import iris.analysis

import matplotlib
from matplotlib.backends.backend_agg import FigureCanvasAgg as FigureCanvas
from matplotlib.figure import Figure
from matplotlib.lines import Line2D

import geopandas
import cmocean
from pandas import qcut

# Define the region to plot
latMin = 24
latMax = 36
lonMin = 89
lonMax = 125
aspect = (lonMax - lonMin) * 0.86 / (latMax - latMin)  # .86 is cos(latMean)

fig = Figure(
    figsize=(11 * aspect, 11),  # Width, Height (inches)
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
    xmin=-180,
    xmax=180,
    ymin=-90,
    ymax=90,
):

    cs = iris.coord_systems.GeogCS(iris.fileformats.pp.EARTH_RADIUS)
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
    iris.Constraint(latitude=lambda cell: (latMin - 1) < cell < (latMax + 1))
    & iris.Constraint(longitude=lambda cell: (lonMin - 1) < cell < (lonMax + 1)),
)
orog.data[orog.data < -10] = -10
omax = orog.data.max()
orog.coord("latitude").coord_system = coord_s
orog.coord("longitude").coord_system = coord_s
pc = plot_cube(0.005, lonMin, lonMax, latMin, latMax)
pc.coord("latitude").guess_bounds()
pc.coord("longitude").guess_bounds()
orog = orog.regrid(pc, iris.analysis.Linear())
lats = orog.coord("latitude").points
lons = orog.coord("longitude").points
mask_img = ax_map.pcolorfast(
    lons,
    lats,
    orog.data + np.random.uniform(0.0, 100.0, orog.data.shape),
    cmap=cmocean.cm.gray,
    vmin=-10,
    vmax=omax,
    alpha=1.0,
    zorder=20,
)

# Get sea from the land cover data
lct = iris.load_cube(
    "/scratch/hadpb/rivers/PROBAV_LC100_global_v3.0.1_2019-nrt_Discrete-Classification-map_EPSG-4326.nc",
    iris.Constraint(latitude=lambda cell: (latMin - 1) < cell < (latMax + 1))
    & iris.Constraint(longitude=lambda cell: (lonMin - 1) < cell < (lonMax + 1)),
)
# Sea is 200 and inland water is 80, 90 is wetland
lct.data[lct.data == 200] = 0
lct.data[lct.data != 0] = 1
lct.coord("latitude").coord_system = coord_s
lct.coord("longitude").coord_system = coord_s
lcr = lct.regrid(pc, iris.analysis.Nearest())

sea_img = ax_map.pcolorfast(
    lons,
    lats,
    np.ma.masked_array(
        orog.data + np.random.uniform(0.0, 3000.0, orog.data.shape), lcr.data
    ),
    cmap=recolourMap([0, 0, 1]),
    vmin=-10,
    vmax=omax,
    alpha=1.0,
    zorder=40,
)
# Get inland water from the land cover data
lct = iris.load_cube(
    "/scratch/hadpb/rivers/PROBAV_LC100_global_v3.0.1_2019-nrt_Discrete-Classification-map_EPSG-4326.nc",
    iris.Constraint(latitude=lambda cell: (latMin - 1) < cell < (latMax + 1))
    & iris.Constraint(longitude=lambda cell: (lonMin - 1) < cell < (lonMax + 1)),
)
# Inland water is 80, 90 is wetland
lct.data[(lct.data == 80) | (lct.data == 90)] = 0
lct.data[lct.data != 0] = 1
lct.coord("latitude").coord_system = coord_s
lct.coord("longitude").coord_system = coord_s
lct.coord("latitude").guess_bounds()
lct.coord("longitude").guess_bounds()
# lats = lct.coord("latitude").points
# lons = lct.coord("longitude").points
lcr = lct.regrid(pc, iris.analysis.Nearest())
# lcr.data[lcr.data<0.5]=0

wtr_img = ax_map.pcolorfast(
    lons,
    lats,
    np.ma.masked_array(
        orog.data + np.random.uniform(0.0, 300.0, orog.data.shape), lcr.data
    ),
    cmap=recolourMap([0, 0, 1]),
    vmin=-10,
    vmax=omax,
    alpha=1.0,
    zorder=40,
)
# Get forest from the land cover data
lct = iris.load_cube(
    "/scratch/hadpb/rivers/PROBAV_LC100_global_v3.0.1_2019-nrt_Discrete-Classification-map_EPSG-4326.nc",
    iris.Constraint(latitude=lambda cell: (latMin - 1) < cell < (latMax + 1))
    & iris.Constraint(longitude=lambda cell: (lonMin - 1) < cell < (lonMax + 1)),
)
# Various forest types
lct.data[(lct.data >= 111) & (lct.data <= 126)] = 0
lct.data[lct.data != 0] = 1
lct.coord("latitude").coord_system = coord_s
lct.coord("longitude").coord_system = coord_s
lcr = lct.regrid(pc, iris.analysis.Nearest())

forest_img = ax_map.pcolorfast(
    lons,
    lats,
    np.ma.masked_array(
        orog.data + np.random.uniform(0.0, 3000.0, orog.data.shape), lcr.data
    ),
    cmap=recolourMap([0.0, 0.55, 0]),
    vmin=-10,
    vmax=omax,
    alpha=1.0,
    zorder=30,
)
#
# Get crops
lct = iris.load_cube(
    "/scratch/hadpb/rivers/PROBAV_LC100_global_v3.0.1_2019-nrt_Discrete-Classification-map_EPSG-4326.nc",
    iris.Constraint(latitude=lambda cell: (latMin - 1) < cell < (latMax + 1))
    & iris.Constraint(longitude=lambda cell: (lonMin - 1) < cell < (lonMax + 1)),
)
lct.data[lct.data == 40] = 0
lct.data[lct.data != 0] = 1
lct.coord("latitude").coord_system = coord_s
lct.coord("longitude").coord_system = coord_s
lcr = lct.regrid(pc, iris.analysis.Nearest())
lcr.data[lcr.data < 0.5] = 0

crops_img = ax_map.pcolorfast(
    lons,
    lats,
    np.ma.masked_array(
        orog.data + np.random.uniform(0.0, 3000.0, orog.data.shape), lcr.data
    ),
    cmap=recolourMap([0.55, 0.55, 0.0]),
    vmin=-10,
    vmax=omax,
    alpha=1.0,
    zorder=30,
)
# Get built-up areas
lct = iris.load_cube(
    "/scratch/hadpb/rivers/PROBAV_LC100_global_v3.0.1_2019-nrt_Discrete-Classification-map_EPSG-4326.nc",
    iris.Constraint(latitude=lambda cell: (latMin - 1) < cell < (latMax + 1))
    & iris.Constraint(longitude=lambda cell: (lonMin - 1) < cell < (lonMax + 1)),
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

# Add the river
rivers = geopandas.read_file(
    "%s/rivers/RiverHRCenterlinesCombo.shp" % os.getenv("SCRATCH")
)
yangtze = rivers[rivers["NAME"] == "Yangtze"]
yc = list(yangtze.geometry)[0].coords  # yc now an iterable of (x,y,0)
rx = [i[0] for i in yc]
ry = [i[1] for i in yc]
ax_map.add_line(
    Line2D(
        rx,
        ry,
        linewidth=3,
        color=(0.0, 0.0, 1, 1),
        alpha=1.0,
        zorder=200,
    )
)
# Add the river catchment
# catchments = geopandas.read_file("../make_catchment_mask/Major_Basins_of_the_World.shp")
# yangtze_c = catchments[catchments["NAME"] == "Yangtze"]
# yc = list(yangtze_c.geometry)[0].boundary.coords  # yc now an iterable of (x,y,0)
# rx = [i[0] for i in yc]
# ry = [i[1] for i in yc]
# ax_map.add_line(
#    Line2D(
#        rx,
#        ry,
#        linewidth=0.5,
#        color=(0, 0, 0, 1),
#        alpha=1.0,
#        zorder=200,
#    )
# )


# Output as png
fig.savefig("flat.png")
