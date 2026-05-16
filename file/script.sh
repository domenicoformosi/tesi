#!/usr/bin/env bash
# ============================================================
# docker_network_setup.sh
# ============================================================

set -euo pipefail

# ---------- Configurazione ----------
NETWORK_NAME="mynet"
CONTAINER_1="node1"
CONTAINER_2="node2"
CONTAINER_3="node3"
IMAGE="alpine:latest"       

# Colori per output
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log()  { echo -e "${CYAN}[INFO]${NC}  $*"; }
ok()   { echo -e "${GREEN}[OK]${NC}    $*"; }
err()  { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ---------- Pulizia preventiva ----------
cleanup() {
  log "Pulizia risorse esistenti (se presenti)..."
  docker rm -f "$CONTAINER_1" "$CONTAINER_2" "$CONTAINER_3" 2>/dev/null && ok "Container rimossi" || true
  docker network rm "$NETWORK_NAME"             2>/dev/null && ok "Rete rimossa"     || true
}

cleanup

# ---------- 1. Crea la rete bridge ----------
log "Creazione rete Docker: $NETWORK_NAME"
docker network create \
  --driver bridge \
  --subnet 172.20.0.0/24 \
  --gateway 172.20.0.1 \
  "$NETWORK_NAME"
ok "Rete '$NETWORK_NAME' creata (172.20.0.0/24)"

# ---------- 2. Avvia i container ----------
log "Avvio container: $CONTAINER_1"
docker run -d \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_TIME \
  --name "$CONTAINER_1" \
  --network "$NETWORK_NAME" \
  --ip 172.20.0.10 \
  "$IMAGE" \
  sh -c "while true; do sleep 3600; done"
ok "$CONTAINER_1 avviato (IP: 172.20.0.10)"

log "Avvio container: $CONTAINER_2"
docker run -d \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_TIME \
  --name "$CONTAINER_2" \
  --network "$NETWORK_NAME" \
  --ip 172.20.0.11 \
  "$IMAGE" \
  sh -c "while true; do sleep 3600; done"
ok "$CONTAINER_2 avviato (IP: 172.20.0.11)"

log "Avvio container: $CONTAINER_3"
docker run -d \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_TIME \
  --name "$CONTAINER_3" \
  --network "$NETWORK_NAME" \
  --ip 172.20.0.12 \
  "$IMAGE" \
  sh -c "while true; do sleep 3600; done"
ok "$CONTAINER_3 avviato (IP: 172.20.0.12)"

# ---------- 3. Verifica connettività ----------
log "Test ping: $CONTAINER_1 → $CONTAINER_2 (per nome)"
docker exec "$CONTAINER_1" ping -c 3 "$CONTAINER_2" \
  && ok "Ping riuscito: $CONTAINER_1 → $CONTAINER_2" \
  || err "Ping fallito!"

log "Test ping: $CONTAINER_2 → $CONTAINER_1 (per IP)"
docker exec "$CONTAINER_2" ping -c 3 172.20.0.10 \
  && ok "Ping riuscito: $CONTAINER_2 → $CONTAINER_1" \
  || err "Ping fallito!"

log "Test ping: $CONTAINER_3 → $CONTAINER_1 (per IP)"
docker exec "$CONTAINER_3" ping -c 3 172.20.0.10 \
  && ok "Ping riuscito: $CONTAINER_3 → $CONTAINER_1" \
  || err "Ping fallito!"

log "Test ping: $CONTAINER_3 → $CONTAINER_2 (per IP)"
docker exec "$CONTAINER_3" ping -c 3 172.20.0.11 \
  && ok "Ping riuscito: $CONTAINER_3 → $CONTAINER_2" \
  || err "Ping fallito!"


# ---------- 4. Installo tool necessari ----------
log "Install bash su $CONTAINER_1 e $CONTAINER_2 e $CONTAINER_3"

docker exec "$CONTAINER_1" apk add --no-cache bash \
  && ok "Bash installato su $CONTAINER_1" \
  || err "Installazione di bash fallita su $CONTAINER_1"

docker exec "$CONTAINER_2" apk add --no-cache bash \
  && ok "Bash installato su $CONTAINER_2" \
  || err "Installazione di bash fallita su $CONTAINER_2"

docker exec "$CONTAINER_3" apk add --no-cache bash \
  && ok "Bash installato su $CONTAINER_3" \
  || err "Installazione di bash fallita su $CONTAINER_3"

log "Abilito repository di testing su $CONTAINER_1 e $CONTAINER_2 e $CONTAINER_3"

docker exec "$CONTAINER_1" sh -c \
  'echo "@testing https://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories' \
  && ok "Repository di testing abilitato su $CONTAINER_1" \
  || err "Abilitazione repository di testing fallita su $CONTAINER_1"

docker exec "$CONTAINER_2" sh -c \
  'echo "@testing https://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories' \
  && ok "Repository di testing abilitato su $CONTAINER_2" \
  || err "Abilitazione repository di testing fallita su $CONTAINER_2"

docker exec "$CONTAINER_3" sh -c \
  'echo "@testing https://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories' \
  && ok "Repository di testing abilitato su $CONTAINER_3" \
  || err "Abilitazione repository di testing fallita su $CONTAINER_3"

log "Installo linuxptp su $CONTAINER_1 e $CONTAINER_2 e $CONTAINER_3"

docker exec "$CONTAINER_1" sh -c \
  'apk add --no-cache linuxptp \
   --repository=https://dl-cdn.alpinelinux.org/alpine/edge/testing \
   --allow-untrusted' \
  && ok "linuxptp installato su $CONTAINER_1" \
  || err "Installazione di linuxptp fallita su $CONTAINER_1"

docker exec "$CONTAINER_2" sh -c \
  'apk add --no-cache linuxptp \
   --repository=https://dl-cdn.alpinelinux.org/alpine/edge/testing \
   --allow-untrusted' \
  && ok "linuxptp installato su $CONTAINER_2" \
  || err "Installazione di linuxptp fallita su $CONTAINER_2"

docker exec "$CONTAINER_3" sh -c \
  'apk add --no-cache linuxptp \
   --repository=https://dl-cdn.alpinelinux.org/alpine/edge/testing \
   --allow-untrusted' \
  && ok "linuxptp installato su $CONTAINER_3" \
  || err "Installazione di linuxptp fallita su $CONTAINER_3"
  
# ---------- 5. Creo alias shell ----------
cat > /tmp/docker_aliases.sh <<EOF
alias node1="docker exec -it $CONTAINER_1 bash"
alias node2="docker exec -it $CONTAINER_2 bash"
alias node3="docker exec -it $CONTAINER_3 bash"
EOF
echo ""
ok "Esegui: source /tmp/docker_aliases.sh"
# ---------- 6. Copio file di configurazione linuxptp ----------
log "Copio file di configurazione linuxptp per $CONTAINER_1, $CONTAINER_2 e $CONTAINER_3"

docker cp oc.conf $CONTAINER_1:/etc/ptp4l.conf
docker cp oc.conf $CONTAINER_2:/etc/ptp4l.conf
docker cp gm.conf $CONTAINER_3:/etc/ptp4l.conf

# ---------- 7. Riepilogo ----------
echo ""
echo "============================================="
echo "  Riepilogo infrastruttura"
echo "============================================="
docker network inspect "$NETWORK_NAME" \
  --format '  Rete   : {{.Name}} ({{.Driver}}) — Subnet: {{range .IPAM.Config}}{{.Subnet}}{{end}}'
docker inspect "$CONTAINER_1" \
  --format "  $CONTAINER_1 : {{.NetworkSettings.Networks.${NETWORK_NAME}.IPAddress}}"
docker inspect "$CONTAINER_2" \
  --format "  $CONTAINER_2 : {{.NetworkSettings.Networks.${NETWORK_NAME}.IPAddress}}"
docker inspect "$CONTAINER_3" \
  --format "  $CONTAINER_3 : {{.NetworkSettings.Networks.${NETWORK_NAME}.IPAddress}}"
echo "============================================="
echo ""
ok "Setup completato! I container sono attivi e comunicano."
echo ""
echo "  Connettiti a node1:  docker exec -it $CONTAINER_1 bash"
echo "  Connettiti a node2:  docker exec -it $CONTAINER_2 bash"
echo "  Connettiti a node3:  docker exec -it $CONTAINER_3 bash"
echo "  Pulisci tutto:       docker rm -f $CONTAINER_1 $CONTAINER_2 $CONTAINER_3 && docker network rm $NETWORK_NAME"
