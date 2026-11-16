# syntax=docker/dockerfile:1
FROM python:3.15-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc libpq-dev \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
# BuildKit pip cache: packages are cached between rebuilds (~30s after first build)
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r requirements.txt

# pip only serves the build. The base image's pip (24.0 on Python 3.11,
# measured 2026-11-13) carries 12 known vulnerabilities, in two copies: the
# installed package and the wheel kept by ensurepip, used only by
# `python -m venv`. Nothing calls either at runtime (deploy/start_api.sh
# runs python and uvicorn only).
RUN pip uninstall -y pip \
    && rm -f /usr/local/lib/python3*/ensurepip/_bundled/pip-*.whl

COPY . .
EXPOSE 8000
CMD ["uvicorn", "market_insights.api.main:app", "--host", "0.0.0.0", "--port", "8000"]
