#!/usr/bin/env python

# Plain rectangular format

import sys

import matplotlib
from matplotlib.backends.backend_agg import FigureCanvasAgg as FigureCanvas
from matplotlib.figure import Figure
from matplotlib.patches import Rectangle

from PIL import Image
import numpy as np
import random

# Load the data from a csv file
import csv

# Open the CSV file
people = []
with open("people.csv", "r") as file:
    # Create a CSV reader
    reader = csv.reader(file)

    # Get the header row
    header = next(reader)

    # Loop through each row in the CSV
    countBack = 0
    for row in reader:
        if len(row) == 0:
            people.append(row)
        else:
            people.append(
                [
                    row[0].strip(),
                    int(row[1]),
                    int(row[2]),
                    row[3].strip(),
                    row[4].strip(),
                    row[5].strip,
                    countBack,
                ]
            )
        countBack += 1

# Create a figure
fig = Figure(
    figsize=(30, 42.43),
    dpi=300,
    facecolor=(0.5, 0.5, 0.5, 1),
    edgecolor=None,
    linewidth=0.0,
    frameon=False,
    subplotpars=None,
    tight_layout=None,
)
canvas = FigureCanvas(fig)
font = {
    "family": "sans-serif",
    "sans-serif": "Arial",
    "weight": "normal",
    "size": 32,
}
matplotlib.rc("font", **font)

# Plain background
bgcolour = (0.95, 0.95, 0.95, 1)
axb = fig.add_axes([0, 0, 1, 1])
axb.set_axis_off()
axb.add_patch(
    Rectangle(
        (0, 0),
        1,
        1,
        facecolor=bgcolour,
        fill=True,
        zorder=1,
    )
)

fig_width, fig_height = fig.get_size_inches()
fig_aspect = fig_width / fig_height


# Set the margins
borderFractions = [0.05, 0.025, 0.01, 0.01]

# Axes for plot
ax = fig.add_axes(
    [
        borderFractions[0],
        borderFractions[1],
        1 - borderFractions[0] - borderFractions[2],
        1 - borderFractions[1] - borderFractions[3],
    ],
    facecolor=(0.95, 0.95, 0.95, 1),
)
ax_aspect = (
    fig_width
    * (1 - borderFractions[0] - borderFractions[2])
    / fig_height
    * (1 - borderFractions[1] - borderFractions[3])
)


# No black border
for edge in ["top", "right"]:
    ax.spines[edge].set_visible(False)

# X axis from -3200 to present+space
ax.set_xlim(-4200, 3250)
ax.set_xlabel("Year")
ax.set_xticks(range(-3500, 2100, 500))

# Y axis from 0 to length of csv
ax.set_ylabel("Lifetimes ago")
# Y axis integers in csv length
ax.set_ylim(len(people) + 0, -10)
ax.set_yticks(range(0, len(people) + 5, 5))

ax.set_aspect("auto")

# Add a grid
ax.grid(color=(0.5, 0.5, 0.5, 0.25), linestyle="-", linewidth=0.25, zorder=-10)

Austria = dict(
    colors=("#a40000", "#16317d", "#007e2f", "#ffcd12", "#b86092", "#721b3e", "#00b7a7")
)


# Different professions in different colours
# Uses 'Austria' palette from MetBrewer
def set_color(person):
    if person[4] == "monarch":
        return "#a40000"
    elif person[4] == "writer" or person[4] == "poet":
        return "#16317d"
    elif person[4] == "philosopher" or person[4] == "scientist":
        return "#007e2f"
    elif person[4] == "priest" or person[4] == "saint" or person[4] == "religious":
        return "#ffcd12"
    elif person[4] == "artist" or person[4] == "musician":
        return "#b86092"
    elif person[4] == "general":
        return "#721b3e"
    elif person[4] == "politician":
        return "#00b7a7"
    elif person[4] == "merchant":
        return (0.722, 0.451, 0.2, 1)
    else:
        return (0, 0, 0, 1)


# Find the spot to add an image
def getImageExtent(box_bb, name_bb, pIdx):
    ximscale = 0.05
    ximsize = (ax.get_xlim()[1] - ax.get_xlim()[0]) * ximscale
    aspect = abs(
        (ax.get_ylim()[1] - ax.get_ylim()[0]) / (ax.get_xlim()[1] - ax.get_xlim()[0])
    )
    yimsize = ximsize * ax.get_data_ratio() * ax_aspect
    xoffset = ximsize
    yoffset = yimsize
    if pIdx // 2 % 3 != 1:
        xoffset += ximsize
        yoffset += yimsize
    if pIdx // 2 % 3 == 2:
        xoffset += ximsize
        yoffset += yimsize
    if pIdx % 2 == 1:  # Bottom right
        xoffset -= 100
        yoffset -= 0
        return [
            box_bb.x1 + xoffset,
            box_bb.x1 + xoffset + ximsize,
            box_bb.y0 + yoffset + yimsize,
            box_bb.y0 + yoffset,
        ]
    else:
        xoffset += 1000  # Need space for names
        if pIdx == 108:  # Don't waste space on Iry-Hor
            xoffset -= 1000
        return [
            box_bb.x0 - xoffset + ximsize,
            box_bb.x0 - xoffset,
            box_bb.y0 - yoffset + yimsize,
            box_bb.y0 - yoffset,
        ]


# For each person, plot a bar showing their lifespan
for pIdx in range(len(people)):
    person = people[pIdx]
    if len(person) != 0:
        col = set_color(person)
        box = ax.add_patch(
            Rectangle(
                (person[1], pIdx - 0.48),
                person[2] - person[1],
                0.96,
                facecolor=col,
                fill=True,
                zorder=20,
            )
        )
        name = ax.text(
            person[1] - 25,
            pIdx,
            person[0],
            horizontalalignment="right",
            verticalalignment="center",
            color=(0, 0, 0, 1),
            zorder=30,
            fontsize=24,
        )
        name_bg = ax.text(  # Background for name text
            person[1] - 25,
            pIdx,
            person[0],
            horizontalalignment="right",
            verticalalignment="center",
            color=bgcolour,
            zorder=10,
            fontsize=24,
            backgroundcolor=bgcolour,
        )

        # Get plot positions of box and name to use placing picture
        box_bb = box.get_bbox()  # In ax data coords
        name_bb = name.get_window_extent()  # In display coords
        name_bb = name_bb.transformed(ax.transData.inverted())  # In ax data coords
        img_extent = getImageExtent(box_bb, name_bb, pIdx)

        img = Image.open("pictures/%s.webp" % person[0])
        img_array = np.array(img)
        imgs = ax.imshow(img_array, extent=img_extent, aspect="auto", zorder=40)
        # Draw a line linking box and name
        if pIdx % 2 == 1:  # Below right
            ax.plot(
                [box_bb.x1 + 10, img_extent[0]],
                [(box_bb.y0 + box_bb.y1) / 2, img_extent[3]],
                color=col,
                linewidth=0.35,
                zorder=5,
            )
        else:
            ax.plot(
                [name_bb.x0 - 10, img_extent[0]],
                [(name_bb.y0 + name_bb.y1) / 2, img_extent[2]],
                color=col,
                linewidth=0.35,
                zorder=5,
            )

# Add some overall descriptive text
ax.text(
    -4000,
    -9,
    "An AI Reads History",
    horizontalalignment="left",
    verticalalignment="top",
    color=(0, 0, 0, 1),
    fontsize=56,
    zorder=100,
    backgroundcolor=bgcolour,
)
ax.text(
    -4000,
    -6.5,
    "78 people from Wikipedia",
    horizontalalignment="left",
    verticalalignment="top",
    color=(0, 0, 0, 1),
    fontsize=40,
    zorder=100,
    backgroundcolor=bgcolour,
)
ax.text(
    -4000,
    -0,
    "How many overlapping human lifetimes does it take \nto cover recorded history.\n\n"
    + "People selected, and pictured, by ChatGPT.",
    horizontalalignment="left",
    verticalalignment="top",
    color=(0, 0, 0, 1),
    fontsize=32,
    zorder=100,
    backgroundcolor=bgcolour,
)
axb.text(
    0.99,
    0.005,
    "Philip Brohan, 2023-12-28\n"
    + "https://brohan.org/Posters/posters/An_AI_reads_history",
    horizontalalignment="right",
    verticalalignment="bottom",
    color=(0, 0, 0, 1),
    fontsize=16,
    zorder=100,
    backgroundcolor=bgcolour,
)
# Output as png
fig.savefig("AI_reads_history.png")
