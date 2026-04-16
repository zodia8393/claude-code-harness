# 테스트 생성 상세

## pytest + Arrange-Act-Assert

### 테스트 설계 매트릭스
| 카테고리 | 필수 | 예시 |
|----------|------|------|
| 정상 | 필수 | 유효한 DataFrame 입력 |
| 경계값 | 필수 | 빈 리스트, 1건, 0, 음수 |
| None/NULL | 필수 | None, NaN, "", 빈 DataFrame |
| 타입 오류 | 권장 | str→int |
| 예외 | 권장 | 연결 실패, 파일 미존재 |
| sad path | 의무(2개+) | 잘못된 입력, 실패 경로 |

### Mock 전략
- DB: MagicMock conn/cursor
- 파일: tmp_path + mock_open
- 환경변수: monkeypatch
- 네트워크: responses 또는 mock

### 작성 규칙
- 파일: test_{모듈명}.py, 함수: test_{함수명}_{시나리오}
- 한 테스트 하나의 assertion (관련 assert 허용)
- 테스트 간 독립성, 하드코딩 경로 금지
- Karpathy: 테스트 대상을 단순 입력으로 먼저 실행하여 동작 이해
