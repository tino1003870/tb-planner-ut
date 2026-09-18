#!/usr/bin/env python3

from dataclasses import dataclass, asdict
import json
import uuid


@dataclass
class Task:
    uid: str = ""
    title: str = ""
    level: int = 0
    duration: int = 1
    synced: bool = False
    wbs: str = ""
    parent: str = ""
    order: int = -1
    dtstart: str = None
    due: str = None


class TaskModel:

    def __init__(self):
        self.tasks = []

    def addTask(
        self,
        title,
        level,
        duration,
        synced=False,
        uid="",
        wbs="",
        parent="",
        order=-1,
        dtstart=None,
        due=None
    ):
        if not title.strip():
            return

        # Jeder neue Task bekommt sofort eine stabile UID.
        if not uid:
            uid = str(uuid.uuid4())

        self.tasks.append(
            Task(
                uid=uid,
                title=title.strip(),
                level=level,
                duration=duration,
                synced=synced,
                wbs=wbs,
                parent=parent,
                order=order,
                dtstart=dtstart,
                due=due
            )
        )

    def setTaskTitle(self, index, title):
        if index < 0 or index >= len(self.tasks):
            return

        trimmed = title.strip()

        if not trimmed:
            return

        task = self.tasks[index]

        if task.title == trimmed:
            return

        task.title = trimmed
        task.synced = False

    def _updateOrder(self):
        for index, task in enumerate(self.tasks):
            task.order = index

    def moveTaskUp(self, index):
        print(
            "TaskModel.moveTaskUp:",
            "index=", index,
            "count=", len(self.tasks),
            flush=True
        )

        if index <= 0 or index >= len(self.tasks):
            print(
                "TaskModel.moveTaskUp: ungültiger Index",
                flush=True
            )
            return

        task = self.tasks[index]
        previous = self.tasks[index - 1]

        print(
            "TaskModel.moveTaskUp BEFORE:",
            "task=", repr(task.title),
            "order=", task.order,
            "previous=", repr(previous.title),
            "previous_order=", previous.order,
            flush=True
        )

        self.tasks[index], self.tasks[index - 1] = (
            self.tasks[index - 1],
            self.tasks[index]
        )

        # order entspricht immer der aktuellen Listenposition.
        self.tasks[index - 1].order = index - 1
        self.tasks[index].order = index

        self.markAllUnsynced()

        print(
            "TaskModel.moveTaskUp AFTER:",
            "task=", repr(self.tasks[index - 1].title),
            "index=", index - 1,
            "order=", self.tasks[index - 1].order,
            "next=", repr(self.tasks[index].title),
            "index=", index,
            "order=", self.tasks[index].order,
            flush=True
        )

    def moveTaskDown(self, index):
        print(
            "TaskModel.moveTaskDown:",
            "index=", index,
            "count=", len(self.tasks),
            flush=True
        )

        if index < 0 or index >= len(self.tasks) - 1:
            print(
                "TaskModel.moveTaskDown: ungültiger Index",
                flush=True
            )
            return

        task = self.tasks[index]
        following = self.tasks[index + 1]

        print(
            "TaskModel.moveTaskDown BEFORE:",
            "task=", repr(task.title),
            "order=", task.order,
            "following=", repr(following.title),
            "following_order=", following.order,
            flush=True
        )

        self.tasks[index], self.tasks[index + 1] = (
            self.tasks[index + 1],
            self.tasks[index]
        )

        # order entspricht immer der aktuellen Listenposition.
        self.tasks[index].order = index
        self.tasks[index + 1].order = index + 1

        self.markAllUnsynced()

        print(
            "TaskModel.moveTaskDown AFTER:",
            "task=", repr(self.tasks[index].title),
            "index=", index,
            "order=", self.tasks[index].order,
            "next=", repr(self.tasks[index + 1].title),
            "index=", index + 1,
            "order=", self.tasks[index + 1].order,
            flush=True
        )

    def indentTask(self, index):
        print(
            "TaskModel.indentTask:",
            "index=", index,
            "count=", len(self.tasks),
            flush=True
        )

        if index <= 0 or index >= len(self.tasks):
            print(
                "TaskModel.indentTask: ungültiger Index",
                flush=True
            )
            return

        task = self.tasks[index]

        print(
            "TaskModel.indentTask:",
            "title=", repr(task.title),
            "level_before=", task.level,
            flush=True
        )

        if task.level >= 4:
            print(
                "TaskModel.indentTask: maximale Ebene erreicht",
                flush=True
            )
            return

        # Ein Task darf höchstens eine Ebene tiefer
        # als sein unmittelbarer Vorgänger liegen.
        previous = self.tasks[index - 1]

        if task.level > previous.level:
            print(
                "TaskModel.indentTask: bereits tiefer als Vorgänger",
                flush=True
            )
            return

        task.level += 1
        task.synced = False

        print(
            "TaskModel.indentTask:",
            "level_after=", task.level,
            flush=True
        )

    def outdentTask(self, index):
        if index < 0 or index >= len(self.tasks):
            return

        task = self.tasks[index]

        if task.level <= 0:
            return

        task.level -= 1
        task.synced = False

    def removeTask(self, index):
        if index < 0 or index >= len(self.tasks):
            return

        self.tasks.pop(index)

    def setTaskSynced(self, index, synced):
        if index < 0 or index >= len(self.tasks):
            return

        self.tasks[index].synced = synced

    def markAllUnsynced(self):
        for task in self.tasks:
            task.synced = False

    def taskCount(self):
        return len(self.tasks)

    def taskData(self, index):
        if index < 0 or index >= len(self.tasks):
            return {}

        task = self.tasks[index]

        return {
            "uid": task.uid,
            "summary": task.title,
            "level": task.level,
            "duration": task.duration,
            "synced": task.synced,
            "wbs": task.wbs,
            "parent": task.parent,
            "order": task.order
        }

    def setTaskUid(self, index, uid):
        if index < 0 or index >= len(self.tasks):
            return

        self.tasks[index].uid = uid

    def setTaskPlannerData(self, index, uid, wbs, parent, order):
        if index < 0 or index >= len(self.tasks):
            return

        task = self.tasks[index]

        task.uid = uid
        task.wbs = wbs
        task.parent = parent
        task.order = order
        task.synced = True

    def markAllSynced(self):
        for task in self.tasks:
            task.synced = True

    def taskArray(self):
        # Die physische Reihenfolge der Liste ist die maßgebliche
        # Reihenfolge der Tasks.
        #
        # order wird deshalb bei jeder Ausgabe aus der aktuellen
        # Listenposition neu aufgebaut.
        self._updateOrder()

        result = []

        print(
            "TaskModel.taskArray:",
            "count=", len(self.tasks),
            flush=True
        )

        for index, task in enumerate(self.tasks):
            print(
                "TaskModel.taskArray:",
                index,
                repr(task.title),
                "uid=", task.uid,
                "level=", task.level,
                "order=", task.order,
                "synced=", task.synced,
                flush=True
            )

            result.append({
                "uid": task.uid,
                "summary": task.title,
                "level": task.level,
                "duration": task.duration,
                "dtstart": getattr(task, "dtstart", None),
                "due": getattr(task, "due", None),
                "synced": task.synced,
                "wbs": task.wbs,
                "parent": task.parent,
                "order": index,
                "dtstart": task.dtstart,
                "due": task.due
            })

        return result

    def applySyncResult(self, index, uid, wbs, parent, order):
        if index < 0 or index >= len(self.tasks):
            return

        task = self.tasks[index]

        if uid:
            task.uid = uid

        task.wbs = wbs
        task.parent = parent
        task.order = order
        task.synced = True

    def clear(self):
        self.tasks.clear()


if __name__ == "__main__":
    model = TaskModel()

    model.addTask("Hauptaufgabe", 0, 5)
    model.addTask("Unteraufgabe", 1, 2)

    print(json.dumps(
        model.taskArray(),
        ensure_ascii=False,
        indent=2
    ))
