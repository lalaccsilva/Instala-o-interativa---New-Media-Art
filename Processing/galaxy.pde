class Galaxy {
  ArrayList<Particle> particles;

  Galaxy(int numParticles) {
    particles = new ArrayList<Particle>();
    for (int i = 0; i < numParticles; i++) {
      float startX = random(width);
      float startY = random(height);
      particles.add(new Particle(startX, startY));
    }
  }

  void update() {
    for (Particle p : particles) {
      p.update();
    }
  }

  void display() {
    for (Particle p : particles) {
      p.display();
    }
  }

  void adjustParticles(float targetX, float targetY) {
    for (Particle p : particles) {
      p.adjustPosition(targetX, targetY);
      
      p.x += random(-1, 1);
      p.y += random(-1, 1);
    }
  }
}
