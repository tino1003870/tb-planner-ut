import QtQuick 2.7
import Lomiri.Components 1.3
import Lomiri.Components.Pickers 1.3
import QtQuick.Layouts 1.3
import io.thp.pyotherside 1.5

MainView {
    id: root

    property int ganttModelRevision: 0

    property bool taskSyncRunning: false
    property string selectedTaskUid: ""
    property date selectedTaskStartDate: new Date()

    function taskDateToDate(value) {
        if (!value || value.length !== 8)
            return null

        var y = parseInt(value.substring(0, 4))
        var m = parseInt(value.substring(4, 6)) - 1
        var d = parseInt(value.substring(6, 8))

        return new Date(y, m, d)
    }

    function dateToTaskDate(value) {
        if (!value)
            return ""

        var y = value.getFullYear()
        var m = value.getMonth() + 1
        var d = value.getDate()

        return String(y) +
               (m < 10 ? "0" : "") + m +
               (d < 10 ? "0" : "") + d
    }

    function formatTaskDate(value) {
        if (!value)
            return ""

        var d = value.getDate()
        var m = value.getMonth() + 1

        return (d < 10 ? "0" : "") + d +
               "." +
               (m < 10 ? "0" : "") + m +
               "." +
               value.getFullYear()
    }

    ListModel {
        id: pythonTaskModel
    }

    function refreshPythonTaskModel() {
        var selectedUid = root.selectedTaskUid

        console.log(
            "REFRESH BEFORE:",
            "index=", taskList.currentIndex,
            "uid=", selectedUid
        )

        python.call(
            "backend.getTasks",
            [],
            function(tasks) {

                pythonTaskModel.clear()

                if (!tasks) {
                    taskList.currentIndex = -1
                    console.log("REFRESH: keine Tasks")
                    return
                }

                for (var i = 0; i < tasks.length; ++i)
                    pythonTaskModel.append(tasks[i])

                root.ganttModelRevision++

                console.log(
                    "GANTT MODEL REVISION:",
                    root.ganttModelRevision
                )

                var newIndex = -1

                if (selectedUid !== "") {
                    for (var j = 0;
                         j < pythonTaskModel.count;
                         ++j) {

                        var refreshedTask =
                            pythonTaskModel.get(j)

                        if (refreshedTask.uid === selectedUid) {
                            newIndex = j
                            break
                        }
                    }
                }

                taskList.currentIndex = newIndex

                console.log(
                    "REFRESH AFTER:",
                    "selectedUid=", selectedUid,
                    "newIndex=", newIndex
                )

                console.log(
                    "[GANTT STATE AFTER REFRESH]",
                    "count=", pythonTaskModel.count,
                    "startDate=", ganttContent.startDate,
                    "endDate=", ganttContent.endDate,
                    "ganttDays=", ganttContent.ganttDays,
                    "pixelsPerDay=", ganttContent.pixelsPerDay,
                    "width=", ganttContent.width,
                    "height=", ganttContent.height
                )
            }
        )
    }

    Python {
        id: python

        Component.onCompleted: {
            console.log("Python-Test: PyOtherSide geladen")

            python.addImportPath("python")

            python.importModule("backend", function() {
                console.log("Python-Modul backend geladen")
            })
        }

        onError: {
            console.log("Python-Fehler:", traceback)
        }

        onReceived: {
            console.log("Python-Antwort:", data)
        }
    }

    Component.onCompleted: {
        python.call(
            "backend.loadConnectionSettings",
            [],
            function(settings) {
                if (!settings)
                    return

                urlField.text = settings.url
                usernameField.text = settings.username
                passwordField.text = ""
            }
        )
    }



    objectName: "mainView"
    applicationName: "tb-planner.com.tino"

    width: units.gu(45)
    height: units.gu(75)

    property int page: 0

    Page {
        anchors.fill: parent

        header: PageHeader {
            id: header
            title: "TB Planner"
        }

        Flickable {
            id: pageFlickable

            x: 0
            y: header.height
            width: parent.width
            height: parent.height - header.height

            contentWidth: width
            contentHeight: contentColumn.height

            clip: true

            flickableDirection: Flickable.VerticalFlick

            Column {
                id: contentColumn

                x: units.gu(2)
                width: pageFlickable.width - units.gu(4)

                spacing: units.gu(1)

                /* =====================================================
                   STARTSEITE
                   ===================================================== */

                Column {
                    width: parent.width
                    spacing: units.gu(2)

                    visible: root.page === 0

                    Item {

width: parent.width
                        height: units.gu(4)
                    }

                    Label {
                        width: parent.width

                        text: "TB Planner"

                        font.pixelSize: units.gu(3)
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Label {
                        width: parent.width

                        text: "Projektplanung"

                        horizontalAlignment: Text.AlignHCenter
                    }

                    Item {
                        width: parent.width
                        height: units.gu(2)
                    }

                    Button {
                        width: parent.width
                        height: units.gu(6)

                        text: "Verbindungen"

                        onClicked: root.page = 1
                    }

                    Button {
                        width: parent.width
                        height: units.gu(6)

                        text: "Taskliste"

                        onClicked: root.page = 2
                    }

                    Item {
                        width: parent.width
                        height: units.gu(3)
                    }

                    Button {
                        width: parent.width
                        height: units.gu(5)

                        text: "Beenden"

                        onClicked: Qt.quit()
                    }
                }


                /* =====================================================
                   VERBINDUNGEN
                   ===================================================== */

                Column {
                    width: parent.width
                    spacing: units.gu(1)

                    visible: root.page === 1

                    Label {
                        width: parent.width

                        text: "Verbindungen"

                        font.pixelSize: units.gu(2.5)
                    }

                    Label {
                        width: parent.width

                        text: "CalDAV-Verbindung"

                        font.pixelSize: units.gu(1.8)
                    }

                    TextField {
                        id: urlField

                        width: parent.width

                        placeholderText: "CalDAV-URL"

                        text: "https://caldav.web.de:443/begenda/dav/4369253c-5ad8-4f96-a511-5b8952097a87/calendar/"
                    }

                    TextField {
                        id: usernameField

                        width: parent.width

                        placeholderText: "Benutzername"
                    }

                    TextField {
                        id: passwordField

                        width: parent.width

                        placeholderText: "Passwort"

                        echoMode: TextInput.Password
                    }

                    Item {
                        width: parent.width
                        height: units.gu(1)
                    }

                    Button {
                        width: parent.width
                        height: units.gu(5)

                        text: "Einstellungen laden"

                        onClicked: {
                            python.call(
                                "backend.loadConnectionSettings",
                                [],
                                function(settings) {
                                    if (!settings)
                                        return

                                    urlField.text = settings.url
                                    usernameField.text = settings.username
                                    passwordField.text = ""

                                    outputText.text =
                                        "Verbindungseinstellungen geladen.\n"
                                        + "Passwort muss erneut eingegeben werden."
                                }
                            )
                        }
                    }

                    Button {
                        width: parent.width
                        height: units.gu(5)

                        text: "Einstellungen speichern"

                        onClicked: {
                            python.call(
                                "backend.saveConnectionSettings",
                                [
                                    urlField.text,
                                    usernameField.text
                                ],
                                function(result) {
                                    if (result && result.message)
                                        outputText.text = result.message
                                }
                            )
                        }
                    }

                    Item {
                        width: parent.width
                        height: units.gu(1)
                    }

                    Button {
                        width: parent.width
                        height: units.gu(5)

                        text: "VTODOs lesen"

                        enabled: !root.taskSyncRunning

                        onClicked: {
                            console.log(
                                "[DEBUG] VTODO-Laden gestartet"
                            )

                            outputText.text = ""
                            pythonTaskModel.clear()

                            root.taskSyncRunning = true

                            // Sofort zur Taskliste wechseln,
                            // damit das Sync-Overlay sichtbar wird.
                            root.page = 2

                            console.log(
                                "[DEBUG] VTODO-Laden: Taskseite geöffnet"
                            )

                            python.call(
                                "backend.loadWebDeTasks",
                                [
                                    urlField.text,
                                    usernameField.text,
                                    passwordField.text
                                ],
                                function(result) {
                                    console.log(
                                        "[DEBUG] VTODO-Laden abgeschlossen"
                                    )

                                    if (!result) {
                                        outputText.text =
                                            "Python: Keine Daten erhalten."

                                        root.taskSyncRunning = false

                                        console.log(
                                            "[DEBUG] VTODO-Laden: keine Daten"
                                        )

                                        return
                                    }

                                    for (var i = 0; i < result.length; ++i) {
                                        pythonTaskModel.append(result[i])
                                    }

                                    outputText.text =
                                        "Python: " +
                                        result.length +
                                        " VTODOs geladen."

                                    root.taskSyncRunning = false

                                    console.log(
                                        "[DEBUG] VTODO-Laden: Overlay beendet, Tasks=",
                                        result.length
                                    )
                                }
                            )
                        }
                    }

                                        Button {
                        width: parent.width
                        height: units.gu(5)

                        text: "Synchronisieren"

                        onClicked: {
                            outputText.text = ""
                            root.taskSyncRunning = true

                            python.call(
                                "backend.syncTasks",
                                [
                                    urlField.text,
                                    usernameField.text,
                                    passwordField.text
                                ],
                                function(result) {
                                    if (!result || !result.success) {
                                        outputText.text =
                                            "Synchronisation fehlgeschlagen.\n" +
                                            (result && result.error
                                                ? result.error
                                                : "Keine Daten erhalten.")
                                        root.taskSyncRunning = false
                                        return
                                    }

                                    outputText.text =
                                        "Synchronisation abgeschlossen.\n" +
                                        "Tasks: " +
                                        result.results.length

                                    root.refreshPythonTaskModel()
                                    root.taskSyncRunning = false
                                }
                            )
                        }
                    }

                    Item {
                        width: parent.width
                        height: units.gu(2)
                    }

                    Button {
                        width: parent.width
                        height: units.gu(5)

                        text: "Zurück"

                        onClicked: root.page = 0
                    }
                }


                /* =====================================================
                   TASKLISTE
                   ===================================================== */

                Column {
                    width: parent.width
                    spacing: units.gu(1)

                    visible: root.page === 2

                    Label {
                        width: parent.width

                        text: "Taskliste"

                        font.pixelSize: units.gu(2.5)
                    }

                    Button {
                        width: parent.width
                        height: units.gu(5)

                        text: "Aufgabe hinzufügen"

                        enabled: !root.taskSyncRunning

                        onClicked: {
                            root.page = 3
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: units.gu(35)

                        color: "transparent"

                        border.color: "gray"
                        border.width: 1

                        clip: true

                        ListView {
                            id: taskList

                            x: units.gu(1)
                            y: units.gu(1)

                            width: parent.width - units.gu(2)
                            height: parent.height - units.gu(2)

                            model: pythonTaskModel

                            currentIndex: -1

                            clip: true

                            boundsBehavior: Flickable.StopAtBounds

                            delegate: Item {
                                width: taskList.width
                                height: units.gu(5)

                                MouseArea {
                                    id: taskSelectArea
                                    anchors.fill: parent
                                    z: -1

                                    onClicked: {
                                        taskList.currentIndex = index
                                        root.selectedTaskUid = uid
                                        selectedTaskTitle.text = title
                                        selectedTaskDuration.text =
                                            duration.toString()

                                        var selectedTask =
                                            pythonTaskModel.get(index)

                                        var selectedDate =
                                            root.taskDateToDate(
                                                selectedTask.dtstart
                                            )

                                        if (selectedDate)
                                            root.selectedTaskStartDate =
                                                selectedDate
                                        else
                                            root.selectedTaskStartDate =
                                                new Date()

                                        startDateButton.date =
                                            root.selectedTaskStartDate

                                        startDateButton.text =
                                            root.formatTaskDate(
                                                root.selectedTaskStartDate
                                            )

                                        console.log(
                                            "TASK SELECTED:",
                                            "index=", index,
                                            "uid=", uid,
                                            "title=", title
                                        )
                                    }
                                }

                                Row {
                                    x: 0
                                    y: 0

                                    width: parent.width
                                    height: parent.height

                                    spacing: units.gu(1)

                                    Item {
                                        width: level * units.gu(3)
                                        height: 1
                                    }

                                    Label {
                                        width: parent.width
                                             - level * units.gu(3)
                                             - units.gu(13)

                                        height: parent.height

                                        text: title

                                        verticalAlignment:
                                            Text.AlignVCenter

                                        elide: Text.ElideRight
                                    }

                                    Label {
                                        width: units.gu(5)

                                        height: parent.height

                                        text: duration + " d"

                                        verticalAlignment:
                                            Text.AlignVCenter

                                        horizontalAlignment:
                                            Text.AlignRight
                                    }

                                    Label {
                                        width: units.gu(7)

                                        height: parent.height

                                        text: synced ? "sync'd" : "unsynced"

                                        verticalAlignment:
                                            Text.AlignVCenter

                                        horizontalAlignment:
                                            Text.AlignRight

                                        color: synced ? "green" : "red"

                                        font.pixelSize: units.dp(11)
                                    }

                                    Button {
                                        width: units.gu(5)
                                        height: units.gu(4)

                                        text: "×"

                                        enabled: !root.taskSyncRunning

                                        onClicked:
                                            python.call("backend.removeTask", [index], function() {
                                                root.refreshPythonTaskModel()
                                            })
                                    }
                                }
                            }

                            Label {
                                anchors.centerIn: parent

                                visible: taskList.count === 0

                                text: "Noch keine Aufgaben."
                            }
                        }
                    }

                    Button {
                        width: parent.width
                        height: units.gu(5)

                        text: "Gantt-Diagramm"

                        enabled: !root.taskSyncRunning

                        onClicked: {
                            root.page = 4
                        }
                    }

                    Item {
                        width: parent.width
                        height: units.gu(1)
                    }

/* =====================================================
                       TASK-BEARBEITUNG
                       ===================================================== */

                    Label {
                        width: parent.width

                        text: "Ausgewählter Task"

                        font.pixelSize: units.gu(2)
                    }

                    Row {
                        width: parent.width
                        height: units.gu(5)

                        spacing: units.gu(1)

                        TextField {
                            id: selectedTaskTitle

                            enabled: !root.taskSyncRunning

                            width: parent.width - units.gu(11)
                            height: units.gu(5)

                            placeholderText: "Task auswählen"
                        }

                        Button {
                            width: units.gu(10)
                            height: units.gu(5)

                            text: "Übernehmen"

                                        enabled: !root.taskSyncRunning

                            onClicked: {
                                if (taskList.currentIndex >= 0) {
                                    python.call(
                                        "backend.setTaskTitle",
                                        [
                                            taskList.currentIndex,
                                            selectedTaskTitle.text
                                        ],
                                        function() {
                                            root.refreshPythonTaskModel()
                                        }
                                    )
                                }
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        height: units.gu(5)

                        spacing: units.gu(1)

                        Label {
                            width: units.gu(11)
                            height: parent.height

                            text: "Startdatum:"
                            verticalAlignment: Text.AlignVCenter
                        }

                        Button {
                            id: startDateButton

                            width: parent.width - units.gu(12)
                            height: units.gu(5)

                            text: "Datum auswählen"

                            enabled:
                                !root.taskSyncRunning &&
                                taskList.currentIndex >= 0

                            onClicked: {
                                PickerPanel.openDatePicker(
                                    startDateButton,
                                    "date",
                                    "Years|Months|Days"
                                )
                            }

                            property date date: new Date()

                            onDateChanged: {
                                root.selectedTaskStartDate = date
                                text =
                                    root.formatTaskDate(date)
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        height: units.gu(5)

                        spacing: units.gu(1)

                        Label {
                            width: units.gu(11)
                            height: parent.height

                            text: "Dauer:"
                            verticalAlignment: Text.AlignVCenter
                        }

                        TextField {
                            id: selectedTaskDuration

                            width: parent.width - units.gu(18)
                            height: units.gu(5)

                            text: "1"

                            inputMethodHints:
                                Qt.ImhDigitsOnly

                            enabled:
                                !root.taskSyncRunning &&
                                taskList.currentIndex >= 0
                        }

                        Label {
                            width: units.gu(5)
                            height: parent.height

                            text: "Tage"
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Row {
                        width: parent.width
                        height: units.gu(5)

                        spacing: units.gu(1)

                        Button {
                            id: durationButton

                            width: parent.width
                            height: units.gu(5)

                            text: "Dauer setzen"

                            enabled:
                                !root.taskSyncRunning &&
                                taskList.currentIndex >= 0

                            onClicked: {
                                var duration =
                                    parseInt(selectedTaskDuration.text)

                                if (isNaN(duration) || duration < 1)
                                    duration = 1

                                selectedTaskDuration.text =
                                    duration.toString()

                                python.call(
                                    "backend.setTaskDuration",
                                    [
                                        taskList.currentIndex,
                                        duration
                                    ],
                                    function() {
                                        durationButton.text =
                                            "Dauer gesetzt: " +
                                            duration + " Tage"

                                        root.refreshPythonTaskModel()
                                    }
                                )
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        height: units.gu(5)

                        spacing: units.gu(1)

                        Button {
                            width: parent.width
                            height: units.gu(5)

                            text: "Startdatum setzen"

                            enabled:
                                !root.taskSyncRunning &&
                                taskList.currentIndex >= 0

                            onClicked: {
                                python.call(
                                    "backend.setTaskStartDate",
                                    [
                                        taskList.currentIndex,
                                        root.dateToTaskDate(
                                            root.selectedTaskStartDate
                                        )
                                    ],
                                    function() {
                                        startDateButton.text =
                                            "Gesetzt: " +
                                            root.formatTaskDate(
                                                root.selectedTaskStartDate
                                            )

                                        root.refreshPythonTaskModel()
                                    }
                                )
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        height: units.gu(5)

                        spacing: units.gu(1)

                        Button {
                            width: (parent.width - units.gu(4)) / 5
                            height: units.gu(5)

                            text: "↑"

                                        enabled: !root.taskSyncRunning

                            onClicked: {
                                if (taskList.currentIndex >= 0) {
                                    var oldIndex = taskList.currentIndex
                                    var task = pythonTaskModel.get(oldIndex)

                                    console.log(
                                        "MOVE UP BEFORE:",
                                        "index=", oldIndex,
                                        "uid=", task.uid,
                                        "title=", task.title
                                    )

                                    python.call(
                                        "backend.moveTaskUp",
                                        [oldIndex],
                                        function(result) {
                                            console.log(
                                                "MOVE UP PYTHON RESULT:",
                                                JSON.stringify(result)
                                            )

                                            root.refreshPythonTaskModel()

                                            console.log(
                                                "MOVE UP AFTER REFRESH:",
                                                "currentIndex=", taskList.currentIndex
                                            )
                                        }
                                    )
                                }
                            }
                        }

                        Button {
                            width: (parent.width - units.gu(4)) / 5
                            height: units.gu(5)

                            text: "↓"

                                        enabled: !root.taskSyncRunning

                            onClicked: {
                                if (taskList.currentIndex >= 0) {
                                    var oldIndex = taskList.currentIndex
                                    var task = pythonTaskModel.get(oldIndex)

                                    console.log(
                                        "MOVE DOWN BEFORE:",
                                        "index=", oldIndex,
                                        "uid=", task.uid,
                                        "title=", task.title
                                    )

                                    python.call(
                                        "backend.moveTaskDown",
                                        [oldIndex],
                                        function(result) {
                                            console.log(
                                                "MOVE DOWN PYTHON RESULT:",
                                                JSON.stringify(result)
                                            )

                                            root.refreshPythonTaskModel()

                                            console.log(
                                                "MOVE DOWN AFTER REFRESH:",
                                                "currentIndex=", taskList.currentIndex
                                            )
                                        }
                                    )
                                }
                            }
                        }

                        Button {
                            width: (parent.width - units.gu(4)) / 5
                            height: units.gu(5)

                            text: "←"

                                        enabled: !root.taskSyncRunning

                            onClicked: {
                                if (taskList.currentIndex >= 0)
                                    python.call(
                                        "backend.outdentTask",
                                        [taskList.currentIndex],
                                        function() {
                                            root.refreshPythonTaskModel()
                                        }
                                    )
                            }
                        }

                        Button {
                            width: (parent.width - units.gu(4)) / 5
                            height: units.gu(5)

                            text: "→"

                                        enabled: !root.taskSyncRunning

                            onClicked: {
                                if (taskList.currentIndex >= 0)
                                    python.call(
                                        "backend.indentTask",
                                        [taskList.currentIndex],
                                        function() {
                                            root.refreshPythonTaskModel()
                                        }
                                    )
                            }
                        }

                        Button {
                            width: (parent.width - units.gu(4)) / 5
                            height: units.gu(5)

                            text: "×"

                            onClicked: {
                                if (taskList.currentIndex >= 0) {
                                    python.call(
                                        "backend.removeTask",
                                        [taskList.currentIndex],
                                        function() {
                                            selectedTaskTitle.text = ""
                                            root.selectedTaskUid = ""
                                            taskList.currentIndex = -1
                                            root.refreshPythonTaskModel()
                                        }
                                    )
                                }
                            }
                        }
                    }


                    Button {
                        width: parent.width
                        height: units.gu(5)

                        text: "Synchronisieren"

                        enabled: !root.taskSyncRunning

                        onClicked: {
                            
                            root.taskSyncRunning = true
outputText.text = ""

                            python.call(
                                "backend.syncTasks",
                                [
                                    urlField.text,
                                    usernameField.text,
                                    passwordField.text
                                ],
                                function(result) {
                                    if (!result || !result.success) {
                                        outputText.text =
                                            "Python-Sync-Fehler: " +
                                            (result
                                             ? result.error
                                             : "Keine Antwort")
                                        root.taskSyncRunning = false
                                        return
                                    }

                                    outputText.text =
                                        "Synchronisation abgeschlossen.\n" +
                                        "Tasks: " +
                                        result.results.length

                                    root.refreshPythonTaskModel()
                                    root.taskSyncRunning = false
                                }
                            )
                        }
                    }

                    Label {
                        width: parent.width

                        text: "Status"

                        font.pixelSize: units.gu(2)
                    }

                    Rectangle {
                        width: parent.width
                        height: units.gu(15)

                        color: "transparent"

                        border.color: "gray"
                        border.width: 1

                        clip: true

                        Flickable {
                            id: outputFlickable

                            x: units.gu(1)
                            y: units.gu(1)

                            width: parent.width - units.gu(2)
                            height: parent.height - units.gu(2)

                            contentWidth: width
                            contentHeight: outputText.height

                            clip: true

                            TextEdit {
                                id: outputText

                                x: 0
                                y: 0

                                width: outputFlickable.width

                                readOnly: true

                                wrapMode: TextEdit.Wrap

                                font.pixelSize: units.dp(12)

                                text: "Synchronisationsausgabe"
                            }
                        }
                    }

                    Button {
                        width: parent.width
                        height: units.gu(5)

                        text: "Zurück"

                        onClicked: root.page = 0
                    }
                }


                /* =====================================================
                   AUFGABE ANLEGEN
                   ===================================================== */

                /* =====================================================
                   GANTT-DIAGRAMM
                   ===================================================== */

                Column {
                    id: ganttPage

                    width: parent.width
                    spacing: units.gu(1)

                    visible: root.page === 4

                    property real pixelsPerDay: 35

                    function dateValue(text) {
                        if (!text || text.length !== 8)
                            return null

                        var y = parseInt(text.substring(0, 4))
                        var m = parseInt(text.substring(4, 6)) - 1
                        var d = parseInt(text.substring(6, 8))

                        return new Date(y, m, d)
                    }

                    function minDate() {
                        var result = null

                        for (var i = 0; i < pythonTaskModel.count; ++i) {
                            var t = pythonTaskModel.get(i)
                            var d = dateValue(t.dtstart)

                            if (d && (!result || d < result))
                                result = d
                        }

                        return result
                    }

                    function maxDate() {
                        var result = null

                        for (var i = 0; i < pythonTaskModel.count; ++i) {
                            var t = pythonTaskModel.get(i)
                            var d = dateValue(t.due)

                            if (d && (!result || d > result))
                                result = d
                        }

                        return result
                    }

                    function dayDiff(a, b) {
                        return Math.round(
                            (b.getTime() - a.getTime()) /
                            (24 * 60 * 60 * 1000)
                        )
                    }

                    function formatDate(d) {
                        if (!d)
                            return ""

                        var day = d.getDate()
                        var month = d.getMonth() + 1

                        return (
                            (day < 10 ? "0" : "") + day +
                            "." +
                            (month < 10 ? "0" : "") + month
                        )
                    }

                    Label {
                        width: parent.width
                        text: "Gantt-Diagramm"
                        font.pixelSize: units.gu(2.5)
                    }

                    Row {
                        width: parent.width
                        spacing: units.gu(1)

                        Button {
                            width: (parent.width - 4 * units.gu(1)) / 5
                            height: units.gu(4)
                            text: "−"

                            onClicked: {
                                ganttContent.pixelsPerDay =
                                    Math.max(
                                        10,
                                        ganttContent.pixelsPerDay - 5
                                    )
                            }
                        }

                        Button {
                            width: (parent.width - 4 * units.gu(1)) / 5
                            height: units.gu(4)
                            text: "Woche"

                            onClicked: {
                                ganttContent.pixelsPerDay = 20
                            }
                        }

                        Button {
                            width: (parent.width - 4 * units.gu(1)) / 5
                            height: units.gu(4)
                            text: "Tag"

                            onClicked: {
                                ganttContent.pixelsPerDay = 35
                            }
                        }

                        Button {
                            width: (parent.width - 4 * units.gu(1)) / 5
                            height: units.gu(4)
                            text: "+"

                            onClicked: {
                                ganttContent.pixelsPerDay =
                                    Math.min(
                                        100,
                                        ganttContent.pixelsPerDay + 5
                                    )
                            }
                        }

                        Button {
                            width: (parent.width - 4 * units.gu(1)) / 5
                            height: units.gu(4)
                            text: "Zurück"

                            onClicked: {
                                root.page = 2
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: units.gu(45)

                        border.color: "gray"
                        border.width: 1
                        color: "transparent"

                        clip: true

                        Flickable {
                            id: ganttFlickable

                            anchors.fill: parent

                            contentWidth:
                                Math.max(
                                    width,
                                    ganttContent.width
                                )

                            contentHeight:
                                Math.max(
                                    height,
                                    ganttContent.height
                                )

                            flickableDirection:
                                Flickable.HorizontalAndVerticalFlick

                            boundsBehavior:
                                Flickable.StopAtBounds

                            Item {
                                id: ganttContent

                                property real pixelsPerDay: 35

                            function dateValue(value) {
                                if (!value)
                                    return null

                                var s = String(value)

                                if (s.length === 8) {
                                    var y = parseInt(s.substring(0, 4))
                                    var m = parseInt(s.substring(4, 6)) - 1
                                    var d = parseInt(s.substring(6, 8))
                                    return new Date(y, m, d)
                                }

                                var result = new Date(s)
                                return isNaN(result.getTime()) ? null : result
                            }

                            function calculateMinDate() {
                                var result = null

                                for (var i = 0;
                                     i < pythonTaskModel.count;
                                     ++i) {

                                    var t = pythonTaskModel.get(i)
                                    var d = dateValue(t.dtstart)

                                    if (d && (!result || d < result))
                                        result = d
                                }

                                return result
                            }

                            function calculateMaxDate() {
                                var result = null

                                for (var i = 0;
                                     i < pythonTaskModel.count;
                                     ++i) {

                                    var t = pythonTaskModel.get(i)
                                    var d = dateValue(t.due)

                                    if (d && (!result || d > result))
                                        result = d
                                }

                                return result
                            }

                            function dayDiff(a, b) {
                                if (!a || !b)
                                    return 0

                                return Math.round(
                                    (b.getTime() - a.getTime()) /
                                    (24 * 60 * 60 * 1000)
                                )
                            }

                            function formatDate(d) {
                                if (!d)
                                    return ""

                                var day = d.getDate()
                                var month = d.getMonth() + 1

                                return (
                                    (day < 10 ? "0" : "") + day +
                                    "." +
                                    (month < 10 ? "0" : "") + month
                                )
                            }


                                width: Math.max(
                                    ganttFlickable.width,
                                    ganttContent.labelWidth +
                                    ganttContent.pixelsPerDay *
                                    ganttContent.ganttDays
                                )

                                height:
                                    units.gu(7) +
                                    pythonTaskModel.count *
                                    units.gu(5)

                                /*
                                 * Die Datumswerte hängen ausdrücklich von
                                 * pythonTaskModel.count ab. Dadurch wird die
                                 * Berechnung auch nach einem kompletten
                                 * Model-Refresh erneut ausgeführt.
                                 */

                                property var startDate:
                                    root.ganttModelRevision >= 0 &&
                                    pythonTaskModel.count > 0
                                    ? calculateMinDate()
                                    : null

                                property var endDate:
                                    root.ganttModelRevision >= 0 &&
                                    pythonTaskModel.count > 0
                                    ? calculateMaxDate()
                                    : null

                                property int ganttDays:
                                    startDate && endDate
                                    ? parentColumn.dayDiff(
                                          startDate,
                                          endDate
                                      ) + 1
                                    : 1

                                property real labelWidth:
                                    units.gu(18)

                                Column {
                                    id: parentColumn
                                    objectName: "ganttParentColumn"

                                    visible: false

                                    property real pixelsPerDay:
                                        ganttPage.pixelsPerDay

                                    function minDate() {
                                        return ganttContent.minDate()
                                    }

                                    function maxDate() {
                                        return ganttContent.maxDate()
                                    }

                                    function dayDiff(a, b) {
                                        return ganttContent.dayDiff(a, b)
                                    }
                                }

                                Rectangle {
                                    x: 0
                                    y: 0
                                    width: ganttContent.labelWidth
                                    height: ganttContent.height

                                    color: "transparent"

                                    border.color: "#cccccc"
                                    border.width: 1
                                }

                                Row {
                                    x: ganttContent.labelWidth
                                    y: 0

                                    Repeater {
                                        model: ganttContent.ganttDays

                                        delegate: Rectangle {
                                            width:
                                                ganttContent.pixelsPerDay

                                            height: units.gu(7)

                                            color: "transparent"

                                            border.color: "#dddddd"
                                            border.width: 1

                                            Label {
                                                anchors.centerIn: parent

                                                text: {
                                                    if (!ganttContent.startDate)
                                                        return ""

                                                    var d =
                                                        new Date(
                                                            ganttContent.startDate
                                                        )

                                                    d.setDate(
                                                        d.getDate() + index
                                                    )

                                                    return ganttContent.formatDate(d)
                                                }

                                                font.pixelSize:
                                                    units.gu(1.2)
                                            }
                                        }
                                    }
                                }

                                Repeater {
                                    model: pythonTaskModel

                                    delegate: Item {
                                        width: ganttContent.width
                                        height: units.gu(5)

                                        y:
                                            units.gu(7) +
                                            index * units.gu(5)

                                        Label {
                                            x: 0
                                            y: 0

                                            width:
                                                ganttContent.labelWidth -
                                                units.gu(1)

                                            height: parent.height

                                            verticalAlignment:
                                                Text.AlignVCenter

                                            elide:
                                                Text.ElideRight

                                            text: {
                                                var t =
                                                    pythonTaskModel.get(index)

                                                var indent =
                                                    ""

                                                for (
                                                    var n = 0;
                                                    n < t.level;
                                                    ++n
                                                )
                                                    indent += "    "

                                                return (
                                                    indent +
                                                    (t.wbs
                                                     ? t.wbs + " "
                                                     : "") +
                                                    t.title
                                                )
                                            }

                                            font.pixelSize:
                                                units.gu(1.6)
                                        }

                                        Rectangle {
                                            x: ganttContent.labelWidth
                                            y: 0

                                            width:
                                                ganttContent.ganttDays *
                                                ganttContent.pixelsPerDay

                                            height: parent.height

                                            color: "transparent"

                                            border.color: "#eeeeee"
                                            border.width: 1
                                        }

                                        Rectangle {
                                            id: taskBar

                                            y: units.gu(1)

                                            height: units.gu(3)

                                            color: "#607D8B"
                                            z: 10

                                            visible: {
                                                var t =
                                                    pythonTaskModel.get(index)

                                                return !!(
                                                    ganttContent.startDate &&
                                                    t.dtstart &&
                                                    t.due
                                                )
                                            }

                                            x: {
                                                var t =
                                                    pythonTaskModel.get(index)

                                                if (
                                                    !ganttContent.startDate ||
                                                    !t.dtstart
                                                )
                                                    return 0

                                                var d =
                                                    ganttContent.dateValue(
                                                        String(t.dtstart)
                                                    )

                                                if (!d)
                                                    return 0

                                                var result =
                                                    ganttContent.labelWidth +
                                                    ganttContent.dayDiff(
                                                        ganttContent.startDate,
                                                        d
                                                    ) *
                                                    ganttContent.pixelsPerDay

                                                console.log(
                                                    "[GANTT BAR]",
                                                    index,
                                                    t.title,
                                                    "x=", result
                                                )

                                                return result
                                            }

                                            width: {
                                                var t =
                                                    pythonTaskModel.get(index)

                                                if (!t || !t.dtstart || !t.due)
                                                    return 0

                                                var a =
                                                    ganttContent.dateValue(
                                                        String(t.dtstart)
                                                    )

                                                var b =
                                                    ganttContent.dateValue(
                                                        String(t.due)
                                                    )

                                                if (!a || !b)
                                                    return 0

                                                var days =
                                                    ganttContent.dayDiff(a, b)

                                                var result = Math.max(
                                                    ganttContent.pixelsPerDay,
                                                    (days + 1) *
                                                    ganttContent.pixelsPerDay
                                                )

                                                console.log(
                                                    "[GANTT BAR]",
                                                    index,
                                                    t.title,
                                                    "width=", result,
                                                    "days=", days
                                                )

                                                return result
                                            }

                                            radius: units.gu(0.5)

                                            border.color: "black"
                                            border.width: 1

                                            Component.onCompleted: {
                                                var t = pythonTaskModel.get(index)

                                                console.log(
                                                    "[GANTT]",
                                                    "count=", pythonTaskModel.count,
                                                    "start=", ganttContent.startDate,
                                                    "end=", ganttContent.endDate,
                                                    "ppd=", ganttContent.pixelsPerDay,
                                                    "task=", t.title,
                                                    "dtstart=", t.dtstart,
                                                    "due=", t.due
                                                )
                                            }

                                            Text {
                                                anchors.fill: parent
                                                anchors.leftMargin:
                                                    units.gu(0.5)
                                                anchors.rightMargin:
                                                    units.gu(0.5)

                                                verticalAlignment:
                                                    Text.AlignVCenter

                                                elide:
                                                    Text.ElideRight

                                                text: {
                                                    var t =
                                                        pythonTaskModel.get(
                                                            index
                                                        )

                                                    return t.title
                                                }

                                                font.pixelSize:
                                                    units.gu(1.3)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Label {
                        width: parent.width

                        text: {
                            if (pythonTaskModel.count === 0)
                                return "Keine Tasks."

                            if (!ganttContent.startDate)
                                return "Keine Datumsdaten vorhanden."

                            return (
                                "Zeitraum: " +
                                ganttContent.formatDate(
                                    ganttContent.startDate
                                ) +
                                " – " +
                                ganttContent.formatDate(
                                    ganttContent.endDate
                                )
                            )
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: units.gu(1)

                    visible: root.page === 3

                    Label {
                        width: parent.width

                        text: "Neue Aufgabe"

                        font.pixelSize: units.gu(2.5)
                    }

                    TextField {
                        id: titleField

                        width: parent.width

                        placeholderText: "Aufgabentitel"
                    }

                    Label {
                        width: parent.width

                        text: "Ebene"
                    }

                    OptionSelector {
                        id: levelSelector

                        width: parent.width

                        text: "Ebene"

                        selectedIndex: 0

                        model: [
                            "Ebene 0",
                            "Ebene 1",
                            "Ebene 2",
                            "Ebene 3",
                            "Ebene 4"
                        ]
                    }

                    Label {
                        width: parent.width

                        text: "Dauer in Tagen"
                    }

                    TextField {
                        id: durationField

                        width: parent.width

                        text: "1"

                        inputMethodHints:
                            Qt.ImhDigitsOnly
                    }

                    Button {
                        width: parent.width
                        height: units.gu(5)

                        text: "Aufgabe anlegen"

                        onClicked: {
                            var duration =
                                parseInt(durationField.text)

                            if (isNaN(duration) || duration < 1)
                                duration = 1

                            var projectMin = ganttPage.minDate()

                            if (!projectMin) {
                                console.log(
                                    "NEW TASK: Kein Projektminimum vorhanden"
                                )

                                outputText.text =
                                    "Aufgabe kann nicht angelegt werden: " +
                                    "kein Projektminimum vorhanden."

                                return
                            }

                            var dueDate =
                                new Date(projectMin.getTime())

                            dueDate.setDate(
                                dueDate.getDate() + duration - 1
                            )

                            function formatTaskDate(d) {
                                return (
                                    d.getFullYear() +
                                    String(d.getMonth() + 1).padStart(2, "0") +
                                    String(d.getDate()).padStart(2, "0")
                                )
                            }

                            var dtstart =
                                formatTaskDate(projectMin)

                            var due =
                                formatTaskDate(dueDate)

                            console.log(
                                "NEW TASK:",
                                "title=", titleField.text,
                                "level=", levelSelector.selectedIndex,
                                "duration=", duration,
                                "dtstart=", dtstart,
                                "due=", due
                            )

                            python.call(
                                "backend.addTask",
                                [
                                    titleField.text,
                                    levelSelector.selectedIndex,
                                    duration,
                                    dtstart,
                                    due
                                ],
                                function(result) {
                                    titleField.text = ""
                                    durationField.text = "1"
                                    levelSelector.selectedIndex = 0

                                    root.refreshPythonTaskModel()
                                    root.page = 2
                                }
                            )
                        }
                    }

                    Button {
                        width: parent.width
                        height: units.gu(5)

                        text: "Abbrechen"

                        onClicked: root.page = 2
                    }
                }
            }
        }
    }



    
    // =========================================================
    // SYNC-SPERRE FÜR DIE TASK-SEITE
    // =========================================================
    Rectangle {
        id: taskSyncOverlay

        anchors.fill: parent

        visible: root.page === 2 && root.taskSyncRunning

        color: "white"
        opacity: 0.65

        z: 1000

        MouseArea {
            anchors.fill: parent
            enabled: taskSyncOverlay.visible

            onClicked: {
                // Absichtlich keine Aktion.
                // Die komplette Task-Seite bleibt während
                // des Syncs gesperrt.
            }
        }

        Label {
            anchors.centerIn: parent

            text: "Synchronisiere ..."
            font.pixelSize: units.gu(2.2)

            opacity: 1.0
        }
    }

}
