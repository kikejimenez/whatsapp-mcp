# Stage 1: build the Go WhatsApp bridge (CGO required for go-sqlite3)
# Using Debian-based Go image so the binary is glibc-compatible with python:3.11-slim
FROM golang:1.25-bookworm AS go-builder
WORKDIR /src
COPY whatsapp-bridge/go.mod whatsapp-bridge/go.sum ./
RUN go mod download
COPY whatsapp-bridge/ ./
RUN CGO_ENABLED=1 go build -o /out/whatsapp-bridge .

# Stage 2: runtime — Python + uv + compiled Go bridge
FROM python:3.11-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates ffmpeg \
    && rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir uv

COPY --from=go-builder /out/whatsapp-bridge /usr/local/bin/whatsapp-bridge

COPY whatsapp-mcp-server/ /app/whatsapp-mcp-server/
RUN cd /app/whatsapp-mcp-server && uv sync

RUN mkdir -p /app/whatsapp-bridge/store
WORKDIR /app/whatsapp-bridge

CMD ["whatsapp-bridge"]
