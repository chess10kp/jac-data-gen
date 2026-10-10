"""Beanie / Motor connection helpers for DocumentDB.

DocumentDB exposes a single gateway endpoint that speaks the MongoDB wire
protocol but advertises itself as a *standalone* server (not a replica set).
Beanie talks to it through Motor (async PyMongo), so the driver needs three
tweaks:

  - directConnection=True         -> don't attempt replica-set topology
                                     discovery (the gateway is standalone).
  - tls=True                      -> the gateway only accepts TLS.
  - tlsAllowInvalidCertificates   -> the default install uses a self-signed
                                     cert. Set TLS_INSECURE=false and mount a
                                     CA bundle (tlsCAFile) for production-grade
                                     verification.

The connection string itself (MONGO_URI) carries the credentials. If it still
contains ``replicaSet=rs0`` we strip it here so the driver does not try to match
a replica-set name the gateway never advertises.
"""

from __future__ import annotations

import os
import re

from beanie import init_beanie
from motor.motor_asyncio import AsyncIOMotorClient

_client: AsyncIOMotorClient | None = None


def sanitize_uri(uri: str | None) -> str:
    """Remove ``replicaSet=...`` from a DocumentDB connection string.

    ``replicaSet`` is incompatible with a direct connection to the gateway; the
    driver raises "client is configured to connect to a replica set named 'rs0'
    but this node belongs to a set named 'None'" otherwise.
    """
    if not uri:
        raise ValueError("MONGO_URI is not set. Provide a DocumentDB connection string.")
    return re.sub(r"[?&]replicaSet=[^&]*", "", uri)


def build_client_kwargs() -> dict:
    """Return the Motor client kwargs DocumentDB's gateway requires."""
    tls_insecure = os.environ.get("TLS_INSECURE", "true").lower() != "false"
    return {
        "directConnection": True,
        "tls": True,
        "tlsAllowInvalidCertificates": tls_insecure,
        "serverSelectionTimeoutMS": int(os.environ.get("SERVER_SELECTION_TIMEOUT_MS", "10000")),
    }


async def init(document_models, uri: str | None = None, db_name: str | None = None):
    """Connect Motor to DocumentDB and initialise Beanie for ``document_models``."""
    global _client
    clean_uri = sanitize_uri(uri or os.environ.get("MONGO_URI"))
    database_name = db_name or os.environ.get("MONGO_DB", "beanie_demo")

    _client = AsyncIOMotorClient(clean_uri, **build_client_kwargs())
    await init_beanie(database=_client[database_name], document_models=document_models)
    return _client


def get_client() -> AsyncIOMotorClient | None:
    return _client


async def ping() -> bool:
    """Return True if the gateway responds to an admin ``ping``."""
    if _client is None:
        return False
    result = await _client.admin.command("ping")
    return result.get("ok") == 1


async def close() -> None:
    global _client
    if _client is not None:
        _client.close()
        _client = None
