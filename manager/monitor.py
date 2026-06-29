#!/usr/bin/env python3
import json
import os
import socket
import time
from datetime import datetime, timezone
from http.client import HTTPConnection
from urllib.parse import quote

SOCKET_PATH = "/var/run/docker.sock"
STATUS_PATH = "/var/www/html/status.json"
SERVICES = ("manager", "ej1", "ej2", "ej3")


class UnixHTTPConnection(HTTPConnection):
    def __init__(self, socket_path):
        super().__init__("localhost")
        self.socket_path = socket_path

    def connect(self):
        self.sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.sock.connect(self.socket_path)


def docker_get(path):
    conn = UnixHTTPConnection(SOCKET_PATH)
    conn.request("GET", path)
    response = conn.getresponse()
    body = response.read()
    conn.close()

    if response.status >= 400:
        raise RuntimeError(f"Docker API {path} returned {response.status}")

    return json.loads(body.decode("utf-8"))


def cpu_percent(stats):
    cpu = stats.get("cpu_stats", {})
    precpu = stats.get("precpu_stats", {})
    cpu_delta = (
        cpu.get("cpu_usage", {}).get("total_usage", 0)
        - precpu.get("cpu_usage", {}).get("total_usage", 0)
    )
    system_delta = cpu.get("system_cpu_usage", 0) - precpu.get("system_cpu_usage", 0)
    online_cpus = cpu.get("online_cpus") or len(cpu.get("cpu_usage", {}).get("percpu_usage", [])) or 1

    if cpu_delta > 0 and system_delta > 0:
        return round((cpu_delta / system_delta) * online_cpus * 100, 2)

    return 0.0


def memory_usage(stats):
    memory = stats.get("memory_stats", {})
    usage = memory.get("usage", 0)
    cache = memory.get("stats", {}).get("cache", 0)
    limit = memory.get("limit", 0)
    active_usage = max(usage - cache, 0)
    percent = round((active_usage / limit) * 100, 2) if limit else 0.0

    return {
        "usageBytes": active_usage,
        "limitBytes": limit,
        "percent": percent,
    }


def network_usage(stats):
    networks = stats.get("networks", {}) or {}
    rx = sum(interface.get("rx_bytes", 0) for interface in networks.values())
    tx = sum(interface.get("tx_bytes", 0) for interface in networks.values())

    return {"rxBytes": rx, "txBytes": tx}


def collect_status():
    filters = quote(json.dumps({"label": ["com.docker.compose.project"]}))
    containers = docker_get(f"/containers/json?all=1&filters={filters}")
    by_service = {}

    for container in containers:
        service = container.get("Labels", {}).get("com.docker.compose.service")
        if service in SERVICES:
            by_service[service] = container

    result = []
    for service in SERVICES:
        container = by_service.get(service)

        if not container:
            result.append({
                "service": service,
                "name": service,
                "state": "missing",
                "running": False,
                "cpuPercent": 0.0,
                "memory": {"usageBytes": 0, "limitBytes": 0, "percent": 0.0},
                "network": {"rxBytes": 0, "txBytes": 0},
            })
            continue

        stats = docker_get(f"/containers/{container['Id']}/stats?stream=false")
        name = (container.get("Names") or [service])[0].lstrip("/")

        result.append({
            "service": service,
            "name": name,
            "state": container.get("State", "unknown"),
            "status": container.get("Status", ""),
            "running": container.get("State") == "running",
            "cpuPercent": cpu_percent(stats),
            "memory": memory_usage(stats),
            "network": network_usage(stats),
        })

    return {
        "updatedAt": datetime.now(timezone.utc).isoformat(),
        "containers": result,
    }


def write_status(payload):
    tmp_path = f"{STATUS_PATH}.tmp"
    with open(tmp_path, "w", encoding="utf-8") as status_file:
        json.dump(payload, status_file, ensure_ascii=False)
    os.replace(tmp_path, STATUS_PATH)


def main():
    while True:
        try:
            payload = collect_status()
        except Exception as exc:
            payload = {
                "updatedAt": datetime.now(timezone.utc).isoformat(),
                "error": str(exc),
                "containers": [],
            }

        write_status(payload)
        time.sleep(2)


if __name__ == "__main__":
    main()
