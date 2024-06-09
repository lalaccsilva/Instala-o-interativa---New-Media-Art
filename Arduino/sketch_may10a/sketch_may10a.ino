#include "WiFi.h"
#include "PubSubClient.h"
#include "Wire.h"
#include <NewPing.h>

/*const char *ssid = "IoT-Test";
const char *password = "Denohd0dkooz8Oir";
const char *mqtt_broker = "10.6.0.57";*/

const char *ssid = "Lala";
const char *password = "12345678";
const char *mqtt_broker = "192.168.174.121";

const char *topic = "Test";
const char *topic_ultrasonic = "ultrasonic";
const char *topic_noise = "noise";
const int mqtt_port = 1883;
WiFiClient espClient;
PubSubClient client(espClient);

#define TRIGGER_PIN 13
#define ECHO_PIN 12
#define MAX_DISTANCE 200

const int noisePin = 34;
int val = 0;

NewPing sonar(TRIGGER_PIN, ECHO_PIN, MAX_DISTANCE);

void setup() {
  Serial.begin(115200);
  pinMode(noisePin, INPUT);

  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.println("Connecting to WiFi..");
  }
  Serial.println("Connected to the Wi-Fi network");
  client.setServer(mqtt_broker, mqtt_port);
  client.setCallback(callback);

  while (!client.connected()) {
    if (client.connect("esp32-client")) {
      Serial.println("Connected to MQTT broker");
    } else {
      Serial.print("Failed with state ");
      Serial.print(client.state());
      delay(2000);
    }
  }
  client.publish(topic, "Hi, I'm ESP32 <3");
  client.subscribe(topic);
}

void callback(char *topic, byte *payload, unsigned int length) {
  Serial.print("Message arrived in topic: ");
  Serial.println(topic);
  Serial.print("Message:");
  for (int i = 0; i < length; i++) {
    Serial.print((char)payload[i]);
  }
  Serial.println();
  Serial.println("-----------------------");
}

void loop() {
  unsigned int distance = sonar.ping_cm();

  char size = 'S';

  if (distance > 60) {
    size = 'R';
  }
  if (distance < 60 && distance > 0) {
    size = 'L';
  }

  char ruido = 'N';

  val = analogRead(noisePin);
  Serial.print(val);
  if (val > 40) {
    Serial.print(" : Si  ");
    ruido = 'A';
    Serial.println(ruido);
  } else {
    Serial.print(" : No  ");
    ruido = 'B';
    Serial.println(ruido);
  }

  Serial.print(size);
  Serial.print(" - Distance: ");
  Serial.print(distance);
  Serial.println(" cm");

  // Publish ultrasonic data
  char ultrasonicData[50];
  sprintf(ultrasonicData, "{\"size\":\"%c\",\"distance\":%d}", size, distance);
  client.publish(topic_ultrasonic, ultrasonicData);

  // Publish noise data
  char noiseData[20];
  sprintf(noiseData, "{\"val\":\"%d\",\"noise\":\"%c\"}", val, ruido);
  client.publish(topic_noise, noiseData);

  client.loop();
}
