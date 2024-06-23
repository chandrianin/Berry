import QtQuick 2.15
import QtQuick.Controls
import QtMultimedia
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

    property int chargePosX: 0
    property int chargePosY: 0


    property real moveValue: 3.5

    property int standCounter: 0
    property int standIterations: 10

    property int activeChargeIterations: 20
    property int activeChargeCounter: 0
    property int disabledChargindInterval: 10000

    property string targetText: ""
    property int targetTextLength: 0
    property string newText: ""
    property int symbolIndex: 0

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
            if (standCounter < standIterations) {
                standHappyBerryFirstFrame();
            }
            else {
                standHappyBerry();
            }
        }
    }

    Timer {
        id: stopChargingTimer
        running: false
        repeat: false
        interval: chargingBerry.frameCount * chargingBerry.frameDuration
        onTriggered: {
            standHappyBerryFirstFrame();
            moveTimer.running = true;

            console.log("charging disabled");
            activationChargeTimer.running = false;
            waitChargingTimer.running = true;
        }
    }
    Timer {
        id: waitChargingTimer
        running: false
        repeat: false
        interval: disabledChargindInterval
        onTriggered: {
            if (posX > berryEnvironment.x + berry.x && posX < berryEnvironment.x + berry.x + berry.width && posY > berryEnvironment.y + berry.y && posY < berryEnvironment.y + berry.y + berry.height) {
                if (chargePosX > chargingModule.x && chargePosX < chargingModule.x + chargingModule.width && chargePosY > chargingModule.y && chargePosY < chargingModule.y + chargingModule.height){
                    waitChargingTimer.interval += disabledChargindInterval;
                    console.log("chargind block");
                }
                else {
                    console.log("charging enabled");
                    activationChargeTimer.running = true;
                    //TODO добавить анимцию появления chargingModule
                    chargingModule.visible = true;
                }
            }
        }
    }
    Timer {
        id: activationChargeTimer
        running: true
        repeat: true
        interval: 100
        onTriggered: {
            if (activeChargeCounter === activeChargeIterations) {
                chargingModule.visible = false;

                moveTimer.running = false;
                charge();
                stopChargingTimer.running = true;
                activeChargeCounter = 0;
            }
            else if (posX > berryEnvironment.x + berry.x && posX < berryEnvironment.x + berry.x + berry.width && posY > berryEnvironment.y + berry.y && posY < berryEnvironment.y + berry.y + berry.height) {
                if (chargePosX > chargingModule.x && chargePosX < chargingModule.x + chargingModule.width && chargePosY > chargingModule.y && chargePosY < chargingModule.y + chargingModule.height){
                    activeChargeCounter += 1;
                }
            }
            else {
                activeChargeCounter = 0;
            }
        }
    }

    Timer {
        id: action_1_stopTimer
        interval: action_1.frameCount * action_1.frameDuration
        running: false
        repeat: false
        onTriggered: {
            standHappyBerryFirstFrame()
            moveTimer.running = true
        }
    }
    Timer {
        id: action_2_stopTimer
        interval: action_2.frameCount * action_2.frameDuration
        running: false
        repeat: false
        onTriggered: {
            standHappyBerryFirstFrame()
            moveTimer.running = true
        }
    }
    Timer {
        id: action_3_stopTimer
        interval: action_3.frameCount * action_3.frameDuration
        running: false
        repeat: false
        onTriggered: {
            standHappyBerryFirstFrame()
            moveTimer.running = true
        }
    }

    Timer {
        id: textOutputTimer
        running: false
        repeat: true
        interval: 80
        onTriggered: {
            if (symbolIndex < targetTextLength) {
                newText += targetText[symbolIndex];
                textToDialog.text = newText;
                if (symbolIndex + 1 < targetTextLength && targetText[symbolIndex + 1] === " ") {
                    specialSymbolSound.play();
                } else if (targetText[symbolIndex] !== " ") {
                    symbolSound.play();
                }

                // произнести singleAudio
                symbolIndex += 1;
            }
            else {
                symbolIndex = 0;
                targetTextLength = 0;
                targetText = "";
                newText = "";
                textOutputTimer.running = false;
            }
            // console.log(symbolIndex);
        }
    }

    function test(){
        console.log("happy");
        console.log(dialog.width);
        console.log(dialog.height);
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
        standCounter = 0;
        standTimer.running = true
    }
    function standHappyBerryFirstFrame(){
        standCounter++;
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

    function charge(){
        stopSprits();
        chargingBerry.visible = true;
    }

    function randomAction() {
        let actions = Array(action_1, action_2, action_3);
        moveTimer.running = false
        stopSprits();
        let randomIndex = Math.ceil(Math.random() * (actions.length)) - 1;
        actions[randomIndex].visible = true;
        if (action_1.visible === true) {
            action_1_stopTimer.running = true;
        }
        else if (action_2.visible === true) {
            action_2_stopTimer.running = true;
        }
        else if (action_3.visible === true) {
            action_3_stopTimer.running = true;
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

        return {x: xMove, y: yMove}
    }
    function horizontalMove() {

        let berryX = berryEnvironment.x + berry.x + berry.width/2;
        let berryY = berryEnvironment.y + berry.y + berry.height/2;
        let coordinates = deltaMove(posX, berryX, posY, berryY);
        let x = coordinates.x;
        let y = coordinates.y;
        if (x === 0 && y === 0){
            standTimer.running = true;
            // console.log("stop");
            standHappyBerryFirstFrame();
            return
        }
        else if (posX > berryX && posY > berryY) {
            berryEnvironment.x += x;
            berryEnvironment.y += y;
        }
        else if (posX < berryX && posY > berryY) {
            berryEnvironment.x -= x;
            berryEnvironment.y += y;
        }
        else if (posX < berryX && posY < berryY) {
            berryEnvironment.x -= x;
            berryEnvironment.y -= y;
        }
        else if (posX > berryX && posY < berryY) {
            berryEnvironment.x += x;
            berryEnvironment.y -= y;
        }


        let tg = y/x;
        // console.log(posY - berryY);
        if (tg > -1 && tg <= 1 && posX - berryX > 0){
            // console.log("right");
            rightHappyMove();
        }
        else if ((tg > 1 || tg < -1) && posY - berryY < 0) {
            // console.log("top");
            topHappyMove();
        }
        else if (tg > -1 && tg <= 1 && posX - berryX < 0) {
            // console.log("left");
            leftHappyMove();
        }
        else if ((tg > 1 || tg < -1) && posY - berryY > 0) {
            // console.log("bottom");
            bottomHappyMove();
        }

    }

    function say(text) {
        targetText = text;
        dialog.visible = true;
        targetTextLength = targetText.length;
        textOutputTimer.running = true;
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
            onTriggered: {
                moveTimer.running = true;
                activationChargeTimer.running = true;
            }
        }
        MenuItem {
            text:qsTr("Exit")
            onTriggered: {
                systemTray.hide()
                Qt.quit()
            }
        }
    }

    SoundEffect {
        id: symbolSound
        source: "audio/singleBerryTalk.wav"
    }
    SoundEffect {
        id: specialSymbolSound
        source: "audio/specialSingleBerryTalk.wav"
    }

    Rectangle {
        id: container
        anchors.fill: parent
        color: "transparent"
        // border.color: "red"
        // border.width: 2
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onClicked: {
                if (chargingBerry.visible === true){
                    mainWindow.flags = Qt.FramelessWindowHint | Qt.WindowTransparentForInput | Qt.WindowStaysOnTopHint
                }
                else if (posX > berryEnvironment.x + berry.x && posX < berryEnvironment.x + berry.x + berry.width && posY > berryEnvironment.y + berry.y && posY < berryEnvironment.y + berry.y + berry.height) {
                    randomAction();
                }
                else {
                    moveTimer.running = false; // Включение режима ходьюы
                    activationChargeTimer.running = false; // Выключение зарядки
                    standHappyBerryFirstFrame(); // Акивация спрайта "стою и ничего не делаю"
                    mainWindow.flags = Qt.FramelessWindowHint | Qt.WindowTransparentForInput | Qt.WindowStaysOnTopHint // Флаги безоконного приложения над всеми окнами
                }

            }

            onPositionChanged: {
                if (!(chargingBerry.visible === true || action_1.visible === true || action_2.visible === true || action_3.visible === true)) {
                    if (mouse.x < berry.width/2) {
                        posX = berry.width/2
                    }
                    else if (mouse.x > container.width - berry.width/2 - berryEnvironment.width/2) {
                        posX = container.width - berry.width/2 - berryEnvironment.width/2 - 5
                    }
                    else {
                        posX = mouse.x
                    }

                    if (mouse.y < berryEnvironment.height - berry.height + berry.height/2) {
                        posY = berryEnvironment.height - berry.height + berry.height/2 + 5
                    }
                    else if (mouse.y > container.height - berry.height/2) {
                        posY = container.height - berry.height/2
                    }
                    else {
                        posY = mouse.y
                    }
                    chargePosX = mouse.x;
                    chargePosY = mouse.y;
                }

            }
        }

        Rectangle {
            id: berryEnvironment
            width: 405
            height: 300
            color: "transparent"
            // border.color: "green"
            // border.width: 2
            x: container.width/2 - berry.width/2
            y: container.height/2 - berryEnvironment.height + berry.height/2


            Image {
                id: dialog
                visible: true
                width: 250
                source: "images/environment/dialog.png"
                anchors.right: parent.right
                anchors.top: parent.top
            }

            FontLoader {
                id: balsamiq
                source: "font/BalsamiqSans-BoldItalic.ttf"
            }
            Text {
                id: textToDialog
                text: ""

                width: 250
                height: 146

                font.family: balsamiq.name
                wrapMode: Text.Wrap
                font.pixelSize: 15
                lineHeight: 0.89
                font.italic: true
                font.bold: true

                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignTop
                color: "#693875"


                anchors.right: parent.right
                anchors.top: parent.top
                padding: 15
                leftPadding: 16
                rightPadding: 16
            }

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
                    source: "images/Berry/happy/stand_5.png"
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
                    source: "images/Berry/happy/stand_5.png"
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
                    source: "images/Berry/happy/moveRight_8.png"
                    frameCount: 8
                    frameWidth: 200
                    frameHeight: 200
                    frameDuration: 125
                }
                AnimatedSprite {
                    id: moveHappyLeft
                    antialiasing: false
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "images/Berry/happy/moveLeft_8.png"
                    frameCount: 8
                    frameWidth: 200
                    frameHeight: 200
                    frameDuration: 125
                }
                AnimatedSprite {
                    id: moveHappyBottom
                    antialiasing: false
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "images/Berry/happy/moveBottom_6.png"
                    frameCount: 6
                    frameWidth: 200
                    frameHeight: 200
                    frameDuration: 125
                }
                AnimatedSprite {
                    id: moveHappyTop
                    antialiasing: false
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "images/Berry/happy/moveTop_6.png"
                    frameCount: 6
                    frameWidth: 200
                    frameHeight: 200
                    frameDuration: 125
                }

                AnimatedSprite {
                    id: chargingBerry
                    antialiasing: false
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "images/Berry/charging.png"
                    frameCount: 39
                    frameWidth: 200
                    frameHeight: 200
                    frameDuration: 125
                }

                AnimatedSprite {
                    id: action_1
                    antialiasing: true
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "images/Berry/action_1.png"
                    frameCount: 11
                    frameWidth: 200
                    frameHeight: 200
                    frameDuration: 125
                }
                AnimatedSprite {
                    id: action_2
                    antialiasing: true
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "images/Berry/action_2.png"
                    frameCount: 14
                    frameWidth: 200
                    frameHeight: 200
                    frameDuration: 125
                }
                AnimatedSprite {
                    id: action_3
                    antialiasing: true
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "images/Berry/action_3.png"
                    frameCount: 19
                    frameWidth: 200
                    frameHeight: 200
                    frameDuration: 125
                }

            }

        }

        Image {
            id: chargingModule
            antialiasing: true;
            source: "images/environment/chargingModule.png"
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 1
            anchors.leftMargin: 1
        }
    }
}
