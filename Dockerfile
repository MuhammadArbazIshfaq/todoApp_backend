# syntax=docker/dockerfile:1
# -----------------------------
# Ultra-lightweight Rails Dockerfile (<200MB)
# -----------------------------

# --- Base stage ---
ARG RUBY_VERSION=3.2.2
FROM ruby:$RUBY_VERSION-alpine AS base

# Set working directory
WORKDIR /app

# Install minimal runtime dependencies
RUN apk add --no-cache \
      libpq \
      tzdata \
      wget \
      && rm -rf /var/cache/apk/*

# Set production environment for smaller footprint
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    RAILS_LOG_TO_STDOUT="1" \
    RAILS_SERVE_STATIC_FILES="true"

# --- Build stage ---
FROM base AS build

# Install build dependencies
RUN apk add --no-cache \
      build-base \
      git \
      postgresql-dev \
      && rm -rf /var/cache/apk/*

# Copy Gemfiles and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local without 'development test' && \
    bundle install \
      --jobs $(nproc) \
      --retry 3 && \
    bundle clean --force && \
    rm -rf /usr/local/bundle/cache/*.gem && \
    find /usr/local/bundle -name "*.c" -delete 2>/dev/null || true && \
    find /usr/local/bundle -name "*.o" -delete 2>/dev/null || true

# Copy app source code
COPY . .

# Make entrypoint executable
RUN chmod +x /app/bin/docker-entrypoint

# Clean up unnecessary files
RUN rm -rf \
      /app/log/* \
      /app/tmp/* \
      /app/vendor/bundle/ruby/*/cache \
      /app/test \
      /app/spec \
      /app/.git* \
      /app/README.md

# --- Final runtime stage ---
FROM base

# Copy gems and app from build stage
COPY --from=build --chown=1000:1000 /usr/local/bundle /usr/local/bundle
COPY --from=build --chown=1000:1000 /app /app

WORKDIR /app

# Create non-root user for security
RUN addgroup -g 1000 -S rails && \
    adduser -u 1000 -S rails -G rails && \
    mkdir -p /app/tmp /app/log && \
    chown -R rails:rails /app

USER rails

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/up || exit 1# Expose HTTP port
EXPOSE 3000

# Default command (skip entrypoint for now)
CMD ["sh", "-c", "bundle exec rails db:prepare && bundle exec puma -C config/puma.rb"]
