FROM python:3.11-slim

# Do not write .pyc files and run in unbuffered mode
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Install build deps (removed after pip install) and pip install requirements
COPY requirements.txt ./
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential \
    && pip install --no-cache-dir -r requirements.txt \
    && apt-get purge -y --auto-remove build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy application code
COPY . /app

# Expose a default port. Adjust if your app uses a different port.
EXPOSE 8000

# Default command. Assumes `main.py` starts the application.
CMD ["python", "main.py"]
