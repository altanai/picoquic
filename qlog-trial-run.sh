#!/bin/bash
set -eu
ROOT="/mnt/c/Users/altan/Downloads/ietf/quic/picoquic"
TRIAL="$ROOT/qlog-trial"
rm -rf "$TRIAL"
mkdir -p "$TRIAL/www" "$TRIAL/server" "$TRIAL/client" "$TRIAL/download"
cat > "$TRIAL/www/index.html" << 'HTML'
<!DOCTYPE html>
<html><body>
<h1>picoquic qlog trial</h1>
<p>Hello from the forked picoquic demo.</p>
</body></html>
HTML
cd "$ROOT/build"
./picoquicdemo -1 -L -p 44433 \
  -c "$ROOT/certs/cert.pem" \
  -k "$ROOT/certs/key.pem" \
  -w "$TRIAL/www" \
  -q "$TRIAL/server" \
  > "$TRIAL/server.log" 2>&1 &
SERVER_PID=$!
sleep 1
set +e
./picoquicdemo -L \
  -n test.example.com \
  -t "$ROOT/certs/test-ca.crt" \
  -o "$TRIAL/download" \
  -q "$TRIAL/client" \
  127.0.0.1 44433 '*0:0:/index.html;' \
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
