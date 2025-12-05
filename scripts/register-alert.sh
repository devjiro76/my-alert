#!/bin/bash
# register-alert.sh - 알림 등록 (캐시 기반)
# Usage: register-alert.sh "2025-12-02 14:00" "JIRA-111 해결하기" [notification|dialog]
# launchd job 대신 캐시 파일에 저장하여 macOS 등록 알림 방지

ALERT_TIME="$1"
MESSAGE="$2"
STYLE="${3:-dialog}"
CACHE_DIR="$HOME/.claude/cache/my-alert"
CACHE_FILE="$CACHE_DIR/alerts.json"

if [ -z "$ALERT_TIME" ] || [ -z "$MESSAGE" ]; then
    echo "Usage: register-alert.sh \"YYYY-MM-DD HH:MM\" \"message\" [notification|dialog]"
    exit 1
fi

# 캐시 디렉토리 생성
mkdir -p "$CACHE_DIR"

# 캐시 파일 없으면 초기화
if [ ! -f "$CACHE_FILE" ]; then
    echo '{"alerts": []}' > "$CACHE_FILE"
fi

# 고유 ID 생성
ALERT_ID="alert_$(date +%s)_$$"

# python으로 캐시에 알림 추가 (중복 체크 포함)
# 메시지를 환경변수로 전달하여 이스케이프 문제 방지
export ALERT_MESSAGE="$MESSAGE"

python3 -c "
import json
import os
from datetime import datetime

alert_time = '$ALERT_TIME'
message = os.environ.get('ALERT_MESSAGE', '')
style = '$STYLE'
alert_id = '$ALERT_ID'

# 시간 파싱 (epoch로 변환)
epoch_time = None
normalized_time = None
for fmt in ['%Y-%m-%d %H:%M:%S', '%Y-%m-%d %H:%M']:
    try:
        dt = datetime.strptime(alert_time, fmt)
        epoch_time = dt.timestamp()
        normalized_time = dt.strftime('%Y-%m-%d %H:%M')
        break
    except:
        continue

if epoch_time is None:
    print('ERROR: Invalid time format')
    exit(1)

try:
    with open('$CACHE_FILE', 'r') as f:
        data = json.load(f)
except:
    data = {'alerts': []}

# 중복 체크: 같은 시간(분 단위) + 같은 메시지 + shown=false
for alert in data.get('alerts', []):
    if alert.get('shown', False):
        continue  # 이미 표시된 알림은 무시

    # 시간 정규화
    existing_time = alert.get('time', '')
    for fmt in ['%Y-%m-%d %H:%M:%S', '%Y-%m-%d %H:%M']:
        try:
            dt = datetime.strptime(existing_time, fmt)
            existing_time = dt.strftime('%Y-%m-%d %H:%M')
            break
        except:
            continue

    # 중복 확인
    if existing_time == normalized_time and alert.get('message') == message:
        print(f'DUPLICATE: {alert.get(\"id\")}')
        exit(2)

# 새 알림 추가
data['alerts'].append({
    'id': alert_id,
    'time': normalized_time,
    'epoch': epoch_time,
    'message': message,
    'style': style,
    'shown': False,
    'created': datetime.now().isoformat()
})

with open('$CACHE_FILE', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print(f'OK')
"

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ Alert scheduled: $ALERT_TIME"
    echo "   Message: $MESSAGE"
    echo "   Style: $STYLE"
    echo "   ID: $ALERT_ID"
elif [ $EXIT_CODE -eq 2 ]; then
    echo "⚠️  중복된 알림입니다 (같은 시간 + 같은 메시지)"
    echo "   시간: $ALERT_TIME"
    echo "   메시지: $MESSAGE"
    exit 2
else
    echo "❌ Failed to schedule alert"
    exit 1
fi
