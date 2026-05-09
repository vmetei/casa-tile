// Parametric tile SVG generator. Ported from build.ps1.
// Each pattern produces a deterministic SVG given the same seed.

type Pattern = 'marble' | 'wood' | 'concrete' | 'terrazzo' | 'subway' | 'hexagon' | 'stone' | 'decorative';

// Mulberry32 — small, deterministic PRNG.
function rng(seed: number) {
  let s = seed >>> 0;
  return () => {
    s = (s + 0x6D2B79F5) >>> 0;
    let t = s;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function seedFromString(s: string): number {
  let h = 0;
  for (let i = 0; i < s.length; i++) {
    h = ((h * 31) + s.charCodeAt(i)) & 0x7fffffff;
  }
  return h;
}

const r2 = (n: number) => Math.round(n * 100) / 100;
const r1 = (n: number) => Math.round(n * 10) / 10;

function svgWrap(inner: string): string {
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 600" preserveAspectRatio="xMidYMid slice">${inner}</svg>`;
}

function marble(base: string, accent: string, seed: number): string {
  const rand = rng(seed);
  const parts: string[] = [`<rect width="600" height="600" fill="${base}"/>`];
  for (let i = 0; i < 6; i++) {
    const y = 40 + Math.floor(rand() * 520);
    const sw = r1(1.0 + rand() * 3.5);
    const op = r2(0.3 + rand() * 0.4);
    const c1 = y + Math.floor(rand() * 100 - 50);
    const c2 = y + Math.floor(rand() * 100 - 50);
    const c3 = y + Math.floor(rand() * 100 - 50);
    parts.push(`<path d="M0,${y} Q150,${c1} 300,${c2} T600,${c3}" stroke="${accent}" stroke-width="${sw}" fill="none" opacity="${op}" stroke-linecap="round"/>`);
  }
  for (let i = 0; i < 4; i++) {
    const x = 50 + Math.floor(rand() * 500);
    const op = r2(0.15 + rand() * 0.25);
    parts.push(`<path d="M${x},0 Q${x + 25},200 ${x - 15},400 T${x + 5},600" stroke="${accent}" stroke-width="1" fill="none" opacity="${op}"/>`);
  }
  return svgWrap(parts.join(''));
}

function wood(base: string, accent: string, seed: number): string {
  const rand = rng(seed);
  const parts: string[] = [`<rect width="600" height="600" fill="${base}"/>`];
  let x = 0;
  while (x < 600) {
    const sw = r1(0.4 + rand() * 1.2);
    const op = r2(0.15 + rand() * 0.4);
    const j = Math.floor(rand() * 7 - 3);
    parts.push(`<path d="M${x},0 Q${x + j},300 ${x},600" stroke="${accent}" stroke-width="${sw}" fill="none" opacity="${op}"/>`);
    x += 4 + Math.floor(rand() * 8);
  }
  for (let i = 0; i < 2; i++) {
    const cx = 100 + Math.floor(rand() * 400);
    const cy = 100 + Math.floor(rand() * 400);
    const rx = 8 + Math.floor(rand() * 14);
    const ry = 14 + Math.floor(rand() * 22);
    parts.push(`<ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="${ry}" fill="${accent}" opacity="0.25"/>`);
    parts.push(`<ellipse cx="${cx}" cy="${cy}" rx="${rx - 3}" ry="${ry - 4}" fill="none" stroke="${accent}" stroke-width="0.8" opacity="0.4"/>`);
  }
  return svgWrap(parts.join(''));
}

function concrete(base: string, accent: string, seed: number): string {
  const rand = rng(seed);
  const parts: string[] = [`<rect width="600" height="600" fill="${base}"/>`];
  for (let i = 0; i < 350; i++) {
    const cx = Math.floor(rand() * 600);
    const cy = Math.floor(rand() * 600);
    const r = r1(0.5 + rand() * 2.5);
    const op = r2(0.05 + rand() * 0.25);
    parts.push(`<circle cx="${cx}" cy="${cy}" r="${r}" fill="${accent}" opacity="${op}"/>`);
  }
  for (let i = 0; i < 6; i++) {
    const cx = Math.floor(rand() * 600);
    const cy = Math.floor(rand() * 600);
    const r = 60 + Math.floor(rand() * 80);
    parts.push(`<circle cx="${cx}" cy="${cy}" r="${r}" fill="${accent}" opacity="0.05"/>`);
  }
  return svgWrap(parts.join(''));
}

function terrazzo(base: string, accent: string, seed: number): string {
  const rand = rng(seed);
  const palette = [accent, '#d8d0c0', '#a09080', '#705b48', '#e8d8c0'];
  const parts: string[] = [`<rect width="600" height="600" fill="${base}"/>`];
  for (let i = 0; i < 90; i++) {
    const cx = Math.floor(rand() * 600);
    const cy = Math.floor(rand() * 600);
    const size = 6 + Math.floor(rand() * 22);
    const color = palette[Math.floor(rand() * palette.length)];
    const op = r2(0.5 + rand() * 0.4);
    const sides = 5 + Math.floor(rand() * 3);
    const pts: string[] = [];
    for (let j = 0; j < sides; j++) {
      const a = (j / sides) * 2 * Math.PI + rand() * 0.6;
      const rad = size * (0.7 + rand() * 0.5);
      pts.push(`${r1(cx + Math.cos(a) * rad)},${r1(cy + Math.sin(a) * rad)}`);
    }
    parts.push(`<polygon points="${pts.join(' ')}" fill="${color}" opacity="${op}"/>`);
  }
  return svgWrap(parts.join(''));
}

function subway(base: string, accent: string, _seed: number): string {
  const parts: string[] = [`<rect width="600" height="600" fill="#ddd"/>`];
  const tw = 150, th = 75, g = 6;
  let row = 0;
  for (let y = 0; y < 600; y += th + g) {
    const offset = row % 2 === 1 ? -Math.floor(tw / 2) : 0;
    for (let x = offset; x < 600; x += tw + g) {
      parts.push(`<rect x="${x}" y="${y}" width="${tw}" height="${th}" fill="${base}" rx="2"/>`);
      parts.push(`<rect x="${x}" y="${y}" width="${tw}" height="6" fill="#fff" opacity="0.18"/>`);
      parts.push(`<rect x="${x}" y="${y + th - 4}" width="${tw}" height="4" fill="${accent}" opacity="0.18"/>`);
    }
    row++;
  }
  return svgWrap(parts.join(''));
}

function hexagon(base: string, accent: string, _seed: number): string {
  const parts: string[] = [`<rect width="600" height="600" fill="#ececec"/>`];
  const r = 55;
  const hexW = r * 2;
  const hexH = Math.sqrt(3) * r;
  let row = 0;
  for (let cy = 0; cy < 700; cy += hexH) {
    const xOffset = row % 2 === 1 ? r * 1.5 : 0;
    for (let cx = xOffset; cx < 700; cx += hexW * 1.5) {
      const pts: string[] = [];
      for (let i = 0; i < 6; i++) {
        const a = (i * Math.PI) / 3;
        pts.push(`${r1(cx + Math.cos(a) * (r - 3))},${r1(cy + Math.sin(a) * (r - 3))}`);
      }
      parts.push(`<polygon points="${pts.join(' ')}" fill="${base}" stroke="${accent}" stroke-width="1" opacity="0.95"/>`);
    }
    row++;
  }
  return svgWrap(parts.join(''));
}

function stone(base: string, accent: string, seed: number): string {
  const rand = rng(seed);
  const parts: string[] = [`<rect width="600" height="600" fill="${base}"/>`];
  for (let i = 0; i < 25; i++) {
    const cx = Math.floor(rand() * 600);
    const cy = Math.floor(rand() * 600);
    const r = 30 + Math.floor(rand() * 90);
    const op = r2(0.05 + rand() * 0.25);
    parts.push(`<circle cx="${cx}" cy="${cy}" r="${r}" fill="${accent}" opacity="${op}"/>`);
  }
  for (let i = 0; i < 10; i++) {
    const x1 = Math.floor(rand() * 600);
    const y1 = Math.floor(rand() * 600);
    const x2 = x1 + Math.floor(rand() * 300 - 150);
    const y2 = y1 + Math.floor(rand() * 300 - 150);
    parts.push(`<line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" stroke="${accent}" stroke-width="0.7" opacity="0.3"/>`);
  }
  for (let i = 0; i < 200; i++) {
    parts.push(`<circle cx="${Math.floor(rand() * 600)}" cy="${Math.floor(rand() * 600)}" r="1" fill="${accent}" opacity="0.2"/>`);
  }
  return svgWrap(parts.join(''));
}

function decorative(base: string, accent: string, _seed: number): string {
  const parts: string[] = [`<rect width="600" height="600" fill="${base}"/>`];
  const cell = 100;
  for (let r = 0; r < 6; r++) {
    for (let c = 0; c < 6; c++) {
      const cx = c * cell + cell / 2;
      const cy = r * cell + cell / 2;
      const variant = (r + c) % 3;
      if (variant === 0) {
        parts.push(`<g transform="translate(${cx},${cy})">`);
        for (let i = 0; i < 4; i++) {
          parts.push(`<ellipse cx="0" cy="-22" rx="14" ry="28" fill="${accent}" opacity="0.85" transform="rotate(${i * 90})"/>`);
        }
        parts.push(`<circle cx="0" cy="0" r="8" fill="${base}"/></g>`);
      } else if (variant === 1) {
        const half = 35;
        parts.push(`<polygon points="${cx},${cy - half} ${cx + half},${cy} ${cx},${cy + half} ${cx - half},${cy}" fill="none" stroke="${accent}" stroke-width="3"/>`);
        parts.push(`<circle cx="${cx}" cy="${cy}" r="10" fill="${accent}"/>`);
      } else {
        parts.push(`<g transform="translate(${cx},${cy})">`);
        parts.push(`<rect x="-30" y="-30" width="60" height="60" fill="none" stroke="${accent}" stroke-width="2"/>`);
        parts.push(`<rect x="-30" y="-30" width="60" height="60" fill="none" stroke="${accent}" stroke-width="2" transform="rotate(45)"/>`);
        parts.push(`<circle cx="0" cy="0" r="6" fill="${accent}"/></g>`);
      }
    }
  }
  for (let i = 0; i <= 6; i++) {
    const p = i * cell;
    parts.push(`<line x1="0" y1="${p}" x2="600" y2="${p}" stroke="#000" stroke-width="0.4" opacity="0.1"/>`);
    parts.push(`<line x1="${p}" y1="0" x2="${p}" y2="600" stroke="#000" stroke-width="0.4" opacity="0.1"/>`);
  }
  return svgWrap(parts.join(''));
}

const generators: Record<Pattern, (b: string, a: string, s: number) => string> = {
  marble, wood, concrete, terrazzo, subway, hexagon, stone, decorative,
};

export function tileSvg(pattern: Pattern, baseColor: string, accentColor: string, slug: string): string {
  const seed = seedFromString(slug);
  return generators[pattern](baseColor, accentColor, seed);
}

// Build a data: URL — used inline as <img src="..."> without writing files.
export function tileSvgDataUrl(pattern: Pattern, baseColor: string, accentColor: string, slug: string): string {
  const svg = tileSvg(pattern, baseColor, accentColor, slug);
  return `data:image/svg+xml;utf8,${encodeURIComponent(svg)}`;
}
