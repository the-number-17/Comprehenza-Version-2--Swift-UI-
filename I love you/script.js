/* ==============================================
   script.js — "I Love You" Interactive Website
   ============================================== */

// ─── DOM Elements ────────────────────────────
const bgCanvas = document.getElementById('bg-canvas');
const celebCanvas = document.getElementById('celebration-canvas');
const card = document.getElementById('card');
const question = document.getElementById('question');
const btnYes = document.getElementById('btn-yes');
const btnNo = document.getElementById('btn-no');
const redFlash = document.getElementById('red-flash');
const celebText = document.getElementById('celebration-text');
const detectiveIcon = document.getElementById('detective-icon');
const loveIcon = document.getElementById('love-icon');

const bgCtx = bgCanvas.getContext('2d');
const celebCtx = celebCanvas.getContext('2d');

// ─── State ───────────────────────────────────
let noClickCount = 0;
let isValentine = false;

// ─── Begging Questions Cycle ─────────────────
const noQuestions = [
  "Are you sure? 🤨",
  "Are you really sure? 😢",
  "Please think again… 🥺",
  "My heart is breaking… 💔",
  "You're really going to say no? 😭",
  "But… I made this whole website for you! 🥹",
  "Pretty please? With sugar on top? 🍬",
  "I'll ask one more time… please? 🙏",
  "Okay but what if I say PRETTY PLEASE? 💕",
  "I refuse to believe you mean it 😤",
  "Come on… just click Yes already! 😩",
  "I'll wait forever if I have to… ⏳",
  "The Yes button is RIGHT THERE ➡️",
  "Do it for the vibes 🌹",
  "Last chance… or I'll ask again 😏",
];

// ─── Resize Canvases ─────────────────────────
function resizeCanvases() {
  bgCanvas.width = window.innerWidth;
  bgCanvas.height = window.innerHeight;
  celebCanvas.width = window.innerWidth;
  celebCanvas.height = window.innerHeight;
}
resizeCanvases();
window.addEventListener('resize', resizeCanvases);

// ==============================================
//  DETECTIVE BACKGROUND — Floating particles
// ==============================================
const particles = [];
const PARTICLE_COUNT = 80;

class Particle {
  constructor() {
    this.reset();
  }

  reset() {
    this.x = Math.random() * bgCanvas.width;
    this.y = Math.random() * bgCanvas.height;
    this.size = Math.random() * 2 + 0.5;
    this.speedX = (Math.random() - 0.5) * 0.4;
    this.speedY = (Math.random() - 0.5) * 0.4;
    this.opacity = Math.random() * 0.4 + 0.1;
    this.hue = 40 + Math.random() * 15; // Gold-amber tones
  }

  update() {
    this.x += this.speedX;
    this.y += this.speedY;

    if (this.x < 0 || this.x > bgCanvas.width) this.speedX *= -1;
    if (this.y < 0 || this.y > bgCanvas.height) this.speedY *= -1;
  }

  draw(ctx) {
    ctx.beginPath();
    ctx.arc(this.x, this.y, this.size, 0, Math.PI * 2);
    ctx.fillStyle = `hsla(${this.hue}, 50%, 60%, ${this.opacity})`;
    ctx.fill();
  }
}

// Initialize particles
for (let i = 0; i < PARTICLE_COUNT; i++) {
  particles.push(new Particle());
}

// Draw connecting lines between close particles
function drawLines(ctx) {
  for (let i = 0; i < particles.length; i++) {
    for (let j = i + 1; j < particles.length; j++) {
      const dx = particles[i].x - particles[j].x;
      const dy = particles[i].y - particles[j].y;
      const dist = Math.sqrt(dx * dx + dy * dy);

      if (dist < 120) {
        ctx.beginPath();
        ctx.moveTo(particles[i].x, particles[i].y);
        ctx.lineTo(particles[j].x, particles[j].y);
        ctx.strokeStyle = `rgba(201, 168, 76, ${0.08 * (1 - dist / 120)})`;
        ctx.lineWidth = 0.5;
        ctx.stroke();
      }
    }
  }
}

// Spotlight effect that follows a slow path
let spotlightAngle = 0;
function drawSpotlight(ctx) {
  spotlightAngle += 0.003;
  const cx = bgCanvas.width / 2 + Math.cos(spotlightAngle) * 200;
  const cy = bgCanvas.height / 2 + Math.sin(spotlightAngle * 0.7) * 150;

  const gradient = ctx.createRadialGradient(cx, cy, 0, cx, cy, 350);
  gradient.addColorStop(0, 'rgba(201, 168, 76, 0.04)');
  gradient.addColorStop(1, 'rgba(0, 0, 0, 0)');

  ctx.fillStyle = gradient;
  ctx.fillRect(0, 0, bgCanvas.width, bgCanvas.height);
}

// Detective background animation loop
function animateDetective() {
  if (isValentine) return;

  bgCtx.clearRect(0, 0, bgCanvas.width, bgCanvas.height);

  // Dark fog
  bgCtx.fillStyle = 'rgba(10, 10, 15, 0.15)';
  bgCtx.fillRect(0, 0, bgCanvas.width, bgCanvas.height);

  drawSpotlight(bgCtx);

  particles.forEach(p => {
    p.update();
    p.draw(bgCtx);
  });

  drawLines(bgCtx);

  requestAnimationFrame(animateDetective);
}

animateDetective();

// ==============================================
//  VALENTINE CELEBRATION — Hearts & sparkles
// ==============================================
const hearts = [];
const sparkles = [];

class Heart {
  constructor() {
    this.reset();
  }

  reset() {
    this.x = Math.random() * celebCanvas.width;
    this.y = celebCanvas.height + 30 + Math.random() * 100;
    this.size = Math.random() * 18 + 10;
    this.speed = Math.random() * 2 + 1;
    this.wobble = Math.random() * Math.PI * 2;
    this.wobbleSpeed = Math.random() * 0.03 + 0.01;
    this.rotation = Math.random() * 0.4 - 0.2;
    this.opacity = Math.random() * 0.6 + 0.4;
    const pinks = ['#ff1e6c', '#ff6b9d', '#ff85a2', '#ff4081', '#e91e63', '#f06292'];
    this.color = pinks[Math.floor(Math.random() * pinks.length)];
  }

  update() {
    this.y -= this.speed;
    this.wobble += this.wobbleSpeed;
    this.x += Math.sin(this.wobble) * 1.2;

    if (this.y < -40) this.reset();
  }

  draw(ctx) {
    ctx.save();
    ctx.translate(this.x, this.y);
    ctx.rotate(this.rotation);
    ctx.globalAlpha = this.opacity;

    const s = this.size;
    ctx.beginPath();
    ctx.moveTo(0, s * 0.3);
    ctx.bezierCurveTo(-s * 0.5, -s * 0.3, -s, s * 0.1, 0, s);
    ctx.bezierCurveTo(s, s * 0.1, s * 0.5, -s * 0.3, 0, s * 0.3);
    ctx.fillStyle = this.color;
    ctx.fill();
    ctx.closePath();

    ctx.restore();
  }
}

class Sparkle {
  constructor() {
    this.reset();
  }

  reset() {
    this.x = Math.random() * celebCanvas.width;
    this.y = Math.random() * celebCanvas.height;
    this.size = Math.random() * 3 + 1;
    this.maxOpacity = Math.random() * 0.8 + 0.2;
    this.opacity = 0;
    this.fadeIn = true;
    this.speed = Math.random() * 0.02 + 0.005;
  }

  update() {
    if (this.fadeIn) {
      this.opacity += this.speed;
      if (this.opacity >= this.maxOpacity) this.fadeIn = false;
    } else {
      this.opacity -= this.speed;
      if (this.opacity <= 0) this.reset();
    }
  }

  draw(ctx) {
    ctx.save();
    ctx.globalAlpha = this.opacity;

    // Star shape
    ctx.beginPath();
    ctx.fillStyle = '#fff';
    for (let i = 0; i < 4; i++) {
      const angle = (i * Math.PI) / 2;
      ctx.moveTo(this.x, this.y);
      ctx.lineTo(
        this.x + Math.cos(angle) * this.size,
        this.y + Math.sin(angle) * this.size
      );
    }
    ctx.arc(this.x, this.y, this.size * 0.4, 0, Math.PI * 2);
    ctx.fill();

    ctx.restore();
  }
}

function initCelebration() {
  for (let i = 0; i < 50; i++) {
    const h = new Heart();
    h.y = Math.random() * celebCanvas.height; // Spread initially
    hearts.push(h);
  }
  for (let i = 0; i < 60; i++) {
    sparkles.push(new Sparkle());
  }
}

function animateValentine() {
  if (!isValentine) return;

  celebCtx.clearRect(0, 0, celebCanvas.width, celebCanvas.height);

  hearts.forEach(h => {
    h.update();
    h.draw(celebCtx);
  });

  sparkles.forEach(s => {
    s.update();
    s.draw(celebCtx);
  });

  requestAnimationFrame(animateValentine);
}

// ==============================================
//  BUTTON HANDLERS
// ==============================================

// ─── YES Button ──────────────────────────────
btnYes.addEventListener('click', () => {
  if (isValentine) return;
  isValentine = true;

  // Transition body
  document.body.classList.add('valentine');

  // Clear detective canvas
  bgCtx.clearRect(0, 0, bgCanvas.width, bgCanvas.height);

  // Transform card
  card.classList.add('love-card');
  question.textContent = "I knew it! I love you so much! 💖";
  question.classList.add('love-text');

  // Swap icons
  detectiveIcon.classList.add('hidden');
  loveIcon.classList.remove('hidden');

  // Transform buttons
  btnYes.textContent = "Forever & Always 💕";
  btnYes.classList.add('love-btn');
  btnNo.style.display = 'none';

  // Show celebration canvas
  celebCanvas.classList.add('active');
  initCelebration();
  animateValentine();

  // Show celebration text after a beat
  setTimeout(() => {
    card.style.opacity = '0';
    card.style.transform = 'scale(0.8)';
    card.style.pointerEvents = 'none';

    celebText.classList.remove('hidden');
    // Force reflow
    void celebText.offsetWidth;
    celebText.classList.add('visible');
  }, 1200);
});

// ─── NO Button ───────────────────────────────
btnNo.addEventListener('click', () => {
  if (isValentine) return;

  // Shake the card
  card.classList.remove('shake');
  void card.offsetWidth; // Force reflow to restart animation
  card.classList.add('shake');

  // Red flash
  redFlash.classList.add('flash');
  setTimeout(() => redFlash.classList.remove('flash'), 300);

  // Cycle through the questions
  question.textContent = noQuestions[noClickCount % noQuestions.length];
  noClickCount++;

  // Make yes button grow and no button shrink subtly
  const yesScale = Math.min(1 + noClickCount * 0.04, 1.35);
  const noScale = Math.max(1 - noClickCount * 0.02, 0.7);
  const noOpacity = Math.max(1 - noClickCount * 0.04, 0.4);

  btnYes.style.transform = `scale(${yesScale})`;
  btnYes.classList.add('growing');

  btnNo.style.transform = `scale(${noScale})`;
  btnNo.style.opacity = noOpacity;
  btnNo.classList.add('shrinking');

  // After enough clicks, start hinting more aggressively with the yes button
  if (noClickCount >= 3) {
    btnYes.classList.add('love-btn');
    btnYes.textContent = "Yes, I love you too! 💖✨";
  }

  if (noClickCount >= 6) {
    btnNo.textContent = "I'll come around… 😅";
  }

  if (noClickCount >= 10) {
    btnNo.textContent = "Okay fine… maybe 😳";
  }

  if (noClickCount >= 13) {
    btnNo.textContent = "...🥺";
  }
});

// Remove shake class after animation ends
card.addEventListener('animationend', () => {
  card.classList.remove('shake');
});
