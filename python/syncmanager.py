#!/usr/bin/env python3

import json
from pathlib import Path


DEFAULT_CALDAV_URL = (
    "https://caldav.web.de:443/begenda/dav/"
    "4369253c-5ad8-4f96-a511-5b8952097a87/calendar/"
)


class SyncManager:
    """
    Python-Ersatz für den bisherigen C++-SyncManager.

    Die eigentliche CalDAV-/VTODO-Logik bleibt in planner.py.
    """

    def __init__(self):
        self.settings_file = (
            Path.home() / ".config" / "tb-planner" / "settings.json"
        )

    # ---------------------------------------------------------
    # Verbindungseinstellungen
    # ---------------------------------------------------------

    def loadConnectionSettings(self):
        if not self.settings_file.exists():
            return {
                "url": DEFAULT_CALDAV_URL,
                "username": ""
            }

        try:
            with self.settings_file.open("r", encoding="utf-8") as f:
                settings = json.load(f)

            caldav = settings.get("caldav", {})

            return {
                "url": caldav.get("url", DEFAULT_CALDAV_URL),
                "username": caldav.get("username", "")
            }

        except (OSError, json.JSONDecodeError):
            return {
                "url": DEFAULT_CALDAV_URL,
                "username": ""
            }

    def saveConnectionSettings(self, url, username):
        self.settings_file.parent.mkdir(
            parents=True,
            exist_ok=True
        )

        settings = {
            "caldav": {
                "url": url,
                "username": username
            }
        }

        with self.settings_file.open("w", encoding="utf-8") as f:
            json.dump(
                settings,
                f,
                ensure_ascii=False,
                indent=2
            )

        return {
            "success": True,
            "message": (
                "\nVerbindungseinstellungen gespeichert.\n"
                "Passwort wird nicht gespeichert.\n"
            )
        }

    # ---------------------------------------------------------
    # Request für planner.py
    # ---------------------------------------------------------

    @staticmethod
    def build_sync_request(calendar_url, username, password, tasks):
        return {
            "calendar_url": calendar_url,
            "username": username,
            "password": password,
            "operation": "sync",
            "tasks": [
                {
                    "uid": task.get("uid", ""),
                    "summary": task.get("summary", ""),
                    "level": task.get("level", 0),
                    "duration": task.get("duration", 1),
                    "wbs": task.get("wbs", ""),
                    "parent": task.get("parent", ""),
                    "order": task.get("order", -1)
                }
                for task in tasks
            ]
        }

    @staticmethod
    def build_list_request(calendar_url, username, password):
        return {
            "calendar_url": calendar_url,
            "username": username,
            "password": password,
            "operation": "list"
        }

    # ---------------------------------------------------------
    # Ergebnisse aus planner.py verarbeiten
    # ---------------------------------------------------------

    @staticmethod
    def apply_sync_results(tasks, response):
        if not response.get("success"):
            return tasks, response

        results = response.get("results", [])
        successful = 0

        for index, result in enumerate(results):

            if not result.get("success"):
                continue

            if index >= len(tasks):
                continue

            task = tasks[index]

            uid = result.get("uid", "")
            if uid:
                task["uid"] = uid

            task["level"] = result.get(
                "level",
                task.get("level", 0)
            )
            task["wbs"] = result.get("wbs", "")
            task["parent"] = result.get("parent", "")
            task["order"] = result.get("order", -1)
            task["synced"] = True

            successful += 1

        return tasks, {
            "success": True,
            "tasks": tasks,
            "results": results,
            "successful": successful,
            "total": len(results)
        }

    @staticmethod
    def apply_list_results(tasks, response):
        if not response.get("success"):
            return tasks, response

        new_tasks = []

        for task in response.get("tasks", []):
            title = task.get("summary", "")
            wbs = task.get("wbs", "")

            level = 0 if not wbs else wbs.count(".")

            new_tasks.append({
                "uid": task.get("uid", ""),
                "summary": title,
                "title": title,
                "level": level,
                "duration": 1,
                "synced": True,
                "wbs": wbs,
                "parent": task.get("parent", ""),
                "order": task.get("order", -1)
            })

        return new_tasks, {
            "success": True,
            "tasks": new_tasks
        }


if __name__ == "__main__":
    manager = SyncManager()

    print(json.dumps(
        manager.loadConnectionSettings(),
        ensure_ascii=False,
        indent=2
    ))
