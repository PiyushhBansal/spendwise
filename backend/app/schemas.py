from datetime import date, datetime
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

Category = Literal["food", "transport", "housing", "utilities", "health", "entertainment", "shopping", "other"]


class ExpenseBase(BaseModel):
    title: str = Field(min_length=1, max_length=120)
    amount: Decimal = Field(gt=0, max_digits=10, decimal_places=2)
    category: Category
    spent_on: date
    note: str | None = Field(default=None, max_length=500)


class ExpenseCreate(ExpenseBase):
    pass


class ExpenseUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=120)
    amount: Decimal | None = Field(default=None, gt=0, max_digits=10, decimal_places=2)
    category: Category | None = None
    spent_on: date | None = None
    note: str | None = Field(default=None, max_length=500)


class ExpenseOut(ExpenseBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    created_at: datetime


class CategoryTotal(BaseModel):
    category: str
    total: Decimal
    count: int


class Summary(BaseModel):
    total: Decimal
    count: int
    by_category: list[CategoryTotal]
