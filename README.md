# my-alert

macOS에서 자연어로 알림을 예약할 수 있는 간단한 알림 스케줄러입니다.

## 특징

- **자연어 지원**: "30분 후에 알림", "오후 3시에 알림" 등 편하게 요청
- **네이티브 알림**: macOS 다이얼로그로 알림 표시
- **백그라운드 동작**: launchd가 1분마다 자동으로 체크
- **중복 방지**: 같은 시간·메시지 알림 자동 차단
- **API 제공**: 다른 스크립트에서도 사용 가능

## 사용법

### Claude Code에서

자연어로 편하게 요청하세요. Claude가 자동으로 설치하고 알림을 등록합니다:

```
"30분 후에 커피 마시라고 알려줘"
"오후 3시에 회의 준비 알림 해줘"
"5분 후에 JIRA 체크하라고 알림"
```


## 알림 관리

### 알림 목록 보기

```bash
~/Library/Scripts/my-alert/list-alerts.sh
```

### 알림 취소

```bash
# ID로 취소
~/Library/Scripts/my-alert/cancel-alert.sh --id alert_1234567890_12345

# 메시지로 취소
~/Library/Scripts/my-alert/cancel-alert.sh --message "커피"
```

### 알림 수정

```bash
~/Library/Scripts/my-alert/update-alert.sh --id alert_1234567890_12345 --time "2025-12-03 16:00"
```

## 서비스 관리

```bash
# 상태 확인
launchctl list | grep my-alert-runner

# 중지
launchctl unload ~/Library/LaunchAgents/com.user.my-alert-runner.plist

# 재시작
launchctl load ~/Library/LaunchAgents/com.user.my-alert-runner.plist
```

## 문제 해결

### 알림이 표시되지 않을 때

1. **서비스 확인**
   ```bash
   launchctl list | grep my-alert-runner
   ```
   목록에 없으면 설치 필요

2. **알림 등록 확인**
   ```bash
   ~/Library/Scripts/my-alert/list-alerts.sh
   ```
   알림이 없으면 다시 등록

3. **로그 확인**
   ```bash
   tail -30 /tmp/my-alert-runner.log
   ```

4. **서비스 재시작**
   ```bash
   launchctl unload ~/Library/LaunchAgents/com.user.my-alert-runner.plist
   launchctl load ~/Library/LaunchAgents/com.user.my-alert-runner.plist
   ```

## 제한사항

- macOS 전용 (launchd, osascript 사용)
- 1분 단위 정확도 (1분마다 체크)
- 알림 시간이 지나면 자동 삭제

---

## 수동 설치 (직접 사용 시)

Claude Code 없이 직접 사용하려면:

```bash
bash ~/.claude/skills/my-alert/scripts/setup.sh
```

### API 사용 (다른 스크립트에서)

```bash
~/Library/Scripts/my-alert/register-alert.sh "YYYY-MM-DD HH:MM" "메시지" "dialog"
```

### 파일 위치

```
~/Library/Scripts/my-alert/          # 실행 스크립트
~/.claude/cache/my-alert/alerts.json # 알림 데이터
~/Library/LaunchAgents/              # launchd 설정
/tmp/my-alert-runner.log            # 실행 로그
```
