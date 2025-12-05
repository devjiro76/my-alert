#!/bin/bash
# update-alert.sh - 알림 수정
# Usage: update-alert.sh --id <alert_id> [--time <new_time>] [--message <new_message>] [--style <new_style>]

CACHE_FILE="$HOME/.claude/cache/my-alert/alerts.json"

if [ ! -f "$CACHE_FILE" ]; then
    echo "❌ 등록된 알림이 없습니다."
    exit 1
fi

# 인자 파싱
ALERT_ID=""
NEW_TIME=""
NEW_MESSAGE=""
NEW_STYLE=""

while [ $# -gt 0 ]; do
    case "$1" in
        --id)
            ALERT_ID="$2"
            shift 2
            ;;
        --time)
            NEW_TIME="$2"
            shift 2
            ;;
        --message)
            NEW_MESSAGE="$2"
            shift 2
            ;;
        --style)
            NEW_STYLE="$2"
            shift 2
            ;;
        *)
            echo "Usage: update-alert.sh --id <id> [--time <time>] [--message <msg>] [--style <style>]"
            exit 1
            ;;
    esac
done

if [ -z "$ALERT_ID" ]; then
    echo "Usage: update-alert.sh --id <id> [--time <time>] [--message <msg>] [--style <style>]"
    echo ""
    echo "최소 하나 이상의 변경 사항(--time, --message, --style)을 지정해야 합니다."
    exit 1
fi

if [ -z "$NEW_TIME" ] && [ -z "$NEW_MESSAGE" ] && [ -z "$NEW_STYLE" ]; then
    echo "❌ 변경할 내용을 지정해주세요 (--time, --message, --style 중 하나 이상)"
    exit 1
fi

# Python으로 알림 수정
python3 -c "
import json
from datetime import datetime

alert_id = '$ALERT_ID'
new_time = '''$NEW_TIME'''
new_message = '''$NEW_MESSAGE'''
new_style = '''$NEW_STYLE'''

try:
    with open('$CACHE_FILE', 'r') as f:
        data = json.load(f)

    alerts = data.get('alerts', [])
    found = False
    old_alert = None

    for alert in alerts:
        if alert.get('id') == alert_id:
            found = True
            old_alert = alert.copy()

            # 시간 변경
            if new_time:
                epoch_time = None
                for fmt in ['%Y-%m-%d %H:%M:%S', '%Y-%m-%d %H:%M']:
                    try:
                        dt = datetime.strptime(new_time, fmt)
                        epoch_time = dt.timestamp()
                        # 초 제거한 형식으로 저장
                        new_time = dt.strftime('%Y-%m-%d %H:%M')
                        break
                    except:
                        continue

                if epoch_time is None:
                    print('❌ 잘못된 시간 형식입니다.')
                    exit(1)

                alert['time'] = new_time
                alert['epoch'] = epoch_time

            # 메시지 변경
            if new_message:
                alert['message'] = new_message

            # 스타일 변경
            if new_style:
                alert['style'] = new_style

            # shown 상태 리셋 (수정된 알림은 다시 표시되어야 함)
            alert['shown'] = False

            break

    if not found:
        print(f'❌ 알림을 찾을 수 없습니다: {alert_id}')
        exit(1)

    # 저장
    data['alerts'] = alerts
    with open('$CACHE_FILE', 'w') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    # 결과 출력
    print('✅ 알림이 수정되었습니다.')
    print()
    print('변경 전:')
    print(f'  시간: {old_alert.get(\"time\")}')
    print(f'  메시지: {old_alert.get(\"message\")}')
    print(f'  스타일: {old_alert.get(\"style\", \"dialog\")}')
    print()
    print('변경 후:')
    for alert in alerts:
        if alert.get('id') == alert_id:
            print(f'  시간: {alert.get(\"time\")}')
            print(f'  메시지: {alert.get(\"message\")}')
            print(f'  스타일: {alert.get(\"style\", \"dialog\")}')
            break

except Exception as e:
    print(f'❌ 오류: {e}')
    exit(1)
"

if [ $? -eq 0 ]; then
    exit 0
else
    exit 1
fi
