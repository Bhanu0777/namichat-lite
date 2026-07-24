from typing import Any, Generic, List, Optional, Type, TypeVar, Union
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.database import Base

ModelType = TypeVar("ModelType", bound=Base)

PkType = Union[int, UUID]


class BaseRepository(Generic[ModelType]):
    """Generic read/write repository implementing the Repository pattern."""

    def __init__(self, model: Type[ModelType], db: Session) -> None:
        self.model = model
        self.db = db

    def get(self, id: PkType) -> Optional[ModelType]:
        return self.db.get(self.model, id)

    def get_or_none(self, id: PkType) -> Optional[ModelType]:
        return self.get(id)

    def list(self, *, skip: int = 0, limit: int = 100) -> List[ModelType]:
        stmt = select(self.model).offset(skip).limit(limit)
        return list(self.db.scalars(stmt).all())

    def count(self) -> int:
        stmt = select(func.count()).select_from(self.model)
        return int(self.db.scalar(stmt) or 0)

    def add(self, obj: ModelType) -> ModelType:
        self.db.add(obj)
        self.db.flush()
        self.db.refresh(obj)
        return obj

    def update(self, obj: ModelType, values: dict[str, Any]) -> ModelType:
        for key, value in values.items():
            setattr(obj, key, value)
        self.db.add(obj)
        self.db.flush()
        self.db.refresh(obj)
        return obj

    def delete(self, obj: ModelType) -> None:
        self.db.delete(obj)
        self.db.flush()
