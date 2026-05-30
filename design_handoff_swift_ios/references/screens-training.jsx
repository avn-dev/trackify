// Training plan, active workout, exercise detail

function TrainingPlanScreen() {
  const t = useTheme();
  const days = [
    { day: 'Tag A', focus: 'Push', exercises: 6, time: 58, color: t.accent, status: 'today' },
    { day: 'Tag B', focus: 'Pull', exercises: 6, time: 62, color: t.text, status: 'next' },
    { day: 'Tag C', focus: 'Legs', exercises: 5, time: 70, color: t.text, status: 'planned' },
    { day: 'Tag D', focus: 'Upper', exercises: 7, time: 65, color: t.text, status: 'planned' },
  ];
  return (
    <Screen theme={t}>
      <ScreenHeader theme={t} eyebrow="Plan · 4-Tage Split" title="Training" action={
        <CircleBtn theme={t}>{I.search(18)}</CircleBtn>
      }/>

      {/* Tab pills */}
      <div style={{ padding: '0 20px 16px', display: 'flex', gap: 8 }}>
        {['Mein Plan', 'Vorlagen', 'Verlauf'].map((p, i) => (
          <div key={p} style={{
            padding: '8px 14px', borderRadius: 999,
            background: i === 0 ? t.text : 'transparent',
            color: i === 0 ? t.bg : t.textMid,
            border: i === 0 ? 'none' : `1px solid ${t.border}`,
            fontFamily: 'Geist, system-ui', fontSize: 13, fontWeight: 500,
          }}>{p}</div>
        ))}
      </div>

      <div style={{ padding: '0 20px 100px', display: 'flex', flexDirection: 'column', gap: 10 }}>
        {days.map((d, i) => (
          <div key={d.day} style={{
            background: d.status === 'today' ? t.text : t.surface,
            color: d.status === 'today' ? t.bg : t.text,
            borderRadius: 22, padding: 18, border: `1px solid ${d.status === 'today' ? 'transparent' : t.border}`,
            position: 'relative',
          }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
              <div>
                <div style={{ fontSize: 11, fontFamily: 'Geist Mono, monospace', textTransform: 'uppercase', letterSpacing: 1, opacity: 0.6 }}>{d.day}</div>
                <div style={{ fontFamily: 'Geist, system-ui', fontSize: 24, fontWeight: 600, letterSpacing: -0.6, marginTop: 4 }}>{d.focus}</div>
                <div style={{ display: 'flex', gap: 12, marginTop: 10, fontFamily: 'Geist Mono, monospace', fontSize: 12, opacity: 0.65 }}>
                  <span>{d.exercises} Übungen</span><span>·</span><span>~{d.time} min</span>
                </div>
              </div>
              <div style={{
                fontSize: 10, padding: '4px 8px', borderRadius: 6, letterSpacing: 0.8, fontFamily: 'Geist Mono, monospace',
                background: d.status === 'today' ? t.accent : 'transparent',
                color: d.status === 'today' ? t.accentText : t.textMid,
                border: d.status === 'today' ? 'none' : `1px solid ${t.border}`,
                textTransform: 'uppercase', fontWeight: 600,
              }}>{d.status === 'today' ? 'Heute' : d.status === 'next' ? 'Morgen' : '—'}</div>
            </div>
            {d.status === 'today' && (
              <div style={{ marginTop: 16, display: 'flex', gap: 8 }}>
                <button style={{ flex: 1, background: t.accent, color: t.accentText, border: 'none', borderRadius: 12, height: 40, fontFamily: 'Geist, system-ui', fontSize: 13, fontWeight: 600, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6 }}>{I.play(12)} Starten</button>
                <button style={{ background: t.bg, border: `1px solid ${t.borderStrong}`, borderRadius: 12, height: 40, padding: '0 14px', color: t.text, fontFamily: 'Geist, system-ui', fontSize: 13 }}>Vorschau</button>
              </div>
            )}
          </div>
        ))}

        {/* Free workout */}
        <button style={{
          marginTop: 8, background: 'transparent', border: `1.5px dashed ${t.borderStrong}`,
          borderRadius: 22, padding: 18, color: t.text, textAlign: 'left',
          fontFamily: 'Geist, system-ui', display: 'flex', alignItems: 'center', gap: 14,
        }}>
          <div style={{ width: 40, height: 40, borderRadius: 12, background: t.surface, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{I.plus(20)}</div>
          <div>
            <div style={{ fontSize: 15, fontWeight: 600 }}>Freies Workout</div>
            <div style={{ fontSize: 12, color: t.textMuted, fontFamily: 'Geist Mono, monospace' }}>Übungen frei wählen</div>
          </div>
        </button>
      </div>

      <TabBar active="train" theme={t}/>
    </Screen>
  );
}


function ActiveWorkoutScreen() {
  const t = useTheme();
  return (
    <Screen theme={t}>
      {/* live header */}
      <div style={{ padding: '54px 20px 12px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{ width: 8, height: 8, borderRadius: 4, background: t.accent }}></div>
          <span style={{ fontFamily: 'Geist Mono, monospace', fontSize: 12, color: t.textMid, textTransform: 'uppercase', letterSpacing: 1 }}>LIVE · Tag A</span>
        </div>
        <button style={{ background: 'transparent', border: 'none', color: t.danger, fontFamily: 'Geist, system-ui', fontSize: 13, fontWeight: 500 }}>Beenden</button>
      </div>

      {/* Big clock */}
      <div style={{ padding: '4px 20px 12px', display: 'flex', alignItems: 'baseline', justifyContent: 'space-between' }}>
        <div style={{ fontFamily: 'Geist Mono, monospace', fontSize: 52, fontWeight: 500, letterSpacing: -2, fontVariantNumeric: 'tabular-nums' }}>
          32:14
        </div>
        <div style={{ textAlign: 'right' }}>
          <div style={{ fontSize: 11, color: t.textMuted, fontFamily: 'Geist Mono, monospace', textTransform: 'uppercase', letterSpacing: 0.6 }}>Volumen</div>
          <div style={{ fontFamily: 'Geist Mono, monospace', fontSize: 18, fontWeight: 500, marginTop: 2, fontVariantNumeric: 'tabular-nums' }}>4.820 kg</div>
        </div>
      </div>

      {/* Progress dots */}
      <div style={{ padding: '0 20px 18px', display: 'flex', gap: 4 }}>
        {[
          {s: 'd'},{s: 'd'},{s: 'd'},{s: 'a'},{s: 'a'},{s: 'a'},{s: 'a'},{s: 'p'},{s: 'p'},{s: 'p'},{s: 'p'},{s: 'p'},{s: 'p'},{s: 'p'},{s: 'p'},{s: 'p'},{s: 'p'},{s: 'p'},{s: 'p'},{s: 'p'},{s: 'p'},{s: 'p'}
        ].map((dot, i) => (
          <div key={i} style={{
            flex: 1, height: 4, borderRadius: 2,
            background: dot.s === 'd' ? t.accent : dot.s === 'a' ? t.text : t.borderStrong,
          }}></div>
        ))}
      </div>

      <div style={{ padding: '0 20px 120px', display: 'flex', flexDirection: 'column', gap: 12 }}>
        {/* Current exercise — focused */}
        <div style={{ background: t.surface, borderRadius: 22, padding: 16, border: `1.5px solid ${t.accent}` }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <div>
              <div style={{ fontSize: 10, color: t.accent, fontFamily: 'Geist Mono, monospace', letterSpacing: 1, textTransform: 'uppercase', fontWeight: 600 }}>● Aktuell · Ü 2/6</div>
              <div style={{ fontFamily: 'Geist, system-ui', fontSize: 20, fontWeight: 600, marginTop: 6, letterSpacing: -0.4 }}>Schrägbank Kurzhantel</div>
              <div style={{ fontSize: 12, color: t.textMuted, fontFamily: 'Geist Mono, monospace', marginTop: 2 }}>Brust · 4×8-10 · RIR 2</div>
            </div>
            <button style={{ background: t.surface2, border: 'none', borderRadius: 10, width: 32, height: 32, color: t.text, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{I.more(16)}</button>
          </div>

          {/* Sets */}
          <div style={{ marginTop: 14, display: 'flex', flexDirection: 'column', gap: 4 }}>
            <div style={{ display: 'grid', gridTemplateColumns: '24px 1fr 1fr 1fr 28px', gap: 8, fontSize: 10, color: t.textMuted, fontFamily: 'Geist Mono, monospace', textTransform: 'uppercase', letterSpacing: 0.8, padding: '4px 8px' }}>
              <span>Set</span><span>Kg</span><span>Wdh</span><span>RIR</span><span></span>
            </div>
            {[
              { n: 1, kg: 18, wdh: 10, rir: 3, done: true },
              { n: 2, kg: 20, wdh: 9, rir: 2, done: true },
              { n: 3, kg: 20, wdh: 8, rir: 2, done: false, active: true },
              { n: 4, kg: '—', wdh: '—', rir: '—', done: false },
            ].map(s => (
              <div key={s.n} style={{
                display: 'grid', gridTemplateColumns: '24px 1fr 1fr 1fr 28px', gap: 8,
                alignItems: 'center', padding: '10px 8px', borderRadius: 12,
                background: s.active ? t.bg : 'transparent',
                border: s.active ? `1px solid ${t.borderStrong}` : '1px solid transparent',
                fontFamily: 'Geist Mono, monospace', fontVariantNumeric: 'tabular-nums', fontSize: 14,
                color: s.done ? t.textMuted : t.text,
                textDecoration: s.done ? 'line-through' : 'none',
              }}>
                <span style={{ color: s.done ? t.accent : t.text, fontWeight: 500 }}>{s.done ? '✓' : s.n}</span>
                <span>{s.kg}</span>
                <span>{s.wdh}</span>
                <span style={{ color: s.rir === '—' ? t.textMuted : t.text }}>{s.rir}</span>
                {s.active
                  ? <span style={{ width: 24, height: 24, borderRadius: 6, background: t.accent, color: t.accentText, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{I.check(14)}</span>
                  : <span style={{ color: t.textMuted, justifySelf: 'end' }}>{I.chev(12, 'right')}</span>}
              </div>
            ))}
          </div>

          {/* Rest timer */}
          <div style={{ marginTop: 12, background: t.bg, borderRadius: 14, padding: '12px 14px', display: 'flex', alignItems: 'center', gap: 10, border: `1px solid ${t.border}` }}>
            <div style={{ width: 28, height: 28, borderRadius: 14, background: t.accent, color: t.accentText, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{I.clock(16)}</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 11, color: t.textMuted, fontFamily: 'Geist Mono, monospace', textTransform: 'uppercase', letterSpacing: 0.6 }}>Pause läuft</div>
              <div style={{ fontFamily: 'Geist Mono, monospace', fontSize: 18, fontWeight: 500, fontVariantNumeric: 'tabular-nums' }}>01:24<span style={{ color: t.textMuted, fontSize: 13 }}> / 02:00</span></div>
            </div>
            <button style={{ background: 'transparent', color: t.text, border: `1px solid ${t.borderStrong}`, borderRadius: 999, padding: '8px 14px', fontSize: 12, fontFamily: 'Geist, system-ui' }}>Skip</button>
          </div>
        </div>

        {/* Next */}
        <div style={{ background: t.surface, borderRadius: 18, padding: 14, border: `1px solid ${t.border}`, display: 'flex', alignItems: 'center', gap: 12, opacity: 0.7 }}>
          <div style={{ width: 36, height: 36, borderRadius: 10, background: t.surface2, display: 'flex', alignItems: 'center', justifyContent: 'center', color: t.text }}>{I.dumbbell(18)}</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontFamily: 'Geist, system-ui', fontSize: 14, fontWeight: 500 }}>Schulterdrücken</div>
            <div style={{ fontSize: 11, color: t.textMuted, fontFamily: 'Geist Mono, monospace' }}>Als nächstes · 4×10</div>
          </div>
          {I.chev(14, 'right')}
        </div>
      </div>

      {/* Bottom action */}
      <div style={{ position: 'absolute', bottom: 30, left: 20, right: 20, display: 'flex', gap: 10 }}>
        <button style={{ flex: 1, background: t.accent, color: t.accentText, border: 'none', borderRadius: 999, height: 56, fontFamily: 'Geist, system-ui', fontSize: 16, fontWeight: 600, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8 }}>{I.check(18)} Satz abschließen</button>
          <button style={{ width: 56, height: 56, borderRadius: 28, background: t.surface, border: `1px solid ${t.borderStrong}`, color: t.text, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{I.pause(16)}</button>
      </div>
    </Screen>
  );
}


function ExerciseDetailScreen() {
  const t = useTheme();
  return (
    <Screen theme={t}>
      <ScreenHeader theme={t} back="Übungen" eyebrow="Brust · Hauptübung" title="Schrägbank Kurzhantel"
        action={<CircleBtn theme={t}>{I.more(16)}</CircleBtn>}/>

      {/* hero placeholder */}
      <div style={{ margin: '0 20px 18px', height: 180, borderRadius: 22, background: t.surface, border: `1px solid ${t.border}`, display: 'flex', alignItems: 'center', justifyContent: 'center', flexDirection: 'column', color: t.textMuted, position: 'relative', overflow: 'hidden' }}>
        <svg style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', opacity: 0.5 }}><defs><pattern id="stripe" patternUnits="userSpaceOnUse" width="14" height="14" patternTransform="rotate(45)"><line x1="0" y1="0" x2="0" y2="14" stroke={t.border} strokeWidth="12"/></pattern></defs><rect width="100%" height="100%" fill="url(#stripe)"/></svg>
        <div style={{ position: 'relative', fontFamily: 'Geist Mono, monospace', fontSize: 11, textTransform: 'uppercase', letterSpacing: 1 }}>Demo-Video</div>
      </div>

      {/* Stat row */}
      <div style={{ padding: '0 20px', display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 10 }}>
        <Card theme={t} pad={12}>
          <Stat theme={t} label="1RM Schätz." value="42" unit="kg"/>
        </Card>
        <Card theme={t} pad={12}>
          <Stat theme={t} label="Letztes Mal" value="20" unit="× 9"/>
        </Card>
        <Card theme={t} pad={12}>
          <Stat theme={t} label="Sätze ges." value="148"/>
        </Card>
      </div>

      <div style={{ padding: '18px 20px 100px' }}>
        <SectionHead theme={t} action="4 Wochen">Fortschritt</SectionHead>
        <Card theme={t} pad={16} style={{ margin: '0 0 18px' }}>
          <LineChart theme={t} width={326} height={140} accent showAxis
            data={[
              {y: 32, label: 'KW16'},{y: 34},{y: 33},{y: 36, label: 'KW17'},{y: 38},{y: 37},{y: 40, label: 'KW18'},{y: 41, dot: true},{y: 42, label: 'KW19'}
            ]}/>
        </Card>

        <SectionHead theme={t}>Verlauf</SectionHead>
        {[
          { d: '12. Mai', sets: '4×9·8·8·7', kg: '18-20' },
          { d: '08. Mai', sets: '4×10·9·8·8', kg: '17,5' },
          { d: '05. Mai', sets: '4×10·10·9·8', kg: '17,5' },
        ].map(h => (
          <div key={h.d} style={{ background: t.surface, borderRadius: 14, padding: '14px 16px', marginBottom: 8, display: 'flex', alignItems: 'center', border: `1px solid ${t.border}` }}>
            <div style={{ flex: 1 }}>
              <div style={{ fontFamily: 'Geist, system-ui', fontSize: 14, fontWeight: 500 }}>{h.d}</div>
              <div style={{ fontSize: 11, color: t.textMuted, fontFamily: 'Geist Mono, monospace', marginTop: 2 }}>{h.sets}</div>
            </div>
            <div style={{ fontFamily: 'Geist Mono, monospace', fontSize: 14, color: t.text, fontVariantNumeric: 'tabular-nums' }}>{h.kg} kg</div>
          </div>
        ))}
      </div>
    </Screen>
  );
}

Object.assign(window, { TrainingPlanScreen, ActiveWorkoutScreen, ExerciseDetailScreen });
