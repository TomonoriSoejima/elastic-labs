import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class MountInfoParser {

    private static final String POD_REGEX = ".*/pods/([^/]+)/.*";
    private static final String CONTAINER_ID_REGEX = ".*/containers/([a-f0-9]{64})/.*";

    public static void main(String[] args) {
        Path mountInfoPath = Paths.get("./mountinfo");

        try {
            List<String> lines = Files.readAllLines(mountInfoPath);

            String containerId = null;
            String podUid = null;

            for (String line : lines) {
                // Match Kubernetes Pod UID
                Matcher podMatcher = Pattern.compile(POD_REGEX).matcher(line);
                if (podMatcher.find()) {
                    podUid = podMatcher.group(1);
                }

                // Match Container ID
                Matcher containerMatcher = Pattern.compile(CONTAINER_ID_REGEX).matcher(line);
                if (containerMatcher.find()) {
                    containerId = containerMatcher.group(1);
                }
            }

            System.out.println("Container ID: " + (containerId != null ? containerId : "Not Found"));
            System.out.println("Kubernetes Pod UID: " + (podUid != null ? podUid : "Not Found"));

        } catch (IOException e) {
            System.err.println("Failed to read mountinfo file: " + e.getMessage());
        }
    }
}