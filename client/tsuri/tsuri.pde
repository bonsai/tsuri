import java.net.HttpURLConnection;
import java.net.URL;
import java.io.OutputStream;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;

String serverUrl = "http://localhost:8080";
volatile long sessionId = 0;
volatile String gameStatus = "CONNECTING";
volatile int score = 0;
volatile int catches = 0;
volatile int casts = 0;
volatile String connectionStatus = "Connecting to Spring Boot...";
int waveOffset = 0;
boolean showHelp = true;

void setup() {
  size(1100, 700);
  smooth(4);
  textFont(createFont("SansSerif", 18));
  newSession();
}

void draw() {
  drawOcean();
  drawBoatBow();
  drawHud();
  waveOffset = (waveOffset + 1) % 10000;
}

void drawOcean() {
  background(11, 38, 69);
  noStroke();
  for (int y = 0; y < height * 0.72; y += 4) {
    float t = map(y, 0, height * 0.72, 0, 1);
    fill(lerpColor(color(23, 87, 133), color(3, 30, 57), t));
    rect(0, y, width, 4);
  }
  // Horizon and animated surface only; never draw an underwater view.
  stroke(127, 211, 235, 150);
  strokeWeight(2);
  line(0, height * 0.52, width, height * 0.52);
  noFill();
  for (int row = 0; row < 8; row++) {
    stroke(69, 172, 204, 45 + row * 5);
    beginShape();
    for (int x = -20; x <= width + 20; x += 12) {
      float y = height * 0.55 + row * 17 + sin((x + waveOffset * (1 + row * 0.12)) * 0.012) * (4 + row);
      vertex(x, y);
    }
    endShape();
  }
}

void drawBoatBow() {
  noStroke();
  fill(8, 15, 24, 100);
  beginShape();
  vertex(width * 0.24, height);
  vertex(width * 0.39, height * 0.80);
  vertex(width * 0.61, height * 0.80);
  vertex(width * 0.76, height);
  endShape(CLOSE);
  fill(95, 101, 105);
  beginShape();
  vertex(width * 0.20, height);
  vertex(width * 0.42, height * 0.79);
  vertex(width * 0.58, height * 0.79);
  vertex(width * 0.80, height);
  endShape(CLOSE);
  fill(166, 171, 171);
  beginShape();
  vertex(width * 0.31, height);
  vertex(width * 0.445, height * 0.84);
  vertex(width * 0.555, height * 0.84);
  vertex(width * 0.69, height);
  endShape(CLOSE);
  stroke(224, 217, 186);
  strokeWeight(3);
  line(width * 0.42, height * 0.80, width * 0.58, height * 0.80);
  noStroke();
}

void drawHud() {
  fill(0, 0, 0, 135);
  rect(20, 20, 350, 145, 12);
  fill(255);
  textSize(22);
  text("TSURI / OPEN OCEAN", 38, 51);
  textSize(16);
  text("状態: " + gameStatus, 38, 80);
  text("釣果: " + catches + "   スコア: " + score, 38, 107);
  text("キャスト: " + casts + "   Session: " + (sessionId == 0 ? "-" : sessionId), 38, 134);

  fill(0, 0, 0, 155);
  rect(20, height - 78, width - 40, 55, 10);
  fill(255);
  textSize(15);
  text("C / クリック: キャスト   B: アタリ（テスト）   R / クリック: リール   N: 新規セッション", 36, height - 45);
  fill(connectionStatus.startsWith("Connected") ? color(116, 235, 160) : color(255, 206, 120));
  text(connectionStatus, 38, 190);
  if ("CAUGHT".equals(gameStatus)) {
    fill(255, 236, 140);
    textAlign(CENTER, CENTER);
    textSize(38);
    text("HIT!  FISH CAUGHT!", width / 2, height * 0.37);
    textAlign(LEFT, BASELINE);
  }
}

void keyPressed() {
  if (key == 'c' || key == 'C') sendEvent("CAST");
  if (key == 'b' || key == 'B') sendEvent("BITE");
  if (key == 'r' || key == 'R') sendEvent("REEL");
  if (key == 'n' || key == 'N') newSession();
  if (key == 'h' || key == 'H') showHelp = !showHelp;
}

void mousePressed() {
  if ("BITE".equals(gameStatus) || "WAITING".equals(gameStatus) || "REELING".equals(gameStatus)) {
    sendEvent("REEL");
  } else {
    sendEvent("CAST");
  }
}

void newSession() {
  connectionStatus = "Connecting to Spring Boot...";
  request("POST", "/api/game/start", "{}", true);
}

void sendEvent(String type) {
  if (sessionId == 0) {
    connectionStatus = "Start the Spring Boot server first.";
    return;
  }
  String json = "{\"sessionId\":" + sessionId + ",\"type\":\"" + type + "\"}";
  request("POST", "/api/game/event", json, false);
}

void request(String method, String path, String body, boolean startRequest) {
  Thread worker = new Thread(() -> {
    HttpURLConnection conn = null;
    try {
      conn = (HttpURLConnection) new URL(serverUrl + path).openConnection();
      conn.setRequestMethod(method);
      conn.setConnectTimeout(2500);
      conn.setReadTimeout(2500);
      conn.setRequestProperty("Content-Type", "application/json; charset=utf-8");
      if ("POST".equals(method)) {
        conn.setDoOutput(true);
        try (OutputStream out = conn.getOutputStream()) {
          out.write(body.getBytes(StandardCharsets.UTF_8));
        }
      }
      int code = conn.getResponseCode();
      BufferedReader reader = new BufferedReader(new InputStreamReader(
        code < 400 ? conn.getInputStream() : conn.getErrorStream(), StandardCharsets.UTF_8));
      StringBuilder response = new StringBuilder();
      String line;
      while ((line = reader.readLine()) != null) response.append(line);
      reader.close();
      JSONObject data = parseJSONObject(response.toString());
      if (data != null) {
        if (data.hasKey("sessionId")) sessionId = data.getLong("sessionId");
        if (data.hasKey("status")) gameStatus = data.getString("status");
        if (data.hasKey("score")) score = data.getInt("score");
        if (data.hasKey("catches")) catches = data.getInt("catches");
        if (data.hasKey("casts")) casts = data.getInt("casts");
      }
      connectionStatus = code >= 200 && code < 300
        ? "Connected: " + serverUrl : "Server error HTTP " + code;
    } catch (Exception e) {
      connectionStatus = "Server unavailable. Start ./mvnw spring-boot:run";
    } finally {
      if (conn != null) conn.disconnect();
    }
  });
  worker.setDaemon(true);
  worker.start();
}
