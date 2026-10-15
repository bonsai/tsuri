package jp.bonsai.tsuri;

import jakarta.persistence.EntityManager;
import jakarta.persistence.EntityNotFoundException;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import java.time.Instant;
import java.util.*;

@RestController
@RequestMapping("/api/game")
@CrossOrigin
public class GameController {
    private final EntityManager db;
    public GameController(EntityManager db) { this.db = db; }

    @PostMapping("/start")
    @Transactional
    public Map<String, Object> start() {
        GameSession session = new GameSession();
        session.status = "IDLE";
        db.persist(session);
        db.flush();
        return state(session);
    }

    @GetMapping("/state")
    @Transactional(readOnly = true)
    public Map<String, Object> current(@RequestParam(required = false) Long sessionId) {
        GameSession session = sessionId == null
            ? db.createQuery("select s from GameSession s order by s.id desc", GameSession.class)
                .setMaxResults(1).getResultStream().findFirst().orElse(null)
            : db.find(GameSession.class, sessionId);
        if (session == null) return Map.of("status", "NO_SESSION", "score", 0, "catches", 0, "casts", 0);
        return state(session);
    }

    @PostMapping("/event")
    @Transactional
    public Map<String, Object> event(@RequestBody Map<String, Object> body) {
        Long id = Long.valueOf(String.valueOf(body.getOrDefault("sessionId", "0")));
        GameSession session = db.find(GameSession.class, id);
        if (session == null) throw new EntityNotFoundException("Session not found: " + id);
        String type = String.valueOf(body.getOrDefault("type", "")).toUpperCase(Locale.ROOT);
        switch (type) {
            case "CAST" -> { session.status = "WAITING"; session.casts++; }
            case "BITE" -> session.status = "BITE";
            case "REEL" -> {
                if ("BITE".equals(session.status) || "WAITING".equals(session.status)) {
                    session.status = "CAUGHT";
                    session.catches++;
                    session.score += 10;
                    db.persist(new CatchRecord(session.id, "アジ", 20, 10));
                } else {
                    session.status = "REELING";
                }
            }
            case "RESET" -> session.status = "IDLE";
            case "END" -> { session.status = "ENDED"; session.endedAt = Instant.now(); }
            default -> throw new IllegalArgumentException("Unknown event type: " + type);
        }
        db.flush();
        return state(session);
    }

    @GetMapping("/history")
    @Transactional(readOnly = true)
    public List<Map<String, Object>> history() {
        return db.createQuery("select c from CatchRecord c order by c.caughtAt desc", CatchRecord.class)
            .setMaxResults(100).getResultList().stream().map(c -> {
                Map<String, Object> item = new LinkedHashMap<>();
                item.put("id", c.id); item.put("sessionId", c.sessionId);
                item.put("caughtAt", c.caughtAt); item.put("species", c.species);
                item.put("sizeCm", c.sizeCm); item.put("points", c.points);
                return item;
            }).toList();
    }

    private Map<String, Object> state(GameSession s) {
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("sessionId", s.id); out.put("status", s.status); out.put("score", s.score);
        out.put("catches", s.catches); out.put("casts", s.casts);
        out.put("startedAt", s.startedAt); out.put("endedAt", s.endedAt);
        return out;
    }
}
