# tsuri

Processing 4 client + Spring Boot Java server + SQLite database.

## Run server on Windows

Install JDK 21 and Maven. From the repository root:

```powershell
.\run-server.ps1
```

The server listens at `http://localhost:8080`. SQLite data is stored in `data/tsuri.db`.

## Run clients

### Browser fishing game

Start the Java server, then open `http://localhost:8080/` in a browser (Spring Boot serves the page from `src/main/resources/static/`). `src/main/resources/static/index.html` serves a responsive Canvas fishing game: cast, wait for a bite, and reel in a catch. If the server is unavailable, the page falls back to local demo mode; catches are only persisted when the Java server is running.

### Processing client

Install Processing 4, open `client/tsuri/tsuri.pde`, and press Run. The default server URL is `http://localhost:8080`. Change `serverUrl` in the sketch to connect to another server.

## Controls

- C or click: cast
- B: simulate a bite
- R: reel
- N: new session

The browser scene shows only the first-person boat bow, horizon, and ocean surface; there is no underwater view. A fish appears above the surface only after a successful catch. Successful reels save catch records to SQLite when the Java server is running. Camera footage is not stored or uploaded.

## API

- `POST /api/game/start`
- `GET /api/game/state`
- `POST /api/game/event` with `{"sessionId":1,"type":"CAST"}`
- `GET /api/game/history`

The browser client uses the existing HTTP API and keyboard/mouse controls. Camera gesture recognition, WebSocket push, automated integration tests, and packaged Windows launch scripts remain follow-up work.
