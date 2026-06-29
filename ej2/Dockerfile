FROM gcc:bookworm as builder

WORKDIR /app
COPY parte2_code.c .
RUN gcc -o parte2_code parte2_code.c

FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends openssh-server && \
    rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --shell /bin/bash runner && \
    mkdir -p /home/runner/.ssh && \
    chown -R runner:runner /home/runner/.ssh && \
    chmod 700 /home/runner/.ssh && \
    ssh-keygen -t ed25519 -N '' -f /home/runner/ssh_host_ed25519_key && \
    chown runner:runner /home/runner/ssh_host_ed25519_key /home/runner/ssh_host_ed25519_key.pub && \
    chmod 600 /home/runner/ssh_host_ed25519_key && \
    printf '%s\n' \
      'Port 2222' \
      'ListenAddress 0.0.0.0' \
      'HostKey /home/runner/ssh_host_ed25519_key' \
      'PidFile /tmp/sshd.pid' \
      'PermitRootLogin no' \
      'PasswordAuthentication no' \
      'PubkeyAuthentication yes' \
      'AuthorizedKeysFile /home/runner/.ssh/authorized_keys' \
      'StrictModes no' \
      'AllowUsers runner' \
      'UsePAM no' \
      > /home/runner/sshd_config && \
    chown runner:runner /home/runner/sshd_config

WORKDIR /app
COPY --from=builder /app/parte2_code .
RUN mv ./parte2_code ./parte2_code.bin && \
    printf '%s\n' '#!/bin/sh' 'exec stdbuf -oL -eL /app/parte2_code.bin "$@"' > ./parte2_code && \
    chmod +x ./parte2_code ./parte2_code.bin
EXPOSE 2222

USER runner

CMD ["/usr/sbin/sshd", "-D", "-e", "-f", "/home/runner/sshd_config"]
