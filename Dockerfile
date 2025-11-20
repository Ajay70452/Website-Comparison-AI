# 1. Base Image: Use a modern, slim Python version based on Debian 12 "Bookworm"
FROM python:3.12-slim-bookworm

# 2. Set Environment Variables
ENV PYTHONUNBUFFERED=1 \
    PLAYWRIGHT_BROWSERS_PATH=/ms-playwright/

# 3. Install Playwright's UPDATED system dependencies for Debian Bookworm
# This is the corrected list.
RUN apt-get update && apt-get install -y \
    #
    # Main browser dependencies
    libnss3 \
    libxss1 \
    libasound2 \
    libxkbcommon-x11-0 \
    libgbm1 \
    #
    # Font dependencies
    fonts-noto-color-emoji \
    #
    # Other common dependencies
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libatspi2.0-0 \
    libcairo2 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libexpat1 \
    libfontconfig1 \
    libgbm1 \
    libgcc1 \
    libgdk-pixbuf-2.0-0 \
    libglib2.0-0 \
    libgtk-3-0 \
    libpango-1.0-0 \
    libx11-6 \
    libxcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxrandr2 \
    #
    # Clean up the apt cache to keep the image small
    && rm -rf /var/lib/apt/lists/*

# 4. Set the working directory inside the container.
WORKDIR /app

# 5. Copy and install Python dependencies.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 6. Install ONLY the Chromium browser to save space.
RUN python -m playwright install --with-deps chromium

# 7. Copy your application code into the container.
COPY . .

# 8. Define the command to run your app.
CMD gunicorn -w 2 -k uvicorn.workers.UvicornWorker main:app --bind 0.0.0.0:${PORT} --timeout 180