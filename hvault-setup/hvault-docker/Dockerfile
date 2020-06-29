FROM amazon/aws-cli

RUN yum install -y jq
RUN yum install -y curl

COPY volumes/config/vaultrun.sh /usr/local/bin/vaultrun.sh
ENTRYPOINT 'vaultrun.sh'

