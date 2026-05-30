// Run live tracking + run history (with map)

function RunLiveScreen() {
  const t = useTheme();
  return (
    <Screen theme={t} style={{ background: t.bg }}>
      {/* status line */}
      <div style={{ padding: '54px 20px 0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <div style={{ width: 8, height: 8, borderRadius: 4, background: t.accent, boxShadow: `0 0 0 4px ${t.accent}22` }}></div>
          <span style={{ fontFamily: 'Geist Mono, monospace', fontSize: 11, color: t.textMid, textTransform: 'uppercase', letterSpacing: 1 }}>LIVE · GPS GUT</span>
        </div>
        <button style={{ background: 'transparent', border: `1px solid ${t.border}`, borderRadius: 999, padding: '6px 12px', fontSize: 12, color: t.textMid, fontFamily: 'Geist, system-ui', display: 'inline-flex', alignItems: 'center', gap: 6 }}>{I.map(14)} Karte</button>
      </div>

      {/* Hero metric: distance */}
      <div style={{ padding: '36px 20px 0', textAlign: 'center' }}>
        <div style={{ fontFamily: 'Geist Mono, monospace', fontSize: 11, color: t.textMuted, textTransform: 'uppercase', letterSpacing: 1.2 }}>Distanz</div>
        <div style={{ fontFamily: 'Geist Mono, monospace', fontSize: 88, fontWeight: 500, letterSpacing: -3.5, lineHeight: 1, marginTop: 4, fontVariantNumeric: 'tabular-nums' }}>
          5,42<span style={{ fontSize: 28, color: t.textMuted, marginLeft: 4 }}>km</span>
        </div>
      </div>

      {/* Three secondary stats */}
      <div style={{ padding: '36px 20px 0', display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 0 }}>
        {[
          { label: 'Zeit', value: '28:14' },
          { label: 'Pace', value: '5:12', accent: true },
          { label: 'BPM', value: '154' },
        ].map((s, i) => (
          <div key={s.label} style={{
            textAlign: 'center', padding: '0 6px',
            borderLeft: i === 0 ? 'none' : `1px solid ${t.border}`,
          }}>
            <div style={{ fontFamily: 'Geist Mono, monospace', fontSize: 10, color: t.textMuted, textTransform: 'uppercase', letterSpacing: 1 }}>{s.label}</div>
            <div style={{ fontFamily: 'Geist Mono, monospace', fontSize: 28, fontWeight: 500, letterSpacing: -1, marginTop: 6, color: s.accent ? t.accent : t.text, fontVariantNumeric: 'tabular-nums' }}>{s.value}</div>
          </div>
        ))}
      </div>

      {/* Höhenmeter */}
      <div style={{ padding: '34px 20px 0' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
          <div style={{ fontFamily: 'Geist Mono, monospace', fontSize: 11, color: t.textMuted, textTransform: 'uppercase', letterSpacing: 1 }}>Höhenmeter</div>
          <div style={{ fontFamily: 'Geist Mono, monospace', fontSize: 14, color: t.text, fontVariantNumeric: 'tabular-nums' }}>+82<span style={{ color: t.textMuted }}> m</span></div>
        </div>
        <div style={{ marginTop: 8 }}>
          <ElevationChart theme={t} width={362} height={64}/>
        </div>
      </div>

      {/* km splits */}
      <div style={{ padding: '24px 20px 160px' }}>
        <div style={{ fontFamily: 'Geist Mono, monospace', fontSize: 11, color: t.textMuted, textTransform: 'uppercase', letterSpacing: 1, marginBottom: 8 }}>Splits</div>
        <div style={{ background: t.surface, borderRadius: 14, border: `1px solid ${t.border}`, overflow: 'hidden' }}>
          {[
            { k: 1, pace: '5:18', bpm: 148 },
            { k: 2, pace: '5:14', bpm: 152 },
            { k: 3, pace: '5:09', bpm: 156, best: true },
            { k: 4, pace: '5:11', bpm: 155 },
            { k: 5, pace: '5:08', bpm: 158 },
          ].map((s, i, arr) => (
            <div key={s.k} style={{
              display: 'grid', gridTemplateColumns: '36px 1fr 60px 56px',
              padding: '10px 14px', alignItems: 'center', gap: 8,
              borderBottom: i === arr.length - 1 ? 'none' : `1px solid ${t.border}`,
              fontFamily: 'Geist Mono, monospace', fontSize: 13, fontVariantNumeric: 'tabular-nums',
            }}>
              <span style={{ color: t.textMuted }}>KM {s.k}</span>
              <div style={{ height: 4, borderRadius: 2, background: t.surface2, position: 'relative', overflow: 'hidden' }}>
                <div style={{ position: 'absolute', left: 0, top: 0, bottom: 0, width: `${30 + s.k * 14}%`, background: s.best ? t.accent : t.text, borderRadius: 2 }}></div>
              </div>
              <span style={{ color: s.best ? t.accent : t.text }}>{s.pace}/km</span>
              <span style={{ color: t.textMid, textAlign: 'right' }}>{s.bpm} bpm</span>
            </div>
          ))}
        </div>
      </div>

      {/* Bottom controls */}
      <div style={{ position: 'absolute', bottom: 30, left: 0, right: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 14 }}>
        <button style={{ width: 60, height: 60, borderRadius: 30, background: t.surface, border: `1px solid ${t.borderStrong}`, color: t.text, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><rect x="6" y="6" width="12" height="12" rx="2"/></svg>
        </button>
        <button style={{ width: 88, height: 88, borderRadius: 44, background: t.accent, color: t.accentText, border: `8px solid ${t.bg}`, boxShadow: `0 0 0 1px ${t.accent}`, fontFamily: 'Geist, system-ui', fontWeight: 600, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{I.pause(22)}</button>
        <button style={{ width: 60, height: 60, borderRadius: 30, background: t.surface, border: `1px solid ${t.borderStrong}`, color: t.text, display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'Geist Mono, monospace', fontSize: 11 }}>LAP</button>
      </div>
    </Screen>
  );
}

function ElevationChart({ theme, width = 320, height = 60 }) {
  const t = theme;
  // sample elevation profile
  const pts = [0, 2, 6, 5, 12, 18, 22, 26, 32, 30, 38, 45, 52, 60, 64, 70, 78, 82, 78, 80];
  const max = Math.max(...pts), min = Math.min(...pts);
  const w = width, h = height;
  const xs = pts.map((p, i) => (i / (pts.length - 1)) * w);
  const ys = pts.map(p => h - ((p - min) / (max - min)) * (h - 6) - 3);
  const path = pts.map((p, i) => `${i === 0 ? 'M' : 'L'}${xs[i]} ${ys[i]}`).join(' ');
  const area = `${path} L${w} ${h} L0 ${h} Z`;
  return (
    <svg width={width} height={height} style={{ display: 'block' }}>
      <path d={area} fill={t.accent} opacity="0.12"/>
      <path d={path} fill="none" stroke={t.accent} strokeWidth="1.6" strokeLinejoin="round"/>
    </svg>
  );
}


function RunHistoryScreen() {
  const t = useTheme();
  return (
    <Screen theme={t}>
      <ScreenHeader theme={t} eyebrow="Cardio · Mai" title="Läufe"
        action={<CircleBtn theme={t}>{I.filter(16)}</CircleBtn>}/>

      {/* Month summary */}
      <div style={{ padding: '0 20px 16px' }}>
        <Card theme={t} pad={18}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <div>
              <div style={{ fontSize: 11, color: t.textMuted, textTransform: 'uppercase', letterSpacing: 0.6, fontFamily: 'Geist Mono, monospace' }}>Mai · 8 Läufe</div>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 4, marginTop: 8 }}>
                <span style={{ fontFamily: 'Geist Mono, monospace', fontSize: 36, fontWeight: 500, letterSpacing: -1.4, fontVariantNumeric: 'tabular-nums' }}>42,8</span>
                <span style={{ fontSize: 14, color: t.textMuted, fontFamily: 'Geist Mono, monospace' }}>km</span>
              </div>
              <div style={{ fontSize: 12, color: t.accent, fontFamily: 'Geist Mono, monospace', marginTop: 4 }}>↑ 18% vs. April</div>
            </div>
            <div style={{ textAlign: 'right' }}>
              <div style={{ fontSize: 11, color: t.textMuted, textTransform: 'uppercase', letterSpacing: 0.6, fontFamily: 'Geist Mono, monospace' }}>Ø Pace</div>
              <div style={{ fontFamily: 'Geist Mono, monospace', fontSize: 22, fontWeight: 500, marginTop: 8, fontVariantNumeric: 'tabular-nums' }}>5:14<span style={{ fontSize: 12, color: t.textMuted }}>/km</span></div>
            </div>
          </div>
          <div style={{ marginTop: 16 }}>
            <BarChart theme={t} width={326} height={84} data={[
              { y: 4.2, label: 'KW16' },{ y: 6.8, label: 'KW17' },{ y: 8.1, label: 'KW18' },{ y: 11.2, label: 'KW19' },{ y: 12.5, label: 'KW20', today: true }
            ]}/>
          </div>
        </Card>
      </div>

      <SectionHead theme={t}>Letzte Läufe</SectionHead>
      <div style={{ padding: '0 20px 100px', display: 'flex', flexDirection: 'column', gap: 10 }}>
        {[
          { d: 'Heute · 07:42', dist: '5,42', time: '28:14', pace: '5:12', gain: 82, route: 'r1' },
          { d: 'Mo · 12. Mai', dist: '8,10', time: '42:50', pace: '5:18', gain: 124, route: 'r2' },
          { d: 'Sa · 10. Mai', dist: '12,02', time: '1:04:30', pace: '5:22', gain: 186, route: 'r3' },
        ].map((r, i) => (
          <div key={i} style={{ background: t.surface, borderRadius: 20, padding: 14, border: `1px solid ${t.border}`, display: 'flex', gap: 12, alignItems: 'center' }}>
            <MiniMap theme={t} route={r.route} />
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontFamily: 'Geist Mono, monospace', fontSize: 10, color: t.textMuted, textTransform: 'uppercase', letterSpacing: 0.6 }}>{r.d}</div>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 4, marginTop: 4 }}>
                <span style={{ fontFamily: 'Geist Mono, monospace', fontSize: 20, fontWeight: 500, fontVariantNumeric: 'tabular-nums' }}>{r.dist}</span>
                <span style={{ fontSize: 11, color: t.textMuted, fontFamily: 'Geist Mono, monospace' }}>km</span>
              </div>
              <div style={{ fontSize: 11, color: t.textMid, fontFamily: 'Geist Mono, monospace', marginTop: 4, display: 'flex', gap: 8, fontVariantNumeric: 'tabular-nums' }}>
                <span>{r.time}</span><span style={{ opacity: 0.4 }}>·</span><span>{r.pace}/km</span><span style={{ opacity: 0.4 }}>·</span><span>+{r.gain}m</span>
              </div>
            </div>
            <span style={{ color: t.textMuted }}>{I.chev(14, 'right')}</span>
          </div>
        ))}

        {/* Detail callout — embedded route map */}
        <Card theme={t} pad={0} style={{ marginTop: 14, overflow: 'hidden' }}>
          <BigMap theme={t}/>
          <div style={{ padding: 16 }}>
            <div style={{ fontSize: 11, color: t.textMuted, textTransform: 'uppercase', letterSpacing: 0.6, fontFamily: 'Geist Mono, monospace' }}>Heute · 07:42</div>
            <div style={{ display: 'flex', gap: 14, marginTop: 8, fontFamily: 'Geist Mono, monospace', fontVariantNumeric: 'tabular-nums' }}>
              <div><div style={{ fontSize: 9, color: t.textMuted, textTransform: 'uppercase' }}>Distanz</div><div style={{ fontSize: 18, fontWeight: 500, letterSpacing: -0.5 }}>5,42<span style={{ fontSize: 10, color: t.textMuted, marginLeft: 2 }}>km</span></div></div>
              <div><div style={{ fontSize: 9, color: t.textMuted, textTransform: 'uppercase' }}>Zeit</div><div style={{ fontSize: 18, fontWeight: 500, letterSpacing: -0.5 }}>28:14</div></div>
              <div><div style={{ fontSize: 9, color: t.textMuted, textTransform: 'uppercase' }}>Pace</div><div style={{ fontSize: 18, fontWeight: 500, letterSpacing: -0.5, color: t.accent }}>5:12</div></div>
              <div><div style={{ fontSize: 9, color: t.textMuted, textTransform: 'uppercase' }}>D+</div><div style={{ fontSize: 18, fontWeight: 500, letterSpacing: -0.5 }}>+82<span style={{ fontSize: 10, color: t.textMuted, marginLeft: 2 }}>m</span></div></div>
            </div>
          </div>
        </Card>
      </div>

      <TabBar active="run" theme={t}/>
    </Screen>
  );
}

function MiniMap({ theme, route = 'r1' }) {
  const t = theme;
  const paths = {
    r1: 'M8 38 Q14 20 24 22 T42 14 Q50 18 54 30 T64 34',
    r2: 'M6 28 Q16 12 30 18 T54 28 Q62 36 60 50',
    r3: 'M10 14 Q24 30 18 44 Q14 56 32 54 T60 38 Q64 28 56 16',
  };
  return (
    <div style={{ width: 72, height: 64, borderRadius: 14, background: t.surface2, position: 'relative', overflow: 'hidden', flexShrink: 0 }}>
      <svg viewBox="0 0 72 64" width="72" height="64">
        <defs>
          <pattern id={`g-${route}`} patternUnits="userSpaceOnUse" width="8" height="8">
            <path d="M 8 0 L 0 0 0 8" fill="none" stroke={t.border} strokeWidth="0.5"/>
          </pattern>
        </defs>
        <rect width="72" height="64" fill={`url(#g-${route})`}/>
        <path d={paths[route]} stroke={t.accent} strokeWidth="2.2" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
        <circle cx="8" cy={route === 'r3' ? '14' : route === 'r2' ? '28' : '38'} r="2.5" fill={t.bg} stroke={t.accent} strokeWidth="1.5"/>
      </svg>
    </div>
  );
}

function BigMap({ theme }) {
  const t = theme;
  return (
    <div style={{ width: '100%', height: 180, background: t.surface2, position: 'relative', overflow: 'hidden' }}>
      <svg viewBox="0 0 320 180" width="100%" height="180" preserveAspectRatio="xMidYMid slice">
        <defs>
          <pattern id="g-big" patternUnits="userSpaceOnUse" width="20" height="20">
            <path d="M 20 0 L 0 0 0 20" fill="none" stroke={t.border} strokeWidth="0.6"/>
          </pattern>
        </defs>
        <rect width="320" height="180" fill={`url(#g-big)`}/>
        {/* faux streets */}
        <path d="M0 60 L320 70 M0 120 L320 100 M80 0 L100 180 M220 0 L210 180" stroke={t.border} strokeWidth="1"/>
        {/* route */}
        <path d="M40 140 Q70 60 130 80 T220 50 Q260 60 280 110 T270 160" stroke={t.accent} strokeWidth="3" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
        {/* start/end */}
        <circle cx="40" cy="140" r="6" fill={t.bg} stroke={t.accent} strokeWidth="2.5"/>
        <circle cx="270" cy="160" r="6" fill={t.accent} stroke={t.bg} strokeWidth="2.5"/>
      </svg>
      <div style={{ position: 'absolute', top: 12, left: 14, fontFamily: 'Geist Mono, monospace', fontSize: 10, color: t.textMid, textTransform: 'uppercase', letterSpacing: 1, background: t.bg, padding: '4px 8px', borderRadius: 4, border: `1px solid ${t.border}` }}>Englischer Garten · Loop</div>
    </div>
  );
}

Object.assign(window, { RunLiveScreen, RunHistoryScreen, MiniMap, BigMap });
