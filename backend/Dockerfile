# ---- Stage 1: install dependencies into an isolated virtualenv ----
FROM python:3.12-slim AS build

ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
RUN pip install -r requirements.txt \
    # build tooling is not needed at runtime (and pip vendors its own urllib3/msgpack)
    && pip uninstall -y pip setuptools wheel

# ---- Stage 2: minimal runtime image ----
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"

# Patch OS packages, and drop the base image's own pip/setuptools so Trivy only sees what the app ships
RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/* \
    && (python -m pip uninstall -y pip setuptools wheel || true) \
    && rm -rf /usr/local/lib/python3.12/ensurepip

WORKDIR /app
COPY --from=build /opt/venv /opt/venv
COPY alembic.ini .
COPY alembic ./alembic
COPY app ./app

# Run as an unprivileged user
RUN groupadd --system --gid 10001 app && useradd --system --uid 10001 --gid app --no-create-home app \
    && chown -R app:app /app
USER 10001

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=3s --start-period=20s CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health')" || exit 1

# Apply migrations, then start the API
CMD ["sh", "-c", "alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port 8000"]
