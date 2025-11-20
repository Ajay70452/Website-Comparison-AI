# 1. Base Image: Use a modern, slim Python version.
FROM python:3.10-slim-buster

# 2. Set Environment Variables for a smoother build process.
ENV PYTHONUNBUFFERED=1

# 3. Install Playwright's system dependencies (using the official Playwright base image list)
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

# 4. Set the working directory, create a non-root user for security
WORKDIR /app
RUN useradd -m appuser
USER appuser

# 5. Copy and install Python dependencies.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 6. Install the Playwright browsers (we will use the simple command which is now robust)
RUN python -m playwright install --with-deps chromium

# 7. Copy your application code into the container.
COPY . .

# 8. Define the command to run your app.
# We simplify the CMD to directly run the app with Uvicorn, which is safer on App Platform.
# The ${PORT} variable is automatically injected by DO.
CMD uvicorn main:app --host 0.0.0.0 --port ${PORT}