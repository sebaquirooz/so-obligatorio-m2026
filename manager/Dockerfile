FROM debian:bookworm-slim

WORKDIR /app

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends nginx openssh-client python3 && \
    rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --shell /bin/sh manager && \
    mkdir -p /home/manager/.ssh && \
    chmod 700 /home/manager/.ssh
RUN mkdir -p /var/www/html

COPY index.html /var/www/html/index.html
COPY nginx.conf /etc/nginx/nginx.conf
COPY monitor.py /app/monitor.py
COPY start.sh /app/start.sh
RUN sed -i 's/\r$//' /app/start.sh && \
    chmod +x /app/start.sh && \
    printf '%s\n' '#!/bin/sh' 'exec ssh ej1 "$@"' > /usr/local/bin/run-ej1 && \
    printf '%s\n' '#!/bin/sh' "exec ssh ej2 'cd /app && ./parte2_code'" > /usr/local/bin/run-ej2 && \
    printf '%s\n' '#!/bin/sh' "exec ssh -tt ej3 'cd /app && ./main'" > /usr/local/bin/run-ej3 && \
    chmod +x /usr/local/bin/run-ej1 /usr/local/bin/run-ej2 /usr/local/bin/run-ej3 && \
    chown -R manager:manager /app /var/www/html /home/manager/.ssh

EXPOSE 8080

USER manager:root

ENTRYPOINT ["/app/start.sh"]
