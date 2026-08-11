"""titiler-pgstac entry: local COG hrefs and custom polar TMS.

The catalogue stores public ``FILE_SERVER_URL`` hrefs (``https://.../files/data/cogs/...``).
Rewrite those to ``file:///data/cogs/...`` so tile renders read the compose
``./data`` mount instead of hopping through the file-server.

Custom Arctic / Antarctic TMS JSON in ``TILEMATRIXSET_DIRECTORY`` is registered
on morecantile before the FastAPI app loads its TMS routes.
"""

from __future__ import annotations

import copy
import json
import logging
import os
from pathlib import Path

import morecantile
from morecantile import TileMatrixSet

logger = logging.getLogger("titiler_pgstac_app")

# Must match the ``titiler-pgstac`` tag on the compose ``titiler`` service.
# This file patches ItemIdParams and img_profiles; bump both together.
EXPECTED_TITILER_PGSTAC = "3.0.0"

_TMS_DIR = Path(os.environ.get("TILEMATRIXSET_DIRECTORY", "/custom_tms"))
# Public hrefs look like ``https://host/files/data/cogs/...`` after ingest.
_FILES_DATA_MARKER = "/files/data/"
_LOCAL_DATA_ROOT = os.environ.get("TILER_HREF_LOCAL_ROOT", "/data").rstrip("/")


def _require_pinned_titiler(deps) -> None:
    """Refuse to start if the image no longer matches this wrap."""
    import importlib.metadata

    version = importlib.metadata.version("titiler-pgstac")
    if version != EXPECTED_TITILER_PGSTAC:
        raise RuntimeError(
            "config/titiler_pgstac_app.py targets titiler-pgstac "
            f"{EXPECTED_TITILER_PGSTAC}; this image has {version}. "
            "Bump the compose pin and re-check ItemIdParams and "
            "img_profiles together."
        )
    if not hasattr(deps, "get_stac_item") or not hasattr(deps, "ItemIdParams"):
        raise RuntimeError(
            "titiler.pgstac.dependencies no longer exposes get_stac_item "
            "or ItemIdParams; update config/titiler_pgstac_app.py"
        )


def _use_lossless_webp() -> None:
    """Encode ``.webp`` tiles without lossy compression.

    rio-tiler's WebP profile defaults to quality 75. TiTiler does not expose
    ``quality`` or ``lossless`` as tile query parameters, so set it here.
    """
    from rio_tiler.profiles import img_profiles

    data = getattr(img_profiles, "data", None)
    profile = data.get("webp") if isinstance(data, dict) else None
    if profile is None:
        raise RuntimeError(
            "rio-tiler img_profiles.data has no 'webp' profile; "
            "update _use_lossless_webp"
        )
    profile["lossless"] = True
    logger.info("WebP tile output set to lossless")


def _register_custom_tms() -> None:
    """Load ``EPSG####.json`` grids so polar views keep working."""
    if not _TMS_DIR.is_dir():
        logger.warning("Custom TMS directory missing: %s", _TMS_DIR)
        return
    for path in sorted(_TMS_DIR.glob("*.json")):
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
            tms = TileMatrixSet.model_validate(payload)
            morecantile.tms.tilematrixsets[tms.id] = tms
            logger.info("Registered custom TMS %s from %s", tms.id, path.name)
        except Exception:
            logger.exception("Could not register custom TMS from %s", path)


def rewrite_asset_href(href: str | None) -> str | None:
    """Map a public file-server COG href onto the local data mount."""
    if not href or href.startswith("file://") or href.startswith("/"):
        return href
    idx = href.find(_FILES_DATA_MARKER)
    if idx < 0:
        return href
    tail = href[idx + len(_FILES_DATA_MARKER) :].lstrip("/")
    return f"file://{_LOCAL_DATA_ROOT}/{tail}"


def _rewrite_item_hrefs(item):
    """Point every asset on a loaded Item at the local COG path."""
    for asset in item.assets.values():
        rewritten = rewrite_asset_href(asset.href)
        if rewritten and rewritten != asset.href:
            asset.href = rewritten
    return item


def slim_item_to_requested_assets(item, assets_param: str | None):
    """Keep only the assets named in the tile query.

    PgSTACReader walks every asset on init. A forecast Item has one COG per
    lead, so that walk dominated each tile before this filter.
    """
    if not assets_param:
        return item
    keys = [
        part.split("|", 1)[0].strip()
        for part in assets_param.split(",")
        if part.split("|", 1)[0].strip()
    ]
    keep = {key: item.assets[key] for key in keys if key in item.assets}
    if not keep or len(keep) == len(item.assets):
        return item
    slim = copy.copy(item)
    slim.assets = keep
    return slim


_use_lossless_webp()
_register_custom_tms()

from threading import Lock  # noqa: E402

import pystac  # noqa: E402
from cachetools import TTLCache, cached  # noqa: E402
from cachetools.keys import hashkey  # noqa: E402
from fastapi import HTTPException, Path, Request  # noqa: E402
from psycopg.rows import dict_row  # noqa: E402
from typing_extensions import Annotated  # noqa: E402

from titiler.pgstac import dependencies as _pgstac_deps  # noqa: E402
from titiler.pgstac.settings import CacheSettings  # noqa: E402

_require_pinned_titiler(_pgstac_deps)

_cache_config = CacheSettings()
_item_cache = TTLCache(maxsize=_cache_config.maxsize, ttl=_cache_config.ttl)


@cached(
    _item_cache,
    key=lambda pool, collection, item: hashkey(collection, item),
    lock=Lock(),
)
def get_stac_item(pool, collection: str, item: str):
    """Load one Item by primary key and rewrite COG hrefs to disk.

    titiler-pgstac uses ``pgstac.search()`` here. That path builds a full
    search response (~140 KB and ~150 ms for an IceNet forecast Item).
    ``pgstac.get_item`` returns the same Feature without the search wrapper.
    """
    with pool.connection() as conn:
        with conn.cursor(row_factory=dict_row) as cursor:
            cursor.execute(
                "SELECT pgstac.get_item(%s, %s) AS item;",
                (item, collection),
            )
            row = cursor.fetchone()
    payload = row.get("item") if row else None
    if not payload:
        raise HTTPException(
            status_code=404,
            detail=f"No item '{item}' found in '{collection}' collection",
        )
    if isinstance(payload, str):
        payload = json.loads(payload)
    return _rewrite_item_hrefs(pystac.Item.from_dict(payload))


def ItemIdParams(
    request: Request,
    collection_id: Annotated[
        str,
        Path(description="STAC Collection Identifier"),
    ],
    item_id: Annotated[str, Path(description="STAC Item Identifier")],
):
    """Load one Item and drop assets the tile request does not need."""
    item = get_stac_item(request.app.state.dbpool, collection_id, item_id)
    return slim_item_to_requested_assets(item, request.query_params.get("assets"))


_pgstac_deps.get_stac_item = get_stac_item
_pgstac_deps.ItemIdParams = ItemIdParams

from titiler.pgstac.main import app  # noqa: E402, F401
