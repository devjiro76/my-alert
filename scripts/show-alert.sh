#!/bin/bash
# show-alert.sh - macOS 알림 표시
# Usage: show-alert.sh "제목" "내용" [notification|dialog|meeting]
#   - notification: 알림 센터 (현재 시간 표시)
#   - dialog: 다이얼로그 팝업 (현재 시간 표시)
#   - meeting: 미팅 알림용 다이얼로그 (현재 시간 미표시)

TITLE="${1:-알림}"
MESSAGE="${2:-}"
STYLE="${3:-notification}"

CURRENT_TIME=$(date '+%H:%M')

# 특수 문자 이스케이프 함수
escape_for_applescript() {
    # 먼저 불필요한 백슬래시 제거 (\\! -> !)
    local text="$1"
    text=$(echo "$text" | sed 's/\\!/!/g')
    # 그 다음 AppleScript용 이스케이프 (\ -> \\, " -> \")
    echo "$text" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

ESCAPED_TITLE=$(escape_for_applescript "$TITLE")
ESCAPED_MESSAGE=$(escape_for_applescript "$MESSAGE")

if [ "$STYLE" = "meeting" ]; then
    # 미팅 알림: 현재 시간 없이 메시지만 표시
    osascript -e "display dialog \"$ESCAPED_MESSAGE\" buttons {\"확인\"} default button \"확인\" with icon note with title \"$ESCAPED_TITLE\""
elif [ "$STYLE" = "dialog" ]; then
    # 커스텀 알림: 현재 시간 포함
    FULL_MESSAGE="⏰ $CURRENT_TIME

$ESCAPED_MESSAGE"
    ESCAPED_FULL=$(escape_for_applescript "$FULL_MESSAGE")
    osascript -e "display dialog \"$ESCAPED_FULL\" buttons {\"확인\"} default button \"확인\" with icon note with title \"$ESCAPED_TITLE\""
else
    # notification: 알림 센터
    osascript -e "display notification \"$ESCAPED_MESSAGE\" with title \"$ESCAPED_TITLE\" subtitle \"⏰ $CURRENT_TIME\" sound name \"Glass\""
fi
