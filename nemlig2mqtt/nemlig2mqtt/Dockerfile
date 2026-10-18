FROM lordmike/nemlig2mqtt:latest
RUN apk add --no-cache jq
COPY run.sh /run.sh
RUN chmod a+x /run.sh
ENTRYPOINT ["/run.sh"]
