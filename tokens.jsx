// Design tokens for Trackify — two themes, one accent.
// Read with useTheme(); cards/buttons/charts compose from these.

const themes = {
  dark: {
    name: 'dark',
    bg: '#0b0b0c',
    bgElev: '#101012',
    surface: '#161618',
    surface2: '#1c1c1f',
    border: 'rgba(255,255,255,0.08)',
    borderStrong: 'rgba(255,255,255,0.14)',
    text: '#f6f6f7',
    textMid: '#b8b8bd',
    textMuted: '#76767c',
    accent: '#c8ff3d',
    accentText: '#0b0b0c',
    danger: '#ff6b4a',
    grid: 'rgba(255,255,255,0.06)',
    chartLine: '#f6f6f7',
    chartFill: 'rgba(246,246,247,0.06)',
  },
  light: {
    name: 'light',
    bg: '#f6f5f1',
    bgElev: '#fafaf8',
    surface: '#ffffff',
    surface2: '#efeeea',
    border: 'rgba(11,11,12,0.08)',
    borderStrong: 'rgba(11,11,12,0.14)',
    text: '#0b0b0c',
    textMid: '#3a3a3d',
    textMuted: '#86858a',
    accent: '#c8ff3d',
    accentText: '#0b0b0c',
    danger: '#e0432a',
    grid: 'rgba(11,11,12,0.05)',
    chartLine: '#0b0b0c',
    chartFill: 'rgba(11,11,12,0.05)',
  },
};

const ThemeCtx = React.createContext(themes.dark);
const useTheme = () => React.useContext(ThemeCtx);

// ─── shared SVG icons (single-stroke, currentColor) ────────────
const I = {
  plus: (s = 16) => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round"><path d="M12 5v14M5 12h14"/></svg>,
  check: (s = 16) => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M4 12l5 5L20 6"/></svg>,
  chev: (s = 14, dir = 'right') => {
    const d = { right: 'M9 6l6 6-6 6', left: 'M15 6l-6 6 6 6', down: 'M6 9l6 6 6-6', up: 'M6 15l6-6 6 6' }[dir];
    return <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d={d}/></svg>;
  },
  x: (s = 16) => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round"><path d="M6 6l12 12M18 6l-12 12"/></svg>,
  arrow: (s = 16) => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M5 12h14M13 6l6 6-6 6"/></svg>,
  dumbbell: (s = 20) => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round"><path d="M3 9v6M6 6v12M18 6v12M21 9v6M6 12h12"/></svg>,
  run: (s = 20) => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><circle cx="16" cy="4.5" r="1.7"/><path d="M14 21l1.5-5-3-2.5L11 17M14 11l-1.5-3-4 1.5L7 14m6.5-3l3 2 2.5-1"/></svg>,
  scale: (s = 20) => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="4" width="18" height="16" rx="2.5"/><path d="M8 8.5h8M12 11v5"/></svg>,
  ruler: (s = 20) => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><path d="M3 14l7-11 11 7-7 11z"/><path d="M7 11l1.5 1M10 9l2 1.5M13 7l2 1.5"/></svg>,
  flame: (s = 20) => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinejoin="round"><path d="M12 3c0 4 4 5 4 9a4 4 0 11-8 0c0-2 1.5-3 2-5 .5 2 2 3 2 5"/></svg>,
  clock: (s = 16) => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></svg>,
  bolt: (s = 16) => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinejoin="round"><path d="M13 3l-8 11h6l-1 7 8-11h-6l1-7z"/></svg>,
  heart: (s = 16) => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinejoin="round"><path d="M12 20S4 14 4 9a4 4 0 017-2.5A4 4 0 0118 9c0 5-8 11-8 11z"/></svg>,
  more: (s = 16) => <svg width={s} height={s} viewBox="0 0 24 24" fill="currentColor"><circle cx="5" cy="12" r="1.6"/><circle cx="12" cy="12" r="1.6"/><circle cx="19" cy="12" r="1.6"/></svg>,
  settings: (s = 18) => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 00.34 1.87l.06.06a2 2 0 11-2.83 2.83l-.06-.06a1.7 1.7 0 00-1.87-.34 1.7 1.7 0 00-1 1.55V21a2 2 0 11-4 0v-.09a1.7 1.7 0 00-1.11-1.55 1.7 1.7 0 00-1.87.34l-.06.06a2 2 0 11-2.83-2.83l.06-.06a1.7 1.7 0 00.34-1.87 1.7 1.7 0 00-1.55-1H3a2 2 0 110-4h.09a1.7 1.7 0 001.55-1.11 1.7 1.7 0 00-.34-1.87l-.06-.06a2 2 0 112.83-2.83l.06.06a1.7 1.7 0 001.87.34h.01A1.7 1.7 0 0010 4.6V4a2 2 0 114 0v.09a1.7 1.7 0 001 1.55 1.7 1.7 0 001.87-.34l.06-.06a2 2 0 112.83 2.83l-.06.06a1.7 1.7 0 00-.34 1.87v.01a1.7 1.7 0 001.55 1H21a2 2 0 110 4h-.09a1.7 1.7 0 00-1.55 1z"/></svg>,
  bell: (s = 18) => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><path d="M6 8a6 6 0 1112 0c0 7 3 9 3 9H3s3-2 3-9M10 21a2 2 0 004 0"/></svg>,
  map: (s = 18) => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinejoin="round"><path d="M9 4l-6 2v14l6-2 6 2 6-2V4l-6 2-6-2zM9 4v14M15 6v14"/></svg>,
  search: (s = 18) => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round"><circle cx="11" cy="11" r="7"/><path d="M21 21l-4.5-4.5"/></svg>,
  filter: (s = 16) => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><path d="M4 5h16l-6 8v6l-4 2v-8L4 5z"/></svg>,
  play: (s = 14) => <svg width={s} height={s} viewBox="0 0 24 24" fill="currentColor"><path d="M7 4l13 8-13 8V4z"/></svg>,
  pause: (s = 14) => <svg width={s} height={s} viewBox="0 0 24 24" fill="currentColor"><rect x="6" y="4" width="4" height="16" rx="1"/><rect x="14" y="4" width="4" height="16" rx="1"/></svg>,
  trend: (s = 14, up = true) => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d={up ? 'M4 17l7-7 4 4 5-7M14 7h6v6' : 'M4 7l7 7 4-4 5 7M14 17h6v-6'}/></svg>,
  google: (s = 18) => <svg width={s} height={s} viewBox="0 0 24 24"><path fill="#4285F4" d="M22.6 12.2c0-.7-.1-1.4-.2-2.1H12v4h6c-.2 1.4-1 2.6-2.2 3.4v2.8h3.6c2.1-2 3.3-4.9 3.3-8.1z"/><path fill="#34A853" d="M12 23c3 0 5.5-1 7.3-2.7l-3.6-2.8c-1 .7-2.3 1.1-3.7 1.1-2.8 0-5.3-1.9-6.1-4.5H2.2v2.8C4.1 20.5 7.8 23 12 23z"/><path fill="#FBBC04" d="M5.9 14.1c-.2-.7-.4-1.4-.4-2.1s.1-1.4.4-2.1V7.1H2.2C1.4 8.6 1 10.3 1 12s.4 3.4 1.2 4.9l3.7-2.8z"/><path fill="#EA4335" d="M12 5.4c1.6 0 3 .5 4.2 1.6l3.1-3.1C17.5 2.1 15 1 12 1 7.8 1 4.1 3.5 2.2 7.1l3.7 2.8C6.7 7.3 9.2 5.4 12 5.4z"/></svg>,
  apple: (s = 18, color = '#fff') => <svg width={s} height={s} viewBox="0 0 24 24" fill={color}><path d="M17.05 12.04c.03 3.2 2.81 4.27 2.84 4.28-.02.08-.45 1.52-1.46 3-.88 1.28-1.79 2.55-3.23 2.57-1.41.03-1.87-.83-3.48-.83-1.62 0-2.12.81-3.46.86-1.39.05-2.45-1.38-3.34-2.66-1.82-2.61-3.21-7.36-1.34-10.57.93-1.59 2.59-2.6 4.39-2.62 1.37-.03 2.66.92 3.49.92.84 0 2.41-1.13 4.06-.97.69.03 2.62.28 3.87 2.1-.1.06-2.31 1.34-2.28 4.02M14.41 4.2c.74-.9 1.24-2.15 1.1-3.4-1.07.04-2.36.7-3.13 1.6-.68.79-1.28 2.07-1.12 3.29 1.19.09 2.4-.6 3.15-1.49"/></svg>,
};

// ─── primitives ────────────────────────────────────────────────
function Stat({ label, value, unit, delta, deltaDir, theme }) {
  const t = theme;
  return (
    <div style={{ flex: 1 }}>
      <div style={{ fontSize: 11, color: t.textMuted, textTransform: 'uppercase', letterSpacing: 0.4, fontWeight: 500 }}>{label}</div>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 4, marginTop: 6 }}>
        <span style={{ fontFamily: 'Geist Mono, ui-monospace, monospace', fontSize: 28, fontWeight: 500, color: t.text, letterSpacing: -1, fontVariantNumeric: 'tabular-nums' }}>{value}</span>
        {unit && <span style={{ fontSize: 12, color: t.textMuted, fontFamily: 'Geist Mono, ui-monospace, monospace' }}>{unit}</span>}
      </div>
      {delta && (
        <div style={{ fontSize: 11, color: deltaDir === 'down' ? t.danger : t.text, marginTop: 4, fontFamily: 'Geist Mono, ui-monospace, monospace', fontVariantNumeric: 'tabular-nums', display: 'flex', alignItems: 'center', gap: 3 }}>
          <span style={{ color: deltaDir === 'down' ? t.danger : t.accent }}>{deltaDir === 'down' ? '↓' : '↑'}</span>{delta}
        </div>
      )}
    </div>
  );
}

function PrimaryButton({ children, theme, onClick, full, style = {} }) {
  return (
    <button onClick={onClick} style={{
      background: theme.accent, color: theme.accentText,
      border: 'none', borderRadius: 999, height: 52,
      width: full ? '100%' : undefined,
      padding: full ? undefined : '0 24px',
      fontFamily: 'Geist, system-ui', fontWeight: 600, fontSize: 16,
      letterSpacing: -0.2, cursor: 'pointer', display: 'inline-flex',
      alignItems: 'center', justifyContent: 'center', gap: 8,
      ...style,
    }}>{children}</button>
  );
}

function GhostButton({ children, theme, full, style = {} }) {
  return (
    <button style={{
      background: 'transparent', color: theme.text,
      border: `1px solid ${theme.borderStrong}`, borderRadius: 999, height: 52,
      width: full ? '100%' : undefined, padding: full ? undefined : '0 24px',
      fontFamily: 'Geist, system-ui', fontWeight: 500, fontSize: 15,
      cursor: 'pointer', display: 'inline-flex', alignItems: 'center',
      justifyContent: 'center', gap: 10, ...style,
    }}>{children}</button>
  );
}

function Card({ children, theme, style = {}, pad = 16 }) {
  return (
    <div style={{
      background: theme.surface, borderRadius: 22,
      border: `1px solid ${theme.border}`,
      padding: pad, ...style,
    }}>{children}</div>
  );
}

function SectionHead({ children, action, theme, style = {} }) {
  return (
    <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', padding: '0 20px', marginBottom: 12, ...style }}>
      <span style={{ fontFamily: 'Geist, system-ui', fontSize: 13, fontWeight: 500, textTransform: 'uppercase', letterSpacing: 0.5, color: theme.textMuted }}>{children}</span>
      {action && <span style={{ fontSize: 13, color: theme.textMid, fontFamily: 'Geist, system-ui' }}>{action}</span>}
    </div>
  );
}

// ─── chart: lightweight sparkline / line / area ────────────────
function LineChart({ data, theme, width = 320, height = 140, showAxis = true, showFill = true, accent = false, baseline = null }) {
  const t = theme;
  const pad = { l: showAxis ? 28 : 0, r: 4, t: 8, b: showAxis ? 18 : 0 };
  const w = width - pad.l - pad.r;
  const h = height - pad.t - pad.b;
  const ys = data.map(d => d.y);
  const min = Math.min(...ys), max = Math.max(...ys);
  const span = max - min || 1;
  const range = [min - span * 0.15, max + span * 0.15];
  const x = (i) => pad.l + (i / (data.length - 1)) * w;
  const y = (v) => pad.t + h - ((v - range[0]) / (range[1] - range[0])) * h;
  const pts = data.map((d, i) => `${x(i)},${y(d.y)}`).join(' ');
  const path = data.map((d, i) => `${i === 0 ? 'M' : 'L'}${x(i)} ${y(d.y)}`).join(' ');
  const fillPath = `${path} L${x(data.length - 1)} ${pad.t + h} L${x(0)} ${pad.t + h} Z`;
  const stroke = accent ? t.accent : t.chartLine;
  const ticks = [range[0], (range[0] + range[1]) / 2, range[1]];
  return (
    <svg width={width} height={height} style={{ display: 'block', overflow: 'visible' }}>
      {showAxis && ticks.map((tv, i) => (
        <g key={i}>
          <line x1={pad.l} x2={pad.l + w} y1={y(tv)} y2={y(tv)} stroke={t.grid} strokeWidth="1"/>
          <text x={pad.l - 6} y={y(tv) + 3} textAnchor="end" fontFamily="Geist Mono, monospace" fontSize="9" fill={t.textMuted}>{tv.toFixed(0)}</text>
        </g>
      ))}
      {baseline != null && (
        <line x1={pad.l} x2={pad.l + w} y1={y(baseline)} y2={y(baseline)} stroke={t.accent} strokeWidth="1" strokeDasharray="3 3" opacity="0.7"/>
      )}
      {showFill && <path d={fillPath} fill={accent ? t.accent : t.chartLine} opacity={accent ? 0.12 : 0.06}/>}
      <path d={path} fill="none" stroke={stroke} strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round"/>
      {data.map((d, i) => d.dot && (
        <circle key={i} cx={x(i)} cy={y(d.y)} r="3" fill={t.bg} stroke={stroke} strokeWidth="1.5"/>
      ))}
      {showAxis && data.map((d, i) => d.label && (
        <text key={i} x={x(i)} y={height - 4} textAnchor="middle" fontFamily="Geist Mono, monospace" fontSize="9" fill={t.textMuted}>{d.label}</text>
      ))}
    </svg>
  );
}

// ─── chart: bars (for weekly volume etc) ────────────────────────
function BarChart({ data, theme, width = 320, height = 120, accent = false }) {
  const t = theme;
  const max = Math.max(...data.map(d => d.y), 1);
  const bw = (width - 16) / data.length - 6;
  const h = height - 24;
  return (
    <svg width={width} height={height}>
      {data.map((d, i) => {
        const bh = (d.y / max) * h;
        const x = 8 + i * (bw + 6);
        const y = 4 + (h - bh);
        const isToday = d.today;
        return (
          <g key={i}>
            <rect x={x} y={4} width={bw} height={h} rx={bw / 2} fill={t.grid}/>
            <rect x={x} y={y} width={bw} height={bh} rx={bw / 2} fill={isToday ? t.accent : (accent ? t.accent : t.chartLine)}/>
            <text x={x + bw / 2} y={height - 6} textAnchor="middle" fontFamily="Geist Mono, monospace" fontSize="9" fill={isToday ? t.text : t.textMuted}>{d.label}</text>
          </g>
        );
      })}
    </svg>
  );
}

// ─── tab bar (bottom) ──────────────────────────────────────────
function TabBar({ active, theme }) {
  const t = theme;
  const items = [
    { k: 'home', label: 'Home', icon: <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinejoin="round"><path d="M4 11l8-7 8 7v9a1 1 0 01-1 1h-4v-6h-6v6H5a1 1 0 01-1-1v-9z"/></svg> },
    { k: 'train', label: 'Training', icon: I.dumbbell(22) },
    { k: 'run', label: 'Cardio', icon: I.run(22) },
    { k: 'body', label: 'Körper', icon: <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round"><circle cx="12" cy="5" r="2.3"/><path d="M9 22v-6H7v-4a4 4 0 014-4h2a4 4 0 014 4v4h-2v6"/></svg> },
    { k: 'me', label: 'Profil', icon: <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round"><circle cx="12" cy="8" r="4"/><path d="M4 21c0-4 4-7 8-7s8 3 8 7"/></svg> },
  ];
  return (
    <div style={{
      position: 'absolute', left: 0, right: 0, bottom: 0,
      paddingBottom: 28, paddingTop: 8,
      background: `linear-gradient(to top, ${t.bg} 70%, transparent)`,
      display: 'flex', justifyContent: 'space-around',
    }}>
      {items.map(it => (
        <div key={it.k} style={{
          display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4,
          color: it.k === active ? t.text : t.textMuted,
          padding: '6px 12px',
        }}>
          {it.icon}
          <span style={{ fontSize: 10, fontWeight: 500, letterSpacing: 0.2 }}>{it.label}</span>
        </div>
      ))}
    </div>
  );
}

// ─── header (smaller than full nav bar) ────────────────────────
function ScreenHeader({ title, eyebrow, action, back, theme }) {
  const t = theme;
  return (
    <div style={{ padding: '54px 20px 14px', display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', gap: 12 }}>
      <div style={{ flex: 1, minWidth: 0 }}>
        {back && (
          <button style={{ background: 'transparent', border: 'none', color: t.textMid, padding: 0, marginBottom: 10, display: 'flex', alignItems: 'center', gap: 4, fontFamily: 'Geist, system-ui', fontSize: 14, cursor: 'pointer' }}>
            {I.chev(14, 'left')} {back}
          </button>
        )}
        {eyebrow && <div style={{ fontSize: 11, fontWeight: 500, letterSpacing: 0.6, textTransform: 'uppercase', color: t.textMuted, marginBottom: 6, fontFamily: 'Geist Mono, monospace' }}>{eyebrow}</div>}
        <h1 style={{ margin: 0, fontFamily: 'Geist, system-ui', fontSize: 32, fontWeight: 600, color: t.text, letterSpacing: -1, lineHeight: 1.05 }}>{title}</h1>
      </div>
      {action}
    </div>
  );
}

// ─── shared "Screen" wrapper: background + safe area top ───────
function Screen({ children, theme, style = {} }) {
  return (
    <div style={{
      width: '100%', height: '100%', background: theme.bg,
      color: theme.text, fontFamily: 'Geist, system-ui',
      position: 'relative', overflow: 'hidden', ...style,
    }}>{children}</div>
  );
}

Object.assign(window, {
  themes, ThemeCtx, useTheme,
  I, Stat, PrimaryButton, GhostButton, Card, SectionHead,
  LineChart, BarChart, TabBar, ScreenHeader, Screen,
});
