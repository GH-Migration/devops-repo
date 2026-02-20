FROM tomcat:latest

# Ensure the default webapps are present
RUN cp -R /usr/local/tomcat/webapps.dist/* /usr/local/tomcat/webapps

# Copy the WAR file using a relative path from the project root
COPY webapp/target/*.war /usr/local/tomcat/webapps