FROM python:3.11-slim

# Identifies which app runs in this image (used by scripts, ECS, and docker ps)
LABEL org.opencontainers.image.title="fastapi-translation" \
      org.opencontainers.image.description="English to Turkish Translator API (FastAPI + Hugging Face)"

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements-docker.txt .

RUN pip install --no-cache-dir torch --index-url https://download.pytorch.org/whl/cpu \
    && pip install --no-cache-dir -r requirements-docker.txt

COPY main.py .
COPY templates/ templates/

ENV PYTHONUNBUFFERED=1 \
    HF_HOME=/root/.cache/huggingface \
    PORT=3000

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=300s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:3000/health')" || exit 1

CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT}"]
