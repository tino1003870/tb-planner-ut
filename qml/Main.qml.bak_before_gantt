import QtQuick 2.7
import Lomiri.Components 1.3
import QtQuick.Layouts 1.3
import io.thp.pyotherside 1.5

MainView {
    id: root

    property bool taskSyncRunning: false

    ListModel {
        id: pythonTaskModel
    }

    function refreshPythonTaskModel() {
        var selectedUid = ""

        if (taskList.currentIndex >= 0 &&
            taskList.currentIndex < pythonTaskModel.count) {

            selectedUid =
                pythonTaskModel.get(taskList.currentIndex).uid

            console.log(
                "REFRESH BEFORE:",
                "index=", taskList.currentIndex,
                "uid=", selectedUid
            )
        }

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
                                        selectedTaskTitle.text = title
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

                            python.call(
                                "backend.addTask",
                                [
                                    titleField.text,
                                    levelSelector.selectedIndex,
                                    duration
                                ],
                                function() {
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
