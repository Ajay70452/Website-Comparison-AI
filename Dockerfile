# 1. Base Image: Use a supported Python version.
FROM python:3.10-slim-bookworm

# 2. Set Environment Variables
ENV PYTHONUNBUFFERED=1

# 3. Set the Working Directory
WORKDIR /app

# 4. Install Dependencies as ROOT (Critical for Playwright's system deps)
# We do this before switching to the unprivileged user.
RUN apt-get update && apt-get install -y \
    python3-pip \
    libnss3 \
    libfontconfig1 \
    libgbm-dev \
    libgtk-3-0 \
    libasound2 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdbus-glib-1-2 \
    libdrm2 \
    libgl1-mesa-glx \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libxtst6 \
    libxkbcommon0 \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# 5. Copy requirements and install Python packages (still as root)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 6. Install the Playwright browsers (CRITICAL: MUST run as root)
# The --with-deps flag ensures all necessary system dependencies are linked correctly.
ENV PLAYWRIGHT_BROWSERS_PATH=/usr/local/bin/ms-playwright

RUN python -m playwright install --with-deps chromium

# 7. Create and switch to the unprivileged user for runtime security.
RUN useradd -m appuser
USER appuser

# 8. Copy your application code (now as the unprivileged user)
COPY --chown=appuser:appuser . .

# 9. Define the command to run your app.
CMD uvicorn main:app --host 0.0.0.0 --port ${PORT}