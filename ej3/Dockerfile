FROM debian:bookworm-slim AS builder

WORKDIR /app

COPY main.adb .

RUN apt-get update && \
    apt-get install -y --no-install-recommends gnat && \
    rm -rf /var/lib/apt/lists/* && \
    gnatmake main.adb

FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends openssh-server libgnat-12 && \
    rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --shell /bin/bash runner && \
    mkdir -p /var/run/sshd /home/runner/.ssh && \
    chown -R runner:runner /home/runner/.ssh && \
    chmod 700 /home/runner/.ssh

WORKDIR /app
COPY --from=builder /app/main .
RUN chmod +x ./main
EXPOSE 22
CMD ["/bin/sh", "-c", "chmod 700 /home/runner/.ssh && if [ -f /home/runner/.ssh/authorized_keys ]; then chmod 600 /home/runner/.ssh/authorized_keys || true; fi && chown -R runner:runner /home/runner/.ssh || true && exec /usr/sbin/sshd -D"]
