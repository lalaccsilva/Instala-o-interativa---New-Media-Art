class Particle {
  float x, y, vx, vy, size, targetSize;
  color baseColor;
  float maxBrightness = 255;
  float minBrightness = 10;
  boolean isExploding = false;

  Particle(float startX, float startY) {
    x = startX;
    y = startY;
    vx = random(-1, 1);
    vy = random(-1, 1);
    baseColor = color(255);
    size = random(0.5, 3);
    targetSize = size;
  }

  void update() {
    x += vx;
    y += vy;

    x = (x + width) % width;
    y = (y + height) % height;

    size = lerp(size, targetSize, 0.1);

    if (isExploding) {
      vx *= 1.1;
      vy *= 1.1;
      if (abs(vx) > 15 || abs(vy) > 15) {
        isExploding = false;
        vx = random(-1, 1);
        vy = random(-1, 1);
      }
    }
  }

  void display() {
    noStroke();
    fill(baseColor);
    ellipse(x, y, size, size);
  }

  void adjustBrightness(float targetX, float targetY) {
    float d = dist(x, y, targetX, targetY);
    float brightness = map(d, 200, width - 600 /*Distancia del brillo*/, maxBrightness, minBrightness);
    baseColor = color(brightness);
  }

  void adjustPosition(float targetX, float targetY) {
    float d = dist(x, y, targetX, targetY);
    float attractionRadius = 90; // Diámetro de atracción
    if (d < attractionRadius) {
      float newX = targetX + random(-50, 50);
      float newY = targetY + random(-50, 50);
      x = lerp(x, newX, 0.1);
      y = lerp(y, newY, 0.1);
    }
  }

  void explode() {
    isExploding = true;
    vx = random(-5, 5);
    vy = random(-5, 5);
  }
}
