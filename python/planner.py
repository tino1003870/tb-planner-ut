#!/usr/bin/env python3

from pathlib import Path
from urllib.parse import urljoin
import xml.etree.ElementTree as ET
import json
import sys

from caldav.client import CalDAVClient
from caldav.ical import PlannerTask, parse_vtodo, task_to_vtodo


class Planner:
    """
    Zentrale Python-Schnittstelle für den TB-Planner.

    Kümmert sich um:
      - Verbindung zu einem CalDAV-Kalender
      - Lesen von VTODOs
      - Erzeugen neuer VTODOs
      - Aktualisieren vorhandener VTODOs
      - Löschen von VTODOs
    """

    def __init__(self, calendar_url, username, password):
        self.calendar_url = calendar_url.rstrip("/") + "/"

        self.client = CalDAVClient(
            self.calendar_url,
            username,
            password,
        )

    def _task_url(self, uid):
        """
        Erzeugt die URL einer VTODO-Ressource.

        web.de akzeptiert als Ressourcennamen die UID mit .ics.
        """
        return urljoin(self.calendar_url, uid + ".ics")

    def list_tasks(self):
        """
        Liest alle VTODOs aus dem Kalender.

        Rückgabe:
            Liste von PlannerTask-Objekten.
        """

        body = """<?xml version="1.0" encoding="utf-8" ?>
<D:propfind xmlns:D="DAV:">
    <D:prop>
        <D:getetag/>
        <D:displayname/>
        <D:resourcetype/>
    </D:prop>
</D:propfind>
"""

        status, headers, data = self.client.propfind(
            self.calendar_url,
            body,
        )

        if status != 207:
            raise RuntimeError(
                f"PROPFIND fehlgeschlagen: HTTP {status}"
            )

        try:
            root = ET.fromstring(data)
        except ET.ParseError as e:
            raise RuntimeError(
                f"PROPFIND lieferte ungültiges XML: {e}"
            )

        # DAV-Namespace
        dav = "{DAV:}"

        tasks = []

        # Alle DAV:response-Elemente durchlaufen
        for response in root.findall(f"{dav}response"):

            href_element = response.find(f"{dav}href")

            if href_element is None or not href_element.text:
                continue

            href = href_element.text

            # Der Kalender selbst ist ebenfalls eine response,
            # aber keine einzelne .ics-Ressource.
            if not href.endswith(".ics"):
                continue

            task_url = urljoin(
                self.calendar_url,
                href,
            )

            try:
                get_status, _, ics_data = self.client.get(
                    task_url
                )

                if get_status != 200:
                    continue

                task = parse_vtodo(
                    ics_data.decode("utf-8")
                )

                tasks.append(task)

            except ValueError:
                # Ressource enthält keine gültige VTODO.
                continue

        return tasks

    def create_task(self, task):
        """
        Erstellt eine neue VTODO-Ressource.
        """

        url = self._task_url(task.uid)

        ics = task_to_vtodo(task)

        status, headers, data = self.client.put(
            url,
            ics,
        )

        if status not in (200, 201, 204):
            raise RuntimeError(
                f"PUT fehlgeschlagen: HTTP {status}"
            )

        return task

    def update_task(self, task):
        """
        Aktualisiert eine vorhandene VTODO-Ressource.
        """

        url = self._task_url(task.uid)

        ics = task_to_vtodo(task)

        status, headers, data = self.client.put(
            url,
            ics,
        )

        if status not in (200, 201, 204):
            raise RuntimeError(
                f"UPDATE fehlgeschlagen: HTTP {status}"
            )

        return task

    def delete_task(self, uid):
        """
        Löscht eine VTODO-Ressource.
        """

        url = self._task_url(uid)

        status, headers, data = self.client.delete(
            url
        )

        if status not in (200, 204):
            raise RuntimeError(
                f"DELETE fehlgeschlagen: HTTP {status}"
            )

        return True


def task_to_dict(task):
    """
    Wandelt einen PlannerTask in ein JSON-kompatibles Dictionary um.
    """

    return {
        "uid": task.uid,
        "summary": task.summary,
        "description": task.description,
        "status": task.status,
        "percent_complete": task.percent_complete,
        "dtstart": task.dtstart,
        "due": task.due,
        "wbs": task.wbs,
        "parent": task.parent,
        "order": task.order,
    }


def task_from_dict(data):
    """
    Erzeugt einen PlannerTask aus einem Dictionary.
    """

    return PlannerTask(
        uid=data["uid"],
        summary=data.get("summary", ""),
        description=data.get("description"),
        status=data.get("status", "NEEDS-ACTION"),
        percent_complete=int(
            data.get("percent_complete", 0)
        ),
        dtstart=data.get("dtstart"),
        due=data.get("due"),
        wbs=data.get("wbs"),
        parent=data.get("parent"),
        order=data.get("order"),
    )


def main_cli():
    """
    JSON-CLI für die Kommunikation mit C++.

    Ein Request wird über stdin gelesen.
    Die Antwort wird als genau ein JSON-Objekt
    nach stdout geschrieben.
    """

    try:
        request = json.load(sys.stdin)

        calendar_url = request.get(
            "calendar_url",
            "https://caldav.web.de/"
        )

        username = request.get("username")
        password = request.get("password")

        if username is None:
            username = ""

        if password is None:
            password = ""

        operation = request["operation"]

        planner = Planner(
            calendar_url,
            username,
            password,
        )

        if operation == "list":

            tasks = planner.list_tasks()

            response = {
                "success": True,
                "tasks": [
                    task_to_dict(task)
                    for task in tasks
                ],
            }

        elif operation == "create":

            task = task_from_dict(request["task"])

            planner.create_task(task)

            response = {
                "success": True,
                "task": task_to_dict(task),
            }

        elif operation == "update":

            task = task_from_dict(request["task"])

            planner.update_task(task)

            response = {
                "success": True,
                "task": task_to_dict(task),
            }

        elif operation == "delete":

            uid = request["uid"]

            planner.delete_task(uid)

            response = {
                "success": True,
                "uid": uid,
            }

        else:

            raise ValueError(
                f"Unbekannte Operation: {operation}"
            )

    except Exception as e:

        response = {
            "success": False,
            "error": str(e),
        }

    print(
        json.dumps(
            response,
            ensure_ascii=False,
        )
    )


if __name__ == "__main__":
    main_cli()
