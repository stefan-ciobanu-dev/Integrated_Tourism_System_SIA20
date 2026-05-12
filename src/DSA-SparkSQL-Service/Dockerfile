# Stage 1: Build the REST data service JAR
FROM eclipse-temurin:21-jdk-alpine AS builder
WORKDIR /build
RUN apk add --no-cache maven
COPY pom.xml .
COPY src/ src/
RUN mvn clean package -DskipTests -q

# Stage 2: Spark Thrift Server with the custom REST JAR
FROM apache/spark:3.5.3
USER root

# Install netcat for health check in startup script
RUN apt-get update && apt-get install -y --no-install-recommends netcat-openbsd && rm -rf /var/lib/apt/lists/*

# Copy our REST data service JAR into Spark's jars folder so it's on the classpath
COPY --from=builder /build/target/rest-data-service-1.0.jar /opt/spark/jars/rest-data-service.jar

# Copy the startup script
COPY start-thriftserver.sh /opt/spark/bin/start-thriftserver.sh
RUN chmod +x /opt/spark/bin/start-thriftserver.sh

# Derby metastore directory
RUN mkdir -p /tmp/hive && chmod 777 /tmp/hive

USER spark

EXPOSE 10000 4040

ENTRYPOINT ["/opt/spark/bin/start-thriftserver.sh"]
