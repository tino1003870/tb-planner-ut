#!/usr/bin/env python3

import json
from pathlib import Path

from taskmodel import TaskModel
from syncmanager import SyncManager


class PlannerBackend:
    """
    Python-Ersatz für die bisher in main.cpp enthaltenen
    TaskModel- und SyncManager-Funktionen.
    """

    def __init__(self):
        self.taskModel = TaskModel()
        self.syncManager = SyncManager()

    # ---------------------------------------------------------
    # TaskModel
    # ---------------------------------------------------------

    def addTask(self, title, level, duration,
                synced=False, uid="", wbs="",
                parent="", order=-1,
                dtstart=None, due=None):
        self.taskModel.addTask(
            title, level, duration,
            synced, uid, wbs, parent, order,
            dtstart, due
        )

    def setTaskTitle(self, index, title):
        self.taskModel.setTaskTitle(index, title)

    def moveTaskUp(self, index):
        self.taskModel.moveTaskUp(index)

    def moveTaskDown(self, index):
        self.taskModel.moveTaskDown(index)

    def indentTask(self, index):
        self.taskModel.indentTask(index)

    def outdentTask(self, index):
        self.taskModel.outdentTask(index)

    def removeTask(self, index):
        self.taskModel.removeTask(index)

    def setTaskSynced(self, index, synced):
        self.taskModel.setTaskSynced(index, synced)

    def markAllUnsynced(self):
        self.taskModel.markAllUnsynced()

    def taskCount(self):
        return self.taskModel.taskCount()

    def taskData(self, index):
        return self.taskModel.taskData(index)

    def setTaskUid(self, index, uid):
        self.taskModel.setTaskUid(index, uid)

    def setTaskPlannerData(self, index, uid, wbs, parent, order):
        self.taskModel.setTaskPlannerData(
            index, uid, wbs, parent, order
        )

    def markAllSynced(self):
        self.taskModel.markAllSynced()

    def taskArray(self):
        return self.taskModel.taskArray()

    def applySyncResult(self, index, uid, wbs, parent, order):
        self.taskModel.applySyncResult(
            index, uid, wbs, parent, order
        )

    def clear(self):
        self.taskModel.clear()

    # ---------------------------------------------------------
    # Verbindungseinstellungen
    # ---------------------------------------------------------

    def loadConnectionSettings(self):
        return self.syncManager.loadConnectionSettings()

    def saveConnectionSettings(self, url, username):
        return self.syncManager.saveConnectionSettings(
            url, username
        )

    # ---------------------------------------------------------
    # JSON-Schnittstelle zu planner.py
    # ---------------------------------------------------------

    def buildSyncRequest(self, calendarUrl, username, password):
        return self.syncManager.build_sync_request(
            calendarUrl,
            username,
            password,
            self.taskModel.taskArray()
        )

    def buildListRequest(self, calendarUrl, username, password):
        return self.syncManager.build_list_request(
            calendarUrl,
            username,
            password
        )

    def syncTasks(self, calendarUrl, username, password):
        """
        Synchronisiert die aktuell im Python-TaskModel vorhandenen
        Tasks mit planner.py.
        """
        import subprocess
        import sys

        request = self.buildSyncRequest(
            calendarUrl,
            username,
            password
        )

        planner_script = (
            Path(__file__).resolve().parent / "planner.py"
        )

        try:
            process = subprocess.run(
                [sys.executable, str(planner_script)],
                input=json.dumps(request),
                text=True,
                capture_output=True,
                timeout=60
            )

            if process.returncode != 0:
                return {
                    "success": False,
                    "error": (
                        process.stderr.strip()
                        or "planner.py beendet mit Fehler."
                    )
                }

            response = json.loads(process.stdout)

            result = self.applySyncResults(response)

            return result

        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            }

    def applySyncResults(self, response):
        tasks = self.taskModel.taskArray()

        tasks, result = self.syncManager.apply_sync_results(
            tasks,
            response
        )

        for index, task in enumerate(tasks):
            if index >= self.taskModel.taskCount():
                break

            self.taskModel.setTaskPlannerData(
                index,
                task.get("uid", ""),
                task.get("wbs", ""),
                task.get("parent", ""),
                task.get("order", -1)
            )

        return result

    def applyListResults(self, response):
        tasks, result = self.syncManager.apply_list_results(
            [],
            response
        )

        self.taskModel.clear()

        for task in tasks:
            self.taskModel.addTask(
                task.get("summary", ""),
                task.get("level", 0),
                task.get("duration", 1),
                task.get("synced", True),
                task.get("uid", ""),
                task.get("wbs", ""),
                task.get("parent", ""),
                task.get("order", -1)
            )

        return result


if __name__ == "__main__":
    backend = PlannerBackend()

    backend.addTask("Hauptaufgabe", 0, 5)
    backend.addTask("Unteraufgabe", 1, 2)

    print(
        json.dumps(
            backend.taskArray(),
            ensure_ascii=False,
            indent=2
        )
    )


# -------------------------------------------------------------
# PyOtherSide-Einstiegspunkt
# -------------------------------------------------------------

_backend = PlannerBackend()


def pythonTest():
    return {
        "success": True,
        "message": "Python-Backend funktioniert",
        "taskCount": _backend.taskCount()
    }


def getTasks():
    tasks = _backend.taskModel.taskArray()

    result = []

    for task in tasks:
        result.append({
            "title": task.get("title", task.get("summary", "")),
            "summary": task.get("summary", task.get("title", "")),
            "level": task.get("level", 0),
            "duration": task.get("duration", 1),
            "synced": task.get("synced", False),
            "uid": task.get("uid", ""),
            "wbs": task.get("wbs", ""),
            "parent": task.get("parent", ""),
            "taskOrder": task.get(
                "taskOrder",
                task.get("order", -1)
            ),
            "dtstart": task.get("dtstart"),
            "due": task.get("due")
        })

    return result

def loadConnectionSettings():
    return _backend.loadConnectionSettings()


def saveConnectionSettings(url, username):
    return _backend.saveConnectionSettings(url, username)


def addTask(title, level, duration, dtstart=None, due=None):
    _backend.addTask(
        title,
        level,
        duration,
        dtstart=dtstart,
        due=due
    )
    return _backend.taskModel.taskArray()


def setTaskTitle(index, title):
    _backend.setTaskTitle(index, title)
    return _backend.taskModel.taskArray()


def moveTaskUp(index):
    _backend.moveTaskUp(index)
    return _backend.taskModel.taskArray()


def moveTaskDown(index):
    _backend.moveTaskDown(index)
    return _backend.taskModel.taskArray()


def indentTask(index):
    _backend.indentTask(index)
    return _backend.taskModel.taskArray()


def outdentTask(index):
    _backend.outdentTask(index)
    return _backend.taskModel.taskArray()


def removeTask(index):
    _backend.removeTask(index)
    return _backend.taskModel.taskArray()


def syncTasks(calendar_url, username, password):
    return _backend.syncTasks(
        calendar_url,
        username,
        password
    )



def loadWebDeTasks(calendar_url, username, password):
    from planner import Planner

    print(
        "Python loadWebDeTasks:",
        "url=", repr(calendar_url),
        "username=", repr(username),
        "password_set=", bool(password),
        flush=True
    )

    planner = Planner(
        calendar_url,
        username,
        password
    )

    tasks = planner.list_tasks()

    print(
        "Python loadWebDeTasks: list_tasks() ->",
        len(tasks),
        "Tasks",
        flush=True
    )

    result = []

    for task in tasks:
        wbs = task.wbs or ""
        level = wbs.count(".") if wbs else 0

        result.append({
            "title": task.summary or "",
            "level": level,
            "duration": 1,
            "synced": True,
            "uid": task.uid or "",
            "wbs": wbs,
            "parent": task.parent or "",
            "taskOrder": task.order if task.order is not None else -1,
            "dtstart": task.dtstart or "",
            "due": task.due or ""
        })

        print(
            "Python loadWebDeTasks TASK:",
            "title=", repr(task.summary),
            "dtstart=", repr(task.dtstart),
            "due=", repr(task.due),
            "wbs=", repr(wbs),
            "order=", task.order,
            flush=True
        )

    print(
        "Python loadWebDeTasks: result ->",
        len(result),
        "Tasks",
        flush=True
    )

    if result:
        print(
            "Python loadWebDeTasks: first ->",
            result[0],
            flush=True
        )

    # Die geladenen Tasks auch in das zentrale Python-TaskModel
    # übernehmen. QML arbeitet danach über dieses Model weiter.
    _backend.taskModel.clear()

    for task in result:
        _backend.taskModel.addTask(
            task.get("title", ""),
            task.get("level", 0),
            task.get("duration", 1),
            task.get("synced", True),
            task.get("uid", ""),
            task.get("wbs", ""),
            task.get("parent", ""),
            task.get("taskOrder", -1),
            task.get("dtstart"),
            task.get("due")
        )

    return result
