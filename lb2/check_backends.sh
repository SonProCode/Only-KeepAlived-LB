#!/bin/bash

VIP="172.20.0.100:80"

# Backend list
BACKENDS=(
  "172.20.0.10:80"
  "172.20.0.11:80"
)

for backend in "${BACKENDS[@]}"; do
  IP=$(echo $backend | cut -d: -f1)
  PORT=$(echo $backend | cut -d: -f2)

  # Check backend alive
  if curl -s --max-time 1 http://$IP:$PORT > /dev/null; then
    # Nếu chưa có trong IPVS thì add lại
    ipvsadm -L -n | grep -q "$IP:$PORT"
    if [ $? -ne 0 ]; then
      echo "[+] Add back $backend"
      ipvsadm -a -t $VIP -r $backend -m
    fi
  else
    # Nếu backend chết → remove khỏi IPVS
    ipvsadm -L -n | grep -q "$IP:$PORT"
    if [ $? -eq 0 ]; then
      echo "[-] Remove dead backend $backend"
      ipvsadm -d -t $VIP -r $backend
    fi
  fi
done