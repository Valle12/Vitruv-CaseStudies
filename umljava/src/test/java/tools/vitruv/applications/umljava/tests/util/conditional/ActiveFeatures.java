package tools.vitruv.applications.umljava.tests.util.conditional;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.Set;
import org.json.JSONArray;

public final class ActiveFeatures {
  private static final String REACTIONS_DIR_PROPERTY = "umljava.reactions.dir";
  private static final String REACTIONS_SUFFIX = "-reactions";
  private static final String JSON_EXTENSION = ".json";
  private static volatile Snapshot snapshot;

  private ActiveFeatures() {}

  public static boolean isActive(String feature) {
    Snapshot s = snapshot();
    return s.allActive || s.features.contains(feature);
  }

  private static Snapshot snapshot() {
    Snapshot s = snapshot;
    if (s == null) {
      synchronized (ActiveFeatures.class) {
        s = snapshot;
        if (s == null) {
          s = load();
          snapshot = s;
        }
      }
    }
    return s;
  }

  private static Snapshot load() {
    String dir = System.getProperty(REACTIONS_DIR_PROPERTY);
    if (dir == null || dir.isBlank()) {
      return Snapshot.allActive();
    }
    // Defensive: scripts saved with CRLF (e.g. umljava-tests on Windows) can leave a
    // trailing \r in the property value when invoked from WSL. Strip it.
    dir = dir.strip();

    Path reactionsDir = Path.of(dir).toAbsolutePath().normalize();
    Path json = locateConfigJson(reactionsDir);
    if (json == null || !Files.isRegularFile(json)) {
      return Snapshot.allActive();
    }

    try {
      String content = Files.readString(json);
      JSONArray arr = new JSONArray(content);
      Set<String> features = new LinkedHashSet<>(arr.length());
      for (int i = 0; i < arr.length(); i++) {
        features.add(arr.getString(i));
      }

      return new Snapshot(features, false);
    } catch (IOException e) {
      return Snapshot.allActive();
    }
  }

  private static Path locateConfigJson(Path reactionsDir) {
    String name = reactionsDir.getFileName() == null ? "" : reactionsDir.getFileName().toString();
    if (!name.endsWith(REACTIONS_SUFFIX)) {
      return null;
    }

    String configName = name.substring(0, name.length() - REACTIONS_SUFFIX.length());
    Path parent = reactionsDir.getParent();
    if (parent == null) {
      return null;
    }

    return parent.resolve(configName + JSON_EXTENSION);
  }

  private static final class Snapshot {
    final Set<String> features;
    final boolean allActive;

    Snapshot(Set<String> features, boolean allActive) {
      this.features = features;
      this.allActive = allActive;
    }

    static Snapshot allActive() {
      return new Snapshot(Collections.emptySet(), true);
    }
  }
}
