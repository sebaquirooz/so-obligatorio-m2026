FROM gcc:bookworm as builder

WORKDIR /app
COPY parte2_code.c .
RUN gcc -o parte2_code parte2_code.c

FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends openssh-server && \
    rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --shell /bin/bash runner && \
    mkdir -p /var/run/sshd /home/runner/.ssh && \
    chown -R runner:runner /home/runner/.ssh && \
    chmod 700 /home/runner/.ssh

WORKDIR /app
COPY --from=builder /app/parte2_code .
RUN chmod +x ./parte2_code
EXPOSE 22
CMD ["/bin/sh", "-c", "chmod 700 /home/runner/.ssh && if [ -f /home/runner/.ssh/authorized_keys ]; then chmod 600 /home/runner/.ssh/authorized_keys || true; fi && chown -R runner:runner /home/runner/.ssh || true && exec /usr/sbin/sshd -D"]
