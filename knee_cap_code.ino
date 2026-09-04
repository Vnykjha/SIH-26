#include <Wire.h>
#include <MPU9250_asukiaaa.h>

#include <Adafruit_GFX.h>
#include <Adafruit_ST7735.h>
#include <SPI.h>

// =====================================================
// MPU9250
// =====================================================

#define SDA_PIN 21
#define SCL_PIN 22

MPU9250_asukiaaa mySensor;


// =====================================================
// FLEX SENSOR
// =====================================================

#define FLEX_PIN 34


// =====================================================
// TFT DISPLAY
// =====================================================

#define TFT_CS   5
#define TFT_RST  4
#define TFT_DC   2
#define TFT_MOSI 23
#define TFT_SCLK 18

Adafruit_ST7735 tft = Adafruit_ST7735(
  TFT_CS,
  TFT_DC,
  TFT_RST
);


// =====================================================
// SETUP
// =====================================================

void setup()
{
  Serial.begin(115200);
  delay(1000);

  // -----------------------------
  // MPU9250 I2C
  // -----------------------------

  Wire.begin(SDA_PIN, SCL_PIN);

  mySensor.setWire(&Wire);

  mySensor.beginAccel();
  mySensor.beginGyro();
  mySensor.beginMag();


  // -----------------------------
  // FLEX SENSOR
  // -----------------------------

  pinMode(FLEX_PIN, INPUT);


  // -----------------------------
  // TFT SPI
  // -----------------------------

  SPI.begin(TFT_SCLK, -1, TFT_MOSI, TFT_CS);

  tft.initR(INITR_BLACKTAB);

  tft.setRotation(1);

  tft.fillScreen(ST77XX_BLACK);


  // -----------------------------
  // TFT startup screen
  // -----------------------------

  tft.setTextColor(ST77XX_WHITE);
  tft.setTextSize(2);

  tft.setCursor(5, 5);
  tft.println("MPU9250");

  tft.setTextSize(1);
  tft.setCursor(5, 25);
  tft.println("Initializing...");

  delay(1500);

  tft.fillScreen(ST77XX_BLACK);
}


// =====================================================
// LOOP
// =====================================================

void loop()
{
  // ===================================================
  // FLEX SENSOR
  // ===================================================

  int flexValue = analogRead(FLEX_PIN);

  // Serial Monitor
  Serial.print("FLEX: ");
  Serial.println(flexValue);


  // TFT
  tft.fillRect(0, 0, 160, 20, ST77XX_BLACK);

  tft.setTextSize(1);
  tft.setTextColor(ST77XX_RED);

  tft.setCursor(5, 5);
  tft.print("FLEX: ");
  tft.print(flexValue);


  // ===================================================
  // ACCELEROMETER
  // ===================================================

  if (mySensor.accelUpdate() == 0)
  {
    float ax = mySensor.accelX();
    float ay = mySensor.accelY();
    float az = mySensor.accelZ();

    // Serial Monitor
    Serial.print("ACC X: ");
    Serial.print(ax, 2);

    Serial.print("  Y: ");
    Serial.print(ay, 2);

    Serial.print("  Z: ");
    Serial.println(az, 2);


    // TFT
    tft.fillRect(0, 25, 160, 40, ST77XX_BLACK);

    tft.setTextSize(1);
    tft.setTextColor(ST77XX_GREEN);

    tft.setCursor(5, 30);
    tft.print("ACCELEROMETER");

    tft.setCursor(5, 45);

    tft.print("X:");
    tft.print(ax, 2);

    tft.print(" Y:");
    tft.print(ay, 2);

    tft.print(" Z:");
    tft.print(az, 2);
  }


  // ===================================================
  // GYROSCOPE
  // ===================================================

  if (mySensor.gyroUpdate() == 0)
  {
    float gx = mySensor.gyroX();
    float gy = mySensor.gyroY();
    float gz = mySensor.gyroZ();

    // Serial Monitor
    Serial.print("GYRO X: ");
    Serial.print(gx, 2);

    Serial.print("  Y: ");
    Serial.print(gy, 2);

    Serial.print("  Z: ");
    Serial.println(gz, 2);


    // TFT
    tft.fillRect(0, 70, 160, 40, ST77XX_BLACK);

    tft.setTextColor(ST77XX_YELLOW);

    tft.setCursor(5, 73);
    tft.print("GYROSCOPE");

    tft.setCursor(5, 88);

    tft.print("X:");
    tft.print(gx, 1);

    tft.print(" Y:");
    tft.print(gy, 1);

    tft.print(" Z:");
    tft.print(gz, 1);
  }


  // ===================================================
  // MAGNETOMETER
  // ===================================================

  if (mySensor.magUpdate() == 0)
  {
    float mx = mySensor.magX();
    float my = mySensor.magY();
    float mz = mySensor.magZ();

    // Serial Monitor
    Serial.print("MAG X: ");
    Serial.print(mx, 2);

    Serial.print("  Y: ");
    Serial.print(my, 2);

    Serial.print("  Z: ");
    Serial.println(mz, 2);


    // TFT
    tft.fillRect(0, 115, 160, 13, ST77XX_BLACK);

    tft.setTextColor(ST77XX_CYAN);

    tft.setCursor(5, 116);
    tft.print("MAG: ");

    tft.print(mx, 1);
    tft.print(",");
    tft.print(my, 1);
    tft.print(",");
    tft.print(mz, 1);
  }


  Serial.println("-----------------------");

  delay(500);
}