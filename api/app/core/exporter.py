import csv
import os
from datetime import datetime

import structlog
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.models import User

logger = structlog.get_logger()

EXPORT_DIR = os.environ.get("EXPORT_DIR", "/app/exports")
CSV_PATH = os.path.join(EXPORT_DIR, "users.csv")
LAST_UPDATED_PATH = os.path.join(EXPORT_DIR, ".last_updated")

CSV_FIELDS = [
    "id",
    "username",
    "email",
    "phone_number",
    "hashed_password",
    "role",
    "is_verified",
    "created_at",
    "updated_at",
]


def _role_repr(value):
    if value is None:
        return ""
    if hasattr(value, "value"):
        return str(value.value)
    return str(value)


def _write_users_csv(rows) -> None:
    os.makedirs(EXPORT_DIR, exist_ok=True)
    with open(CSV_PATH, "w", newline="", encoding="utf-8") as fh:
        writer = csv.writer(fh)
        writer.writerow(CSV_FIELDS)
        for r in rows:
            writer.writerow(
                [
                    r.id,
                    r.username,
                    r.email,
                    r.phone_number,
                    r.hashed_password,
                    _role_repr(r.role),
                    int(r.is_verified) if r.is_verified is not None else "",
                    r.created_at,
                    r.updated_at,
                ]
            )
    with open(LAST_UPDATED_PATH, "w", encoding="utf-8") as fh:
        fh.write(datetime.utcnow().isoformat() + "\n")


async def export_users_csv(db: AsyncSession) -> None:
    """Best-effort: dump all users to a CSV for easy inspection in a file.

    Failures are logged and swallowed so they never break auth flows.
    """
    try:
        result = await db.execute(select(User))
        rows = result.scalars().all()
        _write_users_csv(rows)
        logger.info("user_csv_exported", count=len(rows), path=CSV_PATH)
    except Exception as exc:  # noqa: BLE001
        logger.warning("user_csv_export_failed", error=str(exc))
