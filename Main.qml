import QtQuick 2.15
// import QtQuick.Layouts
import QtQuick.Controls
// import QtQuick.Window 2.15
import QSystemTrayIcon



Window {
    id: mainWindow
    width: Screen.width
    height: Screen.height
    flags: Qt.FramelessWindowHint | Qt.WindowTransparentForInput | Qt.WindowStaysOnTopHint
    visible: true
    // title: qsTr("BarryTest")
    color: "transparent"

    Rectangle {
        id: container
        anchors.fill: parent
        color: "transparent"
        border.color: "red"
        border.width: 2

        MouseArea {
            anchors.fill: parent
            onClicked: {
                mainWindow.flags = Qt.FramelessWindowHint | Qt.WindowTransparentForInput | Qt.WindowStaysOnTopHint
            }
        }

        Rectangle {
            id: berryEnviroinment
            width: 400
            height: 400
            color: "transparent"
            border.color: "green"
            border.width: 2
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            AnimatedImage
            {
                id: berry

                width: 200
                height: 200
                antialiasing: true
                // asynchronous: true
                // scale: 1
                // horizontalAlignment: AnimatedImage.AlignHCenter
                // verticalAlignment: AnimatedImage.AlignVCenter

                cache: true
                // source: "../Images/Berry/15-7.gif"
                source: "Images/Berry/test.gif"
                // anchors.bottom: parent.bottom
                speed: 1
                // anchors.horizontalCenter: parent.horizontalCenter
                anchors.left: parent.left
                anchors.bottom: parent.bottom

            }
            Image {
                id: dialog
                width: 250
                height: 250
                source: "Images/einvironment/dialog.png"
                anchors.right: parent.right
                anchors.top: parent.top
                // x: 150
                // y: 120

            }
        }


    }

    QSystemTrayIcon {
        id: systemTray

        // Инициализация
        Component.onCompleted: {
            icon = iconTray
            // toolTip = "Tray"
            show()
        }
        onActivated: {
            if (reason === 1){
                mainWindow.flags = Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
                trayMenu.popup()
            }
        }
    }

    Menu {
        id: trayMenu
        MenuItem {
            text:qsTr("Exit")
            onTriggered: {
                systemTray.hide()
                Qt.quit()
            }
        // MouseArea {
        //     anchors.fill: parent
        // }
        }
    }
}
