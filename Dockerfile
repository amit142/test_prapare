# Build stage
FROM python:3.9-slim AS builder

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /app/wheels -r requirements.txt

# Final stage
FROM python:3.9-slim

WORKDIR /app

# Create a non-root user
RUN adduser --disabled-password --gecos "" appuser

# Copy wheels from builder stage
COPY --from=builder /app/wheels /wheels
COPY --from=builder /app/requirements.txt .

# Install dependencies
RUN pip install --no-cache /wheels/*

# Copy application code
COPY app.py .

# Set environment variables
ENV PORT=5001

# Switch to non-root user
USER appuser

# Expose the port
EXPOSE 5001

# Run the application
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "5001"] 