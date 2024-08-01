# Stage 1: Build Stage
FROM docker-hub.common.repositories.cloud.sap/sapmachine:17-jdk-headless-ubuntu as build

# Create necessary directories and install dependencies
RUN apt-get update && apt-get install -y sudo curl

# Create Jenkins user and group
ARG GID=1000
ARG UID=1000
RUN groupadd -g ${GID} jenkins && \
    useradd -u ${UID} -g jenkins -m jenkins && \
    echo "jenkins:jenkins" | chpasswd && adduser jenkins sudo

# Set the working directory and copy the application source code
WORKDIR /src
COPY . .

# Build the application
RUN ./gradlew build

# Stage 2: Runtime Stage
FROM docker-hub.common.repositories.cloud.sap/sapmachine:jre-headless-ubuntu-17

# Create necessary directories and symlink
RUN mkdir -p /opt/apache-tomcat-7.0.70 && ln -s /logs /opt/apache-tomcat-7.0.70/logs

# Create Jenkins user and group
ARG GID=1000
ARG UID=1000
RUN groupadd -g ${GID} jenkins && \
    useradd -u ${UID} -g jenkins -m jenkins && \
    echo "jenkins:jenkins" | chpasswd && adduser jenkins sudo

# Copy the built application artifact from the build stage
COPY --from=build /app/build/libs/ComponentMappingMessaging*.jar /opt/ComponentMappingMessaging.jar

# Set the user to jenkins
USER jenkins

# Set the entry point to run the application
ENTRYPOINT ["/bin/sh", "-c", "exec java $JAVA_OPTS -Dspring.profiles.active=$SPRING_PROFILES_ACTIVE -jar /opt/ComponentMappingMessaging.jar"]

---------
