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

    property int moveValue: 2

    property int counter: 0
    property int standIterations: 3

    Timer {
        id: moveTimer
        interval: 10 // Интервал в миллисекундах
        repeat: true // Повторять выполнение
        running: false // Не запускать таймер сразу
        onTriggered: {
            horizontalMove()
        }
    }

    Timer {
        id: standTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            if (counter < standIterations) {
                standHappyBerryFirstFrame();
            }
            else {
                standHappyBerry();
            }
        }
    }
    function stopSprits(){
        standTimer.running=false
        for (let i = 0; i < berry.children.length; i++) {
            berry.children[i].visible = false;
        }
    }

    function standHappyBerry(){
        stopSprits();
        standHappy.visible = true;
        counter = 0;
        standTimer.running = true
    }
    function standHappyBerryFirstFrame(){
        counter++;
        stopSprits();
        standHappyFirstFrame.visible = true;
        standTimer.running = true
    }

    function rightHappyMove() {
        stopSprits();
        moveHappyRight.visible = true;
    }
    function topHappyMove() {
        stopSprits();
        moveHappyTop.visible = true;
    }
    function leftHappyMove() {
        stopSprits();
        moveHappyLeft.visible = true;
    }
    function bottomHappyMove() {
        stopSprits();
        moveHappyBottom.visible = true;
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

        return {x: xMove, y: yMove}
    }

    function horizontalMove() {

        let berryX = berryEnviroinment.x + berry.x + berry.width/2;
        let berryY = berryEnviroinment.y + berry.y + berry.height/2;
        let coordinates = deltaMove(posX, berryX, posY, berryY);
        let x = coordinates.x;
        let y = coordinates.y;
        if (x === 0 && y === 0){
            standTimer.running = true;
            console.log("stop");
            standHappyBerryFirstFrame();
            return
        }
        else if (posX > berryX && posY > berryY) {
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


        let tg = y/x;
        console.log(posY - berryY);
        if (tg > -1 && tg <= 1 && posX - berryX > 0){
            console.log("right");
            rightHappyMove();
        }
        else if ((tg > 1 || tg < -1) && posY - berryY < 0) {
            console.log("top");
            topHappyMove();
        }
        else if (tg > -1 && tg <= 1 && posX - berryX < 0) {
            console.log("left");
            leftHappyMove();
        }
        else if ((tg > 1 || tg < -1) && posY - berryY > 0) {
            console.log("bottom");
            bottomHappyMove();
        }

    }


    QSystemTrayIcon {
        id: systemTray

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
                standHappyBerryFirstFrame();
                mainWindow.flags = Qt.FramelessWindowHint | Qt.WindowTransparentForInput | Qt.WindowStaysOnTopHint
            }
            onPositionChanged: {
                if (mouse.x < berry.width/2) {
                    posX = berry.width/2
                }
                else if (mouse.x > container.width - berry.width/2 - berryEnviroinment.width/2) {
                    posX = container.width - berry.width/2 - berryEnviroinment.width/2 - 5
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
            Rectangle {
                id: berry
                width: 200
                height: 200
                color: "transparent"
                anchors.left: parent.left
                anchors.bottom: parent.bottom

                AnimatedSprite {
                    id: standHappy
                    antialiasing: false
                    interpolate: false
                    width: 200
                    height: 200
                    source: "Images/Berry/happy/stand_5.png"
                    frameWidth: 200
                    frameHeight: 200
                    frameCount: 5
                    frameDuration: 200
                }

                AnimatedSprite {
                    id: standHappyFirstFrame
                    antialiasing: false
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "Images/Berry/happy/stand_5.png"
                    frameCount: 1
                    frameWidth: 200
                    frameHeight: 200
                    frameDuration: 1000
                }
                AnimatedSprite {
                    id: moveHappyRight
                    antialiasing: false
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "Images/Berry/happy/moveRight_8.png"
                    frameCount: 8
                    frameWidth: 200
                    frameHeight: 200
                    frameDuration: 200
                }
                AnimatedSprite {
                    id: moveHappyLeft
                    antialiasing: false
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "Images/Berry/happy/moveLeft_8.png"
                    frameCount: 8
                    frameWidth: 200
                    frameHeight: 200
                    frameDuration: 200
                }
                AnimatedSprite {
                    id: moveHappyBottom
                    antialiasing: false
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "Images/Berry/happy/moveBottom_6.png"
                    frameCount: 6
                    frameWidth: 200
                    frameHeight: 200
                    frameDuration: 200
                }
                AnimatedSprite {
                    id: moveHappyTop
                    antialiasing: false
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "Images/Berry/happy/moveTop_6.png"
                    frameCount: 6
                    frameWidth: 200
                    frameHeight: 200
                    frameDuration: 200
                }

            }

            Image {
                id: dialog
                visible: false
                width: 250
                source: "Images/einvironment/dialog.png"
                anchors.right: parent.right
                anchors.top: parent.top
            }
        }

    }


}
