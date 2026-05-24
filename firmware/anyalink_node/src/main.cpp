// AnyaLink ESP32 node — Plan 2: sensores + servo + topics dinámicos.
//
// Cambios aplicados sobre el baseline:
//   2a - Topics dinámicos anyalink/device/{DEVICE_ID}/{command|state|metrics|online}
//   2b - LWT ("offline") + heartbeat "online" + suscripción a TOPIC_CMD
//   2c - DHT22 (temp/humedad) + HX711 (peso) publicados cada 5 s
//   2d - Servo en GPIO13, comando "dispense" vía MQTT JSON
//   2e - IP local mostrada en OLED al conectar
//
// Pines: OLED SDA=21 SCL=22, LED=27, SERVO=13, DHT=4, HX711 DT=16 SCK=17.

#include <WiFi.h>
#include <WiFiMulti.h>
#include <PubSubClient.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <DHT.h>
#include <HX711.h>
#include <ESP32Servo.h>
#include <ArduinoJson.h>

#include "secrets.h"

// ======== TOPICS (dinámicos — se construyen en setup()) ========
String TOPIC_CMD;       // anyalink/device/{DEVICE_ID}/command
String TOPIC_STATE;     // anyalink/device/{DEVICE_ID}/state
String TOPIC_METRICS;   // anyalink/device/{DEVICE_ID}/metrics
String TOPIC_ONLINE;    // anyalink/device/{DEVICE_ID}/online

// ======== PINES ========
const int LED_PIN = 27;

#define DHT_PIN    4
#define DHT_TYPE   DHT22
#define HX711_DT   16
#define HX711_SCK  17
#define CALIBRATION 1.0f   // ajustar empíricamente

#define SERVO_PIN 13

// ======== OLED SSD1306 ========
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET    -1
#define OLED_ADDR     0x3C

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

// ======== SENSORES / ACTUADORES ========
DHT dht(DHT_PIN, DHT_TYPE);
HX711 scale;
Servo dispenseServo;

// ======== OBJETOS MQTT / WiFi ========
WiFiMulti wifiMulti;
WiFiClient espClient;
PubSubClient client(espClient);

static const int WIFI_NETWORK_COUNT =
  sizeof(WIFI_NETWORKS) / sizeof(WifiNetwork);

// =======================================
// (ES) Render de texto en OLED con auto-tamaño según largo.
// Heredado tal cual de ESP32_1 — funciona muy bien para mensajes cortos.
void showTextOnDisplay(const String& textIn) {
  String text = textIn;
  text.trim();

  display.clearDisplay();
  display.setTextColor(SSD1306_WHITE);

  int len = text.length();

  int textSize;
  int maxLines;
  int charsPerLine;

  if (len <= 7) {
    textSize = 3;
    maxLines = 2;
  } else if (len <= 16) {
    textSize = 2;
    maxLines = 3;
  } else {
    textSize = 1;
    maxLines = 4;
  }

  display.setTextSize(textSize);

  int charW = 6 * textSize;
  int charH = 8 * textSize;

  charsPerLine = SCREEN_WIDTH / charW;
  if (charsPerLine < 1) charsPerLine = 1;

  int neededLines = (len + charsPerLine - 1) / charsPerLine;
  if (neededLines > maxLines) neededLines = maxLines;

  int totalTextHeight = neededLines * charH;
  int startY = (SCREEN_HEIGHT - totalTextHeight) / 2;
  if (startY < 0) startY = 0;

  int index = 0;
  int line = 0;

  while (index < len && line < maxLines) {
    int remaining = len - index;
    int take = remaining;

    if (remaining > charsPerLine) {
      take = charsPerLine;
      int lastSpace = text.lastIndexOf(' ', index + take - 1);
      if (lastSpace >= index && lastSpace < index + take) {
        take = lastSpace - index + 1;
      }
    }

    String lineText = text.substring(index, index + take);
    lineText.trim();

    int16_t x1, y1;
    uint16_t w, h;
    display.getTextBounds(lineText.c_str(), 0, 0, &x1, &y1, &w, &h);
    int16_t x = (SCREEN_WIDTH - w) / 2;
    if (x < 0) x = 0;

    int16_t y = startY + line * charH;

    display.setCursor(x, y);
    display.println(lineText);

    index += take;
    line++;
  }

  display.display();
}

// =======================================
// (ES) Callback al recibir mensaje MQTT
void mqttCallback(char* topic, byte* payload, unsigned int length) {
  String t = String(topic);
  String msg;
  for (unsigned int i = 0; i < length; i++) msg += (char)payload[i];
  msg.trim();

  Serial.print("MQTT ["); Serial.print(t); Serial.print("] "); Serial.println(msg);

  if (t == TOPIC_CMD) {
    StaticJsonDocument<256> doc;
    if (deserializeJson(doc, msg) != DeserializationError::Ok) return;

    const char* action = doc["action"] | "";
    const char* cmd_id = doc["cmd_id"] | "";

    if (strcmp(action, "dispense") == 0) {
      showTextOnDisplay("Dispensando");
      dispenseServo.write(0);   delay(300);
      dispenseServo.write(90);  delay(700);
      dispenseServo.write(0);   delay(300);

      StaticJsonDocument<128> ack;
      ack["cmd_id"] = cmd_id;
      ack["status"] = "done";
      String out;
      serializeJson(ack, out);
      client.publish(TOPIC_STATE.c_str(), out.c_str(), false);
    }
  }
}

// =======================================
// (ES) Conectar / reconectar a MQTT
void reconnectMQTT() {
  while (!client.connected()) {
    Serial.print("Conectando a MQTT... ");

    String clientId = "anyalink-node-";
    clientId += String(WiFi.macAddress());

    bool ok;
    if (MQTT_USER[0] == '\0') {
      ok = client.connect(clientId.c_str(),
                          NULL, NULL,
                          TOPIC_ONLINE.c_str(), 1, true, "offline");
    } else {
      ok = client.connect(clientId.c_str(),
                          MQTT_USER, MQTT_PASSWORD,
                          TOPIC_ONLINE.c_str(), 1, true, "offline");
    }

    if (ok) {
      client.publish(TOPIC_ONLINE.c_str(), "online", true);
      client.subscribe(TOPIC_CMD.c_str());
      Serial.println("conectado");
      showTextOnDisplay(WiFi.localIP().toString());
      delay(2000);
    } else {
      Serial.print("falló, rc=");
      Serial.print(client.state());
      Serial.println(" -> reintento en 2s");
      delay(2000);
    }
  }
}

// =======================================
// (ES) Conectar a WiFi (multi-red)
void connectWiFi() {
  WiFi.mode(WIFI_STA);
  Serial.println("Conectando a WiFi (lista preferente)...");

  static bool networksAdded = false;
  if (!networksAdded) {
    for (int i = 0; i < WIFI_NETWORK_COUNT; i++) {
      const WifiNetwork& net = WIFI_NETWORKS[i];
      if (net.password[0] == '\0') {
        wifiMulti.addAP(net.ssid);
      } else {
        wifiMulti.addAP(net.ssid, net.password);
      }
    }
    networksAdded = true;
  }

  int dots = 0;
  while (wifiMulti.run() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
    dots++;
    if (dots > 40) {
      Serial.println("\nReintentando WiFi...");
      WiFi.disconnect();
      dots = 0;
    }
  }

  Serial.println("");
  Serial.print("WiFi conectado a: ");
  Serial.println(WiFi.SSID());
  Serial.print("IP local: ");
  Serial.println(WiFi.localIP());
}

// =======================================
void setup() {
  Serial.begin(115200);
  delay(1000);

  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);

  Wire.begin(21, 22);
  if (!display.begin(SSD1306_SWITCHCAPVCC, OLED_ADDR)) {
    Serial.println("No se encontro OLED SSD1306 :(");
    while (true) {
      delay(1000);
    }
  }
  display.clearDisplay();
  display.setTextSize(2);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 24);
  display.println("Arrancando");
  display.display();

  TOPIC_CMD     = String("anyalink/device/") + DEVICE_ID + "/command";
  TOPIC_STATE   = String("anyalink/device/") + DEVICE_ID + "/state";
  TOPIC_METRICS = String("anyalink/device/") + DEVICE_ID + "/metrics";
  TOPIC_ONLINE  = String("anyalink/device/") + DEVICE_ID + "/online";

  connectWiFi();

  client.setServer(MQTT_HOST, MQTT_PORT);
  client.setCallback(mqttCallback);

  dht.begin();
  scale.begin(HX711_DT, HX711_SCK);
  scale.set_scale(CALIBRATION);
  scale.tare();

  dispenseServo.attach(SERVO_PIN);
}

// =======================================
void loop() {
  if (WiFi.status() != WL_CONNECTED) {
    connectWiFi();
  }

  if (!client.connected()) {
    reconnectMQTT();
  }

  client.loop();

  static unsigned long lastMetrics = 0;
  if (millis() - lastMetrics >= 5000) {
    lastMetrics = millis();

    float weightG = scale.is_ready() ? scale.get_units(3) : 0.0f;
    float tempC   = dht.readTemperature();
    float humPct  = dht.readHumidity();

    StaticJsonDocument<128> doc;
    doc["weight_g"]      = weightG;
    doc["temperature_c"] = isnan(tempC)  ? 0.0f : tempC;
    doc["humidity_pct"]  = isnan(humPct) ? 0.0f : humPct;

    String payload;
    serializeJson(doc, payload);
    client.publish(TOPIC_METRICS.c_str(), payload.c_str(), false);

    showTextOnDisplay(String(weightG, 1) + "g");
  }
}
