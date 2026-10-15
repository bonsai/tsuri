# tsuri

Processing 4 client + Spring Boot Java server + H2 database.

## Run server on Windows

Install JDK 21 and Maven. From the repository root:

```powershell
mvn spring-boot:run
```

Server URL: http://localhost:8080

## Run client

Install Processing 4, open `client/tsuri/tsuri.pde`, and press Run. The default server URL is `http://localhost:8080`. Change `serverUrl` in the sketch to connect to another server.

## Controls

- C or click: cast
- B: simulate a bite
- R: reel
- N: new session

The scene shows the boat bow and ocean surface only; there is no underwater view. Successful reels save sample catches to H2. Camera footage is not stored or uploaded.

## API

- `POST /api/game/start`
- `GET /api/game/state`
- `POST /api/game/event` with `{"sessionId":1,"type":"CAST"}`
- `GET /api/game/history`

This MVP uses HTTP requests and keyboard/mouse test controls. Camera gesture recognition, WebSocket push, tests, and packaged Windows launch scripts are follow-up work.
