import QtQuick 2.7
import Lomiri.Components 1.3
import QtQuick.Layouts 1.3

MainView {
    id: root

    objectName: "mainView"
    applicationName: "tb-planner.com.tino"

    width: units.gu(45)
    height: units.gu(75)

    Page {
        anchors.fill: parent

        header: PageHeader {
            id: header
            title: i18n.tr("TB Planner")
        }

        ColumnLayout {
            anchors {
                top: header.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                topMargin: units.gu(2)
            leftMargin: units.gu(2)
            rightMargin: units.gu(2)
            bottomMargin: 0
            }

            spacing: units.gu(1)

            Label {
                text: i18n.tr("CalDAV-Synchronisation")
                fontSize: "large"
                Layout.alignment: Qt.AlignHCenter
            }

            Button {
                text: i18n.tr("GMX synchronisieren")
                Layout.fillWidth: true

                onClicked: {
                    outputText.text = ""
                    syncManager.syncGmx()
                }
            }

            Button {
                text: i18n.tr("WEB.DE synchronisieren")
                Layout.fillWidth: true

                onClicked: {
                    outputText.text = ""
                    syncManager.syncWebDe()
                }
            }

            Button {
                text: i18n.tr("Beide synchronisieren")
                Layout.fillWidth: true

                onClicked: {
                    outputText.text = ""
                    syncManager.syncBoth()
                }
            }

            Label {
                text: i18n.tr("Ausgabe")
                fontSize: "large"
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true

                color: "transparent"
                border.color: "gray"
                border.width: 2
                clip: true

                Flickable {
                    id: outputFlickable

                    anchors.fill: parent
                    anchors.margins: units.gu(1)

                    contentWidth: width
                    contentHeight: outputText.height

                    boundsBehavior: Flickable.StopAtBounds

                    TextEdit {
                        id: outputText

                        width: outputFlickable.width

                        readOnly: true
                        wrapMode: TextEdit.Wrap

                        text: i18n.tr(
                            "Noch keine Synchronisation gestartet."
                        )

                        font.pixelSize: units.dp(14)
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
                    Math.max(0,
                        outputFlickable.contentHeight -
                        outputFlickable.height)
            })
        }
    }
}
