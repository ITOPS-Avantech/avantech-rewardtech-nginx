#!/usr/bin/env bash
# Run on avantech-publicapps-nginxGW-VM (Ubuntu) before starting Docker nginx.
# Usage: sudo bash vm-install-docker-stop-nginx.sh

set -euo pipefail

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "Run as root: sudo bash $0"
  exit 1
fi

echo "==> Stopping and disabling host nginx (Docker will bind 80/443)..."
systemctl stop nginx 2>/dev/null || true
systemctl disable nginx 2>/dev/null || true
systemctl status nginx --no-pager 2>/dev/null || echo "nginx service stopped or not installed"

echo "==> Installing Docker (official repo)..."
apt-get update
apt-get install -y ca-certificates curl gnupg

install -m 0755 -d /etc/apt/keyrings
if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
fi

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${VERSION_CODENAME:-$VERSION_ID}") stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "==> Enabling Docker..."
systemctl enable docker
systemctl start docker

echo "==> Adding current login user to docker group (if not root-only SSH)..."
if [[ -n "${SUDO_USER:-}" ]]; then
  usermod -aG docker "$SUDO_USER"
  echo "User $SUDO_USER added to group docker (log out and back in for group to apply)."
fi

echo ""
echo "Done."
docker --version
docker compose version
echo ""
echo "Next steps:"
echo "  1. Clone/copy avantech-rewardtech-nginx to the VM"
echo "  2. docker build -f Dockerfile_publicapps_waf -t avantech-publicapps-nginx-waf ."
echo "  3. docker run -d --name publicapps-nginx --network host --restart unless-stopped \\"
echo "       -v /home/azureuser/nginx:/etc/nginx/ssl:ro \\"
echo "       -v /var/www/certbot:/var/www/certbot:ro \\"
echo "       avantech-publicapps-nginx-waf"
