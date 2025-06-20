# ---- Build Stage ----
FROM rust:1.87-alpine3.22 AS builder

# Install git and build-base
RUN apk add --no-cache git build-base

# Clone repository
RUN git clone --depth 1 --branch v0.1.11 https://github.com/bobrippling/podsync/
WORKDIR /podsync

# Build binary
RUN cargo build --release --features backend-sql

# ---- Runtime Stage ----
FROM alpine:3.22

# Install sqlite3 (required to run add-user.sh)
RUN apk add --no-cache sqlite

# Copy files from builder
RUN mkdir /app
WORKDIR /app
COPY --from=builder /podsync/target/release/podsync /app/podsync
COPY --from=builder /podsync/scripts /app/scripts

# Move pod.sql to db folder to only have it in the volume
RUN mkdir /app/db
RUN touch /app/db/pod.sql
RUN ln -s /app/db/pod.sql /app/pod.sql

# Run podsync
ENTRYPOINT ["/app/podsync", "--address", "0.0.0.0", "--port", "80"]
