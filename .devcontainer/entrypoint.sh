#!/bin/bash
# Run setup only on first start (use a marker file)
if [ ! -f /home/node/.setup-done ]; then
  /workspace/.devcontainer/setup-git.sh
  sudo /usr/local/bin/init-firewall.sh
  touch /home/node/.setup-done
fi
exec "$@"
