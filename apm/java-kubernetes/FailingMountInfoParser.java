import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;

public class FailingMountInfoParser {

    public static void main(String[] args) {
        Path mountInfoPath = Paths.get("./mountinfo");

        try {
            List<String> lines = Files.readAllLines(mountInfoPath);

            String containerId = null;
            String podUid = null;

            for (String line : lines) {
                // Match container ID directly using regex
                if (line.contains("/containers/")) {
                    String[] parts = line.split("/");
                    for (String part : parts) {
                        if (part.matches("[a-f0-9]{64}")) {
                            containerId = part;
                            break;
                        }
                    }
                }

                // Attempt to match Kubernetes Pod UID (incorrectly)
                if (line.contains("/pods/")) {
                    String[] parts = line.split("/");
                    if (parts.length > 3) {
                        podUid = parts[3]; // Incorrect assumption about Pod UID location
                    }
                }
            }

            System.out.println("Container ID: " + (containerId != null ? containerId : "Not Found"));
            System.out.println("Kubernetes Pod UID: " + (podUid != null ? podUid : "Not Found"));

        } catch (IOException e) {
            System.err.println("Failed to read mountinfo file: " + e.getMessage());
        }
    }
}