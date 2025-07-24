#!/bin/bash
# 트래픽 허용 전 상태 점검

echo "[BeforeAllowTraffic] 서버 상태 점검 시작"

# Streamlit 프로세스가 떠 있는지 확인
pgrep -f "streamlit run ec2_main_home.py" > /dev/null

if [ $? -ne 0 ]; then
  echo "[ERROR] Streamlit 앱이 실행되고 있지 않음"
  exit 1
else
  echo "[OK] Streamlit 앱 정상 실행 중"
fi
