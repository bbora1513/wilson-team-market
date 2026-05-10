# 🎾 Wilson Team Market

> Wilson Korea 커뮤니케이션팀 전용 Claude 스킬 마켓플레이스

**마켓플레이스 URL** → [bbora1513.github.io/wilson-team-market](https://bbora1513.github.io/wilson-team-market)

---

## 사용법

### 스킬 설치 (팀원)

**방법 A — 원클릭 설치 (PowerShell)**
```powershell
irm https://raw.githubusercontent.com/bbora1513/wilson-team-market/main/install.ps1 | iex
```

**방법 B — 플러그인 지정 설치**
```powershell
# install.ps1 다운로드 후
.\install.ps1 -Plugin wilson-tools
```

**방법 C — 수동 설치**
1. `plugins/` 폴더에서 원하는 `.skill` 파일 다운로드
2. Claude Desktop → 스킬 관리 → 파일 드래그앤드롭

---

## 플러그인 목록

| 플러그인 | 스킬 | 설명 |
|---|---|---|
| **wilson-tools** | `/moodboard`, `/sort-files` | Pinterest 무드보드 수집 + 파일 자동 정리 |

---

## 플러그인 등록 방법

1. **스킬 작성**: `my-skill/SKILL.md` 형식으로 작성 (frontmatter: `name`, `description` 필수)
2. **패키징**: 폴더를 zip 압축 후 `.skill`로 확장자 변경
3. **PR 제출**:
   - `plugins/my-skill.skill` 추가
   - `catalog.json`에 플러그인 정보 추가
4. **머지 후** 마켓플레이스에 자동 반영

### catalog.json 항목 형식

```json
{
  "id": "my-plugin",
  "name": "My Plugin",
  "version": "1.0.0",
  "description": "플러그인 설명",
  "author": "이름",
  "category": "카테고리",
  "tags": ["태그1", "태그2"],
  "skills": [
    {
      "name": "skill-name",
      "trigger": "/skill-name",
      "summary": "스킬 한 줄 설명"
    }
  ],
  "requires": { "mcp": [], "npm": [], "os": "Windows" },
  "file": "plugins/my-plugin.skill",
  "installScript": "install.ps1",
  "updatedAt": "2026-05-10"
}
```

---

## 기술 스택

- **스킬**: Claude Desktop 스킬 시스템 (SKILL.md 기반)
- **MCP**: Playwright (`@playwright/mcp`) — `/moodboard` 스킬 필요
- **마켓플레이스 UI**: 순수 HTML/CSS/JS (빌드 불필요)
- **호스팅**: GitHub Pages

---

*Wilson Korea 커뮤니케이션팀 · maintained by 김보라*
