# Generate custom tilematrixset based on EPSG code and extents
# Examples: https://schemas.opengis.net/tms/2.0/json/examples/tilematrixset/

import json

from morecantile import tms, TileMatrixSet
from pyproj import CRS

def export_tms(tms):
    with open(f"{tms.id}.json", "w") as f:
        json.dump(tms.model_dump(), f, indent=2)

# Create Custom TMS
# Ref: https://developmentseed.org/titiler/examples/code/tiler_with_custom_tms/
EPSG6931 = TileMatrixSet.custom(
    extent=(-8918256.31, -9009964.76, 8918256.31, 9009964.76), # Ref: https://epsg.io/6931
    crs=CRS.from_epsg(6931),
    id="EPSG6931",
    matrix_scale=[1, 1],
)

EPSG6932 = TileMatrixSet.custom(
    extent=(-8918256.31, -9009964.76, 8918256.31, 9009964.76), # Ref: https://epsg.io/6932
    crs=CRS.from_epsg(6932),
    id="EPSG6932",
    matrix_scale=[1, 1],
)

export_tms(EPSG6931)
export_tms(EPSG6932)

