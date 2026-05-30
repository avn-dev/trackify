// Blood / Lab tracking screens

function LabOverviewScreen() {
  const t = useTheme();
  const groups = [
    {
      cat: 'Vitamine & Mineralstoffe',
      items: [
        { name: 'Vitamin D (25-OH)', value: '38', unit: 'ng/ml', range: '30–70', status: 'ok', trend: '+4', trendDir: 'up' },
        { name: 'Ferritin',          value: '24', unit: 'µg/l',  range: '30–200', status: 'low', trend: '−6', trendDir: 'down' },
        { name: 'Magnesium',         value: '0,92', unit: 'mmol/l', range: '0,75–1,02', status: 'ok', trend: '0', trendDir: 'flat' },
        { name: 'Vitamin B12',       value: '486', unit: 'pg/ml', range: '200–900', status: 'ok', trend: '+18', trendDir: 'up' },
      ],
    },
    {
      cat: 'Blutfette',
      items: [
        { name: 'Gesamtcholesterin', value: '198', unit: 'mg/dl', range: '<200', status: 'ok', trend: '−12', trendDir: 'down' },
        { name: 'LDL',               value: '128', unit: 'mg/dl', range: '<116', status: 'high', trend: '−4', trendDir: 'down' },
        { name: 'HDL',               value: '64',  unit: 'mg/dl', range: '>40', status: 'ok', trend: '+2', trendDir: 'up' },
        { name: 'Triglyceride',      value: '88',  unit: 'mg/dl', range: '<150', status: 'ok', trend: '−5', trendDir: 'down' },
      ],
    },
    {
      cat: 'Hormone & Schilddrüse',
      items: [
        { name: 'TSH',         value: '2,1', unit: 'mU/l', range: '0,4–4,0', status: 'ok', trend: '+0,2', trendDir: 'up' },
        { name: 'Testosteron', value: '684', unit: 'ng/dl', range: '300–900', status: 'ok', trend: '+42', trendDir: 'up' },
      ],
    },
    {
      cat: 'Blutbild',
      items: [
        { name: 'Hämoglobin',  value: '14,2', unit: 'g/dl', range: '12–16', status: 'ok' },
        { name: 'Leukozyten',  value: '5,8',  unit: 'Tsd/µl', range: '4–10', status: 'ok' },
      ],
    },
  ];

  return (
    <Screen theme={t}>
      <ScreenHeader theme={t} eyebrow="Labor · Letzte Messung 12. Mai" title="Blutwerte"
        action={<CircleBtn theme={t}>{I.plus(18)}</CircleBtn>}/>

      {/* Summary card */}
      <div style={{ padding: '0 20px 14px' }}>
        <Card theme={t} pad={18}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <div>
              <div style={{ fontSize: 11, color: t.textMuted, textTransform: 'uppercase', letterSpacing: 0.6, fontFamily: 'Geist Mono, monospace' }}>Großes Blutbild · Mai 26</div>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, marginTop: 8 }}>
                <span style={{ fontFamily: 'Geist Mono, monospace', fontSize: 36, fontWeight: 500, letterSpacing: -1.2, fontVariantNumeric: 'tabular-nums' }}>11<span style={{ color: t.textMuted, fontSize: 18 }}> / 13</span></span>
              </div>
              <div style={{ fontSize: 12, color: t.textMid, marginTop: 4, fontFamily: 'Geist Mono, monospace' }}>Marker im Normbereich</div>
            </div>
            {/* status segments */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: 6, alignItems: 'flex-end' }}>
              <StatusPip theme={t} color={t.accent} label="11 normal"/>
              <StatusPip theme={t} color={t.danger}  label="1 zu hoch"/>
              <StatusPip theme={t} color="#f5b13a" label="1 zu niedrig"/>
            </div>
          </div>

          {/* range bar */}
          <div style={{ marginTop: 16, height: 8, borderRadius: 4, background: t.surface2, overflow: 'hidden', display: 'flex' }}>
            <div style={{ width: '85%', background: t.accent }}></div>
            <div style={{ width: '7%', background: t.danger }}></div>
            <div style={{ width: '8%', background: '#f5b13a' }}></div>
          </div>

          <button style={{
            marginTop: 14, width: '100%', height: 44, borderRadius: 12,
            background: 'transparent', border: `1px solid ${t.borderStrong}`,
            color: t.text, fontFamily: 'Geist, system-ui', fontSize: 13, fontWeight: 500,
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
          }}>Bericht ansehen {I.chev(12, 'right')}</button>
        </Card>
      </div>

      {/* Markers by category */}
      <div style={{ padding: '0 20px 100px' }}>
        {groups.map((g, gi) => (
          <div key={g.cat} style={{ marginBottom: 18 }}>
            <SectionHead theme={t} action={`${g.items.length} Marker`} style={{ padding: 0, marginBottom: 10 }}>{g.cat}</SectionHead>
            <Card theme={t} pad={0}>
              {g.items.map((m, i) => (
                <LabRow key={m.name} m={m} theme={t} last={i === g.items.length - 1}/>
              ))}
            </Card>
          </div>
        ))}

        {/* New lab CTA */}
        <button style={{
          width: '100%', background: 'transparent', border: `1.5px dashed ${t.borderStrong}`,
          borderRadius: 22, padding: 18, color: t.text, textAlign: 'left',
          fontFamily: 'Geist, system-ui', display: 'flex', alignItems: 'center', gap: 14,
        }}>
          <div style={{ width: 40, height: 40, borderRadius: 12, background: t.surface, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{I.plus(20)}</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 15, fontWeight: 600 }}>Neue Messung</div>
            <div style={{ fontSize: 12, color: t.textMuted, fontFamily: 'Geist Mono, monospace' }}>Foto · PDF · manuell</div>
          </div>
          {I.chev(14, 'right')}
        </button>
      </div>

      <TabBar active="body" theme={t}/>
    </Screen>
  );
}

function StatusPip({ theme, color, label }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontFamily: 'Geist Mono, monospace', fontSize: 11, color: theme.textMid, letterSpacing: 0.4 }}>
      <span style={{ width: 6, height: 6, borderRadius: 3, background: color }}></span>{label}
    </div>
  );
}

function LabRow({ m, theme, last }) {
  const t = theme;
  // status -> color
  const statusColor = m.status === 'high' ? t.danger : m.status === 'low' ? '#f5b13a' : t.accent;
  const statusLabel = m.status === 'high' ? 'zu hoch' : m.status === 'low' ? 'zu niedrig' : 'normal';
  return (
    <div style={{
      padding: '14px 16px', display: 'grid',
      gridTemplateColumns: '8px 1fr auto', gap: 12, alignItems: 'center',
      borderBottom: last ? 'none' : `1px solid ${t.border}`,
    }}>
      <div style={{ width: 6, height: 6, borderRadius: 3, background: statusColor }}></div>
      <div style={{ minWidth: 0 }}>
        <div style={{ fontFamily: 'Geist, system-ui', fontSize: 14, fontWeight: 500 }}>{m.name}</div>
        <div style={{ fontSize: 11, color: t.textMuted, fontFamily: 'Geist Mono, monospace', marginTop: 2, display: 'flex', gap: 6, alignItems: 'center' }}>
          <span style={{ color: statusColor, textTransform: 'uppercase', letterSpacing: 0.6, fontWeight: 500 }}>{statusLabel}</span>
          <span style={{ opacity: 0.4 }}>·</span>
          <span>Norm {m.range}</span>
        </div>
      </div>
      <div style={{ textAlign: 'right' }}>
        <div style={{ fontFamily: 'Geist Mono, monospace', fontSize: 16, fontWeight: 500, fontVariantNumeric: 'tabular-nums', letterSpacing: -0.3 }}>
          {m.value}<span style={{ fontSize: 10, color: t.textMuted, marginLeft: 2 }}>{m.unit}</span>
        </div>
        {m.trend && (
          <div style={{ fontSize: 10, fontFamily: 'Geist Mono, monospace', marginTop: 2, color: m.trendDir === 'flat' ? t.textMuted : (m.trendDir === 'up' ? t.accent : t.danger), fontVariantNumeric: 'tabular-nums' }}>
            {m.trendDir === 'up' ? '↑' : m.trendDir === 'down' ? '↓' : '–'} {m.trend}
          </div>
        )}
      </div>
    </div>
  );
}


function LabMarkerDetailScreen() {
  const t = useTheme();
  // Vitamin D detail example
  const min = 30, max = 70; // normal range
  const current = 38;
  const fullMin = 10, fullMax = 90;

  // history values for chart
  const history = [
    { y: 18, label: 'Nov 24', dot: false },
    { y: 22, label: '' },
    { y: 25, label: 'Feb 25' },
    { y: 26, label: '' },
    { y: 28, label: 'Mai 25' },
    { y: 31, label: '' },
    { y: 30, label: 'Aug 25' },
    { y: 32, label: '' },
    { y: 34, label: 'Nov 25' },
    { y: 36, label: '' },
    { y: 35, label: 'Feb 26' },
    { y: 38, label: 'Mai 26', dot: true },
  ];

  return (
    <Screen theme={t}>
      <ScreenHeader theme={t} back="Labor" eyebrow="Vitamine · 25-OH" title="Vitamin D"
        action={<CircleBtn theme={t}>{I.more(16)}</CircleBtn>}/>

      {/* Big value + status */}
      <div style={{ padding: '0 20px 16px' }}>
        <Card theme={t} pad={20}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <div>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 6 }}>
                <span style={{ fontFamily: 'Geist Mono, monospace', fontSize: 56, fontWeight: 500, letterSpacing: -2.2, lineHeight: 1, fontVariantNumeric: 'tabular-nums' }}>{current}</span>
                <span style={{ fontSize: 16, color: t.textMuted, fontFamily: 'Geist Mono, monospace' }}>ng/ml</span>
              </div>
              <div style={{ marginTop: 10, display: 'flex', alignItems: 'center', gap: 8 }}>
                <div style={{ background: t.accent, color: t.accentText, padding: '4px 10px', borderRadius: 6, fontFamily: 'Geist Mono, monospace', fontSize: 11, fontWeight: 600, textTransform: 'uppercase', letterSpacing: 0.8 }}>● Normal</div>
                <span style={{ fontSize: 12, color: t.accent, fontFamily: 'Geist Mono, monospace' }}>↑ 4 / 3 Mon.</span>
              </div>
            </div>
            <div style={{ textAlign: 'right' }}>
              <div style={{ fontSize: 11, color: t.textMuted, textTransform: 'uppercase', letterSpacing: 0.6, fontFamily: 'Geist Mono, monospace' }}>Norm</div>
              <div style={{ fontFamily: 'Geist Mono, monospace', fontSize: 14, marginTop: 6, fontVariantNumeric: 'tabular-nums' }}>{min}<span style={{ color: t.textMuted, fontSize: 11 }}>–</span>{max}</div>
              <div style={{ fontSize: 10, color: t.textMuted, fontFamily: 'Geist Mono, monospace', marginTop: 2 }}>ng/ml</div>
            </div>
          </div>

          {/* Range scale */}
          <div style={{ marginTop: 22 }}>
            <RangeScale theme={t} value={current} normMin={min} normMax={max} fullMin={fullMin} fullMax={fullMax}/>
          </div>
        </Card>
      </div>

      {/* Trend chart */}
      <div style={{ padding: '0 20px 16px' }}>
        <Card theme={t} pad={16}>
          <div style={{ display: 'flex', justifyContent: 'space-between' }}>
            <div style={{ fontSize: 11, color: t.textMuted, textTransform: 'uppercase', letterSpacing: 0.6, fontFamily: 'Geist Mono, monospace' }}>Verlauf · 18 Monate</div>
            <div style={{ display: 'flex', gap: 4 }}>
              {['1J','5J','Alles'].map((r, i) => (
                <span key={r} style={{ fontSize: 11, fontFamily: 'Geist Mono, monospace', padding: '2px 8px', borderRadius: 4, color: i === 0 ? t.text : t.textMuted, background: i === 0 ? t.surface2 : 'transparent' }}>{r}</span>
              ))}
            </div>
          </div>
          <div style={{ marginTop: 12, position: 'relative' }}>
            <ChartWithBand theme={t} data={history} bandMin={min} bandMax={max} width={326} height={148}/>
          </div>
        </Card>
      </div>

      {/* Hint card */}
      <div style={{ padding: '0 20px 16px' }}>
        <Card theme={t} pad={14} style={{ display: 'flex', gap: 12, alignItems: 'flex-start' }}>
          <div style={{ width: 32, height: 32, borderRadius: 10, background: t.accent, color: t.accentText, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>{I.bolt(16)}</div>
          <div>
            <div style={{ fontSize: 10, fontFamily: 'Geist Mono, monospace', textTransform: 'uppercase', letterSpacing: 0.8, color: t.textMuted, fontWeight: 600 }}>Tipp</div>
            <div style={{ fontFamily: 'Geist, system-ui', fontSize: 13, lineHeight: 1.4, marginTop: 4, color: t.text }}>
              Du steigerst über 18 Monate stetig. 50+ ng/ml gilt als optimal — weiter so.
            </div>
          </div>
        </Card>
      </div>

      {/* History list */}
      <div style={{ padding: '0 20px 100px' }}>
        <SectionHead theme={t} action="Alle">Einträge</SectionHead>
        <Card theme={t} pad={0}>
          {[
            { d: '12. Mai 2026', v: '38', delta: '+3', src: 'Hausarzt' },
            { d: '08. Feb 2026', v: '35', delta: '−1', src: 'Labor selbst' },
            { d: '04. Nov 2025', v: '36', delta: '+2', src: 'Hausarzt' },
            { d: '12. Aug 2025', v: '30', delta: '+2', src: 'Labor selbst' },
            { d: '05. Mai 2025', v: '28', delta: '+3', src: 'Hausarzt' },
          ].map((e, i, arr) => (
            <div key={i} style={{ padding: '12px 14px', display: 'grid', gridTemplateColumns: '1fr auto auto', gap: 10, alignItems: 'center', borderBottom: i === arr.length - 1 ? 'none' : `1px solid ${t.border}` }}>
              <div>
                <div style={{ fontFamily: 'Geist, system-ui', fontSize: 13, color: t.text }}>{e.d}</div>
                <div style={{ fontSize: 10, color: t.textMuted, fontFamily: 'Geist Mono, monospace', marginTop: 2, textTransform: 'uppercase', letterSpacing: 0.5 }}>{e.src}</div>
              </div>
              <div style={{ fontFamily: 'Geist Mono, monospace', fontSize: 14, fontWeight: 500, fontVariantNumeric: 'tabular-nums' }}>{e.v}<span style={{ color: t.textMuted, fontSize: 10, marginLeft: 2 }}>ng/ml</span></div>
              <div style={{ fontFamily: 'Geist Mono, monospace', fontSize: 11, color: e.delta.startsWith('+') ? t.accent : t.danger, width: 32, textAlign: 'right' }}>{e.delta}</div>
            </div>
          ))}
        </Card>
      </div>

      <TabBar active="body" theme={t}/>
    </Screen>
  );
}

function RangeScale({ theme, value, normMin, normMax, fullMin, fullMax }) {
  const t = theme;
  const w = 326;
  const pad = 4;
  const inner = w - pad * 2;
  const span = fullMax - fullMin;
  const xs = (v) => pad + ((v - fullMin) / span) * inner;
  const valX = xs(value);
  const lowX = xs(normMin);
  const highX = xs(normMax);

  return (
    <div>
      <div style={{ position: 'relative', height: 36 }}>
        <svg width={w} height="36" style={{ display: 'block', overflow: 'visible' }}>
          {/* background track */}
          <rect x={pad} y={14} width={inner} height={8} rx="4" fill={t.surface2}/>
          {/* low (warning) zone */}
          <rect x={pad} y={14} width={lowX - pad} height={8} rx="4" fill="#f5b13a" opacity="0.55"/>
          {/* normal zone */}
          <rect x={lowX} y={14} width={highX - lowX} height={8} fill={t.accent} opacity="0.85"/>
          {/* high zone */}
          <rect x={highX} y={14} width={(pad + inner) - highX} height={8} rx="4" fill={t.danger} opacity="0.55"/>
          {/* value marker */}
          <g transform={`translate(${valX}, 18)`}>
            <line x1="0" x2="0" y1="-8" y2="14" stroke={t.text} strokeWidth="2"/>
            <circle cx="0" cy="-6" r="6" fill={t.bg} stroke={t.text} strokeWidth="2"/>
          </g>
          {/* tick labels */}
          <text x={xs(fullMin)} y={36} fontFamily="Geist Mono, monospace" fontSize="9" fill={t.textMuted}>{fullMin}</text>
          <text x={lowX - 6} y={36} fontFamily="Geist Mono, monospace" fontSize="9" fill={t.textMid} textAnchor="middle">{normMin}</text>
          <text x={highX - 6} y={36} fontFamily="Geist Mono, monospace" fontSize="9" fill={t.textMid} textAnchor="middle">{normMax}</text>
          <text x={xs(fullMax)} y={36} fontFamily="Geist Mono, monospace" fontSize="9" fill={t.textMuted} textAnchor="end">{fullMax}</text>
        </svg>
      </div>
    </div>
  );
}

function ChartWithBand({ theme, data, bandMin, bandMax, width = 326, height = 148 }) {
  const t = theme;
  const pad = { l: 26, r: 4, t: 8, b: 22 };
  const w = width - pad.l - pad.r;
  const h = height - pad.t - pad.b;
  const ys = data.map(d => d.y);
  const allMin = Math.min(bandMin, ...ys);
  const allMax = Math.max(bandMax, ...ys);
  const range = [allMin - 4, allMax + 4];
  const x = (i) => pad.l + (i / (data.length - 1)) * w;
  const y = (v) => pad.t + h - ((v - range[0]) / (range[1] - range[0])) * h;
  const path = data.map((d, i) => `${i === 0 ? 'M' : 'L'}${x(i)} ${y(d.y)}`).join(' ');

  return (
    <svg width={width} height={height} style={{ display: 'block', overflow: 'visible' }}>
      {/* Normal band */}
      <rect x={pad.l} y={y(bandMax)} width={w} height={y(bandMin) - y(bandMax)} fill={t.accent} opacity="0.08"/>
      <line x1={pad.l} x2={pad.l + w} y1={y(bandMax)} y2={y(bandMax)} stroke={t.accent} strokeWidth="1" strokeDasharray="3 3" opacity="0.5"/>
      <line x1={pad.l} x2={pad.l + w} y1={y(bandMin)} y2={y(bandMin)} stroke={t.accent} strokeWidth="1" strokeDasharray="3 3" opacity="0.5"/>
      {/* Tick label for norm bounds */}
      <text x={pad.l - 6} y={y(bandMax) + 3} fontFamily="Geist Mono, monospace" fontSize="9" fill={t.accent} textAnchor="end">{bandMax}</text>
      <text x={pad.l - 6} y={y(bandMin) + 3} fontFamily="Geist Mono, monospace" fontSize="9" fill={t.accent} textAnchor="end">{bandMin}</text>

      {/* Line */}
      <path d={path} fill="none" stroke={t.text} strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round"/>
      {data.map((d, i) => d.dot && (
        <circle key={i} cx={x(i)} cy={y(d.y)} r="4" fill={t.bg} stroke={t.text} strokeWidth="2"/>
      ))}

      {/* labels */}
      {data.map((d, i) => d.label && (
        <text key={i} x={x(i)} y={height - 6} fontFamily="Geist Mono, monospace" fontSize="9" fill={t.textMuted} textAnchor="middle">{d.label}</text>
      ))}
    </svg>
  );
}


function LabAddScreen() {
  const t = useTheme();
  return (
    <Screen theme={t}>
      <ScreenHeader theme={t} back="Labor" title="Neue Messung"/>

      {/* Method tiles */}
      <div style={{ padding: '0 20px 18px', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
        <MethodTile theme={t} active icon={
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
            <path d="M5 7h2l2-3h6l2 3h2a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9a2 2 0 012-2z"/>
            <circle cx="12" cy="13" r="4"/>
          </svg>
        } title="Foto" sub="Befund abfotografieren"/>
        <MethodTile theme={t} icon={
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
            <path d="M14 3H6a2 2 0 00-2 2v14a2 2 0 002 2h12a2 2 0 002-2V9z"/>
            <path d="M14 3v6h6M9 14h6M9 18h4"/>
          </svg>
        } title="PDF" sub="Datei importieren"/>
        <MethodTile theme={t} icon={
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
            <path d="M4 20h4l10-10-4-4L4 16v4z"/><path d="M14 6l4 4"/>
          </svg>
        } title="Manuell" sub="Werte eintippen"/>
        <MethodTile theme={t} icon={
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
            <path d="M12 3v3M12 18v3M5 12H2M22 12h-3M6.3 6.3l-2 -2M19.7 19.7l-2-2M6.3 17.7l-2 2M19.7 4.3l-2 2"/>
            <circle cx="12" cy="12" r="4"/>
          </svg>
        } title="HL7 / Praxis" sub="Live-Import"/>
      </div>

      {/* Camera preview / context */}
      <div style={{ padding: '0 20px 18px' }}>
        <div style={{
          height: 280, borderRadius: 22, background: '#0a0a0c',
          border: `1px solid ${t.border}`, position: 'relative', overflow: 'hidden',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          {/* faux paper */}
          <div style={{
            width: 220, height: 220, background: '#f6f4ef', borderRadius: 6,
            transform: 'rotate(-3deg)', padding: '18px 20px',
            boxShadow: '0 30px 60px rgba(0,0,0,0.4)',
            fontFamily: 'Geist Mono, monospace', fontSize: 8, color: '#3a3a3d', lineHeight: 1.7,
          }}>
            <div style={{ fontWeight: 600, fontSize: 9 }}>LABOR DR. SCHMITT · 12.05.2026</div>
            <div style={{ height: 1, background: '#0a0a0c', marginTop: 4, marginBottom: 8 }}></div>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}><span>Hämoglobin</span><span>14,2 g/dl</span></div>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}><span>Vitamin D</span><span>38 ng/ml</span></div>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}><span>Ferritin</span><span>24 µg/l</span></div>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}><span>LDL</span><span>128 mg/dl</span></div>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}><span>HDL</span><span>64 mg/dl</span></div>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}><span>TSH</span><span>2,1 mU/l</span></div>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}><span>Magnesium</span><span>0,92 mmol/l</span></div>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}><span>Testosteron</span><span>684 ng/dl</span></div>
          </div>
          {/* scan corners */}
          {[
            { top: 32, left: 32, b: 'tl' },
            { top: 32, right: 32, b: 'tr' },
            { bottom: 32, left: 32, b: 'bl' },
            { bottom: 32, right: 32, b: 'br' },
          ].map(c => (
            <div key={c.b} style={{ position: 'absolute', top: c.top, bottom: c.bottom, left: c.left, right: c.right, width: 28, height: 28,
              borderTop: ['tl','tr'].includes(c.b) ? `2px solid ${t.accent}` : 'none',
              borderBottom: ['bl','br'].includes(c.b) ? `2px solid ${t.accent}` : 'none',
              borderLeft: ['tl','bl'].includes(c.b) ? `2px solid ${t.accent}` : 'none',
              borderRight: ['tr','br'].includes(c.b) ? `2px solid ${t.accent}` : 'none',
              borderTopLeftRadius: c.b === 'tl' ? 8 : 0,
              borderTopRightRadius: c.b === 'tr' ? 8 : 0,
              borderBottomLeftRadius: c.b === 'bl' ? 8 : 0,
              borderBottomRightRadius: c.b === 'br' ? 8 : 0,
            }}></div>
          ))}
          {/* status pill */}
          <div style={{
            position: 'absolute', top: 14, left: '50%', transform: 'translateX(-50%)',
            background: 'rgba(0,0,0,0.6)', border: `1px solid rgba(255,255,255,0.15)`, backdropFilter: 'blur(8px)',
            color: '#fff', padding: '6px 12px', borderRadius: 999,
            fontFamily: 'Geist Mono, monospace', fontSize: 10, textTransform: 'uppercase', letterSpacing: 1,
            display: 'flex', alignItems: 'center', gap: 6,
          }}>
            <span style={{ width: 6, height: 6, borderRadius: 3, background: t.accent }}></span>
            Befund erkannt · 8 Marker
          </div>
        </div>
      </div>

      {/* Detected values preview */}
      <div style={{ padding: '0 20px 100px' }}>
        <SectionHead theme={t} action="Bearbeiten" style={{ padding: 0, marginBottom: 10 }}>Erkannte Werte</SectionHead>
        <Card theme={t} pad={0}>
          {[
            { name: 'Vitamin D', v: '38', u: 'ng/ml', ok: true },
            { name: 'Ferritin', v: '24', u: 'µg/l', ok: true },
            { name: 'LDL', v: '128', u: 'mg/dl', ok: true },
            { name: 'TSH', v: '2,1', u: 'mU/l', ok: true },
            { name: 'Magnesium', v: '0,92', u: 'mmol/l', ok: false },
          ].map((m, i, arr) => (
            <div key={m.name} style={{ padding: '12px 14px', display: 'grid', gridTemplateColumns: '20px 1fr auto', gap: 10, alignItems: 'center', borderBottom: i === arr.length - 1 ? 'none' : `1px solid ${t.border}` }}>
              <div style={{ width: 18, height: 18, borderRadius: 5, background: m.ok ? t.accent : t.surface2, color: m.ok ? t.accentText : t.textMuted, display: 'flex', alignItems: 'center', justifyContent: 'center', border: m.ok ? 'none' : `1px solid ${t.borderStrong}` }}>{m.ok ? I.check(12) : null}</div>
              <span style={{ fontFamily: 'Geist, system-ui', fontSize: 13 }}>{m.name}</span>
              <span style={{ fontFamily: 'Geist Mono, monospace', fontSize: 14, fontWeight: 500, fontVariantNumeric: 'tabular-nums' }}>{m.v}<span style={{ color: t.textMuted, fontSize: 10, marginLeft: 2 }}>{m.u}</span></span>
            </div>
          ))}
        </Card>
      </div>

      <div style={{ position: 'absolute', bottom: 30, left: 20, right: 20 }}>
        <PrimaryButton theme={t} full>{I.check(16)} Werte speichern</PrimaryButton>
      </div>
    </Screen>
  );
}

function MethodTile({ theme, active, icon, title, sub }) {
  const t = theme;
  return (
    <button style={{
      background: active ? t.text : t.surface,
      color: active ? t.bg : t.text,
      border: active ? 'none' : `1px solid ${t.border}`,
      borderRadius: 18, padding: '14px 14px', textAlign: 'left',
      display: 'flex', flexDirection: 'column', gap: 8,
      cursor: 'pointer', fontFamily: 'Geist, system-ui',
    }}>
      <div style={{ width: 32, height: 32, borderRadius: 10, background: active ? t.accent : t.surface2, color: active ? t.accentText : t.text, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{icon}</div>
      <div>
        <div style={{ fontSize: 14, fontWeight: 600 }}>{title}</div>
        <div style={{ fontSize: 11, color: active ? 'rgba(11,11,12,0.6)' : t.textMuted, fontFamily: 'Geist Mono, monospace' }}>{sub}</div>
      </div>
    </button>
  );
}

Object.assign(window, { LabOverviewScreen, LabMarkerDetailScreen, LabAddScreen });
