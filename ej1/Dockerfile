FROM ubuntu:20.04
WORKDIR /app
COPY paddock_manager_fixed.sh .

RUN chmod +x paddock_manager_fixed.sh
ENTRYPOINT ["./paddock_manager_fixed.sh"]