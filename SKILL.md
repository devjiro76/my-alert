---
name: my-alert
description: macOS launchd 기반 범용 알림 스케줄러. 자연어로 알림을 요청하면 osascript 네이티브 다이얼로그로 표시합니다. "30분 후에 알림", "오후 3시에 알림" 등 편리하게 사용 가능. 다른 스킬에서 API로도 호출 가능.
---

# my-alert

자연어로 알림을 요청할 수 있는 macOS 알림 스케줄러. 특정 시간에 알림을 등록하면 osascript 네이티브 다이얼로그로 표시합니다.

---

## 🤖 AI 처리 지시사항

**사용자가 알림을 요청하면 자동으로 처리해야 합니다:**

### 1. 자연어 요청 감지
다음과 같은 요청을 받으면 자동으로 알림을 등록:
- "N분 후에 ... 알림 해줘"
- "N시간 후에 ... 알림"
- "오후/오전 N시에 ... 알림"
- "내일 N시에 ... 알림"

### 2. 시간 계산 방법
```bash
# 상대 시간 (N분 후)
date -v+5M '+%Y-%m-%d %H:%M'   # 5분 후
date -v+30M '+%Y-%m-%d %H:%M'  # 30분 후
date -v+1H '+%Y-%m-%d %H:%M'   # 1시간 후

# 절대 시간 (오늘 특정 시각)
# 오후 3시 → 15:00
echo "$(date '+%Y-%m-%d') 15:00"

# 오전 10시 → 10:00
echo "$(date '+%Y-%m-%d') 10:00"

# 시:분 형식 (2시 3분 → 14:03, 오후로 간주)
echo "$(date '+%Y-%m-%d') 14:03"

# 내일
date -v+1d -v15H -v0M '+%Y-%m-%d %H:%M'  # 내일 15:00
```

### 3. 알림 등록 실행
```bash
~/Library/Scripts/my-alert/register-alert.sh "시간" "메시지" "dialog"
```

**예시:**
- 사용자: "5분 후에 휴식 알림 해줘"
  → `~/Library/Scripts/my-alert/register-alert.sh "$(date -v+5M '+%Y-%m-%d %H:%M')" "휴식 알림" "dialog"`

- 사용자: "오후 3시에 회의 준비 알림"
  → `~/Library/Scripts/my-alert/register-alert.sh "$(date '+%Y-%m-%d') 15:00" "회의 준비 알림" "dialog"`

- 사용자: "2시 3분에 방구 끼라고 알려줘"
  → `~/Library/Scripts/my-alert/register-alert.sh "$(date '+%Y-%m-%d') 14:03" "💨 방구 끼세요!" "dialog"`

### 4. 알림 등록 후 검증 (중요!)

**알림 등록 후 반드시 검증해야 합니다:**
```bash
# 등록한 알림이 목록에 있는지 확인
~/Library/Scripts/my-alert/list-alerts.sh | grep -A 3 "메시지키워드"
```

**검증 실패 시:**
- 목록에 없으면 → 등록 실패, 다시 시도 또는 서비스 상태 확인 필요
- 목록에 있으면 → 정상 등록 완료

### 5. 알림 목록 조회
사용자가 "알림 목록", "등록된 알림", "예정된 알림" 등을 요청하면:
```bash
~/Library/Scripts/my-alert/list-alerts.sh
```

### 6. 알림 취소/수정
사용자 요청에 따라 적절한 스크립트 실행:
- 취소: `~/Library/Scripts/my-alert/cancel-alert.sh --id ID`
- 수정: `~/Library/Scripts/my-alert/update-alert.sh --id ID --time "시간" --message "메시지"`

### 7. 서비스 상태 확인

사용자가 "알림이 안 와요", "알림 동작 안 해요" 등을 요청하면:

```bash
# 1. launchd 서비스 상태 확인
launchctl list | grep my-alert-runner

# 2. 서비스 로그 확인
tail -30 /tmp/my-alert-runner.log

# 3. 등록된 알림 목록 확인
~/Library/Scripts/my-alert/list-alerts.sh
```

**상태 해석:**
- `PID가 숫자` → 현재 실행 중 (정상)
- `PID가 -` → 대기 중 (정상, 1분마다 실행되는 주기 서비스)
- `목록에 없음` → 서비스 미설치, setup.sh 실행 필요

### 8. 문제 해결 (트러블슈팅)

**알림이 표시되지 않을 때:**

1. **서비스 실행 확인**
   ```bash
   launchctl list | grep my-alert-runner
   ```
   목록에 없으면 → 설치 필요

2. **알림이 목록에 있는지 확인**
   ```bash
   ~/Library/Scripts/my-alert/list-alerts.sh
   ```
   목록에 없으면 → 등록 실패, 다시 등록

3. **로그 확인**
   ```bash
   tail -30 /tmp/my-alert-runner.log
   ```
   에러 메시지 확인

4. **서비스 재시작**
   ```bash
   launchctl unload ~/Library/LaunchAgents/com.user.my-alert-runner.plist
   launchctl load ~/Library/LaunchAgents/com.user.my-alert-runner.plist
   ```

**일반적인 문제:**
- 알림 시간이 이미 지남 → 과거 시간으로 등록하면 즉시 표시되거나 무시됨
- alerts.json 파일 권한 문제 → `chmod 644 ~/.claude/cache/my-alert/alerts.json`
- 서비스가 설치 안 됨 → `bash ~/.claude/skills/my-alert/scripts/setup.sh` 실행

---

## 핵심 기능

1. **자연어 알림 요청**: "30분 후에", "오후 3시에" 등 자연스럽게 요청
2. **자동 알림 표시**: 1분마다 체크하여 시간 되면 자동 표시
3. **네이티브 다이얼로그**: osascript로 macOS 네이티브 알림
4. **API 제공**: 다른 스킬/스크립트에서 프로그래밍 방식으로 호출 가능

## 사용 예시

자연어로 편하게 알림을 요청하세요:

### 상대 시간
- "30분 후에 회의 시작 알림 해줘"
- "1시간 후에 JIRA 체크하라고 알려줘"
- "10분 후에 휴식 시간 알림"
- "5분 후에 미팅 준비하라고 알림"

### 절대 시간
- "오후 3시에 보고서 작성 알림 해줘"
- "저녁 6시에 퇴근 준비 알림"
- "오전 10시에 스탠드업 미팅 알림"
- "내일 아침 9시에 출근 알림"

### 구체적인 업무
- "15분 후에 'JIRA-111 해결하기' 알림"
- "오후 2시에 '팀 회의 준비' 알림"
- "30분 후에 '휴식 시간' 알림"

## 알림 예시

설정한 시간이 되면 macOS 네이티브 다이얼로그로 알림이 표시됩니다:

- **제목**: "예정된 알림"
- **시간 표시**: 알림이 울린 시각
- **메시지**: 등록한 알림 내용
- **확인 버튼**: 클릭하여 알림 닫기

## 설치

```bash
bash ~/.claude/skills/my-alert/scripts/setup.sh
```

설치되는 항목:
- `~/Library/Scripts/my-alert/` - 스크립트 파일들
- `~/.claude/cache/my-alert/alerts.json` - 알림 데이터
- `~/Library/LaunchAgents/com.user.my-alert-runner.plist` - 1분마다 체크

## 제한사항

- **macOS 전용**: launchd, osascript 사용
- **시간 정확도**: 1분 단위 (1분마다 체크)
- **재부팅 시**: launchd job은 유지되나 알림 데이터는 영구 저장

---

## 알림 관리

등록된 알림을 확인하고 관리할 수 있습니다.

### 알림 목록 보기

```bash
# 예정된 알림만 보기 (기본값)
list-alerts.sh

# 모든 알림 보기 (표시된 알림 포함)
list-alerts.sh --all
```

### 알림 취소

```bash
# ID로 취소
cancel-alert.sh --id alert_1234567890_12345

# 시간으로 취소
cancel-alert.sh --time "2025-12-03 18:00"

# 메시지 키워드로 취소
cancel-alert.sh --message "퇴근"
```

### 알림 수정

```bash
# 시간 변경
update-alert.sh --id alert_1234567890_12345 --time "2025-12-03 19:00"

# 메시지 변경
update-alert.sh --id alert_1234567890_12345 --message "새로운 메시지"

# 여러 항목 동시 변경
update-alert.sh --id alert_1234567890_12345 --time "2025-12-03 19:00" --message "변경된 알림"
```

### 중복 방지

같은 시간(분 단위)과 같은 메시지를 가진 알림은 자동으로 중복 등록이 방지됩니다.

```bash
# 첫 번째 등록 - 성공
register-alert.sh "2025-12-03 14:00" "회의 시작" "dialog"

# 동일한 알림 재등록 - 중복 경고
register-alert.sh "2025-12-03 14:00" "회의 시작" "dialog"
# ⚠️  중복된 알림입니다 (같은 시간 + 같은 메시지)
```

---

## 고급 사용법 (API)

다른 스킬이나 스크립트에서 프로그래밍 방식으로 호출할 수 있습니다.

### API 호출

```bash
~/Library/Scripts/my-alert/register-alert.sh "YYYY-MM-DD HH:mm" "알림 메시지" "dialog"
```

**예시:**
```bash
# 오후 2시 알림
register-alert.sh "2025-12-03 14:00" "JIRA-111 해결하기" "dialog"

# 5분 후 알림
register-alert.sh "$(date -v+5M '+%Y-%m-%d %H:%M')" "미팅 시작" "dialog"
```

### 다른 스킬에서 사용하기

```bash
# 미팅 알림 자동 등록 예시
for meeting in $(get_meetings); do
  alert_time=$(calculate_10min_before "$meeting_start")
  ~/Library/Scripts/my-alert/register-alert.sh "$alert_time" "📌 $meeting_title 10분 전" "dialog"
done
```

### 파일 구조

```
~/Library/Scripts/my-alert/
├── show-alert.sh       # osascript 알림 표시
├── register-alert.sh   # 알림 등록
├── run-alerts.sh       # 1분마다 알림 체크 및 실행
├── list-alerts.sh      # 알림 목록 조회
├── cancel-alert.sh     # 알림 취소
└── update-alert.sh     # 알림 수정

~/.claude/cache/my-alert/
└── alerts.json         # 알림 저장소
```

### 알림 데이터 형식

```json
{
  "alerts": [
    {
      "id": "alert_1733198400_12345",
      "time": "2025-12-03 14:00",
      "epoch": 1733198400,
      "message": "JIRA-111 해결하기",
      "style": "dialog",
      "shown": false,
      "created": "2025-12-03T13:00:00"
    }
  ]
}
```
