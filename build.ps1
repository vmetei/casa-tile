# build.ps1 - Generates Casa Tile static site from data/products.json + data/i18n.json
# Outputs: SVG images, all HTML pages (RO + EN), sitemap.xml, robots.txt
param(
  [string]$SiteUrl = 'https://casatile.example'
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

$products = Get-Content "$root\data\products.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$i18n     = Get-Content "$root\data\i18n.json"     -Raw -Encoding UTF8 | ConvertFrom-Json

$site = $products.site
$collections = $products.collections
$roomDefs = $products.filters.rooms
$finishDefs = $products.filters.finishes
$materialDefs = $products.filters.materials
$prods = $products.products

# Derive list of unique colors and sizes from products
$colorIds = $prods.color | Select-Object -Unique | Sort-Object
$sizeIds  = $prods.size  | Select-Object -Unique
# Sort sizes by area (small to large)
$sizeIds = $sizeIds | Sort-Object @{ Expression = {
  $parts = $_ -split 'x'
  [double]$parts[0] * [double]$parts[1]
}}

$colorPalette = @{
  'white'       = '#ffffff'
  'cream'       = '#f4ead4'
  'beige'       = '#d4c4a0'
  'sand'        = '#cdbfa1'
  'grey'        = '#9c9a96'
  'anthracite'  = '#3d3f42'
  'black'       = '#1f1f23'
  'brown'       = '#7a4f2a'
  'terracotta'  = '#c47550'
  'blue'        = '#3a7aa8'
  'green'       = '#3d6b54'
}
$colorNames = @{
  ro = @{
    'white'='Alb'; 'cream'='Crem'; 'beige'='Bej'; 'sand'='Nisip'; 'grey'='Gri';
    'anthracite'='Antracit'; 'black'='Negru'; 'brown'='Maro'; 'terracotta'='Teracotă';
    'blue'='Albastru'; 'green'='Verde';
  }
  en = @{
    'white'='White'; 'cream'='Cream'; 'beige'='Beige'; 'sand'='Sand'; 'grey'='Grey';
    'anthracite'='Anthracite'; 'black'='Black'; 'brown'='Brown'; 'terracotta'='Terracotta';
    'blue'='Blue'; 'green'='Green';
  }
}

# ------------- HTML helpers -------------
function HE([string]$s) {
  if ($null -eq $s) { return '' }
  return $s.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;')
}
function Stable-Seed($s) {
  $h = 0
  foreach ($c in $s.ToCharArray()) { $h = (($h * 31) + [int]$c) -band 0x7fffffff }
  return $h
}
function Get-Coll($id) { $collections | Where-Object { $_.id -eq $id } | Select-Object -First 1 }

# ------------- SVG generators -------------
function New-MarbleSvg($base, $accent, $seed) {
  $rng = [System.Random]::new($seed)
  $sb = [System.Text.StringBuilder]::new()
  [void]$sb.Append("<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 600 600' preserveAspectRatio='xMidYMid slice'>")
  [void]$sb.Append("<rect width='600' height='600' fill='$base'/>")
  for ($i = 0; $i -lt 6; $i++) {
    $y = $rng.Next(40, 560)
    $sw = [Math]::Round((1.0 + $rng.NextDouble() * 3.5), 1)
    $op = [Math]::Round((0.3 + $rng.NextDouble() * 0.4), 2)
    $cy1 = $y + $rng.Next(-50, 50)
    $cy2 = $y + $rng.Next(-50, 50)
    $cy3 = $y + $rng.Next(-50, 50)
    [void]$sb.Append("<path d='M0,$y Q150,$cy1 300,$cy2 T600,$cy3' stroke='$accent' stroke-width='$sw' fill='none' opacity='$op' stroke-linecap='round'/>")
  }
  for ($i = 0; $i -lt 4; $i++) {
    $x = $rng.Next(50, 550)
    $op = [Math]::Round((0.15 + $rng.NextDouble() * 0.25), 2)
    [void]$sb.Append("<path d='M$x,0 Q$($x+25),200 $($x-15),400 T$($x+5),600' stroke='$accent' stroke-width='1' fill='none' opacity='$op'/>")
  }
  [void]$sb.Append("</svg>")
  return $sb.ToString()
}

function New-WoodSvg($base, $accent, $seed) {
  $rng = [System.Random]::new($seed)
  $sb = [System.Text.StringBuilder]::new()
  [void]$sb.Append("<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 600 600' preserveAspectRatio='xMidYMid slice'>")
  [void]$sb.Append("<rect width='600' height='600' fill='$base'/>")
  $x = 0
  while ($x -lt 600) {
    $sw = [Math]::Round((0.4 + $rng.NextDouble() * 1.2), 1)
    $op = [Math]::Round((0.15 + $rng.NextDouble() * 0.4), 2)
    $jitter = $rng.Next(-3, 4)
    [void]$sb.Append("<path d='M$x,0 Q$($x+$jitter),300 $x,600' stroke='$accent' stroke-width='$sw' fill='none' opacity='$op'/>")
    $x += 4 + $rng.Next(0, 8)
  }
  # A couple of knots
  for ($i = 0; $i -lt 2; $i++) {
    $cx = $rng.Next(100, 500); $cy = $rng.Next(100, 500)
    $rx = 8 + $rng.Next(0, 14); $ry = 14 + $rng.Next(0, 22)
    [void]$sb.Append("<ellipse cx='$cx' cy='$cy' rx='$rx' ry='$ry' fill='$accent' opacity='0.25'/>")
    [void]$sb.Append("<ellipse cx='$cx' cy='$cy' rx='$($rx-3)' ry='$($ry-4)' fill='none' stroke='$accent' stroke-width='0.8' opacity='0.4'/>")
  }
  [void]$sb.Append("</svg>")
  return $sb.ToString()
}

function New-ConcreteSvg($base, $accent, $seed) {
  $rng = [System.Random]::new($seed)
  $sb = [System.Text.StringBuilder]::new()
  [void]$sb.Append("<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 600 600' preserveAspectRatio='xMidYMid slice'>")
  [void]$sb.Append("<rect width='600' height='600' fill='$base'/>")
  for ($i = 0; $i -lt 350; $i++) {
    $cx = $rng.Next(0, 600); $cy = $rng.Next(0, 600)
    $r = [Math]::Round((0.5 + $rng.NextDouble() * 2.5), 1)
    $op = [Math]::Round((0.05 + $rng.NextDouble() * 0.25), 2)
    [void]$sb.Append("<circle cx='$cx' cy='$cy' r='$r' fill='$accent' opacity='$op'/>")
  }
  # Subtle large blotches
  for ($i = 0; $i -lt 6; $i++) {
    $cx = $rng.Next(0, 600); $cy = $rng.Next(0, 600)
    $r = $rng.Next(60, 140)
    [void]$sb.Append("<circle cx='$cx' cy='$cy' r='$r' fill='$accent' opacity='0.05'/>")
  }
  [void]$sb.Append("</svg>")
  return $sb.ToString()
}

function New-TerrazzoSvg($base, $accent, $seed) {
  $rng = [System.Random]::new($seed)
  $palette = @($accent, '#d8d0c0', '#a09080', '#705b48', '#e8d8c0')
  $sb = [System.Text.StringBuilder]::new()
  [void]$sb.Append("<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 600 600' preserveAspectRatio='xMidYMid slice'>")
  [void]$sb.Append("<rect width='600' height='600' fill='$base'/>")
  for ($i = 0; $i -lt 90; $i++) {
    $cx = $rng.Next(0, 600); $cy = $rng.Next(0, 600)
    $size = 6 + $rng.Next(0, 22)
    $color = $palette[$rng.Next(0, $palette.Count)]
    $op = [Math]::Round((0.5 + $rng.NextDouble() * 0.4), 2)
    # irregular polygon (5-7 points)
    $sides = 5 + $rng.Next(0, 3)
    $pts = @()
    for ($j = 0; $j -lt $sides; $j++) {
      $a = ($j / $sides) * 2 * [Math]::PI + ($rng.NextDouble() * 0.6)
      $rad = $size * (0.7 + $rng.NextDouble() * 0.5)
      $px = [Math]::Round($cx + [Math]::Cos($a) * $rad, 1)
      $py = [Math]::Round($cy + [Math]::Sin($a) * $rad, 1)
      $pts += "$px,$py"
    }
    [void]$sb.Append("<polygon points='$($pts -join ' ')' fill='$color' opacity='$op'/>")
  }
  [void]$sb.Append("</svg>")
  return $sb.ToString()
}

function New-SubwaySvg($base, $accent, $seed) {
  $sb = [System.Text.StringBuilder]::new()
  [void]$sb.Append("<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 600 600' preserveAspectRatio='xMidYMid slice'>")
  [void]$sb.Append("<rect width='600' height='600' fill='#ddd'/>")
  $tw = 150; $th = 75; $g = 6
  $row = 0
  for ($y = 0; $y -lt 600; $y += ($th + $g)) {
    $offset = if ($row % 2 -eq 1) { -[int]($tw / 2) } else { 0 }
    for ($x = $offset; $x -lt 600; $x += ($tw + $g)) {
      [void]$sb.Append("<rect x='$x' y='$y' width='$tw' height='$th' fill='$base' rx='2'/>")
      # subtle highlight
      [void]$sb.Append("<rect x='$x' y='$y' width='$tw' height='6' fill='#fff' opacity='0.18'/>")
      [void]$sb.Append("<rect x='$x' y='$($y+$th-4)' width='$tw' height='4' fill='$accent' opacity='0.18'/>")
    }
    $row++
  }
  [void]$sb.Append("</svg>")
  return $sb.ToString()
}

function New-HexagonSvg($base, $accent, $seed) {
  $sb = [System.Text.StringBuilder]::new()
  [void]$sb.Append("<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 600 600' preserveAspectRatio='xMidYMid slice'>")
  [void]$sb.Append("<rect width='600' height='600' fill='#ececec'/>")
  $r = 55
  $hexW = $r * 2
  $hexH = [Math]::Sqrt(3) * $r
  $row = 0
  for ($cy = 0; $cy -lt 700; $cy += $hexH) {
    $xOffset = if ($row % 2 -eq 1) { $r * 1.5 } else { 0 }
    for ($cx = $xOffset; $cx -lt 700; $cx += $hexW * 1.5) {
      $pts = @()
      for ($i = 0; $i -lt 6; $i++) {
        $a = $i * [Math]::PI / 3
        $x = [Math]::Round($cx + [Math]::Cos($a) * ($r - 3), 1)
        $y = [Math]::Round($cy + [Math]::Sin($a) * ($r - 3), 1)
        $pts += "$x,$y"
      }
      [void]$sb.Append("<polygon points='$($pts -join ' ')' fill='$base' stroke='$accent' stroke-width='1' opacity='0.95'/>")
    }
    $row++
  }
  [void]$sb.Append("</svg>")
  return $sb.ToString()
}

function New-StoneSvg($base, $accent, $seed) {
  $rng = [System.Random]::new($seed)
  $sb = [System.Text.StringBuilder]::new()
  [void]$sb.Append("<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 600 600' preserveAspectRatio='xMidYMid slice'>")
  [void]$sb.Append("<rect width='600' height='600' fill='$base'/>")
  # Add weathered patches
  for ($i = 0; $i -lt 25; $i++) {
    $cx = $rng.Next(0, 600); $cy = $rng.Next(0, 600)
    $r = 30 + $rng.Next(0, 90)
    $op = [Math]::Round((0.05 + $rng.NextDouble() * 0.25), 2)
    [void]$sb.Append("<circle cx='$cx' cy='$cy' r='$r' fill='$accent' opacity='$op'/>")
  }
  # Cracks/fissures
  for ($i = 0; $i -lt 10; $i++) {
    $x1 = $rng.Next(0, 600); $y1 = $rng.Next(0, 600)
    $x2 = $x1 + $rng.Next(-150, 150)
    $y2 = $y1 + $rng.Next(-150, 150)
    [void]$sb.Append("<line x1='$x1' y1='$y1' x2='$x2' y2='$y2' stroke='$accent' stroke-width='0.7' opacity='0.3'/>")
  }
  # Speckle
  for ($i = 0; $i -lt 200; $i++) {
    $cx = $rng.Next(0, 600); $cy = $rng.Next(0, 600)
    [void]$sb.Append("<circle cx='$cx' cy='$cy' r='1' fill='$accent' opacity='0.2'/>")
  }
  [void]$sb.Append("</svg>")
  return $sb.ToString()
}

function New-DecorativeSvg($base, $accent, $seed) {
  $sb = [System.Text.StringBuilder]::new()
  [void]$sb.Append("<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 600 600' preserveAspectRatio='xMidYMid slice'>")
  [void]$sb.Append("<rect width='600' height='600' fill='$base'/>")
  # 6x6 grid of motifs, alternating pattern
  $cell = 100
  for ($r = 0; $r -lt 6; $r++) {
    for ($c = 0; $c -lt 6; $c++) {
      $cx = $c * $cell + $cell / 2
      $cy = $r * $cell + $cell / 2
      $variant = ($r + $c) % 3
      if ($variant -eq 0) {
        # 4-petal rosette
        [void]$sb.Append("<g transform='translate($cx,$cy)'>")
        for ($i = 0; $i -lt 4; $i++) {
          $rot = $i * 90
          [void]$sb.Append("<ellipse cx='0' cy='-22' rx='14' ry='28' fill='$accent' opacity='0.85' transform='rotate($rot)'/>")
        }
        [void]$sb.Append("<circle cx='0' cy='0' r='8' fill='$base'/>")
        [void]$sb.Append("</g>")
      } elseif ($variant -eq 1) {
        # diamond
        $half = 35
        [void]$sb.Append("<polygon points='$cx,$($cy-$half) $($cx+$half),$cy $cx,$($cy+$half) $($cx-$half),$cy' fill='none' stroke='$accent' stroke-width='3'/>")
        [void]$sb.Append("<circle cx='$cx' cy='$cy' r='10' fill='$accent'/>")
      } else {
        # 8-pointed star (octagram by 2 squares)
        [void]$sb.Append("<g transform='translate($cx,$cy)'>")
        [void]$sb.Append("<rect x='-30' y='-30' width='60' height='60' fill='none' stroke='$accent' stroke-width='2' transform='rotate(0)'/>")
        [void]$sb.Append("<rect x='-30' y='-30' width='60' height='60' fill='none' stroke='$accent' stroke-width='2' transform='rotate(45)'/>")
        [void]$sb.Append("<circle cx='0' cy='0' r='6' fill='$accent'/>")
        [void]$sb.Append("</g>")
      }
    }
  }
  # grout grid
  for ($i = 0; $i -le 6; $i++) {
    $p = $i * $cell
    [void]$sb.Append("<line x1='0' y1='$p' x2='600' y2='$p' stroke='#000' stroke-width='0.4' opacity='0.1'/>")
    [void]$sb.Append("<line x1='$p' y1='0' x2='$p' y2='600' stroke='#000' stroke-width='0.4' opacity='0.1'/>")
  }
  [void]$sb.Append("</svg>")
  return $sb.ToString()
}

function New-TileSvg($p) {
  $seed = Stable-Seed $p.slug
  switch ($p.pattern) {
    'marble'     { New-MarbleSvg     $p.baseColor $p.accentColor $seed; break }
    'wood'       { New-WoodSvg       $p.baseColor $p.accentColor $seed; break }
    'concrete'   { New-ConcreteSvg   $p.baseColor $p.accentColor $seed; break }
    'terrazzo'   { New-TerrazzoSvg   $p.baseColor $p.accentColor $seed; break }
    'subway'     { New-SubwaySvg     $p.baseColor $p.accentColor $seed; break }
    'hexagon'    { New-HexagonSvg    $p.baseColor $p.accentColor $seed; break }
    'stone'      { New-StoneSvg      $p.baseColor $p.accentColor $seed; break }
    'decorative' { New-DecorativeSvg $p.baseColor $p.accentColor $seed; break }
    default      { New-ConcreteSvg   $p.baseColor $p.accentColor $seed; break }
  }
}

# ------------- Description generator -------------
function Get-Description($p, $locale) {
  $coll = (Get-Coll $p.collection).name.$locale
  $color = $colorNames[$locale][$p.color]
  $finish = (($finishDefs | Where-Object { $_.id -eq $p.finish }).name.$locale).ToLower()
  $material = (($materialDefs | Where-Object { $_.id -eq $p.material }).name.$locale).ToLower()
  $size = $p.size

  if ($locale -eq 'ro') {
    $rooms = ($p.rooms | ForEach-Object { (($roomDefs | Where-Object { $_.id -eq $_2 }).name.ro) })
    $rooms = ($p.rooms | ForEach-Object { $rid = $_; ($roomDefs | Where-Object { $_.id -eq $rid }).name.ro.ToLower() }) -join ', '
    return "Plăcile $($p.name.ro) din colecția $coll oferă un design rafinat în nuanță $($color.ToLower()), finisaj $finish și format $size cm. Realizate din $material de calitate europeană, sunt potrivite pentru: $rooms. Combinație perfectă între eleganță și durabilitate, ideale pentru spații moderne sau clasice."
  } else {
    $rooms = ($p.rooms | ForEach-Object { $rid = $_; ($roomDefs | Where-Object { $_.id -eq $rid }).name.en.ToLower() }) -join ', '
    return "$($p.name.en) tiles from the $coll collection offer a refined design in $($color.ToLower()) tones, $finish finish and $size cm format. Made from European-grade $material, they are suitable for: $rooms. A perfect blend of elegance and durability, ideal for both modern and classic spaces."
  }
}

# ------------- Layout helpers -------------
function Render-Header($locale, $currentPage, $altLocaleHref) {
  $t = $i18n.$locale
  $base = if ($locale -eq 'ro') { '' } else { '/en' }
  $homeUrl = if ($locale -eq 'ro') { '/' } else { '/en/' }
  $catalog = "$base/catalog.html"
  $about = "$base/about.html"
  $contact = "$base/contact.html"
  $altLabel = HE $t.switchTo
@"
<header class="site-header" role="banner">
  <div class="container header-row">
    <a href="$homeUrl" class="brand" aria-label="Casa Tile">Casa<span>Tile</span></a>
    <nav class="nav" aria-label="$($t.nav.home)">
      <ul>
        <li><a href="$homeUrl" data-nav-link>$($t.nav.home)</a></li>
        <li><a href="$catalog" data-nav-link>$($t.nav.catalog)</a></li>
        <li><a href="$about" data-nav-link>$($t.nav.about)</a></li>
        <li><a href="$contact" data-nav-link>$($t.nav.contact)</a></li>
      </ul>
    </nav>
    <div class="header-actions">
      <button class="lang-switch" data-lang-switch data-target="$altLocaleHref" aria-label="$altLabel">$altLabel</button>
      <button class="menu-toggle btn-ghost" data-menu-toggle aria-label="Menu" aria-expanded="false" aria-controls="mobile-menu">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 6h18M3 12h18M3 18h18"/></svg>
      </button>
    </div>
  </div>
  <div class="mobile-menu" id="mobile-menu" data-mobile-menu data-open="false">
    <ul>
      <li><a href="$homeUrl">$($t.nav.home)</a></li>
      <li><a href="$catalog">$($t.nav.catalog)</a></li>
      <li><a href="$about">$($t.nav.about)</a></li>
      <li><a href="$contact">$($t.nav.contact)</a></li>
    </ul>
  </div>
</header>
"@
}

function Render-Footer($locale) {
  $t = $i18n.$locale
  $base = if ($locale -eq 'ro') { '' } else { '/en' }
  $year = (Get-Date).Year
@"
<footer class="site-footer" role="contentinfo">
  <div class="container">
    <div class="footer-grid">
      <div>
        <div class="brand mb-2">Casa<span>Tile</span></div>
        <p class="text-muted">$(HE $t.footer.description)</p>
      </div>
      <div>
        <h4>$(HE $t.footer.quickLinks)</h4>
        <ul>
          <li><a href="$base/">$(HE $t.nav.home)</a></li>
          <li><a href="$base/catalog.html">$(HE $t.nav.catalog)</a></li>
          <li><a href="$base/about.html">$(HE $t.nav.about)</a></li>
          <li><a href="$base/contact.html">$(HE $t.nav.contact)</a></li>
        </ul>
      </div>
      <div>
        <h4>$(HE $t.footer.contact)</h4>
        <ul>
          <li class="text-muted">$(HE $site.address.$locale)</li>
          <li><a href="tel:$($site.phone -replace '[^\d+]','')">$(HE $site.phone)</a></li>
          <li><a href="mailto:$($site.email)">$(HE $site.email)</a></li>
        </ul>
      </div>
    </div>
    <div class="footer-bottom">
      <span>&copy; $year Casa Tile. $(HE $t.footer.rights)</span>
      <span>$(HE $t.footer.privacy) · $(HE $t.footer.terms)</span>
    </div>
  </div>
</footer>
"@
}

function Render-LayoutHead($locale, $title, $description, $canonical, $altLocaleHref, $extraSchemaJson) {
  $altHrefRoot = if ($locale -eq 'ro') { 'en' } else { 'ro' }
  $hreflangSelf = $locale
  $titleHE = HE $title
  $descHE = HE $description

  $schema = ''
  if ($extraSchemaJson) { $schema = "<script type=`"application/ld+json`">$extraSchemaJson</script>" }

@"
<!doctype html>
<html lang="$locale">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="theme-color" content="#1f1d1a">
<title>$titleHE</title>
<meta name="description" content="$descHE">
<link rel="canonical" href="$canonical">
<link rel="alternate" hreflang="$hreflangSelf" href="$canonical">
<link rel="alternate" hreflang="$altHrefRoot" href="$altLocaleHref">
<link rel="alternate" hreflang="x-default" href="$canonical">
<meta property="og:type" content="website">
<meta property="og:title" content="$titleHE">
<meta property="og:description" content="$descHE">
<meta property="og:url" content="$canonical">
<meta property="og:locale" content="$($locale)_$( if ($locale -eq 'ro') { 'RO' } else { 'US' } )">
<meta property="og:site_name" content="Casa Tile">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="$titleHE">
<meta name="twitter:description" content="$descHE">
<link rel="stylesheet" href="/assets/css/styles.css">
<link rel="icon" type="image/svg+xml" href="/assets/images/favicon.svg">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:wght@500;600;700&display=swap">
$schema
</head>
<body>
<a href="#main" class="skip-link">$(HE $i18n.$locale.common.skipToContent)</a>
"@
}

function Render-LayoutFoot($locale, $extraScripts) {
@"
<script src="/assets/js/main.js" defer></script>
$extraScripts
</body>
</html>
"@
}

function Format-Price($n, $locale) {
  $ci = if ($locale -eq 'ro') { 'ro-RO' } else { 'en-US' }
  return ([string][int]$n)
}

# ------------- Product card -------------
function Render-ProductCard($p, $locale, $order) {
  $base = if ($locale -eq 'ro') { '' } else { '/en' }
  $coll = Get-Coll $p.collection
  $name = HE $p.name.$locale
  $collName = HE $coll.name.$locale
  $href = "$base/pages/$($p.slug).html"
  $price = Format-Price $p.price $locale
  $perSqm = HE $i18n.$locale.catalog.perSqm
  $stockLabel = if ($p.stock) { HE $i18n.$locale.catalog.inStock } else { HE $i18n.$locale.catalog.outOfStock }
  $stockClass = if ($p.stock) { 'badge-success' } else { 'badge-danger' }
  $rooms = ($p.rooms -join ',')
  $featured = if ($p.featured) { 'true' } else { 'false' }
  $stock = if ($p.stock) { 'true' } else { 'false' }
  $img = HE "/assets/images/products/$($p.slug).svg"
  $altImg = HE "$($p.name.$locale) - $($coll.name.$locale)"
@"
<article class="product-card"
  data-collection="$($p.collection)"
  data-color="$($p.color)"
  data-size="$($p.size)"
  data-finish="$($p.finish)"
  data-material="$($p.material)"
  data-rooms="$rooms"
  data-price="$($p.price)"
  data-name="$name"
  data-stock="$stock"
  data-featured="$featured"
  data-order="$order">
  <a href="$href" class="img-wrap" aria-label="$name">
    <span class="stock-tag badge $stockClass">$stockLabel</span>
    <img src="$img" alt="$altImg" loading="lazy" width="600" height="600">
  </a>
  <div class="body">
    <span class="collection">$collName</span>
    <h3 class="name"><a href="$href">$name</a></h3>
    <span class="meta">$($p.size) cm · $($colorNames[$locale][$p.color])</span>
    <div class="price-row">
      <span class="price">$price <small>$perSqm</small></span>
      <span class="badge badge-accent">$($p.size)</span>
    </div>
  </div>
</article>
"@
}

# ------------- Pages -------------
function Build-HomePage($locale) {
  $t = $i18n.$locale
  $base = if ($locale -eq 'ro') { '' } else { '/en' }
  $altBase = if ($locale -eq 'ro') { '/en/' } else { '/' }
  $canonical = "$SiteUrl$base/"
  $altLocaleHref = "$SiteUrl$altBase"
  $title = "$($site.name) - $(HE $site.tagline.$locale)"
  $desc = HE $t.home.heroSubtitle
  $altLocaleAbsolute = $altLocaleHref

  $featured = $prods | Where-Object { $_.featured } | Select-Object -First 8
  $cards = ''
  $i = 0
  foreach ($p in $featured) { $cards += (Render-ProductCard $p $locale $i); $i++ }

  $collCards = ''
  foreach ($c in $collections) {
    $sample = $prods | Where-Object { $_.collection -eq $c.id } | Select-Object -First 1
    $img = HE "/assets/images/products/$($sample.slug).svg"
    $name = HE $c.name.$locale
    $collCards += @"
<a href="$base/catalog.html#collection-$($c.id)" class="collection-card">
  <img src="$img" alt="$name" loading="lazy" width="600" height="600">
  <span class="label">$name</span>
</a>
"@
  }

  $heroVisualImgs = ($prods | Where-Object { $_.featured } | Select-Object -First 4 | ForEach-Object {
    "<div><img src=`"/assets/images/products/$($_.slug).svg`" alt=`"$(HE $_.name.$locale)`" loading=`"eager`" width=`"600`" height=`"600`"></div>"
  }) -join "`n"

  $orgSchema = @"
{"@context":"https://schema.org","@type":"Store","name":"Casa Tile","url":"$SiteUrl","telephone":"$($site.phone)","email":"$($site.email)","address":{"@type":"PostalAddress","streetAddress":"$($site.address.$locale)"}}
"@

  $head = Render-LayoutHead $locale $title $desc $canonical $altLocaleAbsolute $orgSchema
  $header = Render-Header $locale 'home' $altLocaleAbsolute
  $footer = Render-Footer $locale
  $foot = Render-LayoutFoot $locale ''

  $html = @"
$head
$header
<main id="main">
<section class="hero">
  <div class="container hero-inner">
    <div>
      <h1>$(HE $t.home.heroTitle)</h1>
      <p class="lead">$(HE $t.home.heroSubtitle)</p>
      <div class="hero-actions">
        <a href="$base/catalog.html" class="btn btn-primary">$(HE $t.home.heroCta)</a>
        <a href="$base/contact.html" class="btn btn-secondary">$(HE $t.home.heroCtaSecondary)</a>
      </div>
    </div>
    <div class="hero-visual" aria-hidden="true">$heroVisualImgs</div>
  </div>
</section>

<section>
  <div class="container">
    <div class="section-head">
      <div>
        <span class="eyebrow">$(HE $t.home.featuredTitle)</span>
        <h2>$(HE $t.home.featuredTitle)</h2>
        <p>$(HE $t.home.featuredSubtitle)</p>
      </div>
      <a href="$base/catalog.html" class="btn btn-secondary">$(HE $t.home.viewAll)</a>
    </div>
    <div class="product-grid">
$cards
    </div>
  </div>
</section>

<section class="collections-strip">
  <div class="container">
    <div class="section-head">
      <div>
        <span class="eyebrow">$(HE $t.home.collectionsTitle)</span>
        <h2>$(HE $t.home.collectionsTitle)</h2>
        <p>$(HE $t.home.collectionsSubtitle)</p>
      </div>
    </div>
    <div class="collections-grid">
$collCards
    </div>
  </div>
</section>

<section>
  <div class="container">
    <div class="section-head"><div><span class="eyebrow">$(HE $t.home.valuesTitle)</span><h2>$(HE $t.home.valuesTitle)</h2></div></div>
    <div class="values-grid">
      <div class="value">
        <div class="icon"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 2l3 6 7 1-5 5 1 7-6-3-6 3 1-7-5-5 7-1z"/></svg></div>
        <h3>$(HE $t.home.value1Title)</h3><p>$(HE $t.home.value1Body)</p>
      </div>
      <div class="value">
        <div class="icon"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg></div>
        <h3>$(HE $t.home.value2Title)</h3><p>$(HE $t.home.value2Body)</p>
      </div>
      <div class="value">
        <div class="icon"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="1" y="3" width="15" height="13"/><polygon points="16,8 20,8 23,11 23,16 16,16"/><circle cx="5.5" cy="18.5" r="2.5"/><circle cx="18.5" cy="18.5" r="2.5"/></svg></div>
        <h3>$(HE $t.home.value3Title)</h3><p>$(HE $t.home.value3Body)</p>
      </div>
      <div class="value">
        <div class="icon"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg></div>
        <h3>$(HE $t.home.value4Title)</h3><p>$(HE $t.home.value4Body)</p>
      </div>
    </div>
  </div>
</section>
</main>
$footer
$foot
"@
  return $html
}

function Build-CatalogPage($locale) {
  $t = $i18n.$locale
  $base = if ($locale -eq 'ro') { '' } else { '/en' }
  $altBase = if ($locale -eq 'ro') { '/en/catalog.html' } else { '/catalog.html' }
  $canonical = "$SiteUrl$base/catalog.html"
  $altLocaleHref = "$SiteUrl$altBase"
  $title = "$(HE $t.catalog.title) - $($site.name)"
  $desc = HE $t.catalog.description

  $cards = ''
  $i = 0
  foreach ($p in $prods) { $cards += (Render-ProductCard $p $locale $i); $i++ }

  # Filter UI
  function FilterGroup($title, $name, $items, $fmt) {
    $opts = ''
    foreach ($it in $items) {
      $matched = @($prods | Where-Object { (Invoke-Command -ScriptBlock $fmt -ArgumentList $_, $it) })
      $count = $matched.Count
      if ($count -eq 0) { continue }
      $value = HE $it.id
      $label = HE $it.label
      $opts += "<label class='filter-option'><input type='checkbox' data-filter='$name' value='$value'><span>$label</span><span class='count'>$count</span></label>`n"
    }
@"
<div class="filter-group" data-collapsed="false">
  <button class="filter-group-title" type="button">
    <span>$title</span>
    <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 6l4 4 4-4"/></svg>
  </button>
  <div class="filter-options">$opts</div>
</div>
"@
  }

  # Collection filter
  $collGroup = FilterGroup (HE $t.catalog.collection) 'collection' (
    $collections | ForEach-Object { @{ id = $_.id; label = $_.name.$locale } }
  ) { param($p, $it) $p.collection -eq $it.id }

  # Color filter (visual swatches)
  $colorOpts = ''
  foreach ($c in $colorIds) {
    $count = ($prods | Where-Object { $_.color -eq $c }).Count
    $name = HE $colorNames[$locale][$c]
    $hex = $colorPalette[$c]
    $colorOpts += "<label class='color-swatch' style='background:$hex' title='$name'><input type='checkbox' data-filter='color' value='$c'><span class='sr-only'>$name</span></label>`n"
  }
  $colorGroup = @"
<div class="filter-group" data-collapsed="false">
  <button class="filter-group-title" type="button"><span>$(HE $t.catalog.color)</span>
    <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 6l4 4 4-4"/></svg>
  </button>
  <div class="filter-options"><div class="color-grid">$colorOpts</div></div>
</div>
"@

  # Size filter
  $sizeGroup = FilterGroup (HE $t.catalog.size) 'size' (
    $sizeIds | ForEach-Object { @{ id = $_; label = "$_ cm" } }
  ) { param($p, $it) $p.size -eq $it.id }

  # Room filter
  $roomGroup = FilterGroup (HE $t.catalog.room) 'room' (
    $roomDefs | ForEach-Object { @{ id = $_.id; label = $_.name.$locale } }
  ) { param($p, $it) $p.rooms -contains $it.id }

  # Finish filter
  $finishGroup = FilterGroup (HE $t.catalog.finish) 'finish' (
    $finishDefs | ForEach-Object { @{ id = $_.id; label = $_.name.$locale } }
  ) { param($p, $it) $p.finish -eq $it.id }

  # Material filter
  $materialGroup = FilterGroup (HE $t.catalog.material) 'material' (
    $materialDefs | ForEach-Object { @{ id = $_.id; label = $_.name.$locale } }
  ) { param($p, $it) $p.material -eq $it.id }

  # Price range
  $priceGroup = @"
<div class="filter-group" data-collapsed="false">
  <button class="filter-group-title" type="button"><span>$(HE $t.catalog.priceRange)</span>
    <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 6l4 4 4-4"/></svg>
  </button>
  <div class="filter-options" style="display:flex;flex-direction:row;gap:.5rem">
    <input type="number" class="field" data-min-price placeholder="Min" min="0" style="width:50%;padding:.5rem;border:1px solid var(--c-border);border-radius:6px">
    <input type="number" class="field" data-max-price placeholder="Max" min="0" style="width:50%;padding:.5rem;border:1px solid var(--c-border);border-radius:6px">
  </div>
</div>
"@

  $itemListSchema = @"
{"@context":"https://schema.org","@type":"ItemList","itemListElement":[$(
($prods | ForEach-Object -Begin { $idx = 0 } -Process {
  $idx++
  "{`"@type`":`"ListItem`",`"position`":$idx,`"url`":`"$SiteUrl$base/pages/$($_.slug).html`",`"name`":`"$([System.Web.HttpUtility]::JavaScriptStringEncode($_.name.$locale))`"}"
}) -join ',')]}
"@

  $head = Render-LayoutHead $locale $title $desc $canonical $altLocaleHref $itemListSchema
  $header = Render-Header $locale 'catalog' $altLocaleHref
  $footer = Render-Footer $locale
  $foot = Render-LayoutFoot $locale '<script src="/assets/js/catalog.js" defer></script>'

  $resultsTpl = "{count} $(HE $t.catalog.results)"

  $html = @"
$head
$header
<main id="main">
<section class="page-hero tight">
  <div class="container">
    <h1>$(HE $t.catalog.title)</h1>
    <p class="lead">$(HE $t.catalog.description)</p>
  </div>
</section>

<section class="tight">
<div class="container">
<div class="catalog-layout">
  <aside class="filters-panel" data-filters data-open="false" aria-label="$(HE $t.catalog.filters)">
    <div class="filters-head">
      <span>$(HE $t.catalog.filters)</span>
      <div style="display:flex;gap:.5rem;align-items:center">
        <button type="button" class="btn-ghost" style="font-size:.85rem;padding:4px 8px" data-clear-filters>$(HE $t.catalog.clearFilters)</button>
        <button type="button" class="filter-close btn-ghost" data-close-filters aria-label="Close filters">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M6 6l12 12M6 18L18 6"/></svg>
        </button>
      </div>
    </div>
    $collGroup
    $colorGroup
    $sizeGroup
    $roomGroup
    $finishGroup
    $materialGroup
    $priceGroup
  </aside>

  <div>
    <div class="toolbar">
      <button type="button" class="btn btn-secondary show-filters-btn" data-show-filters>
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 6h16M7 12h10M10 18h4"/></svg>
        $(HE $t.catalog.filters)
      </button>
      <span class="results-count" data-result-count data-template="$resultsTpl"><strong>$($prods.Count)</strong> $(HE $t.catalog.results)</span>
      <label style="display:flex;gap:.5rem;align-items:center">
        <span style="font-size:.85rem;color:var(--c-text-muted)">$(HE $t.catalog.sortBy)</span>
        <select data-sort>
          <option value="newest">$(HE $t.catalog.sortNewest)</option>
          <option value="price-asc">$(HE $t.catalog.sortPriceAsc)</option>
          <option value="price-desc">$(HE $t.catalog.sortPriceDesc)</option>
          <option value="name-asc">$(HE $t.catalog.sortNameAsc)</option>
        </select>
      </label>
    </div>

    <div class="product-grid" data-product-grid>
$cards
    </div>
    <div class="no-results" data-no-results hidden>$(HE $t.catalog.noResults)</div>
  </div>
</div>
</div>
</section>
</main>
$footer
$foot
"@
  return $html
}

function Build-AboutPage($locale) {
  $t = $i18n.$locale
  $base = if ($locale -eq 'ro') { '' } else { '/en' }
  $altBase = if ($locale -eq 'ro') { '/en/about.html' } else { '/about.html' }
  $canonical = "$SiteUrl$base/about.html"
  $altLocaleHref = "$SiteUrl$altBase"
  $title = "$(HE $t.about.title) - $($site.name)"
  $desc = HE $t.about.lead

  $head = Render-LayoutHead $locale $title $desc $canonical $altLocaleHref $null
  $header = Render-Header $locale 'about' $altLocaleHref
  $footer = Render-Footer $locale
  $foot = Render-LayoutFoot $locale ''

  $html = @"
$head
$header
<main id="main">
<section class="page-hero">
  <div class="container">
    <h1>$(HE $t.about.title)</h1>
    <p class="lead">$(HE $t.about.lead)</p>
  </div>
</section>
<section>
  <div class="container about-grid">
    <div>
      <p>$(HE $t.about.p1)</p>
      <p>$(HE $t.about.p2)</p>
      <p>$(HE $t.about.p3)</p>
      <a href="$base/contact.html" class="btn btn-primary">$(HE $t.contact.title)</a>
    </div>
    <div>
      <div class="stats-grid">
        <div class="stat"><div class="num">15+</div><div class="label">$(HE $t.about.stat1)</div></div>
        <div class="stat"><div class="num">5000+</div><div class="label">$(HE $t.about.stat2)</div></div>
        <div class="stat"><div class="num">$($prods.Count)+</div><div class="label">$(HE $t.about.stat3)</div></div>
        <div class="stat"><div class="num">3</div><div class="label">$(HE $t.about.stat4)</div></div>
      </div>
    </div>
  </div>
</section>
</main>
$footer
$foot
"@
  return $html
}

function Build-ContactPage($locale) {
  $t = $i18n.$locale
  $base = if ($locale -eq 'ro') { '' } else { '/en' }
  $altBase = if ($locale -eq 'ro') { '/en/contact.html' } else { '/contact.html' }
  $canonical = "$SiteUrl$base/contact.html"
  $altLocaleHref = "$SiteUrl$altBase"
  $title = "$(HE $t.contact.title) - $($site.name)"
  $desc = HE $t.contact.lead

  $head = Render-LayoutHead $locale $title $desc $canonical $altLocaleHref $null
  $header = Render-Header $locale 'contact' $altLocaleHref
  $footer = Render-Footer $locale
  $foot = Render-LayoutFoot $locale '<script src="/assets/js/contact.js" defer></script>'

  $hours = ($t.contact.hoursValue -split "`n" | ForEach-Object { HE $_ }) -join '<br>'

  $html = @"
$head
$header
<main id="main">
<section class="page-hero">
  <div class="container">
    <h1>$(HE $t.contact.title)</h1>
    <p class="lead">$(HE $t.contact.lead)</p>
  </div>
</section>
<section>
  <div class="container contact-grid">
    <div class="contact-info">
      <div class="item">
        <div class="icon"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 10c0 7-9 13-9 13S3 17 3 10a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg></div>
        <div><h4>$(HE $t.contact.address)</h4><p>$(HE $site.address.$locale)</p></div>
      </div>
      <div class="item">
        <div class="icon"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"/></svg></div>
        <div><h4>$(HE $t.contact.phone)</h4><p><a href="tel:$($site.phone -replace '[^\d+]','')">$(HE $site.phone)</a></p></div>
      </div>
      <div class="item">
        <div class="icon"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/></svg></div>
        <div><h4>$(HE $t.contact.email)</h4><p><a href="mailto:$($site.email)">$(HE $site.email)</a></p></div>
      </div>
      <div class="item">
        <div class="icon"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12,6 12,12 16,14"/></svg></div>
        <div><h4>$(HE $t.contact.hours)</h4><p>$hours</p></div>
      </div>
    </div>
    <div class="contact-form">
      <h3 style="font-family:var(--font-sans);font-size:1.25rem;margin-bottom:1rem">$(HE $t.contact.formTitle)</h3>
      <form id="contact-form" novalidate>
        <div class="form-row two">
          <div class="field"><label for="cf-name">$(HE $t.contact.name) *</label><input id="cf-name" name="name" required placeholder="$(HE $t.contact.namePlaceholder)"></div>
          <div class="field"><label for="cf-email">$(HE $t.contact.email) *</label><input id="cf-email" name="email" type="email" required placeholder="$(HE $t.contact.emailPlaceholder)"></div>
        </div>
        <div class="form-row">
          <div class="field"><label for="cf-phone">$(HE $t.contact.phone)</label><input id="cf-phone" name="phone" type="tel" placeholder="$(HE $t.contact.phonePlaceholder)"></div>
        </div>
        <div class="form-row">
          <div class="field"><label for="cf-message">$(HE $t.contact.message) *</label><textarea id="cf-message" name="message" required placeholder="$(HE $t.contact.messagePlaceholder)"></textarea></div>
        </div>
        <button type="submit" class="btn btn-primary">$(HE $t.contact.send)</button>
        <div class="form-success" data-form-success>$(HE $t.contact.successMsg)</div>
      </form>
    </div>
  </div>
</section>
</main>
$footer
$foot
"@
  return $html
}

function Build-ProductPage($p, $locale) {
  $t = $i18n.$locale
  $base = if ($locale -eq 'ro') { '' } else { '/en' }
  $altBase = if ($locale -eq 'ro') { "/en/pages/$($p.slug).html" } else { "/pages/$($p.slug).html" }
  $canonical = "$SiteUrl$base/pages/$($p.slug).html"
  $altLocaleHref = "$SiteUrl$altBase"
  $coll = Get-Coll $p.collection
  $title = "$($p.name.$locale) - $($coll.name.$locale) - $($site.name)"
  $desc = Get-Description $p $locale

  # Related products: same collection, exclude self
  $related = $prods | Where-Object { $_.collection -eq $p.collection -and $_.slug -ne $p.slug } | Select-Object -First 4

  $stockLabel = if ($p.stock) { HE $t.catalog.inStock } else { HE $t.catalog.outOfStock }
  $stockClass = if ($p.stock) { 'badge-success' } else { 'badge-danger' }

  $rooms = ($p.rooms | ForEach-Object {
    $rid = $_; $r = $roomDefs | Where-Object { $_.id -eq $rid } | Select-Object -First 1; HE $r.name.$locale
  }) -join ', '
  $colorLabel = HE $colorNames[$locale][$p.color]
  $finishLabel = HE (($finishDefs | Where-Object { $_.id -eq $p.finish }).name.$locale)
  $materialLabel = HE (($materialDefs | Where-Object { $_.id -eq $p.material }).name.$locale)
  $frostLabel = if ($p.frostResistant) { HE $t.product.yes } else { HE $t.product.no }
  $price = Format-Price $p.price $locale
  $perSqm = HE $t.catalog.perSqm
  $img = HE "/assets/images/products/$($p.slug).svg"

  $relatedHtml = ''
  $idx = 0
  foreach ($r in $related) { $relatedHtml += (Render-ProductCard $r $locale $idx); $idx++ }

  $availJson = if ($p.stock) { 'https://schema.org/InStock' } else { 'https://schema.org/OutOfStock' }
  $jsonName = $p.name.$locale -replace '"', '\"'
  $jsonDesc = $desc -replace '"', '\"'
  $productSchema = @"
{"@context":"https://schema.org","@type":"Product","name":"$jsonName","description":"$jsonDesc","image":"$SiteUrl$img","brand":{"@type":"Brand","name":"Casa Tile"},"category":"$($coll.name.$locale)","sku":"$($p.slug)","offers":{"@type":"Offer","priceCurrency":"MDL","price":"$($p.price)","availability":"$availJson","url":"$canonical","priceSpecification":{"@type":"UnitPriceSpecification","price":"$($p.price)","priceCurrency":"MDL","unitCode":"MTK"}}}
"@

  $head = Render-LayoutHead $locale $title $desc $canonical $altLocaleHref $productSchema
  $header = Render-Header $locale 'product' $altLocaleHref
  $footer = Render-Footer $locale
  $foot = Render-LayoutFoot $locale ''

  $html = @"
$head
$header
<main id="main">
<div class="container">
  <nav class="breadcrumbs" aria-label="Breadcrumb">
    <a href="$base/">$(HE $t.nav.home)</a>
    <span aria-hidden="true">/</span>
    <a href="$base/catalog.html">$(HE $t.nav.catalog)</a>
    <span aria-hidden="true">/</span>
    <span>$(HE $p.name.$locale)</span>
  </nav>

  <div class="product-detail">
    <div class="product-image-large">
      <img src="$img" alt="$(HE $p.name.$locale)" width="800" height="800">
    </div>
    <div class="product-info">
      <span class="product-collection">$(HE $coll.name.$locale)</span>
      <h1>$(HE $p.name.$locale)</h1>
      <div class="product-price">$price <small>$perSqm</small></div>
      <div class="stock-line"><span class="badge $stockClass">$stockLabel</span></div>

      <p>$(HE $desc)</p>

      <table class="spec-table">
        <tr><th>$(HE $t.product.collection)</th><td>$(HE $coll.name.$locale)</td></tr>
        <tr><th>$(HE $t.product.size)</th><td>$($p.size) cm</td></tr>
        <tr><th>$(HE $t.product.thickness)</th><td>$($p.thickness) mm</td></tr>
        <tr><th>$(HE $t.product.material)</th><td>$materialLabel</td></tr>
        <tr><th>$(HE $t.product.finish)</th><td>$finishLabel</td></tr>
        <tr><th>$(HE $t.product.color)</th><td>$colorLabel</td></tr>
        <tr><th>$(HE $t.product.waterAbsorption)</th><td>$($p.waterAbsorption)</td></tr>
        <tr><th>$(HE $t.product.frostResistant)</th><td>$frostLabel</td></tr>
        <tr><th>$(HE $t.product.rooms)</th><td>$rooms</td></tr>
      </table>

      <div class="product-actions">
        <a href="$base/contact.html?product=$($p.slug)" class="btn btn-primary">$(HE $t.product.requestQuote)</a>
        <a href="tel:$($site.phone -replace '[^\d+]','')" class="btn btn-secondary">$(HE $t.product.callUs) $($site.phone)</a>
      </div>
    </div>
  </div>
</div>

<section>
  <div class="container">
    <div class="section-head"><div><h2>$(HE $t.product.related)</h2></div><a href="$base/catalog.html" class="btn btn-secondary">$(HE $i18n.$locale.home.viewAll)</a></div>
    <div class="product-grid">$relatedHtml</div>
  </div>
</section>
</main>
$footer
$foot
"@
  return $html
}

# ------------- Sitemap & robots -------------
function Build-Sitemap {
  $now = (Get-Date).ToString('yyyy-MM-dd')
  $urls = New-Object System.Collections.Generic.List[string]
  $locales = @('ro', 'en')
  foreach ($l in $locales) {
    $base = if ($l -eq 'ro') { '' } else { '/en' }
    $alt = if ($l -eq 'ro') { '/en' } else { '' }
    foreach ($pg in @('/', '/catalog.html', '/about.html', '/contact.html')) {
      $loc = "$SiteUrl$base$pg"
      $altLoc = "$SiteUrl$alt$pg"
      $urls.Add(@"
  <url>
    <loc>$loc</loc>
    <xhtml:link rel="alternate" hreflang="$l" href="$loc"/>
    <xhtml:link rel="alternate" hreflang="$( if ($l -eq 'ro') { 'en' } else { 'ro' } )" href="$altLoc"/>
    <lastmod>$now</lastmod>
    <changefreq>weekly</changefreq>
    <priority>$( if ($pg -eq '/') { '1.0' } else { '0.8' } )</priority>
  </url>
"@)
    }
    foreach ($p in $prods) {
      $loc = "$SiteUrl$base/pages/$($p.slug).html"
      $altLoc = "$SiteUrl$alt/pages/$($p.slug).html"
      $urls.Add(@"
  <url>
    <loc>$loc</loc>
    <xhtml:link rel="alternate" hreflang="$l" href="$loc"/>
    <xhtml:link rel="alternate" hreflang="$( if ($l -eq 'ro') { 'en' } else { 'ro' } )" href="$altLoc"/>
    <lastmod>$now</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.7</priority>
  </url>
"@)
    }
  }
@"
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">
$($urls -join "`n")
</urlset>
"@
}

function Build-Robots {
@"
User-agent: *
Allow: /

Sitemap: $SiteUrl/sitemap.xml
"@
}

function Build-FaviconSvg {
@"
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
  <rect width="64" height="64" rx="8" fill="#1f1d1a"/>
  <rect x="8" y="8" width="22" height="22" fill="#b8956a"/>
  <rect x="34" y="8" width="22" height="22" fill="#f4ead4"/>
  <rect x="8" y="34" width="22" height="22" fill="#f4ead4"/>
  <rect x="34" y="34" width="22" height="22" fill="#b8956a"/>
</svg>
"@
}

# ------------- Write all files -------------
function Write-File($path, $content) {
  $dir = Split-Path -Parent $path
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  [System.IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($false))
}

Write-Host "Generating SVG images..." -ForegroundColor Cyan
foreach ($p in $prods) {
  $svg = New-TileSvg $p
  Write-File "$root\assets\images\products\$($p.slug).svg" $svg
}
Write-File "$root\assets\images\favicon.svg" (Build-FaviconSvg)

Write-Host "Building RO pages..." -ForegroundColor Cyan
Write-File "$root\index.html"        (Build-HomePage 'ro')
Write-File "$root\catalog.html"      (Build-CatalogPage 'ro')
Write-File "$root\about.html"        (Build-AboutPage 'ro')
Write-File "$root\contact.html"      (Build-ContactPage 'ro')
foreach ($p in $prods) {
  Write-File "$root\pages\$($p.slug).html" (Build-ProductPage $p 'ro')
}

Write-Host "Building EN pages..." -ForegroundColor Cyan
Write-File "$root\en\index.html"        (Build-HomePage 'en')
Write-File "$root\en\catalog.html"      (Build-CatalogPage 'en')
Write-File "$root\en\about.html"        (Build-AboutPage 'en')
Write-File "$root\en\contact.html"      (Build-ContactPage 'en')
foreach ($p in $prods) {
  Write-File "$root\en\pages\$($p.slug).html" (Build-ProductPage $p 'en')
}

Write-Host "Generating sitemap and robots.txt..." -ForegroundColor Cyan
Write-File "$root\sitemap.xml" (Build-Sitemap)
Write-File "$root\robots.txt"  (Build-Robots)

Write-Host "Done." -ForegroundColor Green
