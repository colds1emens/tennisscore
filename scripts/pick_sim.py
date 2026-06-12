#!/usr/bin/env python3
"""Выбор самого нового доступного iPhone-симулятора (UDID в stdout).

Сортировка: версия iOS-рантайма, затем Pro Max > Pro > остальные, затем имя.
"""

import json
import subprocess
import sys


def runtime_version(runtime_id: str) -> list[int]:
    if "iOS-" not in runtime_id:
        return [0]
    tail = runtime_id.split("iOS-")[-1]
    parts = []
    for chunk in tail.split("-"):
        if chunk.isdigit():
            parts.append(int(chunk))
    return parts or [0]


def model_rank(name: str) -> int:
    if "Pro Max" in name:
        return 2
    if "Pro" in name:
        return 1
    return 0


def main() -> int:
    raw = subprocess.run(
        ["xcrun", "simctl", "list", "-j", "devices", "available"],
        capture_output=True,
        text=True,
        check=True,
    ).stdout
    data = json.loads(raw)
    phones = [
        (runtime, device)
        for runtime, devices in data["devices"].items()
        for device in devices
        if "iPhone" in device["name"] and device.get("isAvailable")
    ]
    if not phones:
        print("Нет доступных iPhone-симуляторов", file=sys.stderr)
        return 1
    phones.sort(
        key=lambda pair: (
            runtime_version(pair[0]),
            model_rank(pair[1]["name"]),
            pair[1]["name"],
        )
    )
    print(phones[-1][1]["udid"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
