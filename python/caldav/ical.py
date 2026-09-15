#!/usr/bin/env python3

from dataclasses import dataclass
from typing import Optional


@dataclass
class PlannerTask:
    """
    Internes Datenmodell eines TB-Planner-Tasks.
    """

    uid: str
    summary: str

    description: Optional[str] = None

    status: str = "NEEDS-ACTION"
    percent_complete: int = 0

    dtstart: Optional[str] = None
    due: Optional[str] = None

    wbs: Optional[str] = None
    parent: Optional[str] = None
    order: Optional[int] = None

def unfold_ics(text):
    """
    Entfaltet RFC-5545-Zeilen.

    Eine Zeile, die mit Leerzeichen oder Tab beginnt,
    gehört zur vorherigen Zeile.
    """

    lines = text.replace("\r\n", "\n").split("\n")

    result = []

    for line in lines:
        if line.startswith((" ", "\t")) and result:
            result[-1] += line[1:]
        else:
            result.append(line)

    return result


def parse_vtodo(text):
    """
    Liest ein einzelnes VCALENDAR/VTODO und erzeugt
    daraus einen PlannerTask.
    """

    properties = {}

    in_vtodo = False

    for line in unfold_ics(text):

        if line == "BEGIN:VTODO":
            in_vtodo = True
            continue

        if line == "END:VTODO":
            break

        if not in_vtodo or ":" not in line:
            continue

        name, value = line.split(":", 1)

        # Parameter entfernen:
        # DTSTART;VALUE=DATE → DTSTART
        name = name.split(";", 1)[0].upper()

        properties[name] = value

    uid = properties.get("UID")

    if not uid:
        raise ValueError("VTODO enthält keine UID")

    summary = properties.get("SUMMARY", "")

    order = properties.get("X-TB-PLANNER-ORDER")

    if order is not None:
        try:
            order = int(order)
        except ValueError:
            order = None

    try:
        percent = int(properties.get("PERCENT-COMPLETE", "0"))
    except ValueError:
        percent = 0

    return PlannerTask(
        uid=uid,
        summary=summary,
        description=properties.get("DESCRIPTION"),
        status=properties.get("STATUS", "NEEDS-ACTION"),
        percent_complete=percent,
        dtstart=properties.get("DTSTART"),
        due=properties.get("DUE"),
        wbs=properties.get("X-TB-PLANNER-WBS"),
        parent=properties.get("X-TB-PLANNER-PARENT"),
        order=order,
    )
def _escape_ics(value):
    """
    Escaping für iCalendar-Textwerte.
    """

    if value is None:
        return ""

    return (
        str(value)
        .replace("\\", "\\\\")
        .replace(";", "\\;")
        .replace(",", "\\,")
        .replace("\n", "\\n")
        .replace("\r", "")
    )


def task_to_vtodo(task, dtstamp="20260914T000000Z"):
    """
    Erzeugt aus einem PlannerTask ein vollständiges
    VCALENDAR mit einem VTODO.
    """

    lines = [
        "BEGIN:VCALENDAR",
        "PRODID:-//TB Planner//EN",
        "VERSION:2.0",
        "BEGIN:VTODO",

        f"UID:{_escape_ics(task.uid)}",
        f"DTSTAMP:{dtstamp}",

        f"SUMMARY:{_escape_ics(task.summary)}",
        f"STATUS:{_escape_ics(task.status)}",

        f"PERCENT-COMPLETE:{task.percent_complete}",
    ]

    if task.description:
        lines.append(
            f"DESCRIPTION:{_escape_ics(task.description)}"
        )

    if task.dtstart:
        lines.append(
            f"DTSTART;VALUE=DATE:{task.dtstart}"
        )

    if task.due:
        lines.append(
            f"DUE;VALUE=DATE:{task.due}"
        )

    if task.wbs:
        lines.append(
            f"X-TB-PLANNER-WBS:{_escape_ics(task.wbs)}"
        )

    if task.parent:
        lines.append(
            f"X-TB-PLANNER-PARENT:{_escape_ics(task.parent)}"
        )

    if task.order is not None:
        lines.append(
            f"X-TB-PLANNER-ORDER:{task.order}"
        )

    lines.extend([
        "END:VTODO",
        "END:VCALENDAR",
        "",
    ])

    return "\r\n".join(lines)
