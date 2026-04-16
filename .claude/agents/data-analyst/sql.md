# SQL 생성 및 쿼리 프로파일링 상세

## B. SQL 생성

### DB 종류 감지 (우선순위)
1. 요청에 명시 ("Oracle로", "PostgreSQL로")
2. 테이블명 패턴 또는 DB 연결 정보 → 자동 감지
3. CLAUDE.md 참조
4. 코드 import문 (oracledb → Oracle)
5. 불명확 → 사용자 확인

### DB별 문법
| 기능 | Oracle | PostgreSQL | MySQL |
|------|--------|------------|-------|
| 행 제한 | FETCH FIRST N ROWS | LIMIT N | LIMIT N |
| NULL 대체 | NVL | COALESCE | IFNULL |
| 현재 날짜 | SYSDATE | CURRENT_DATE | CURDATE() |

### SQL 작성 규칙

**가독성**: 키워드 대문자, 한줄 한컬럼(3개+), 4스페이스, 주석
**성능**: SDATE 필터 필수, SELECT * 금지, 결과 1000건 제한, 인덱스 우선
**안전성**: 바인드 변수(:param), WHERE 필수(UPDATE/DELETE), DROP/TRUNCATE 자동실행 금지

### 출력 (3가지 필수)
1. SQL 쿼리 (주석 포함)
2. 결과 형태 (예상 행수, 용도)
3. Python 실행 코드 (oracledb + pandas)

## B-탐색. DB 탐색

| 유형 | 트리거 | 동작 |
|------|--------|------|
| 테이블 목록 | "어떤 테이블" | 전체 테이블 + 건수 |
| 스키마 | "컬럼", "구조" | 컬럼명, 타입, NULL, 인덱스 |
| 샘플 | "미리보기" | 상위 10건 + 통계 |
| 건수 | "몇 건" | COUNT(*), 날짜별 분포 |

### Oracle 탐색 쿼리
```sql
SELECT table_name, num_rows FROM user_tables ORDER BY num_rows DESC;
SELECT column_name, data_type, nullable FROM user_tab_columns WHERE table_name = :tbl ORDER BY column_id;
SELECT index_name, column_name FROM user_ind_columns WHERE table_name = :tbl;
SELECT SDATE, COUNT(*) cnt FROM :tbl GROUP BY SDATE ORDER BY SDATE;
```

## E. 쿼리 프로파일링

### 실행계획 분석 절차
1. EXPLAIN PLAN FOR [대상 SQL]
2. SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(FORMAT => 'ALL'))
3. 실행계획 트리 해석 (비용, 카디널리티, 접근 방법)
4. 병목 지점 식별
5. 최적화 방안 제시

### 병목 패턴
| 패턴 | 의미 | 최적화 |
|------|------|--------|
| TABLE ACCESS FULL | 전체 스캔 | 인덱스/파티션 |
| NESTED LOOPS (대량) | 행단위 반복 | HASH JOIN |
| SORT ORDER BY (대량) | 대량 정렬 | 인덱스 정렬 |
| 카디널리티 오차 | 통계 부정확 | GATHER_TABLE_STATS |
| 파티션 미활용 | 키 필터 누락 | SDATE WHERE 추가 |

### Oracle 힌트
| 힌트 | 용도 |
|------|------|
| INDEX(t idx) | 인덱스 강제 |
| FULL(t) | 전체 스캔 강제 |
| USE_HASH(a b) | 해시 조인 |
| PARALLEL(t, N) | 병렬 처리 |
| LEADING(a b c) | 조인 순서 |
