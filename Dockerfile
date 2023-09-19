FROM openjdk:17-jre

COPY target/*.war petclinic.war

ENTRYPOINT ["java"]
CMD ["-jar","petclinic.war"]
