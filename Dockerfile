# Spotify MCP Server - Dockerfile
# Multi-stage build for optimal image size

# Stage 1: Dependencies
FROM oven/bun:1 AS deps
WORKDIR /app

# Copy package files
COPY package.json ./

# Install dependencies
RUN bun install --production

# Stage 2: Runtime
FROM oven/bun:1-slim AS runner
WORKDIR /app

# Create non-root user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 mcpuser

# Copy dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules

# Copy application code
COPY --chown=mcpuser:nodejs . .

# Create data directory for tokens
RUN mkdir -p .data && chown -R mcpuser:nodejs .data

# Switch to non-root user
USER mcpuser

# Expose ports
# 3356 = MCP server
# 3357 = OAuth callback server
EXPOSE 3356 3357

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD bun run -e 'fetch("http://localhost:3356/health").then(r => r.ok ? process.exit(0) : process.exit(1)).catch(() => process.exit(1))'

# Start server
CMD ["bun", "run", "src/index.ts"]
