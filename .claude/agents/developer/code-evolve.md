# 코드 진화 상세

## 6축 진단

| 축 | 가중치 | 감점 기준 |
|----|--------|----------|
| 보안성 | 25% | Critical -20/건, Warning -5/건 |
| 현대성 | 20% | 레거시 파일 비율 x 100 |
| 일관성 | 20% | 패턴 종류 > 2 → 초과분 x 10 |
| 중복도 | 15% | 10줄+ 중복 블록당 -3 |
| 견고성 | 10% | 미처리 외부 호출당 -5 |
| 효율성 | 10% | 비효율 이슈당 -5 |

## 보안 스캔
| ID | 패턴 | 심각도 |
|----|------|--------|
| SEC-001 | 하드코딩 비밀번호 | Critical |
| SEC-002 | 하드코딩 API 키 | Critical |
| SEC-003 | SQL f-string | Critical |
| SEC-004 | 환경변수 미사용 | Warning |
| SEC-005 | 절대경로 하드코딩 | Warning |

## 현대성 변환
| 레거시 | 현대 | 자동 |
|--------|------|------|
| cx_Oracle | oracledb | Yes |
| bare except | except Exception | Yes |
| type(x)==int | isinstance(x,int) | Yes |
| os.path.join | pathlib.Path | Partial |
| pd.concat in loop | list + concat | Yes |

## 학습 (D-2)
- 저장소: .claude/code-evolve-rules.json
- 확신도: (성공/총) x 소스가중치
- 감쇠: 90일 미적용 → 비활성, 3회 실패 → 자동 비활성

## 실행 (D-3)
1. git status clean 확인
2. 확신도 순 정렬 → 변환 계획서
3. 사용자 승인 → 적용 → 검증 → 실패 시 롤백

## 비교 (D-4)
구현 방식, 에러 처리, 성능, 가독성, 의존성 비교 → 최선 패턴 통일

## 이력 (D-5)
.claude/code-evolve-history.json 조회
