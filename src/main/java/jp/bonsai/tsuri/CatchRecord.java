package jp.bonsai.tsuri;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
public class CatchRecord {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    public Long id;
    public Long sessionId;
    public Instant caughtAt = Instant.now();
    public String species = "アジ";
    public int sizeCm = 20;
    public int points = 10;

    public CatchRecord() {}
    public CatchRecord(Long sessionId, String species, int sizeCm, int points) {
        this.sessionId = sessionId;
        this.species = species;
        this.sizeCm = sizeCm;
        this.points = points;
        this.caughtAt = Instant.now();
    }
}
