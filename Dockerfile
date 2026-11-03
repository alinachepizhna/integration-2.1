# ---- 1. Base image: small Linux with Python 3.12 -----------------------
FROM python:3.12-slim-bookworm

# Встановлюємо системний компілятор для збирання пакетів із Rust (pydantic-core)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# ---- 2. Add the uv binary ----------------------------------------------
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

# Pre-compile .pyc files and copy instead of hardlink.
ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy

# ---- 3. Dependencies (cached layer) -------------------------------------
WORKDIR /app

# Copy ONLY the dependency manifests first.
COPY pyproject.toml uv.lock ./

# Create /app/.venv and install packages using the system Python
RUN uv sync --frozen --no-dev --python /usr/local/bin/python

# ---- 4. Application code (changes often → its own layer) ----------------
COPY app ./app

# Make /app/.venv/bin visible on the PATH.
ENV PATH="/app/.venv/bin:$PATH"

# Expose port
EXPOSE 8000

# ---- 5. What runs when the container starts ------------------------------
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]