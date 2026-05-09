FROM docker.aa.com/prod/grafbase/nexus:latest

WORKDIR /etc

COPY ./conf/nexus.toml ./nexus.toml
