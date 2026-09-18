FROM tomcat:9.0-jdk17

RUN rm -rf /usr/local/tomcat/webapps/*

# Match any generated .war file in target
COPY target/*.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080
CMD ["catalina.sh", "run"]