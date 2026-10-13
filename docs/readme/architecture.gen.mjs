// 도담 시스템 아키텍처 다이어그램 생성기
//
// 이 스크립트가 docs/readme/architecture.svg 의 정본이다.
// 재생성:  node docs/readme/architecture.gen.mjs   (의존성 없음 · Node 18+)
//
// reason: 이전 그림은 원본 소스가 남지 않아 오탈자·사실오류를 고칠 수 없었다.
//         좌표를 코드로 두면 재생성·부분수정이 가능하다.

import { writeFileSync } from 'node:fs'

/* ── 팔레트: CLAUDE.md 8절 디자인 토큰 ───────────────────────────── */
const C = {
  bg: '#F6F7F3',
  card: '#FFFFFF',
  ink: '#25313A',
  sub: '#5D6E78',
  faint: '#8A9AA4',
  line: '#E3E6E1',
  green: '#3E9B6B',
  greenD: '#2E7A52',
  yellow: '#E9A93B',
  orange: '#E8823C',
  blue: '#3D7BD9',
  purple: '#8B6FD0',
  brown: '#A67B5B',
  slate: '#5B7185',
}

const F = {
  head: 'NanumSquare, NanumGothic, sans-serif',
  body: 'NanumGothic, NanumSquare, sans-serif',
  mono: 'NanumGothicCoding, monospace',
}

const W = 1720
const H = 1315

const out = []
const esc = (s) =>
  String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')

/* ── 프리미티브 ──────────────────────────────────────────────────── */
const text = (x, y, s, o = {}) => {
  const {
    size = 11.5,
    fill = C.sub,
    weight = 400,
    family = F.body,
    anchor = 'start',
    ls = 0,
  } = o
  out.push(
    `<text x="${x}" y="${y}" font-family="${family}" font-size="${size}" font-weight="${weight}" fill="${fill}" text-anchor="${anchor}"${
      ls ? ` letter-spacing="${ls}"` : ''
    }>${esc(s)}</text>`,
  )
}

const rect = (x, y, w, h, o = {}) => {
  const { rx = 10, fill = C.card, stroke = C.line, sw = 1.2, dash = null } = o
  out.push(
    `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="${rx}" fill="${fill}" stroke="${stroke}" stroke-width="${sw}"${
      dash ? ` stroke-dasharray="${dash}"` : ''
    }/>`,
  )
}

/** 그룹 경계 상자 — 제목은 항상 상자 안쪽 상단, 노드는 gy+58 부터 시작한다. */
const group = ({ x, y, w, h, title, sub, color }) => {
  rect(x, y, w, h, { rx: 16, fill: color + '0A', stroke: color + '55', sw: 1.4, dash: '6 5' })
  text(x + 18, y + 28, title, { size: 12.5, weight: 700, fill: color, family: F.head, ls: 1.4 })
  if (sub) text(x + 18, y + 46, sub, { size: 10.5, fill: C.faint })
}

/** 카드형 노드 — 왼쪽 액센트 바 + 제목 + 설명줄 + 모노 줄 + 칩 */
const node = ({ x, y, w, h, title, subs = [], mono = [], chips = [], color }) => {
  rect(x, y, w, h, { rx: 11 })
  // 액센트 바는 카드 테두리 안쪽으로 넣는다 — 밖으로 빼면 둥근 모서리와 어긋나 떨어져 보인다.
  out.push(`<rect x="${x + 2}" y="${y + 12}" width="4" height="${h - 24}" rx="2" fill="${color}"/>`)
  text(x + 20, y + 30, title, { size: 15.5, weight: 700, fill: C.ink, family: F.head })
  subs.forEach((s, i) => text(x + 20, y + 52 + i * 17, s, { size: 11.5 }))
  const monoTop = y + 52 + subs.length * 17 + 8
  mono.forEach((s, i) =>
    text(x + 20, monoTop + i * 16, s, { size: 10.5, family: F.mono, fill: '#4A6070' }),
  )
  chips.forEach((s, i) => {
    const cy = y + h - 16 - (chips.length - 1 - i) * 28
    rect(x + 20, cy - 15, w - 40, 22, { rx: 6, fill: color + '18', stroke: color + '4D', sw: 1 })
    text(x + 30, cy, s, { size: 10.5, fill: C.ink })
  })
}

/* ── 연결선 ─────────────────────────────────────────────────────── */
const edge = (pts, color, { dash = null } = {}) => {
  const d = pts.map((p, i) => `${i ? 'L' : 'M'}${p[0]} ${p[1]}`).join(' ')
  out.push(
    `<path d="${d}" fill="none" stroke="${color}" stroke-width="1.8" stroke-linejoin="round" stroke-linecap="round"${
      dash ? ` stroke-dasharray="${dash}"` : ''
    } marker-end="url(#ah-${color.slice(1)})"/>`,
  )
}

/** 번호 배지 — 선 위에 얹어 라벨 겹침 없이 흐름을 표시한다. */
const badge = (x, y, n, color) => {
  out.push(`<circle cx="${x}" cy="${y}" r="10.5" fill="${C.card}" stroke="${color}" stroke-width="1.6"/>`)
  text(x, y + 4, String(n), {
    size: 11.5,
    weight: 700,
    fill: color,
    family: F.head,
    anchor: 'middle',
  })
}

/* ── 배경 · 마커 ────────────────────────────────────────────────── */
const markerColors = [C.blue, C.greenD, C.purple, C.brown, C.slate]
out.push(`<defs>
${markerColors
  .map(
    (c) =>
      `<marker id="ah-${c.slice(1)}" viewBox="0 0 10 8" markerWidth="8.5" markerHeight="6.5" refX="9.2" refY="4" orient="auto"><path d="M0 0 L10 4 L0 8 z" fill="${c}"/></marker>`,
  )
  .join('\n')}
</defs>`)
rect(0, 0, W, H, { rx: 0, fill: C.bg, stroke: 'none', sw: 0 })

/* ── 헤더 ───────────────────────────────────────────────────────── */
text(48, 62, 'System Architecture', { size: 34, weight: 700, fill: C.ink, family: F.head })
text(48, 92, '도담(dodam) · S15P11B209 — 아동 미술 심리 관찰 AI 서비스', {
  size: 13,
  fill: C.sub,
})
text(48, 112, 'AWS EC2 단일 노드 · Docker Compose 블루-그린 무중단 배포', {
  size: 11.5,
  fill: C.faint,
  family: F.mono,
})

/* ── EXTERNAL SERVICES (상단) ───────────────────────────────────── */
group({ x: 612, y: 130, w: 1040, h: 170, title: 'EXTERNAL SERVICES', sub: '외부 API · 클러스터 밖', color: C.brown })
node({
  x: 632, y: 190, w: 320, h: 92, color: C.brown,
  title: 'OAuth 2.0',
  subs: ['카카오 · 네이버 · 구글', '소셜 로그인 · 자체 계정 병행'],
})
node({
  x: 972, y: 190, w: 320, h: 92, color: C.brown,
  title: 'Firebase FCM',
  subs: ['리포트 완료 · 실패 푸시', '보호자에게만 발송'],
})
node({
  x: 1312, y: 190, w: 320, h: 92, color: C.brown,
  title: 'GMS (OpenAI 호환)',
  subs: ['LLM gpt-4o-mini · STT whisper-1'],
  mono: ['TTS gpt-4o-mini-tts (fable)'],
})

/* ── EC2 외곽 ───────────────────────────────────────────────────── */
rect(290, 336, 1382, 610, { rx: 20, fill: '#FFFFFF66', stroke: '#C8D2CD', sw: 1.6 })
text(308, 366, 'AWS EC2 · Ubuntu 24.04', { size: 13.5, weight: 700, fill: C.ink, family: F.head })
text(308 + 178, 366, '· Docker Compose · 단일 노드 블루-그린', { size: 11.5, fill: C.faint })

/* ── CLIENT ─────────────────────────────────────────────────────── */
group({ x: 48, y: 390, w: 230, h: 290, title: 'CLIENT', sub: '아동 · 보호자', color: C.blue })
node({
  x: 68, y: 448, w: 190, h: 88, color: C.blue,
  title: 'Flutter App',
  subs: ['모바일 · 태블릿', '아동 활동 · 보호자 앱'],
})
node({
  x: 68, y: 560, w: 190, h: 88, color: C.blue,
  title: 'Web Browser',
  subs: ['커뮤니티 · 관리자 콘솔'],
})

/* ── PUBLIC EDGE ────────────────────────────────────────────────── */
group({ x: 310, y: 390, w: 270, h: 290, title: 'PUBLIC EDGE', sub: '유일한 공개 진입점', color: C.greenD })
node({
  x: 330, y: 448, w: 230, h: 200, color: C.greenD,
  title: 'Nginx Gateway',
  subs: ["HTTPS 443 · Let's Encrypt"],
  mono: [
    '/          → web',
    '/api/      → backend',
    '/ai/       → ai',
    '/internal/ → 404 (숨김)',
  ],
})

/* ── APPLICATION STACK ──────────────────────────────────────────── */
group({ x: 612, y: 390, w: 330, h: 290, title: 'APPLICATION STACK', sub: 'Docker Compose · Blue-Green', color: C.green })
node({
  x: 632, y: 448, w: 290, h: 96, color: C.green,
  title: 'Spring Boot API',
  subs: ['backend-blue / green :8080', '인증 · 활동 · 리포트 · 파일 프록시'],
})
node({
  x: 632, y: 568, w: 200, h: 88, color: C.green,
  title: 'Next.js SSR',
  subs: ['web-blue / green :3000', '커뮤니티 · 관리자'],
})

/* ── AI SERVICE ─────────────────────────────────────────────────── */
group({ x: 974, y: 390, w: 330, h: 290, title: 'AI SERVICE', sub: '내부 전용 · 외부 미노출', color: C.orange })
node({
  x: 994, y: 448, w: 290, h: 200, color: C.orange,
  title: 'FastAPI AI',
  subs: ['ai-blue / green :8000', '그림 분석 · 대화 · 리포트 생성'],
  chips: ['YOLO 가중치 로컬 로딩 · sha256 검증', 'RAG 코퍼스 · 프롬프트 레지스트리', '안전 게이트 (위험신호 · 개인정보)'],
})

/* ── MONITORING ─────────────────────────────────────────────────── */
group({ x: 1336, y: 390, w: 316, h: 290, title: 'MONITORING', sub: '별도 Compose 스택', color: C.slate })
node({ x: 1356, y: 448, w: 276, h: 76, color: C.slate, title: 'Prometheus', subs: ['TSDB 15일 보관'] })
node({ x: 1356, y: 536, w: 276, h: 68, color: C.slate, title: 'Grafana', subs: ['대시보드 프로비저닝'] })
node({ x: 1356, y: 616, w: 276, h: 44, color: C.slate, title: 'node-exporter · cAdvisor' })

/* ── DATA LAYER ─────────────────────────────────────────────────── */
group({ x: 310, y: 712, w: 1342, h: 210, title: 'DATA LAYER', sub: 'Compose 네트워크 내부 전용 · Spring Boot 만 접근', color: C.purple })
const dataX = [330, 659, 988, 1317]
node({
  x: dataX[0], y: 772, w: 315, h: 120, color: C.purple,
  title: 'MySQL 8.0',
  subs: ['관계형 정본', '사용자 · 아동 · 활동 · 리포트'],
  mono: ['mysql:3306'],
})
node({
  x: dataX[1], y: 772, w: 315, h: 120, color: C.purple,
  title: 'MongoDB',
  subs: ['스트로크 · 대화 로그', '배치 문서 · TTL 자동 만료'],
  mono: ['mongodb:27017'],
})
node({
  x: dataX[2], y: 772, w: 315, h: 120, color: C.purple,
  title: 'Redis',
  subs: ['토큰 · 캐시', '그림 1회용 접근 토큰'],
  mono: ['redis:6379'],
})
node({
  x: dataX[3], y: 772, w: 315, h: 120, color: C.purple,
  title: 'MinIO',
  subs: ['그림 · 음성 파일', '단일 버킷 + 프리픽스'],
  mono: ['minio:9000 · 프록시만'],
})

/* ── 흐름 카드 (좌측 하단) ──────────────────────────────────────── */
rect(48, 712, 230, 210, { rx: 16, fill: C.card, stroke: C.line, sw: 1.2 })
text(68, 742, '요청 흐름', { size: 13, weight: 700, fill: C.ink, family: F.head })
const flows = [
  [C.blue, ['앱 · 웹 → HTTPS 443', 'Nginx 단일 진입점']],
  [C.blue, ['/api/ → Spring Boot', '/ → Next.js SSR']],
  [C.greenD, ['Spring → FastAPI', 'compose 내부망 호출']],
  [C.greenD, ['FastAPI → Spring', '1회용 토큰으로 그림 수신']],
  [C.purple, ['Spring → 데이터 계층', '읽기 · 쓰기']],
]
flows.forEach(([color, lines], i) => {
  const y = 766 + i * 35
  out.push(`<circle cx="79" cy="${y - 4}" r="9" fill="${C.card}" stroke="${color}" stroke-width="1.5"/>`)
  text(79, y, String(i + 1), { size: 10.5, weight: 700, fill: color, family: F.head, anchor: 'middle' })
  text(96, y - 7, lines[0], { size: 11, fill: C.ink })
  text(96, y + 8, lines[1], { size: 10, fill: C.faint })
})

/* ── 가드레일 밴드 ──────────────────────────────────────────────── */
rect(48, 970, 1604, 72, { rx: 14, fill: '#FFFFFF', stroke: C.line, sw: 1.2 })
out.push(`<rect x="48" y="970" width="5" height="72" rx="2.5" fill="${C.greenD}"/>`)
text(72, 998, '아동 민감정보 가드레일', { size: 13, weight: 700, fill: C.ink, family: F.head })
const guards = [
  ['MinIO 는 공개하지 않는다', 'Spring Boot 프록시 스트리밍으로만 서빙'],
  ['AI 는 그림을 직접 못 읽는다', 'Redis 1회용 토큰 URL 로만 수신'],
  ['내부 경로는 존재를 숨긴다', '/internal/ · /ai/internal/ 은 엣지에서 404'],
]
guards.forEach(([a, b], i) => {
  const x = 300 + i * 452
  text(x, 994, '· ' + a, { size: 11.5, weight: 700, fill: C.ink })
  text(x + 10, 1014, b, { size: 10.5, fill: C.faint })
})

/* ── CI / CD ────────────────────────────────────────────────────── */
group({ x: 48, y: 1070, w: 1604, h: 170, title: 'CI / CD', sub: '배포 파이프라인 — Jenkins 는 같은 EC2 에서 /jenkins/ 로 프록시된다', color: C.yellow })
const ciX = [68, 386, 704, 1022, 1340]
const ci = [
  ['GitLab', ['MR · 푸시 웹훅']],
  ['Jenkins', ['변경 범위 기반 빌드 · 캐시']],
  ['Private Registry', ['이미지 태그 푸시']],
  ['Blue-Green Deploy', ['유휴 색 기동 → 헬스체크']],
  ['Nginx upstream 스위치', ['reload · 무중단 컷오버']],
]
ci.forEach(([t, s], i) => {
  node({ x: ciX[i], y: 1130, w: 290, h: 76, color: C.yellow, title: t, subs: s })
  if (i < 4) edge([[ciX[i] + 290, 1168], [ciX[i + 1] - 4, 1168]], C.slate, { dash: '5 5' })
})

/* ── 연결선 ─────────────────────────────────────────────────────── */
// ① 클라이언트 → 엣지
edge([[258, 492], [326, 492]], C.blue)
edge([[258, 604], [326, 604]], C.blue)
badge(292, 492, 1, C.blue)

// ② 엣지 → 앱
edge([[560, 496], [628, 496]], C.blue)
edge([[560, 612], [628, 612]], C.blue)
badge(594, 496, 2, C.blue)

// Next.js → Spring (SSR · OAuth 교환 후 호출)
edge([[740, 568], [740, 548]], C.greenD)

// ③ Spring → FastAPI  /  ④ FastAPI → Spring (그림 fetch)
edge([[922, 486], [990, 486]], C.greenD)
badge(956, 486, 3, C.greenD)
edge([[994, 522], [926, 522]], C.greenD)
badge(956, 522, 4, C.greenD)

// ⑤ Spring → 데이터 계층
edge([[850, 544], [850, 708]], C.purple)
badge(850, 694, 5, C.purple)

// 외부 API (점선)
edge([[760, 286], [760, 444]], C.brown, { dash: '6 5' })
edge([[1080, 286], [1080, 318], [880, 318], [880, 444]], C.brown, { dash: '6 5' })
edge([[1450, 286], [1450, 318], [1150, 318], [1150, 444]], C.brown, { dash: '6 5' })

// 모니터링 스크레이프 (점선)
edge([[900, 548], [900, 696], [1320, 696], [1320, 486], [1352, 486]], C.slate, { dash: '5 5' })
edge([[1284, 620], [1320, 620], [1320, 486], [1352, 486]], C.slate, { dash: '5 5' })

/* ── 범례 (모든 경계 상자 바깥 · 최하단) ────────────────────────── */
const legend = [
  [C.blue, '사용자 요청 (HTTPS)', false],
  [C.greenD, '내부 API 호출 (compose 네트워크)', false],
  [C.purple, '데이터 읽기 · 쓰기', false],
  [C.brown, '외부 API 호출', true],
  [C.slate, '지표 수집 · 배포', true],
]
let lx = 48
legend.forEach(([color, label, dash]) => {
  out.push(
    `<line x1="${lx}" y1="1280" x2="${lx + 34}" y2="1280" stroke="${color}" stroke-width="2.4"${
      dash ? ' stroke-dasharray="5 4"' : ''
    } stroke-linecap="round"/>`,
  )
  text(lx + 44, 1284, label, { size: 11.5, fill: C.sub })
  lx += 44 + label.length * 12 + 40
})

writeFileSync(
  new URL('./architecture.svg', import.meta.url),
  `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}" role="img" aria-labelledby="t d">\n<title id="t">도담 시스템 아키텍처</title>\n<desc id="d">AWS EC2 단일 노드 위의 Docker Compose 블루-그린 구성 — Nginx 게이트웨이, Spring Boot API, Next.js SSR, FastAPI AI, MySQL·MongoDB·Redis·MinIO 데이터 계층, Prometheus·Grafana 모니터링, GitLab·Jenkins CI/CD.</desc>\n${out.join('\n')}\n</svg>\n`,
)
console.log('architecture.svg 생성 완료')
