#!/usr/bin/env python3

from dataclasses import dataclass, asdict
import json


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
        order=-1
    ):
        if not title.strip():
            return

        self.tasks.append(
            Task(
                uid=uid,
                title=title.strip(),
                level=level,
                duration=duration,
                synced=synced,
                wbs=wbs,
                parent=parent,
                order=order
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

    def moveTaskUp(self, index):
        if index <= 0 or index >= len(self.tasks):
            return

        self.tasks[index], self.tasks[index - 1] = (
            self.tasks[index - 1],
            self.tasks[index]
        )

        self.markAllUnsynced()

    def moveTaskDown(self, index):
        if index < 0 or index >= len(self.tasks) - 1:
            return

        self.tasks[index], self.tasks[index + 1] = (
            self.tasks[index + 1],
            self.tasks[index]
        )

        self.markAllUnsynced()

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
        result = []

        for task in self.tasks:
            result.append({
                "uid": task.uid,
                "summary": task.title,
                "level": task.level,
                "duration": task.duration,
                "synced": task.synced,
                "wbs": task.wbs,
                "parent": task.parent,
                "order": task.order
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
