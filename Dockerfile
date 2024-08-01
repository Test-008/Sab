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

Base Image: Uses the sapmachine:17-jdk-headless-ubuntu image, which includes the JDK needed for building Java applications.
Install Dependencies: Updates package lists and installs sudo and curl.
User Creation: Creates a jenkins user and group with specified UID and GID.
Working Directory: Sets the working directory to /app.
Copy Source Code: Copies the entire source code into the image.
Build Application: Runs the build command (./gradlew build), which compiles the application and creates the build artifacts.
----
Base Image: Uses the sapmachine:jre-headless-ubuntu-17 image, which includes only the JRE needed to run Java applications.
Create Directories and Symlink: Creates necessary directories and a symlink for logs.
User Creation: Recreates the jenkins user and group with the same UID and GID as in the build stage.
Copy Build Artifacts: Copies the built application JAR from the build stage into the runtime stage image using COPY --from=build.
Set User: Sets the jenkins user as the default user.
Entry Point: Defines the entry point to run the application with specified environment variables.

Benefits:

    Smaller Image Size: The runtime stage uses a smaller base image (jre-headless-ubuntu-17) that contains only the JRE, not the full JDK, which reduces the final image size and attack surface.
    Separation of Concerns: By separating the build and runtime stages, you ensure that the final image only contains the necessary runtime dependencies and the built application artifact, making it cleaner and more secure.
    Build Efficiency: The build stage can include all necessary tools and dependencies for building the application, which can be excluded from the final runtime image, improving efficiency.
    Reusability: The build stage can be reused for building other versions or parts of the application, while the runtime stage can remain consistent.
    Security: By keeping the build tools and dependencies out of the runtime image, you reduce the potential vulnerabilities in the final deployed container.
    Consistency: Ensures that the build environment does not interfere with the runtime environment, leading to more predictable and consistent behavior in production.

This multistage approach enhances the overall Docker image management, providing a more efficient, secure, and maintainable solution.
