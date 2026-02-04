FROM docker.io/cloudflare/sandbox:0.7.0

# Install Node.js 22 (required by openclaw) and rsync (for R2 backup sync)
# The base image has Node 20, we need to replace it with Node 22
# Using direct binary download for reliability
ENV NODE_VERSION=22.13.1
RUN ARCH="$(dpkg --print-architecture)" \
    && case "${ARCH}" in \
         amd64) NODE_ARCH="x64" ;; \
         arm64) NODE_ARCH="arm64" ;; \
         *) echo "Unsupported architecture: ${ARCH}" >&2; exit 1 ;; \
       esac \
    && apt-get update && apt-get install -y xz-utils ca-certificates rsync tmux \
    && curl -fsSLk https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz -o /tmp/node.tar.xz \
    && tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 \
    && rm /tmp/node.tar.xz \
    && node --version \
    && npm --version

# Install pnpm globally
RUN npm install -g pnpm

# Install OpenClaw (gateway CLI)
# Pin to specific version for reproducible builds
RUN npm install -g openclaw@2026.1.29 \
    && openclaw --version

# Install agent-browser CLI (headless browser automation for AI agents)
RUN npm install -g agent-browser \
    && agent-browser install --with-deps 2>/dev/null || true

# Install Bitwarden CLI (credential management)
RUN npm install -g @bitwarden/cli \
    && bw --version

# Install Summarize CLI (URL/YouTube/podcast/PDF summarization)
RUN npm install -g @steipete/summarize \
    && summarize --version

# Install goplaces CLI (Google Places API)
RUN curl -fsSL https://github.com/steipete/goplaces/releases/download/v0.2.1/goplaces_0.2.1_linux_amd64.tar.gz -o /tmp/goplaces.tar.gz \
    && tar -xzf /tmp/goplaces.tar.gz -C /usr/local/bin goplaces \
    && rm /tmp/goplaces.tar.gz \
    && goplaces --help > /dev/null 2>&1

# Install uv (fast Python package manager - required for local-places, nano-pdf skills)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh \
    && ln -s /root/.local/bin/uv /usr/local/bin/uv \
    && ln -s /root/.local/bin/uvx /usr/local/bin/uvx \
    && uv --version

# Install GitHub CLI (gh)
RUN ARCH="$(dpkg --print-architecture)" \
    && curl -fsSL "https://github.com/cli/cli/releases/download/v2.67.0/gh_2.67.0_linux_${ARCH}.tar.gz" -o /tmp/gh.tar.gz \
    && tar -xzf /tmp/gh.tar.gz -C /tmp \
    && mv /tmp/gh_2.67.0_linux_${ARCH}/bin/gh /usr/local/bin/gh \
    && rm -rf /tmp/gh* \
    && gh --version

# Install Gemini CLI
RUN npm install -g @google/gemini-cli@latest \
    && gemini --version

# Install Go and build wacli (WhatsApp CLI)
# wacli only releases macOS binaries, so we build from source for Linux
# CGO is required for SQLite FTS5 support
ENV GO_VERSION=1.23.6
RUN apt-get update && apt-get install -y gcc libc6-dev \
    && ARCH="$(dpkg --print-architecture)" \
    && case "${ARCH}" in \
         amd64) GO_ARCH="amd64" ;; \
         arm64) GO_ARCH="arm64" ;; \
         *) echo "Unsupported architecture: ${ARCH}" >&2; exit 1 ;; \
       esac \
    && curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz" -o /tmp/go.tar.gz \
    && tar -C /usr/local -xzf /tmp/go.tar.gz \
    && rm /tmp/go.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"
RUN git clone --depth 1 https://github.com/steipete/wacli.git /tmp/wacli \
    && cd /tmp/wacli \
    && CGO_ENABLED=1 go build -tags sqlite_fts5 -o /usr/local/bin/wacli ./cmd/wacli \
    && rm -rf /tmp/wacli \
    && wacli --version

# Install imgbb CLI (image uploads)
RUN GOBIN=/usr/local/bin go install github.com/wabarc/imgbb/cmd/imgbb@latest \
    && imgbb --help > /dev/null 2>&1

# Create moltbot directories
# Templates are stored in /root/.openclaw-templates for initialization
RUN mkdir -p /root/.openclaw \
    && mkdir -p /root/.openclaw-templates \
    && mkdir -p /root/clawd \
    && mkdir -p /root/clawd/skills

# Copy startup script
ARG CACHE_BUST=2026-02-04-v18
COPY start-moltbot.sh /usr/local/bin/start-moltbot.sh
RUN chmod +x /usr/local/bin/start-moltbot.sh

# Copy default configuration template
COPY moltbot.json.template /root/.openclaw-templates/moltbot.json.template

# Copy custom skills
COPY skills/ /root/clawd/skills/

# Set working directory
WORKDIR /root/clawd

# Expose the gateway port
EXPOSE 18789
