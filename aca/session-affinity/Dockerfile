# build
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /src
COPY demoapp/pom.xml .
RUN mvn -q -e -DskipTests dependency:resolve
COPY demoapp/src ./src
RUN mvn -q -DskipTests package

# run
FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=build /src/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java","-jar","/app/app.jar"]
