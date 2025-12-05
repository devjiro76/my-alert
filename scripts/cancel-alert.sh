#!/bin/bash
# cancel-alert.sh - 알림 취소
# Usage:
#   cancel-alert.sh --id <alert_id>
#   cancel-alert.sh --time "YYYY-MM-DD HH:MM"
#   cancel-alert.sh --message <keyword>

CACHE_FILE="$HOME/.claude/cache/my-alert/alerts.json"

if [ ! -f "$CACHE_FILE" ]; then
    echo "❌ 등록된 알림이 없습니다."
    exit 1
fi

# 인자 파싱
MODE=""
VALUE=""

while [ $# -gt 0 ]; do
    case "$1" in
        --id)
            MODE="id"
            VALUE="$2"
            shift 2
            ;;
        --time)
            MODE="time"
            VALUE="$2"
            shift 2
            ;;
        --message)
            MODE="message"
            VALUE="$2"
            shift 2
            ;;
        *)
            echo "Usage: cancel-alert.sh --id <id> | --time <time> | --message <keyword>"
            exit 1
            ;;
    esac
done

if [ -z "$MODE" ] || [ -z "$VALUE" ]; then
    echo "Usage: cancel-alert.sh --id <id> | --time <time> | --message <keyword>"
    exit 1
fi

# Python으로 알림 삭제
python3 -c "
import json
from datetime import datetime

mode = '$MODE'
value = '''$VALUE'''

try:
    with open('$CACHE_FILE', 'r') as f:
        data = json.load(f)

    alerts = data.get('alerts', [])
    original_count = len(alerts)
    removed = []

    # 필터링
    if mode == 'id':
        remaining = [a for a in alerts if a.get('id') != value]
        removed = [a for a in alerts if a.get('id') == value]

    elif mode == 'time':
        # 시간 정규화
        time_normalized = value
        for fmt in ['%Y-%m-%d %H:%M:%S', '%Y-%m-%d %H:%M']:
            try:
                dt = datetime.strptime(value, fmt)
                time_normalized = dt.strftime('%Y-%m-%d %H:%M')
                break
            except:
                continue

        remaining = []
        for a in alerts:
            alert_time = a.get('time', '')
            # 시간 정규화
            for fmt in ['%Y-%m-%d %H:%M:%S', '%Y-%m-%d %H:%M']:
                try:
                    dt = datetime.strptime(alert_time, fmt)
                    alert_time = dt.strftime('%Y-%m-%d %H:%M')
                    break
                except:
                    continue

            if alert_time == time_normalized:
                removed.append(a)
            else:
                remaining.append(a)

    elif mode == 'message':
        remaining = [a for a in alerts if value not in a.get('message', '')]
        removed = [a for a in alerts if value in a.get('message', '')]

    else:
        print('❌ 잘못된 모드')
        exit(1)

    if not removed:
        print(f'❌ 해당 조건에 맞는 알림을 찾을 수 없습니다: {value}')
        exit(1)

    # 저장
    data['alerts'] = remaining
    with open('$CACHE_FILE', 'w') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    # 결과 출력
    print(f'✅ {len(removed)}개의 알림을 취소했습니다.')
    print()
    for alert in removed:
        print(f'  ID: {alert.get(\"id\")}')
        print(f'  시간: {alert.get(\"time\")}')
        print(f'  메시지: {alert.get(\"message\")}')
        print()

except Exception as e:
    print(f'❌ 오류: {e}')
    exit(1)
"

if [ $? -eq 0 ]; then
    exit 0
else
    exit 1
fi
