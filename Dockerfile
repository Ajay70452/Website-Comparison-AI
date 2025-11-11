FROM python:3.11-slim


ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright/


RUN apt-get update && apt-get install -y \
    # This long list is required for the headless browser to run correctly on Linux
    libwebkit2gtk-4.0-37 \
    libwoff1 \
    libharfbuzz-icu0 \
    libenchant1c2a \
    libsecret-1-0 \
    libgomp1 \
    libhyphen0 \
    libgl1-mesa-glx \
    libgdk-pixbuf2.0-0 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxi6 \
    libxtst6 \
    libnss3 \
    libcups2 \
    libxss1 \
    libxrandr2 \
    libasound2 \
    libpangocairo-1.0-0 \
    libgbm-dev \
    libxkbcommon-x11-0 \
    # Clean up the apt cache to keep the final image smaller
    && rm -rf /var/lib/apt/lists/*


WORKDIR /app


COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

RUN playwright install chromium


COPY . .


CMD ["gunicorn", "-w", "2", "-k", "uvicorn.workers.UvicornWorker", "main:app", "--bind", "0.0.0.0:${PORT}"]