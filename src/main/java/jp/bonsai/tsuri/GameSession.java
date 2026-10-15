package jp.bonsai.tsuri;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
public class GameSession {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    public Long id;
    public Instant startedAt = Instant.now();
    public Instant endedAt;
    public String status = "IDLE";
    public int score = 0;
    public int casts = 0;
    public int catches = 0;
}
