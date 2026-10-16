#!/usr/bin/env bash
# Generates traffic so the Grafana panels have live data.
# Usage: ./scripts/load-test.sh http://<ingress-host-or-localhost:3000> [iterations]
set -euo pipefail

BASE="${1:-http://localhost:3000}"
N="${2:-200}"
CATS=(food transport housing utilities health entertainment shopping other)

for i in $(seq 1 "$N"); do
  cat="${CATS[$((RANDOM % ${#CATS[@]}))]}"
  amount="$((RANDOM % 5000 + 50)).$((RANDOM % 100))"
  id=$(curl -s -X POST "$BASE/api/expenses" -H 'Content-Type: application/json' \
    -d "{\"title\":\"Load test $i\",\"amount\":\"$amount\",\"category\":\"$cat\",\"spent_on\":\"2026-10-15\"}" \
    | sed -E 's/.*"id":([0-9]+).*/\1/')
  curl -s -o /dev/null "$BASE/api/expenses"
  curl -s -o /dev/null "$BASE/api/summary"
  curl -s -o /dev/null "$BASE/api/expenses/$id"
  curl -s -o /dev/null "$BASE/api/expenses/999999"   # deliberate 404s for the status panel
  (( i % 3 == 0 )) && curl -s -o /dev/null -X DELETE "$BASE/api/expenses/$id"
  (( i % 20 == 0 )) && echo "  $i/$N iterations"
done
echo "Done."
