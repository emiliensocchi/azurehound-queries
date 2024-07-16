FROM ubuntu:latest

RUN apt-get update
RUN apt-get install jq git -y

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]