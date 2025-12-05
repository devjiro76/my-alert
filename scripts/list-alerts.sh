#!/bin/bash
# list-alerts.sh - 등록된 알림 목록 보기
# Usage: list-alerts.sh [--all|--upcoming]

CACHE_FILE="$HOME/.claude/cache/my-alert/alerts.json"

# 옵션 처리
FILTER="${1:---upcoming}"

if [ ! -f "$CACHE_FILE" ]; then
    echo "📋 등록된 알림이 없습니다."
    exit 0
fi

# Python으로 알림 목록 출력
python3 -c "
import json
from datetime import datetime

filter_mode = '$FILTER'

try:
    with open('$CACHE_FILE', 'r') as f:
        data = json.load(f)

    alerts = data.get('alerts', [])

    if not alerts:
        print('📋 등록된 알림이 없습니다.')
        exit(0)

    # 필터링
    if filter_mode == '--upcoming':
        alerts = [a for a in alerts if not a.get('shown', False)]

    if not alerts:
        if filter_mode == '--upcoming':
            print('📋 예정된 알림이 없습니다.')
        else:
            print('📋 등록된 알림이 없습니다.')
        exit(0)

    # 정렬 (시간순)
    def get_epoch(alert):
        t = alert.get('epoch', alert.get('time', 0))
        if isinstance(t, (int, float)):
            return t
        if isinstance(t, str):
            for fmt in ['%Y-%m-%d %H:%M:%S', '%Y-%m-%d %H:%M']:
                try:
                    dt = datetime.strptime(t, fmt)
                    return dt.timestamp()
                except:
                    continue
        return 0

    alerts.sort(key=get_epoch)

    # 출력
    print('📋 등록된 알림 목록')
    print('=' * 60)
    print()

    now = datetime.now().timestamp()

    for alert in alerts:
        status = '✅ 표시됨' if alert.get('shown', False) else '⏰ 대기중'
        alert_time = get_epoch(alert)
        time_str = alert.get('time', 'Unknown')

        # 남은 시간 계산
        if not alert.get('shown', False) and alert_time > now:
            diff = int(alert_time - now)
            if diff < 60:
                remaining = f'{diff}초 후'
            elif diff < 3600:
                remaining = f'{diff // 60}분 후'
            elif diff < 86400:
                remaining = f'{diff // 3600}시간 {(diff % 3600) // 60}분 후'
            else:
                remaining = f'{diff // 86400}일 후'
        else:
            remaining = ''

        print(f'[{status}]')
        print(f'ID: {alert.get(\"id\", \"Unknown\")}')
        print(f'시간: {time_str}', end='')
        if remaining:
            print(f' ({remaining})', end='')
        print()
        print(f'메시지: {alert.get(\"message\", \"\")}')
        print(f'스타일: {alert.get(\"style\", \"dialog\")}')
        print()

    print('=' * 60)
    print(f'총 {len(alerts)}개의 알림')

    if filter_mode == '--upcoming':
        shown_count = len([a for a in data.get('alerts', []) if a.get('shown', False)])
        if shown_count > 0:
            print(f'(표시된 알림 {shown_count}개는 --all 옵션으로 확인)')

except Exception as e:
    print(f'❌ 오류: {e}')
    exit(1)
"
