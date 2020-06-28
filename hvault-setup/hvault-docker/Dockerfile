FROM alpine:latest

RUN apk add jq
RUN apk add curl

COPY volumes/config/vaultrun.sh /usr/local/bin/vaultrun.sh
ENTRYPOINT 'vaultrun.sh'

