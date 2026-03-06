FROM openjdk:17-slim

WORKDIR /app

# Copy Java files and data file
COPY FailingMountInfoParser.java .
COPY MountInfoParser.java .
COPY mountinfo .

# Compile Java files
RUN javac FailingMountInfoParser.java MountInfoParser.java

# Run both programs with labels for clarity
CMD ["sh", "-c", \
  "echo '--- Output from FailingMountInfoParser ---' && \
   java FailingMountInfoParser mountinfo && \
   echo '' && \
   echo '--- Output from MountInfoParser ---' && \
   java MountInfoParser mountinfo"]
