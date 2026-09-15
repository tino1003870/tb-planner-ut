import QtQuick 2.7
import Lomiri.Components 1.3
import QtQuick.Layouts 1.3

MainView {
    id: root

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
                            outputText.text =
                                "Laden der Verbindungseinstellungen\n"
                                + "URL und Benutzername.\n"
                                + "Passwort wird nicht gespeichert."
                        }
                    }

                    Button {
                        width: parent.width
                        height: units.gu(5)

                        text: "Einstellungen speichern"

                        onClicked: {
                            outputText.text =
                                "Speichern der Verbindungseinstellungen\n"
                                + "URL und Benutzername.\n"
                                + "Passwort wird nicht gespeichert."
                        }
                    }

                    Item {
                        width: parent.width
                        height: units.gu(1)
                    }

                    Button {
                        width: parent.width
                        height: units.gu(5)

                        text: "VTODOs aus web.de lesen"

                        onClicked: {
                            outputText.text = ""
                            taskModel.clear()

                            syncManager.loadWebDeTasks(
                                usernameField.text,
                                passwordField.text
                            )

                            root.page = 2
                        }
                    }

                    Button {
                        width: parent.width
                        height: units.gu(5)

                        text: "Synchronisieren"

                        onClicked: {
                            outputText.text = ""

                            syncManager.syncBoth()
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

                            model: taskModel

                            clip: true

                            boundsBehavior: Flickable.StopAtBounds

                            delegate: Item {
                                width: taskList.width
                                height: units.gu(5)

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

                                    Button {
                                        width: units.gu(5)
                                        height: units.gu(4)

                                        text: "×"

                                        onClicked:
                                            taskModel.removeTask(index)
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

                        text: "Synchronisieren"

                        onClicked: {
                            outputText.text = ""

                            syncManager.syncBoth()
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

                            taskModel.addTask(
                                titleField.text,
                                levelSelector.selectedIndex,
                                duration
                            )

                            titleField.text = ""
                            durationField.text = "1"
                            levelSelector.selectedIndex = 0

                            root.page = 2
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


    Connections {
        target: syncManager

        onOutputChanged: {
            outputText.text += text

            Qt.callLater(function() {
                outputFlickable.contentY =
                    Math.max(
                        0,
                        outputFlickable.contentHeight -
                        outputFlickable.height
                    )
            })
        }
    }
}
