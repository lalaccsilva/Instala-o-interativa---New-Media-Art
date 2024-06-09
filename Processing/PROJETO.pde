//Based on the code created by Tiago Martins and Sergio Rebelo

import processing.serial.*;
import processing.video.*;
import mqtt.*;

MQTTClient client;
Serial myPort;
Capture video;
int numPixels;
int[] previousFrame;
int[] differenceFrame;
int numCols;
int numRows;
int cellSize = 20;
float ballX = -1;
float ballY = -1;
float targetX = -1;
float targetY = -1;
float ballSpeed = 20;
float smoothing;

Galaxy galaxy;

class Adapter implements MQTTListener {
  void clientConnected() {
    println("Client connected");
    client.subscribe("ultrasonic");
    client.subscribe("noise");
  }

  void messageReceived(String topic, byte[] payload) {
    String message = new String(payload);
    println("New message: " + topic + " - " + message);

    if (topic.equals("noise")) {
      JSONObject json2 = parseJSONObject(message);
      if (json2 != null) {
        int val = json2.getInt("val");
        if (val > 40) {
          for (Particle p : galaxy.particles) {
            p.explode();
          }
        }
      }
    } else if (topic.equals("ultrasonic")) {
      JSONObject json = parseJSONObject(message);
      if (json != null) {
        int distance = json.getInt("distance");
        if (distance < 20) {
          for (Particle p : galaxy.particles) {
            if (p.targetSize < 6) {
              p.targetSize += random(0.5, 3);
            }
          }
        } else if (distance > 20) {
          for (Particle p : galaxy.particles) {
            if (p.targetSize > 3) {
              p.targetSize -= random(0.5, 3);
            }
          }
        }
      }
    } else {
      println("Something went wrong. Received the topic: " + topic);
    }
  }

  void connectionLost() {
    println("Connection lost");
  }
}

Adapter adapter;

void setup() {
  fullScreen();
  adapter = new Adapter();
  client = new MQTTClient(this, adapter);
  client.connect("tcp://192.168.174.121:1883", "processing");
  //client.connect("tcp://10.6.0.57:1883", "processing");
  //myPort = new Serial(this, "COM6", 115200);
  //myPort.bufferUntil('\n');

  galaxy = new Galaxy(3500); // QUANTIDADE
  ballX = width / 2;
  ballY = height / 2;
  video = new Capture(this, width, height);
  video.start();
  numPixels = video.width * video.height;
  previousFrame = new int[numPixels];
  differenceFrame = new int[numPixels];
  numCols = width / cellSize;
  numRows = height / cellSize;
}

void draw() {
  background(0);
  galaxy.update();
  galaxy.display();

  // Movimiento Webcam
  if (video.available()) {
    video.read();
    video.loadPixels();
    for (int i = 0; i < numPixels; i++) {
      color currColor = video.pixels[i];
      color prevColor = previousFrame[i];
      int currR = (currColor >> 16) & 0xFF;
      int currG = (currColor >> 8) & 0xFF;
      int currB = currColor & 0xFF;
      int prevR = (prevColor >> 16) & 0xFF;
      int prevG = (prevColor >> 8) & 0xFF;
      int prevB = prevColor & 0xFF;
      int diffR = abs(currR - prevR);
      int diffG = abs(currG - prevG);
      int diffB = abs(currB - prevB);
      differenceFrame[i] = color(diffR, diffG, diffB);
      previousFrame[i] = currColor;
    }
  }

  // Detección de movimiento
  if (frameCount > 30) {
    float maxDiff = 0;
    for (int col = 0; col < numCols; col++) {
      for (int row = 0; row < numRows; row++) {
        int x = col * cellSize;
        int y = row * cellSize;
        int pixelIndex = y * video.width + video.width - x - 1;
        float diffBrightness = brightness(differenceFrame[pixelIndex]);
        float diffNorm = diffBrightness / 255;
        if (diffNorm > maxDiff) {
          maxDiff = diffNorm;
          targetX = x + cellSize / 2;
          targetY = y + cellSize / 2;
        }
      }
    }
    // Suavizar
    targetX = lerp(targetX, ballX, 0.1);
    targetY = lerp(targetY, ballY, 0.1);
  }

  // Actualización de la posición de la bola
  if (ballX == -1 && ballY == -1) {
    ballX = width / 2;
    ballY = height / 2;
  }

  // Movimiento de la bola hacia el punto de destino
  if (targetX != -1 && targetY != -1) {
    float dx = targetX - ballX;
    float dy = targetY - ballY;
    float distance = dist(ballX, ballY, targetX, targetY);
    smoothing = map(distance, 0, width, 0.02, 0.02); // velocidad según distancia
    ballX += dx * smoothing;
    ballY += dy * smoothing;
  }

  // Lógica para controlar el movimiento de las partículas y brillo
  galaxy.adjustParticles(ballX, ballY);

  for (Particle p : galaxy.particles) {
    p.adjustPosition(ballX, ballY);
    p.adjustBrightness(ballX, ballY);
  }

  // Marco que evita que se vean particulas del otro lado del borde
  stroke(0);
  strokeWeight(30);
  noFill();
  rect(0, 0, width, height);
}

// Teclado para pruebas sin MQTT

void keyPressed() {
  if (key == 'a') {
    for (Particle p : galaxy.particles) {
      p.explode();
    }
  } else if (key == 'q') {
    for (Particle p : galaxy.particles) {
      if (p.targetSize < 6) {
        p.targetSize += random(0.5, 3);
      }
    }
  } else if (key == 'w') {
    for (Particle p : galaxy.particles) {
      if (p.targetSize > 3) {
        p.targetSize -= random(0.5, 3);
      }
    }
  }
}
