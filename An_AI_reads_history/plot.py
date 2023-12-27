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
    "size": 24,
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

# Plot border
borderFraction = 0.05

# Axes for plot
ax = fig.add_axes(
    [borderFraction, borderFraction, 1 - borderFraction * 2, 1 - borderFraction * 2],
    facecolor=(0.95, 0.95, 0.95, 1),
)


# No black border
for edge in ["top", "right"]:
    ax.spines[edge].set_visible(False)

# X axis from -3200 to 2123
ax.set_xlim(-4500, 2500)
ax.set_xlabel("Year")
ax.set_xticks(range(-3500, 2100, 500))

# Y axis from 0 to length of csv
ax.set_ylabel("Lifetimes ago")
# Y axis integers in csv length
ax.set_ylim(len(people) + 5, -15)
ax.set_yticks(range(0, len(people) + 5, 5))


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
def getImageAxis(person, pIdx):
    axscale = 1 - borderFraction * 2
    xrange = ax.get_xlim()[1] - ax.get_xlim()[0]
    yrange = ax.get_ylim()[0] - ax.get_ylim()[1]
    imscale = 0.025
    if pIdx % 2 == 1:  # Bottom left
        xoffset = 0.025 * random.uniform(0.9, 1.1)
        yoffset = 0.025 * random.uniform(0.9, 1.1)
        if pIdx // 2 % 3 != 1:
            xoffset += 0.025 * random.uniform(0.9, 1.1)
            yoffset += 0.025 * random.uniform(0.9, 1.1)
        if pIdx // 2 % 3 == 2:
            xoffset += 0.025 * random.uniform(0.9, 1.1)
            yoffset += 0.025 * random.uniform(0.9, 1.1)
        return fig.add_axes(
            [
                borderFraction
                + ((person[2] - ax.get_xlim()[0]) / xrange) * axscale
                + xoffset,
                1
                - (
                    borderFraction
                    + ((pIdx - ax.get_ylim()[1]) / yrange) * axscale
                    + yoffset
                    + imscale
                ),
                imscale,
                imscale,
            ]
        )
    else:
        xoffset = 0.065 * random.uniform(0.9, 1.1)
        yoffset = 0.025 * random.uniform(0.9, 1.1)
        if pIdx // 2 % 3 != 1:
            xoffset += 0.025 * random.uniform(0.9, 1.1)
            yoffset += 0.025 * random.uniform(0.9, 1.1)
        if pIdx // 2 % 3 == 2:
            xoffset += 0.025 * random.uniform(0.9, 1.1)
            yoffset += 0.025 * random.uniform(0.9, 1.1)
        return fig.add_axes(
            [
                borderFraction
                + ((person[1] - ax.get_xlim()[0]) / xrange) * axscale
                - xoffset
                - imscale,
                1
                - (
                    borderFraction
                    + ((pIdx - ax.get_ylim()[1]) / yrange) * axscale
                    - yoffset
                ),
                imscale,
                imscale,
            ]
        )


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
            fontsize=12,
        )
        name_bg = ax.text(  # Bacground for name text
            person[1] - 25,
            pIdx,
            person[0],
            horizontalalignment="right",
            verticalalignment="center",
            color=bgcolour,
            zorder=10,
            fontsize=12,
            backgroundcolor=bgcolour,
        )

        img = Image.open("pictures/%s.webp" % person[0])
        img_array = np.array(img)
        img_ax = getImageAxis(person, pIdx)
        img_ax.axis("off")
        imgs = img_ax.imshow(img_array)

        # Draw a line linking box and name
        box_bb = box.get_bbox()  # In ax data coords
        img_bb = img_ax.get_position()  # In figure coords
        img_bb = img_bb.transformed(fig.transFigure)  # In display coords
        img_bb = img_bb.transformed(ax.transData.inverted())  # In ax data coords
        name_bb = name.get_window_extent()  # In display coords
        name_bb = name_bb.transformed(ax.transData.inverted())  # In ax data coords
        if pIdx % 2 == 1:
            ax.plot(
                [box_bb.x1 + 10, img_bb.x0 - 10],
                [(box_bb.y0 + box_bb.y1) / 2, img_bb.y1 - 0.25],
                color=col,
                linewidth=0.35,
                zorder=5,
            )
        else:
            ax.plot(
                [name_bb.x0 - 10, img_bb.x1 - 10],
                [(name_bb.y0 + name_bb.y1) / 2, img_bb.y0 - 0.25],
                color=col,
                linewidth=0.35,
                zorder=5,
            )

# Add some overall descriptive text
ax.text(
    -4200,
    -12,
    "An AI Reads History",
    horizontalalignment="left",
    verticalalignment="top",
    color=(0, 0, 0, 1),
    fontsize=48,
    zorder=100,
    backgroundcolor=bgcolour,
)
ax.text(
    -4200,
    -9,
    "79 people from Wikipedia",
    horizontalalignment="left",
    verticalalignment="top",
    color=(0, 0, 0, 1),
    fontsize=36,
    zorder=100,
    backgroundcolor=bgcolour,
)
ax.text(
    -4200,
    -2,
    "How many overlapping human lifetimes does it take to cover recorded history.\n"
    + "People selected, and pictured, by ChatGPT.",
    horizontalalignment="left",
    verticalalignment="top",
    color=(0, 0, 0, 1),
    fontsize=24,
    zorder=100,
    backgroundcolor=bgcolour,
)
# Output as png
fig.savefig("AI_reads_history.png")
