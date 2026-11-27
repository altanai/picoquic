#!/bin/bash
set -eu
ROOT="/mnt/c/Users/altan/Downloads/ietf/quic/picoquic"
TRIAL="$ROOT/qlog-trial-multipath"
rm -rf "$TRIAL"
mkdir -p "$TRIAL/www" "$TRIAL/server" "$TRIAL/client" "$TRIAL/download"
cat > "$TRIAL/www/index.html" << 'HTML'
<!DOCTYPE html>
<html><body>
<h1>picoquic multipath qlog trial</h1>
<p>Second path uses the same address and a different UDP port.</p>
</body></html>
HTML
cd "$ROOT/build"
./picoquicdemo -1 -L -M -p 44434 \
  -c "$ROOT/certs/cert.pem" \
  -k "$ROOT/certs/key.pem" \
  -T "$TRIAL/server-tickets.bin" \
  -N "$TRIAL/server-tokens.bin" \
  -w "$TRIAL/www" \
  -q "$TRIAL/server" \
  > "$TRIAL/server.log" 2>&1 &
SERVER_PID=$!
sleep 1
set +e
./picoquicdemo -L -M -A "0.0.0.0/0" \
  -n test.example.com \
  -t "$ROOT/certs/test-ca.crt" \
  -T "$TRIAL/client-tickets.bin" \
  -N "$TRIAL/client-tokens.bin" \
  -o "$TRIAL/download" \
  -q "$TRIAL/client" \
  127.0.0.1 44434 '*0:0:/200000;' \
  > "$TRIAL/client.log" 2>&1
CLIENT_EXIT=$?
set -e
sleep 1
if kill -0 "$SERVER_PID" 2>/dev/null; then
  kill "$SERVER_PID" || true
  wait "$SERVER_PID" || true
fi
echo "CLIENT_EXIT=$CLIENT_EXIT"
echo "--- server log ---"
cat "$TRIAL/server.log" || true
echo "--- client log ---"
cat "$TRIAL/client.log" || true
echo "--- download ---"
ls -la "$TRIAL/download" || true
echo "--- qlogs ---"
find "$TRIAL" -name '*.qlog' -printf '%p %s\n' || true
