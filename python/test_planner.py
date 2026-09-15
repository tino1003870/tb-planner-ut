#!/usr/bin/env python3

import getpass
import uuid

from planner import Planner
from caldav.ical import PlannerTask


CALENDAR_URL = (
    "https://caldav.web.de:443/"
    "begenda/dav/4369253c-5ad8-4f96-a511-5b8952097a87/"
    "calendar/"
)


def main():
    username = input("web.de Benutzername: ")
    password = getpass.getpass("web.de Passwort: ")

    planner = Planner(
        CALENDAR_URL,
        username,
        password,
    )

    print()
    print("=== 1. Tasks lesen ===")

    tasks = planner.list_tasks()

    print(f"Gefundene Tasks: {len(tasks)}")

    for task in tasks:
        print(
            f"  {task.uid}: "
            f"{task.summary} "
            f"(WBS={task.wbs}, "
            f"Parent={task.parent}, "
            f"Order={task.order})"
        )

    print()
    print("=== 2. Task erzeugen ===")

    uid = "tb-planner-api-test-" + str(uuid.uuid4())

    task = PlannerTask(
        uid=uid,
        summary="TB-PLANNER-API-TEST",
        description="Test der zentralen Planner-API",
        status="NEEDS-ACTION",
        percent_complete=0,
        dtstart="20260914",
        due="20260921",
        wbs="99.1",
        parent="API-TEST-PARENT",
        order=1,
    )

    planner.create_task(task)

    print("Task erzeugt:")
    print("  UID:", task.uid)
    print("  Titel:", task.summary)

    print()
    print("=== 3. Task aktualisieren ===")

    task.summary = "TB-PLANNER-API-UPDATE"
    task.description = "Task wurde über Planner.update_task() aktualisiert"
    task.status = "IN-PROCESS"
    task.percent_complete = 50
    task.due = "20260923"
    task.wbs = "99.2"
    task.parent = "API-TEST-PARENT-UPDATED"
    task.order = 8

    planner.update_task(task)

    print("Task aktualisiert.")

    print()
    print("=== 4. Task erneut lesen ===")

    found = None

    for candidate in planner.list_tasks():
        if candidate.uid == uid:
            found = candidate
            break

    if found is None:
        raise RuntimeError(
            "Der gerade aktualisierte Task wurde nicht gefunden!"
        )

    print("Gefundener Task:")
    print("  UID:", found.uid)
    print("  Titel:", found.summary)
    print("  Beschreibung:", found.description)
    print("  Status:", found.status)
    print("  Fortschritt:", found.percent_complete)
    print("  Start:", found.dtstart)
    print("  Ende:", found.due)
    print("  WBS:", found.wbs)
    print("  Parent:", found.parent)
    print("  Order:", found.order)

    print()
    print("=== 5. Task löschen ===")

    planner.delete_task(uid)

    print("Task gelöscht.")

    print()
    print("=== TEST ERFOLGREICH ===")


if __name__ == "__main__":
    main()
