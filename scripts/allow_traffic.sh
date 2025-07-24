#!/bin/bash
# 실제 트래픽 허용 직전 최종 확인

echo "[AllowTraffic] HTTP 상태 점검 시작"

# 로컬에서 curl 테스트 (80번 포트)
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost)

if [ "$HTTP_CODE" != "200" ]; then
  echo "[ERROR] localhost 응답 코드: $HTTP_CODE"
  exit 1
else
  echo "[OK] HTTP 상태 코드: $HTTP_CODE"
fi
