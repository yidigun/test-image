FROM docker.io/library/node:22-alpine

ARG IMG_TAG
ARG IMG_NAME
ARG LANG=ko_KR.UTF-8
ARG TZ=Asia/Seoul
ARG APPROOT=/webapp
ARG NODEAPP=app.js
ARG SERVERPORT=8080

ENV IMG_NAME=$IMG_NAME
ENV IMG_TAG=$IMG_TAG
ENV LANG=$LANG
ENV TZ=$TZ
ENV APPROOT=$APPROOT
ENV NODEAPP=$NODEAPP
ENV SERVERPORT=$SERVERPORT

WORKDIR $APPROOT
RUN apk add --update curl busybox-extras
COPY nodeapp.sh /
COPY app.js package*.json $APPROOT
RUN npm ci --only=production

EXPOSE $SERVERPORT/tcp

ENTRYPOINT [ "/nodeapp.sh" ]
CMD [ "run" ]
