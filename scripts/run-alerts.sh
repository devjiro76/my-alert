#!/bin/bash
# run-alerts.sh - 알림 실행 (1분마다 체크 및 표시)

CACHE_FILE="$HOME/.claude/cache/my-alert/alerts.json"
SCRIPT_DIR="$HOME/Library/Scripts/my-alert"

# 캐시 파일 없으면 종료
if [ ! -f "$CACHE_FILE" ]; then
    exit 0
fi

NOW=$(date +%s)

# 알림 체크 및 표시
python3 -c "
import json
from datetime import datetime

def to_epoch(t):
    if isinstance(t, (int, float)):
        return t
    if isinstance(t, str):
        for fmt in ['%Y-%m-%d %H:%M:%S', '%Y-%m-%d %H:%M', '%Y-%m-%dT%H:%M:%S']:
            try:
                dt = datetime.strptime(t.replace('+09:00', ''), fmt)
                return dt.timestamp()
            except:
                continue
    return 0

try:
    with open('$CACHE_FILE', 'r') as f:
        data = json.load(f)

    now = $NOW
    triggered = []
    remaining = []

    for alert in data.get('alerts', []):
        alert_time = to_epoch(alert.get('time', 0))
        if alert_time <= now and not alert.get('shown', False):
            # 개행 치환
            msg = alert['message'].replace('\n', '␤')
            style = alert.get('style', 'dialog')
            triggered.append(f\"{msg}|{style}\")
            alert['shown'] = True
            remaining.append(alert)
        elif not alert.get('shown', False):
            remaining.append(alert)
        # shown=True인 과거 알림은 제거

    # 트리거된 알림 출력
    for t in triggered:
        print(t)

    # 캐시 업데이트 (완료된 알림 제거)
    data['alerts'] = remaining
    with open('$CACHE_FILE', 'w') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

except Exception as e:
    pass
" 2>/dev/null | while IFS='|' read -r message style; do
    if [ -n "$message" ]; then
        # ␤ 를 개행으로 복원
        message=$(echo "$message" | sed 's/␤/\n/g')
        "$SCRIPT_DIR/show-alert.sh" "예정된 알림" "$message" "$style"
    fi
done
