#!/usr/bin/env python3
"""Загрузка скриншотов в App Store Connect (многошаговый протокол).

  python3 scripts/asc_upload_screenshots.py <VERSION_LOC_ID> <DISPLAY_TYPE> <dir>

Для каждого PNG в <dir> (по алфавиту): резервируем appScreenshot, заливаем
байты в выданные uploadOperations, коммитим с MD5. Существующий набор того же
типа переиспользуется; уже загруженные кадры с тем же именем пропускаются.
"""
import hashlib
import json
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import asc

ORDER = ["home", "new105", "105", "victory", "history", "settings"]


def find_or_create_set(tok, loc_id, display_type):
    s, p = asc.request(
        "GET",
        f"/v1/appStoreVersionLocalizations/{loc_id}/appScreenshotSets",
        tok,
    )
    for st in p.get("data", []):
        if st["attributes"].get("screenshotDisplayType") == display_type:
            return st["id"]
    s, p = asc.request(
        "POST", "/v1/appScreenshotSets", tok,
        {"data": {"type": "appScreenshotSets",
                  "attributes": {"screenshotDisplayType": display_type},
                  "relationships": {"appStoreVersionLocalization": {
                      "data": {"type": "appStoreVersionLocalizations", "id": loc_id}}}}},
    )
    if s >= 400:
        print("create set FAIL", json.dumps(p)[:300]); sys.exit(2)
    return p["data"]["id"]


def existing_names(tok, set_id):
    s, p = asc.request("GET", f"/v1/appScreenshotSets/{set_id}/appScreenshots", tok)
    return {x["attributes"].get("fileName") for x in p.get("data", [])}


def upload_one(tok, set_id, path):
    data = open(path, "rb").read()
    name = os.path.basename(path)
    # 1) резерв
    s, p = asc.request(
        "POST", "/v1/appScreenshots", tok,
        {"data": {"type": "appScreenshots",
                  "attributes": {"fileSize": len(data), "fileName": name},
                  "relationships": {"appScreenshotSet": {
                      "data": {"type": "appScreenshotSets", "id": set_id}}}}},
    )
    if s >= 400:
        return f"reserve FAIL {s}: " + json.dumps(p.get('errors', p))[:200]
    shot = p["data"]
    shot_id = shot["id"]
    ops = shot["attributes"]["uploadOperations"]
    # 2) заливка байтов
    for op in ops:
        chunk = data[op["offset"]: op["offset"] + op["length"]]
        tmp = f"/tmp/_ss_chunk_{shot_id}"
        open(tmp, "wb").write(chunk)
        cmd = ["curl", "-s", "-S", "-X", op["method"], op["url"], "--data-binary", f"@{tmp}"]
        for h in op.get("requestHeaders", []):
            cmd += ["-H", f"{h['name']}: {h['value']}"]
        subprocess.run(cmd, capture_output=True)
        os.remove(tmp)
    # 3) коммит
    md5 = hashlib.md5(data).hexdigest()
    s, p = asc.request(
        "PATCH", f"/v1/appScreenshots/{shot_id}", tok,
        {"data": {"type": "appScreenshots", "id": shot_id,
                  "attributes": {"uploaded": True, "sourceFileChecksum": md5}}},
    )
    return "OK" if s < 400 else f"commit FAIL {s}: " + json.dumps(p.get('errors', p))[:200]


def sort_key(fn):
    base = os.path.splitext(fn)[0]
    return ORDER.index(base) if base in ORDER else 99


def main():
    loc_id, display_type, d = sys.argv[1], sys.argv[2], sys.argv[3]
    cfg = asc.load_config()
    tok = asc.make_token(cfg)
    set_id = find_or_create_set(tok, loc_id, display_type)
    have = existing_names(tok, set_id)
    files = sorted([f for f in os.listdir(d) if f.endswith(".png")], key=sort_key)
    print(f"set {set_id} ({display_type}), {len(files)} файлов")
    for f in files:
        if f in have:
            print(f"  · {f}: уже есть, пропуск")
            continue
        res = upload_one(tok, set_id, os.path.join(d, f))
        print(f"  · {f}: {res}")


if __name__ == "__main__":
    main()
