#!/usr/bin/env bash
#
# ═══════════════════════════════════════════════════════════════
#  IRSupp Installer — IBSng (customized) + IBSng Telegram Bot
#
#  One-line install:
#    bash <(curl -fsSL https://raw.githubusercontent.com/hosein-boroumand/IBSngBot/main/IRSupp-IBSngBot-Installer.sh)
#
#  Menu-driven manager for two Docker stacks:
#    1) IBSng IRSupp customized image
#    2) IRSupp IBSng Bot (+ PostgreSQL)
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

# ── colors ──
R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'; B='\033[0;36m'; N='\033[0m'
ok()   { echo -e "${G}✅ $1${N}"; }
info() { echo -e "${B}ℹ️  $1${N}"; }
warn() { echo -e "${Y}⚠️  $1${N}"; }
err()  { echo -e "${R}❌ $1${N}"; }

# ── images ──
IBSNG_IMAGE="boroumandhosein/ibsng-irsupp:latest"
BOT_IMAGE="boroumandhosein/ibsngbot:latest"

# ── IBSng container ──
IBSNG_CONTAINER="ibsng"
IBSNG_VOLUME="ibsng_pgdata"
IBSNG_PG_DATA="/var/lib/pgsql/data"

# ── Bot containers ──
BOT_CONTAINER="ibsng_bot_app"
BOT_DB_CONTAINER="ibsng_bot_db"
BOT_DB_VOLUME="ibsng_bot_pgdata"
BOT_DB_PORT="5433"                   # host-local port for the bot's PostgreSQL
BOT_ENV_DIR="/opt/ibsng_bot"
BOT_ENV_FILE="${BOT_ENV_DIR}/bot.env"

# ═══════════════════════════════════════════════════════════════
#  Helpers
# ═══════════════════════════════════════════════════════════════

require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        err "This script must be run as root (use: sudo bash irsupp-installer.sh)."
        exit 1
    fi
}

pause() { echo ""; read -rp "$(echo -e "${Y}Press Enter to continue...${N}")" _; }

ask_port() {
    # ask_port "prompt" default  → echoes chosen port
    local prompt="$1" default="$2" var
    while true; do
        read -rp "$(echo -e "${Y}${prompt}${N} [default ${default}]: ")" var
        var="${var:-$default}"
        if ! [[ "$var" =~ ^[0-9]+$ ]] || [ "$var" -lt 1 ] || [ "$var" -gt 65535 ]; then
            err "Invalid port. Enter a number between 1 and 65535."
            continue
        fi
        echo "$var"
        return
    done
}

container_exists() { docker ps -a --format '{{.Names}}' 2>/dev/null | grep -qx "$1"; }
container_running() { docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "$1"; }

# Read the image tag a container was created from (e.g. "1.0.2" or "latest").
installed_version() {
    local c="$1" img
    img="$(docker inspect --format '{{.Config.Image}}' "$c" 2>/dev/null || true)"
    [ -z "$img" ] && { echo "unknown"; return; }
    case "$img" in
        *:*) echo "${img##*:}" ;;
        *)   echo "latest" ;;
    esac
}

# Short image ID currently in use — helps tell two "latest" builds apart.
installed_build() {
    local c="$1" id
    id="$(docker inspect --format '{{.Image}}' "$c" 2>/dev/null || true)"
    [ -z "$id" ] && { echo ""; return; }
    echo "${id#sha256:}" | cut -c1-12
}

install_docker() {
    if command -v docker >/dev/null 2>&1; then
        ok "Docker is already installed ($(docker --version | cut -d, -f1))."
        return
    fi
    info "Docker is not installed. Installing..."
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update -y
        apt-get install -y ca-certificates curl gnupg
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null || \
        curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg
        . /etc/os-release
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable" \
            > /etc/apt/sources.list.d/docker.list
        apt-get update -y
        apt-get install -y docker-ce docker-ce-cli containerd.io
    elif command -v yum >/dev/null 2>&1; then
        yum install -y yum-utils
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        yum install -y docker-ce docker-ce-cli containerd.io
    else
        err "No supported package manager (apt/yum) found. Please install Docker manually."
        exit 1
    fi
    systemctl enable --now docker
    ok "Docker installed and started."
}

# ═══════════════════════════════════════════════════════════════
#  1) IBSng — install & management
# ═══════════════════════════════════════════════════════════════

ibsng_install() {
    install_docker

    echo ""
    info "Enter ports (press Enter to accept defaults):"
    echo ""
    local WEB_PORT API_PORT AUTH_PORT ACCT_PORT
    WEB_PORT=$(ask_port "Web port (IBSng admin panel)" 80)
    API_PORT=$(ask_port "API port (XML-RPC — the bot connects here)" 1235)
    AUTH_PORT=$(ask_port "RADIUS Authentication port (UDP)" 1812)
    ACCT_PORT=$(ask_port "RADIUS Accounting port (UDP)" 1813)

    echo ""
    info "Port summary:"
    echo -e "   Web:         ${G}$WEB_PORT${N}  → 80/tcp"
    echo -e "   API:         ${G}$API_PORT${N}  → 1235/tcp"
    echo -e "   RADIUS auth: ${G}$AUTH_PORT${N} → 1812/udp"
    echo -e "   RADIUS acct: ${G}$ACCT_PORT${N} → 1813/udp"
    echo ""
    local confirm
    read -rp "$(echo -e "${Y}Proceed? (y/n): ${N}")" confirm
    [ "$confirm" != "y" ] && { warn "Cancelled."; return; }

    if container_exists "$IBSNG_CONTAINER"; then
        warn "A container named '$IBSNG_CONTAINER' already exists."
        local re
        read -rp "$(echo -e "${Y}Remove and reinstall? (volume data is kept) (y/n): ${N}")" re
        if [ "$re" = "y" ]; then
            docker rm -f "$IBSNG_CONTAINER"
            ok "Old container removed."
        else
            warn "Cancelled."; return
        fi
    fi

    info "Pulling image (this may take a few minutes)..."
    docker pull "$IBSNG_IMAGE"
    ok "Image ready."

    docker volume create "$IBSNG_VOLUME" >/dev/null
    ok "Persistent volume '$IBSNG_VOLUME' ready (data survives restarts)."

    info "Starting container..."
    docker run -d \
        --name "$IBSNG_CONTAINER" \
        --restart unless-stopped \
        -p "${WEB_PORT}:80/tcp" \
        -p "${API_PORT}:1235/tcp" \
        -p "${AUTH_PORT}:1812/udp" \
        -p "${ACCT_PORT}:1813/udp" \
        -v "${IBSNG_VOLUME}:${IBSNG_PG_DATA}" \
        "$IBSNG_IMAGE"

    sleep 6
    if container_running "$IBSNG_CONTAINER"; then
        ok "IBSng container started successfully!"
    else
        err "Container failed to start. Logs:"
        docker logs "$IBSNG_CONTAINER" 2>&1 | tail -20
        return
    fi

    local SERVER_IP
    SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
    echo ""
    echo -e "${G}═══════════════════════════════════════════════${N}"
    echo -e "${G}            IBSng installation complete ✅${N}"
    echo -e "${G}═══════════════════════════════════════════════${N}"
    echo ""
    echo -e "🌐 Web panel:   ${B}http://${SERVER_IP}:${WEB_PORT}/IBSng/admin${N}"
    echo -e "🔌 API (XML-RPC): port ${B}${API_PORT}${N} (for the bot)"
    echo -e "📡 RADIUS auth: port ${B}${AUTH_PORT}/udp${N}"
    echo -e "📡 RADIUS acct: port ${B}${ACCT_PORT}/udp${N}"
    echo ""
    echo -e "👤 Default login: user ${Y}system${N} / password ${Y}admin${N}"
    echo ""
    warn "To connect the bot: set host=127.0.0.1 and API port=${API_PORT} in the bot's server settings."
    warn "RADIUS ports must be open as UDP (not TCP)."
    pause
}

# ═══════════════════════════════════════════════════════════════
#  2) Bot — install & management
# ═══════════════════════════════════════════════════════════════

bot_install() {
    install_docker

    echo ""
    info "Bot configuration — please provide the following:"
    echo ""

    local IN_BOT_TOKEN IN_ADMIN_IDS IN_LICENSE_KEY IN_LICENSE_SERVER
    read -rp "$(echo -e "${Y}Telegram bot token (BOT_TOKEN): ${N}")" IN_BOT_TOKEN
    while [ -z "$IN_BOT_TOKEN" ]; do
        warn "Bot token is required."
        read -rp "$(echo -e "${Y}Telegram bot token (BOT_TOKEN): ${N}")" IN_BOT_TOKEN
    done

    read -rp "$(echo -e "${Y}Admin numeric IDs (comma-separated, e.g. 123,456): ${N}")" IN_ADMIN_IDS
    while [ -z "$IN_ADMIN_IDS" ]; do
        warn "At least one admin ID is required."
        read -rp "$(echo -e "${Y}Admin numeric IDs: ${N}")" IN_ADMIN_IDS
    done

    read -rp "$(echo -e "${Y}License key (LICENSE_KEY): ${N}")" IN_LICENSE_KEY
    read -rp "$(echo -e "${Y}License server URL [default https://bot.irsupp.ir]: ${N}")" IN_LICENSE_SERVER
    IN_LICENSE_SERVER="${IN_LICENSE_SERVER:-https://bot.irsupp.ir}"

    # ── generate secrets ──
    info "Generating FERNET_KEY, stable HARDWARE_ID and DB password..."

    local FERNET_KEY
    FERNET_KEY="$(docker run --rm python:3.12-slim \
        sh -c 'pip install -q cryptography >/dev/null 2>&1 && python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"')"

    local HARDWARE_ID
    if [ -f /etc/machine-id ]; then
        HARDWARE_ID="$(cat /etc/machine-id)"
    else
        HARDWARE_ID="$(cat /proc/sys/kernel/random/uuid)"
    fi

    local DB_PASS
    DB_PASS="$(openssl rand -base64 24 | tr -d '/+=' | head -c 24)"

    # ── write env file ──
    mkdir -p "$BOT_ENV_DIR"
    cat > "$BOT_ENV_FILE" <<EOF
# IRSupp IBSng Bot — configuration (generated by installer)
BOT_TOKEN=${IN_BOT_TOKEN}
ADMIN_IDS=${IN_ADMIN_IDS}
DB_USER=ibsng_bot
DB_PASS=${DB_PASS}
DB_HOST=127.0.0.1
DB_PORT=${BOT_DB_PORT}
DB_NAME=ibsng_bot
FERNET_KEY=${FERNET_KEY}
PRODUCT=ibsng_bot
HARDWARE_ID=${HARDWARE_ID}
LICENSE_KEY=${IN_LICENSE_KEY}
LICENSE_SERVER=${IN_LICENSE_SERVER}
LOG_LEVEL=INFO
EOF
    chmod 600 "$BOT_ENV_FILE"
    ok "Configuration saved to ${BOT_ENV_FILE}"

    # ── remove old containers if present (data volume kept) ──
    if container_exists "$BOT_CONTAINER"; then
        warn "Bot container already exists — removing (DB volume is kept)."
        docker rm -f "$BOT_CONTAINER" >/dev/null 2>&1 || true
    fi
    if container_exists "$BOT_DB_CONTAINER"; then
        docker rm -f "$BOT_DB_CONTAINER" >/dev/null 2>&1 || true
    fi

    # ── volume (host networking is used; no custom network needed) ──
    docker volume create "$BOT_DB_VOLUME" >/dev/null
    ok "Persistent DB volume ready."

    # ── pull images ──
    info "Pulling PostgreSQL image..."
    docker pull postgres:16-alpine
    info "Pulling bot image (this may take a few minutes)..."
    docker pull "$BOT_IMAGE"
    ok "Images ready."

    # ── start PostgreSQL (bound to host-local port only, not exposed publicly) ──
    info "Starting PostgreSQL..."
    docker run -d \
        --name "$BOT_DB_CONTAINER" \
        --restart unless-stopped \
        -p "127.0.0.1:${BOT_DB_PORT}:5432" \
        -e POSTGRES_USER=ibsng_bot \
        -e POSTGRES_PASSWORD="${DB_PASS}" \
        -e POSTGRES_DB=ibsng_bot \
        -v "${BOT_DB_VOLUME}:/var/lib/postgresql/data" \
        postgres:16-alpine

    # ── wait for DB health ──
    info "Waiting for the database to become ready..."
    local tries=0
    until docker exec "$BOT_DB_CONTAINER" pg_isready -U ibsng_bot -d ibsng_bot >/dev/null 2>&1; do
        tries=$((tries + 1))
        if [ "$tries" -ge 30 ]; then
            err "Database did not become ready in time. Logs:"
            docker logs "$BOT_DB_CONTAINER" 2>&1 | tail -20
            return
        fi
        sleep 2
    done
    ok "Database is ready."

    # ── start bot ──
    # Host networking: the bot shares the server's network stack, so
    #   - it reaches IBSng at 127.0.0.1:<API port> (exactly like the old setup)
    #   - it reaches its PostgreSQL at 127.0.0.1:${BOT_DB_PORT}
    # No panel changes needed: keep host=127.0.0.1 and the IBSng API port.
    info "Starting the bot..."
    docker run -d \
        --name "$BOT_CONTAINER" \
        --restart unless-stopped \
        --network host \
        --env-file "$BOT_ENV_FILE" \
        "$BOT_IMAGE"

    sleep 6
    if container_running "$BOT_CONTAINER"; then
        ok "Bot container started successfully!"
    else
        err "Bot failed to start. Logs:"
        docker logs "$BOT_CONTAINER" 2>&1 | tail -30
        return
    fi

    echo ""
    echo -e "${G}═══════════════════════════════════════════════${N}"
    echo -e "${G}            Bot installation complete ✅${N}"
    echo -e "${G}═══════════════════════════════════════════════${N}"
    echo ""
    echo -e "🤖 The bot is now running. Open Telegram and send /start."
    echo -e "🔑 Stable HARDWARE_ID: ${B}${HARDWARE_ID:0:8}...${N}"
    echo ""
    info "To connect the bot to IBSng, in the bot's server settings use:"
    echo -e "     host = ${G}127.0.0.1${N}   API port = ${G}1235${N} (or your chosen IBSng API port)"
    echo ""
    warn "If you move to a new server, the license must be re-issued for the new HARDWARE_ID."
    warn "Never change FERNET_KEY — encrypted IBSng passwords depend on it."
    pause
}

# ═══════════════════════════════════════════════════════════════
#  Generic management actions (status / logs / restart / delete)
# ═══════════════════════════════════════════════════════════════

show_status() {
    local c="$1"
    if container_exists "$c"; then
        echo ""
        echo -e "  Image:   ${B}$(docker inspect --format '{{.Config.Image}}' "$c" 2>/dev/null)${N}"
        echo -e "  Version: ${B}$(installed_version "$c")${N}   Build: ${B}$(installed_build "$c")${N}"
        echo ""
        docker ps -a --filter "name=^/${c}$" \
            --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        echo ""
    else
        warn "Container '$c' is not installed yet."
    fi
    pause
}

show_live_log() {
    local c="$1"
    if ! container_exists "$c"; then
        warn "Container '$c' is not installed yet."
        pause
        return
    fi
    info "Showing live logs for '$c' — press Ctrl+C to exit."
    echo ""
    # Show the last 200 lines then keep following. Ctrl+C exits the script
    # completely and returns to the server shell.
    exec docker logs --tail 200 -f "$c"
}

restart_container() {
    local c="$1"
    if container_exists "$c"; then
        docker restart "$c" >/dev/null && ok "'$c' restarted."
    else
        warn "Container '$c' is not installed yet."
    fi
    pause
}

# ═══════════════════════════════════════════════════════════════
#  Sub-menus
# ═══════════════════════════════════════════════════════════════

ibsng_menu() {
    while true; do
        clear
        echo -e "${B}═══════════════════════════════════════════════${N}"
        echo -e "${B}  1) IBSng IRSupp — Management${N}"
        echo -e "${B}═══════════════════════════════════════════════${N}"
        echo ""
        if container_running "$IBSNG_CONTAINER"; then
            echo -e "  State:   ${G}running${N}"
            echo -e "  Version: ${B}$(installed_version "$IBSNG_CONTAINER")${N}  (build $(installed_build "$IBSNG_CONTAINER"))"
        elif container_exists "$IBSNG_CONTAINER"; then
            echo -e "  State:   ${Y}stopped${N}"
            echo -e "  Version: ${B}$(installed_version "$IBSNG_CONTAINER")${N}  (build $(installed_build "$IBSNG_CONTAINER"))"
        else
            echo -e "  State:   ${R}not installed${N}"
        fi
        echo ""
        echo "  1) Install / Reinstall"
        echo "  2) Status"
        echo "  3) Live Log"
        echo "  4) Restart"
        echo "  5) Update (pull latest image)"
        echo "  6) Delete (keeps data volume)"
        echo "  7) Back"
        echo ""
        read -rp "Select: " ch
        case "$ch" in
            1) ibsng_install ;;
            2) show_status "$IBSNG_CONTAINER" ;;
            3) show_live_log "$IBSNG_CONTAINER" ;;
            4) restart_container "$IBSNG_CONTAINER" ;;
            5) ibsng_update ;;
            6) ibsng_delete ;;
            7) return ;;
            *) warn "Invalid choice."; sleep 1 ;;
        esac
    done
}

ibsng_delete() {
    if ! container_exists "$IBSNG_CONTAINER"; then
        warn "Nothing to delete."; pause; return
    fi
    local c
    read -rp "$(echo -e "${Y}Delete IBSng container? Data volume is kept. (y/n): ${N}")" c
    if [ "$c" = "y" ]; then
        docker rm -f "$IBSNG_CONTAINER" >/dev/null && ok "IBSng container removed (volume '$IBSNG_VOLUME' kept)."
    else
        warn "Cancelled."
    fi
    pause
}

ibsng_update() {
    if ! container_exists "$IBSNG_CONTAINER"; then
        warn "IBSng is not installed yet. Use Install first."
        pause; return
    fi

    # read the currently mapped host ports so the user isn't asked again
    local WEB_PORT API_PORT AUTH_PORT ACCT_PORT
    WEB_PORT=$(docker port "$IBSNG_CONTAINER" 80/tcp 2>/dev/null | head -1 | sed 's/.*://')
    API_PORT=$(docker port "$IBSNG_CONTAINER" 1235/tcp 2>/dev/null | head -1 | sed 's/.*://')
    AUTH_PORT=$(docker port "$IBSNG_CONTAINER" 1812/udp 2>/dev/null | head -1 | sed 's/.*://')
    ACCT_PORT=$(docker port "$IBSNG_CONTAINER" 1813/udp 2>/dev/null | head -1 | sed 's/.*://')
    WEB_PORT="${WEB_PORT:-80}"; API_PORT="${API_PORT:-1235}"
    AUTH_PORT="${AUTH_PORT:-1812}"; ACCT_PORT="${ACCT_PORT:-1813}"

    info "Current ports — Web:${WEB_PORT} API:${API_PORT} auth:${AUTH_PORT} acct:${ACCT_PORT}"
    warn "Update will pull the latest image and recreate the container."
    warn "Your data (volume '$IBSNG_VOLUME') is kept."
    local c
    read -rp "$(echo -e "${Y}Proceed with update? (y/n): ${N}")" c
    [ "$c" != "y" ] && { warn "Cancelled."; pause; return; }

    info "Pulling latest image..."
    docker pull "$IBSNG_IMAGE"

    info "Recreating container with the same ports..."
    docker rm -f "$IBSNG_CONTAINER" >/dev/null
    docker run -d \
        --name "$IBSNG_CONTAINER" \
        --restart unless-stopped \
        -p "${API_PORT}:1235/tcp" \
        -p "${WEB_PORT}:80/tcp" \
        -p "${AUTH_PORT}:1812/udp" \
        -p "${ACCT_PORT}:1813/udp" \
        -v "${IBSNG_VOLUME}:${IBSNG_PG_DATA}" \
        "$IBSNG_IMAGE"

    sleep 6
    if container_running "$IBSNG_CONTAINER"; then
        ok "IBSng updated and running."
    else
        err "Container failed to start after update. Logs:"
        docker logs "$IBSNG_CONTAINER" 2>&1 | tail -20
    fi
    pause
}

bot_menu() {
    while true; do
        clear
        echo -e "${B}═══════════════════════════════════════════════${N}"
        echo -e "${B}  2) IRSupp IBSng Bot — Management${N}"
        echo -e "${B}═══════════════════════════════════════════════${N}"
        echo ""
        if container_running "$BOT_CONTAINER"; then
            echo -e "  State:   ${G}running${N}"
            echo -e "  Version: ${B}$(installed_version "$BOT_CONTAINER")${N}  (build $(installed_build "$BOT_CONTAINER"))"
        elif container_exists "$BOT_CONTAINER"; then
            echo -e "  State:   ${Y}stopped${N}"
            echo -e "  Version: ${B}$(installed_version "$BOT_CONTAINER")${N}  (build $(installed_build "$BOT_CONTAINER"))"
        else
            echo -e "  State:   ${R}not installed${N}"
        fi
        echo ""
        echo "  1) Install / Reinstall"
        echo "  2) Status"
        echo "  3) Live Log"
        echo "  4) Restart"
        echo "  5) Update (pull latest image)"
        echo "  6) Delete (keeps data volume)"
        echo "  7) Back"
        echo ""
        read -rp "Select: " ch
        case "$ch" in
            1) bot_install ;;
            2) show_status "$BOT_CONTAINER" ;;
            3) show_live_log "$BOT_CONTAINER" ;;
            4) restart_container "$BOT_CONTAINER" ;;
            5) bot_update ;;
            6) bot_delete ;;
            7) return ;;
            *) warn "Invalid choice."; sleep 1 ;;
        esac
    done
}

bot_delete() {
    if ! container_exists "$BOT_CONTAINER" && ! container_exists "$BOT_DB_CONTAINER"; then
        warn "Nothing to delete."; pause; return
    fi
    local c
    read -rp "$(echo -e "${Y}Delete bot containers? DB data volume is kept. (y/n): ${N}")" c
    if [ "$c" = "y" ]; then
        docker rm -f "$BOT_CONTAINER" >/dev/null 2>&1 || true
        docker rm -f "$BOT_DB_CONTAINER" >/dev/null 2>&1 || true
        ok "Bot containers removed (volume '$BOT_DB_VOLUME' kept)."
    else
        warn "Cancelled."
    fi
    pause
}

bot_update() {
    if ! container_exists "$BOT_CONTAINER"; then
        warn "The bot is not installed yet. Use Install first."
        pause; return
    fi
    if [ ! -f "$BOT_ENV_FILE" ]; then
        err "Configuration file not found (${BOT_ENV_FILE})."
        err "Cannot update without existing config. Use Install / Reinstall instead."
        pause; return
    fi

    warn "Update will pull the latest bot image and recreate the app container."
    warn "Your settings (${BOT_ENV_FILE}) and database volume are kept."
    warn "The database container is NOT touched."
    local c
    read -rp "$(echo -e "${Y}Proceed with update? (y/n): ${N}")" c
    [ "$c" != "y" ] && { warn "Cancelled."; pause; return; }

    info "Pulling latest bot image..."
    docker pull "$BOT_IMAGE"

    # make sure the database container is running (update only recreates the app)
    if ! container_running "$BOT_DB_CONTAINER"; then
        warn "Database container is not running — starting it..."
        docker start "$BOT_DB_CONTAINER" >/dev/null 2>&1 || {
            err "Could not start the database container. Aborting update."
            pause; return
        }
        sleep 4
    fi

    info "Recreating the bot container with existing settings..."
    docker rm -f "$BOT_CONTAINER" >/dev/null
    docker run -d \
        --name "$BOT_CONTAINER" \
        --restart unless-stopped \
        --network host \
        --env-file "$BOT_ENV_FILE" \
        "$BOT_IMAGE"

    sleep 6
    if container_running "$BOT_CONTAINER"; then
        ok "Bot updated and running."
    else
        err "Bot failed to start after update. Logs:"
        docker logs "$BOT_CONTAINER" 2>&1 | tail -30
    fi
    pause
}

# ═══════════════════════════════════════════════════════════════
#  Main menu
# ═══════════════════════════════════════════════════════════════

main_menu() {
    while true; do
        clear
        echo -e "${G}═══════════════════════════════════════════════${N}"
        echo -e "${G}        IRSupp Installer — IBSng & Bot${N}"
        echo -e "${G}═══════════════════════════════════════════════${N}"
        echo ""
        # installed versions at a glance
        if container_exists "$IBSNG_CONTAINER"; then
            if container_running "$IBSNG_CONTAINER"; then
                echo -e "  IBSng : ${G}running${N}  version ${B}$(installed_version "$IBSNG_CONTAINER")${N}"
            else
                echo -e "  IBSng : ${Y}stopped${N}  version ${B}$(installed_version "$IBSNG_CONTAINER")${N}"
            fi
        else
            echo -e "  IBSng : ${R}not installed${N}"
        fi
        if container_exists "$BOT_CONTAINER"; then
            if container_running "$BOT_CONTAINER"; then
                echo -e "  Bot   : ${G}running${N}  version ${B}$(installed_version "$BOT_CONTAINER")${N}"
            else
                echo -e "  Bot   : ${Y}stopped${N}  version ${B}$(installed_version "$BOT_CONTAINER")${N}"
            fi
        else
            echo -e "  Bot   : ${R}not installed${N}"
        fi
        echo ""
        echo "  1) Install IBSng IRSupp Customize version"
        echo "  2) Install IRSupp IBSng Bot"
        echo "  3) Exit"
        echo ""
        read -rp "Select: " ch
        case "$ch" in
            1) ibsng_menu ;;
            2) bot_menu ;;
            3) echo ""; ok "Bye."; exit 0 ;;
            *) warn "Invalid choice."; sleep 1 ;;
        esac
    done
}

require_root

# When run via  bash <(curl ...)  stdin is the pipe, not the keyboard.
# Reconnect stdin to the terminal so all interactive prompts work.
if [ -t 1 ] && [ -e /dev/tty ]; then
    exec < /dev/tty
fi

main_menu
