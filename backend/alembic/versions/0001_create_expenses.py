"""create expenses table

Revision ID: 0001
Revises:
Create Date: 2026-10-15
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "expenses",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("title", sa.String(length=120), nullable=False),
        sa.Column("amount", sa.Numeric(10, 2), nullable=False),
        sa.Column("category", sa.String(length=40), nullable=False),
        sa.Column("spent_on", sa.Date(), nullable=False),
        sa.Column("note", sa.String(length=500), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_expenses_id", "expenses", ["id"])
    op.create_index("ix_expenses_category", "expenses", ["category"])


def downgrade() -> None:
    op.drop_index("ix_expenses_category", table_name="expenses")
    op.drop_index("ix_expenses_id", table_name="expenses")
    op.drop_table("expenses")
