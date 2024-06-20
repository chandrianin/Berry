import QtQuick 2.15
import QtQuick.Controls
import QSystemTrayIcon

ApplicationWindow {
    id: mainWindow
    width: Screen.width
    height: Screen.height - 48
    flags: Qt.FramelessWindowHint | Qt.WindowTransparentForInput | Qt.WindowStaysOnTopHint
    visible: true
    color: "transparent"

    property int posX: 0
    property int posY: 0

    property int moveValue: 3

    Timer {
        id: moveTimer
        interval: 10 // Интервал в миллисекундах
        repeat: true // Повторять выполнение
        running: false // Не запускать таймер сразу
        onTriggered: {
            horizontalMove()
        }
    }

    function deltaMove(Y, y, X, x) {
        let dx = Math.abs(X - x);
        let dy = Math.abs(Y - y);
        if (dx < 2 && dy < 2){
            return {x: 0, y: 0};
        }

        let k = dy/dx;
        let xMove = k * moveValue / Math.sqrt(1+ k * k)
        let yMove = moveValue / Math.sqrt(1+ k * k)
        // console.log(xMove, yMove);

        return {x: xMove, y: yMove}
    }

    function horizontalMove() {

        let berryX = berryEnviroinment.x + berry.x + berry.width/2;
        let berryY = berryEnviroinment.y + berry.y + berry.height/2;
        let coordinates = deltaMove(posX, berryX, posY, berryY);
        let x = coordinates.x;
        let y = coordinates.y;
        console.log(berryX, berryY);
        if (posX > berryX && posY > berryY) {
            berryEnviroinment.x += x;
            berryEnviroinment.y += y;
        }
        else if (posX < berryX && posY > berryY) {
            berryEnviroinment.x -= x;
            berryEnviroinment.y += y;
        }
        else if (posX < berryX && posY < berryY) {
            berryEnviroinment.x -= x;
            berryEnviroinment.y -= y;
        }
        else if (posX > berryX && posY < berryY) {
            berryEnviroinment.x += x;
            berryEnviroinment.y -= y;
        }

    }


    QSystemTrayIcon {
        id: systemTray
        // visible: true
        // Инициализация
        Component.onCompleted: {
            icon = iconTray
            toolTip = "Berry"
            show()
        }
        onActivated: {
            mainWindow.flags = Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
            if (reason === 1){
                trayMenu.popup()
            }
        }
    }

    Menu {
        height: 58
        width: 70
        id: trayMenu
        MenuItem {
            text: qsTr("Move")
            onTriggered: moveTimer.running = true
        }
        MenuItem {
            text:qsTr("Exit")
            onTriggered: {
                // systemTray.visible = false
                systemTray.hide()
                Qt.quit()
        }

        // MouseArea {
        //     anchors.fill: parent
        // }
        }
    }


    Rectangle {
        id: container
        anchors.fill: parent
        color: "transparent"
        border.color: "red"
        border.width: 2
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onClicked: {
                moveTimer.running = false
                mainWindow.flags = Qt.FramelessWindowHint | Qt.WindowTransparentForInput | Qt.WindowStaysOnTopHint
            }
            onPositionChanged: {
                if (mouse.x < berry.width/2) {
                    posX = berry.width/2
                }
                else if (mouse.x > container.width - berry.width/2 - berryEnviroinment.width/2) {
                    posX = container.width - berry.width/2 - berryEnviroinment.width/2 - 5
                    // console.log("posX = ", container.width - berry.width/2)
                }
                else {
                    posX = mouse.x
                }

                if (mouse.y < berryEnviroinment.height - berry.height + berry.height/2) {
                    posY = berryEnviroinment.height - berry.height + berry.height/2 + 5
                }
                else if (mouse.y > container.height - berry.height/2) {
                    posY = container.height - berry.height/2
                }
                else {
                    posY = mouse.y
                }
            }
        }
        Rectangle {
            id: berryEnviroinment
            width: 405
            height: 300
            color: "transparent"
            border.color: "green"
            border.width: 2
            x: berry.width/2
            y: berry.height/2
            // anchors.horizontalCenter: parent.horizontalCenter
            // anchors.bottom: parent.bottom
            AnimatedImage
            {
                id: berry

                width: 200
                height: 200
                // antialiasing: true
                // asynchronous: true
                // scale: 1
                // horizontalAlignment: AnimatedImage.AlignHCenter
                // verticalAlignment: AnimatedImage.AlignVCenter

                cache: true
                // source: "../Images/Berry/15-7.gif"
                source: "Images/Berry/test.gif"
                // anchors.bottom: parent.bottom
                // speed: 1
                // anchors.horizontalCenter: parent.horizontalCenter
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        // berryEnviroinment.x += 1
                    }
                }

            }
            Image {
                id: dialog
                width: 250
                // height: 250
                source: "Images/einvironment/dialog.png"
                anchors.right: parent.right
                anchors.top: parent.top
                // x: 150
                // y: 120

            }
        }

    }


}
