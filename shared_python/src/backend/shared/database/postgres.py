"""PostgreSQL async engine & session factory using SQLAlchemy 2.0."""
from __future__ import annotations

from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from backend.shared.config import get_base_settings

_engine = None
_session_factory = None


class PostgresBase(DeclarativeBase):
    """Base class for all SQLAlchemy ORM models."""
    pass


async def init_postgres() -> None:
    """Initialize the async engine and session factory."""
    global _engine, _session_factory
    settings = get_base_settings()
    _engine = create_async_engine(
        settings.postgres_dsn,
        echo=settings.DEBUG,
        pool_size=20,
        max_overflow=10,
        pool_pre_ping=True,
        pool_recycle=3600,
    )
    _session_factory = async_sessionmaker(
        bind=_engine,
        class_=AsyncSession,
        expire_on_commit=False,
    )


async def get_postgres_session() -> AsyncGenerator[AsyncSession, None]:
    """FastAPI dependency – yields an async session."""
    if _session_factory is None:
        await init_postgres()
    async with _session_factory() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise

