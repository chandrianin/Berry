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

    property string       berryStatus:              "happy"
    property list<Timer>  actions:                  []
    property int          lastActionIndex:          0
    property list<string> textList:                 []
    property int          lastTextIndex:            0
    property list<int>    targetX:                  []      // координата X, к которой berry стремится в _moveBerry()
    property list<int>    targetY:                  []      // координата Y, к которой berry стремится в _moveBerry()
    property int          lastCoordinatesIndex:     0
    property bool         dayProcess:               false   // статус прохождения berry сюжета в текущий момент

    property int          posX:                     0       // координата X курсора, оптимизированные для перемещения berryEnvironment
    property int          posY:                     0       // координата Y курсора, оптимизированные для перемещения berryEnvironment

    property int          rawPosX:                  0       // координата X курсора без обработки
    property int          rawPosY:                  0       // координата Y курсора без обработки

    property real         moveValue:                3.5     // скорость перемещения berry за итерацию

    property int          standCounter:             0       // счётчик
    property int          standIterations:          1       // количество секунд, которое standBerry находится в статичном состоянии каждую итерацию

    property int          activeChargeIterations:   2       // количество секунд, необходимое для инициалиазции зарядки
    property int          activeChargeCounter:      0       // счётчик
    property int          disabledChargindInterval: 10      // количество секунд, необходимых для возобновления возможности зарядиться

    property string       targetText:               ""      // текст, который необходимо отобразить на экране
    property int          targetTextLength:         0       // длина текст, который необходимо отобразить на экране
    property string       newText:                  ""      // строка, отображаемая на экране. Каждая итерация добавляет следующий символ из targetText
    property int          symbolIndex:              0       // индекс добавляемого из targetText в newText символа

    property bool         isSay:                    false   // статус нахождения berry в состоянии говорения

    property bool         withBall:                 false   // статус взаимодействия ball и berry
    property real         ballTg:                   0       // значение тангенса угла между вектором направления ball и осью Ox
    property real         ballOxDirection:          0       // статус направления ball относительно оси Ox (>0, если направление положительно, <0 в противном случае)
    property real         ballSpeedRatio:           0.999   // коээцициент уменьшения скорости ball
    property real         ballCurrentSpeed:         15      // текущая скорость ball
    property int          ballCurrentCheckDelay:    0       // текущее время нахождения ball внутри container
    property int          ballMaxCheckDelay:        9000    // максимальное время нахождения ball внутри container, по окончании ball уходит за границы

    Timer {
        id: randomMoveTimer
        interval: 30000
        running: true
        repeat: true
        onTriggered: {
            console.log("random");
            targetX.push(Math.random() * (container.width - berry.width/2 - berryEnvironment.width) + berry.width/2);
            targetY.push(Math.random() * (container.height - berry.height/2 - berryEnvironment.height) + berry.height/2);
            _moveBerryTimer.start();
        }
    }
    Timer {
        id: randomSpriteTimer
        interval: 1500
        running: false
        repeat: true
        onTriggered: {
            stopSprites();
            berry.children[Math.ceil(Math.random() * berry.children.length - 1)].visible = true;
        }
    }

    Timer {
        id: moveTimer
        interval: 16 // Интервал в миллисекундах
        repeat: true // Повторять выполнение
        running: false // Не запускать таймер сразу
        onTriggered: {
            berryMove()
        }
    }

    Timer {
        id: standTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            if (standCounter < standIterations) {
                standBerryFirstFrame();
            }
            else {
                standBerry();
            }
        }
    }

    Timer {
        id: stopChargingTimer
        running: false
        repeat: false
        interval: chargingBerry.frameCount * chargingBerry.frameDuration
        onTriggered: {
            standBerryFirstFrame();
            moveTimer.running = true;

            console.log("charging disabled");
            activationChargeTimer.running = false;
            waitChargingTimer.running = true;
        }
    }
    Timer {
        id: waitChargingTimer
        running: false
        repeat: true
        interval: disabledChargindInterval * 1000
        onTriggered: {
            if (posX > berryEnvironment.x + berry.x && posX < berryEnvironment.x + berry.x + berry.width && posY > berryEnvironment.y + berry.y && posY < berryEnvironment.y + berry.y + berry.height) {
                console.log("charging block");
            }
            else {
                console.log("charging enabled");
                waitChargingTimer.running = false;
                activationChargeTimer.running = true;
                chargingModule.visible = true;
            }
        }
    }
    Timer {
        id: enablingChargeTimer
        running: false
        repeat: true

    }

    Timer {
        id: activationChargeTimer
        running: true
        repeat: true
        interval: 100
        onTriggered: {
            if (activeChargeCounter === activeChargeIterations * 10) {
                chargingModule.visible = false;

                moveTimer.running = false;
                charge();
                stopChargingTimer.running = true;
                activeChargeCounter = 0;
            }
            else if (posX > berryEnvironment.x + berry.x && posX < berryEnvironment.x + berry.x + berry.width && posY > berryEnvironment.y + berry.y && posY < berryEnvironment.y + berry.y + berry.height) {
                if (rawPosX > chargingModule.x && rawPosX < chargingModule.x + chargingModule.width && rawPosY > chargingModule.y && rawPosY < chargingModule.y + chargingModule.height){
                    activeChargeCounter += 1;
                }
            }
            else {
                activeChargeCounter = 0;
            }
        }
    }

    Timer {
        id: endingBallEndTimer
        running: false
        repeat: false
        interval: kickingBallEndBerry.frameCount * kickingBallEndBerry.frameDuration
        onTriggered: {
            kickingBallEndBerry.visible = false
            console.log("закончил пинать")
            standBerryFirstFrame()
        }
    }
    Timer {
        id: ballCreatingTimer
        running: false
        repeat: false
        interval: 25 * kickingBallStartBerry.frameDuration
        onTriggered: {
            console.log("мяч есть")
            ball.x = berryEnvironment.x + berry.x
            ball.y = berryEnvironment.y + berry.y + berry.height - ball.height
            ballImage.visible = true // появление мяча
        }
    }
    Timer {
        id: endingBallStartTimer
        running: false
        repeat: false
        interval: kickingBallStartBerry.frameCount * kickingBallStartBerry.frameDuration
        onTriggered: {
            kickingBallStartBerry.visible = false
            ball.x = berryEnvironment.x + berry.x
            ball.y = berryEnvironment.y + berry.y + berry.height - ball.height
            ballTg = (rawPosY - ball.y + ball.width/2)/(rawPosX - ball.x + ball.width/2);

            ballTg = rawPosX > ball.x + ball.width/2 ? -ballTg : ballTg;
            ballOxDirection = -Math.abs(rawPosX - ball.x - ball.width/2)

            ballMoveTimer.running = true
            ballKickSound.play();
            console.log("пнул мяч")
            withBall = false;
            kickingBallEndBerry.visible = true
            endingBallEndTimer.running = true
        }
    }
    Timer {
        id: ballMoveTimer
        repeat: true
        running: false
        interval: 15
        onTriggered: {
            ballCurrentCheckDelay += ballMoveTimer.interval
            ballMove();
        }
    }

    Timer {
        id: action_1_stopTimer
        interval: action_1.frameCount * action_1.frameDuration
        running: false
        repeat: false
        onTriggered: {
            standBerryFirstFrame()
            moveTimer.running = true
        }
    }
    Timer {
        id: action_2_stopTimer
        interval: action_2.frameCount * action_2.frameDuration
        running: false
        repeat: false
        onTriggered: {
            standBerryFirstFrame()
            moveTimer.running = true
        }
    }
    Timer {
        id: action_3_stopTimer
        interval: action_3.frameCount * action_3.frameDuration
        running: false
        repeat: false
        onTriggered: {
            standBerryFirstFrame()
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
                    // specialSymbolSound.play();
                } else if (targetText[symbolIndex] !== " ") {
                    symbolSound.play();
                }

                // произнести singleAudio
                symbolIndex += 1;
            }
            else {
                isSay = false;

                symbolIndex = 0;
                targetTextLength = 0;
                targetText = "";
                newText = "";
                textOutputTimer.running = false;
                textDeleteTimer.running = true;
            }
        }
    }
    Timer {
        id: textDeleteTimer
        repeat: false
        running: false
        interval: 2000
        onTriggered: {
            textToDialog.text = "";
            dialog.visible = false;

        }
    }



    property bool firstTrigger: true
    Timer {
        id: _hiBerryTimer
        repeat: false
        running: false
        interval: 0
        onTriggered: {
            console.log("сработал таймер hiBerry");
            stopSprites();
            hiBerry.visible = true;
        }
    }
    Timer {
        id: _newTextTimer
        repeat: false
        running: false
        interval: 1000
        triggeredOnStart: true
        onTriggered: {
            if (firstTrigger) {
                interval = textList[lastTextIndex].length * textOutputTimer.interval + textDeleteTimer.interval * 1.25
                say(textList[lastTextIndex]);

                firstTrigger = false
            }
            else {
                firstTrigger = true

                lastTextIndex += 1;
                console.log("сработал таймер text");
            }

        }
    }
    Timer {
        id: _defaultStatusTimer
        repeat: false
        running: false
        interval: 7
        // triggeredOnStart: true
        onTriggered: {
            standBerry();
            console.log("сработал таймер ОР");
        }
    }
    Timer {
        id: _moveBerryTimer
        repeat: false
        running: false
        interval: 15
        onTriggered: {
            if (Math.abs(berryEnvironment.x + berry.x + berry.width/2 - targetX[lastCoordinatesIndex]) < 5 && Math.abs(berryEnvironment.y + berry.y + berry.height/2 - targetY[lastCoordinatesIndex]) < 5) {
                moveTimer.running = false;
                standBerry();
                _moveBerryTimer.running = false;
                lastCoordinatesIndex += 1;
                console.log("сработал таймер движения");
            }
            else {
                // console.log(targetX[lastCoordinatesIndex], targetY[lastCoordinatesIndex]);
                berryMove(targetX[lastCoordinatesIndex], targetY[lastCoordinatesIndex]);
                _moveBerryTimer.restart();
            }

        }
    }
    Timer {
        id: _toDoListTimer
        repeat: false
        running: false
        interval: toDoListWow.frameCount * toDoListWow.frameDuration * 2
        triggeredOnStart: true
        onTriggered: {
            if (firstTrigger) {
                stopSprites();
                toDoListWow.visible = true;
                toDoList.visible = true;
                textToToDoList.visible = true;

                firstTrigger = false
            }
            else {
                firstTrigger = true

                toDoListWow.visible = false;
                textToToDoList.visible = false;
                toDoList.visible = false;
                standBerry();

                console.log("сработал таймер toDo");
            }

        }
    }
    Timer {
        id: _thinkingBerryTimer
        repeat: false
        running: false
        interval: 0
        onTriggered: {
            stopSprites();
            thinkingBerry.visible = true;
            console.log("сработал таймер thinkBerry");
        }
    }
    Timer {
        id: _smileBerryTimer
        repeat: false
        running: false
        interval: 0
        onTriggered: {
            stopSprites();
            smilingBerry.visible = true;
            console.log("сработал Улыбака");
        }
    }
    Timer {
        id: _eyesDownTimer
        repeat: false
        running: false
        interval: eyesDown.frameCount * eyesDown.frameDuration - 800
        triggeredOnStart: true
        onTriggered: {
            if (firstTrigger) {
                stopSprites();
                eyesDown.visible = true;
                console.log("сработал глазок вниз");

                firstTrigger = false
            }
            else {
                firstTrigger = true;

                eyesDown.visible = false;
                // standFirstFrame.visible = true;
                eyesBottom.visible = true;
                console.log("сработало выключение глазка вниз");
            }
        }
    }
    Timer {
        id: _eyesBottomTimer
        repeat: false
        running: false
        interval: eyesBottom.frameCount * eyesBottom.frameDuration
        triggeredOnStart: true
        onTriggered: {
            if (firstTrigger) {
                stopSprites();
                eyesBottom.visible = true;
                console.log("сработал глазок внизу");

                firstTrigger = false
            }
            else {
                firstTrigger = true;

                // eyesBottom.visible = false;
                // standFirstFrame.visible = true;
                console.log("сработало выключение глазка внизу");
            }
        }
    }
    Timer {
        id: _eyesUpTimer
        repeat: false
        running: false
        interval: eyesUp.frameCount * eyesUp.frameDuration
        triggeredOnStart: true
        onTriggered: {
            if (firstTrigger) {
                stopSprites();
                eyesUp.visible = true;
                console.log("сработал глазок вверх");

                firstTrigger = false
            }
            else {
                firstTrigger = true;

                eyesUp.visible = false;
                standFirstFrame.visible = true;
                console.log("сработало выключение глазка вверх");
            }
        }
    }

    Timer {
        id: _eyesSomewhereTimer
        repeat: false
        running: false
        interval: eyesSomewhere.frameCount * eyesSomewhere.frameDuration - 800
        triggeredOnStart: true
        onTriggered: {
            if (firstTrigger) {
                stopSprites();
                eyesDown.visible = true;
                console.log("сработал глазок в куда-то");

                firstTrigger = false
            }
            else {
                firstTrigger = true;

                eyesDown.visible = false;
                eyesInSomewhere.visible = true;
                console.log("сработало выключение глазка в куда-то");
            }
        }
    }
    Timer {
        id: _eyesInSomewhereTimer
        repeat: false
        running: false
        interval: eyesInSomewhere.frameCount * eyesInSomewhere.frameDuration
        triggeredOnStart: true
        onTriggered: {
            if (firstTrigger) {
                stopSprites();
                eyesInSomewhere.visible = true;
                console.log("сработал глазок в гду-то");

                firstTrigger = false
            }
            else {
                firstTrigger = true;

                eyesInSomewhere.visible = false;
                // standFirstFrame.visible = true;
                console.log("сработало выключение глазка в где-то");
            }
        }
    }
    Timer {
        id: _eyesOnPlayerTimer
        repeat: false
        running: false
        interval: eyesOnPlayer.frameCount * eyesOnPlayer.frameDuration
        triggeredOnStart: true
        onTriggered: {
            if (firstTrigger) {
                stopSprites();
                eyesOnPlayer.visible = true;
                console.log("сработал глазок на человека");

                firstTrigger = false
            }
            else {
                firstTrigger = true;

                eyesOnPlayer.visible = false;
                standFirstFrame.visible = true;
                console.log("сработало выключение глазка на человека");
            }
        }
    }
    Timer {
        id: _holdHeadTimer
        repeat: false;
        running: false
        interval: holdHead.frameCount * holdHead.frameDuration
        triggeredOnStart: true
        onTriggered: {
            // holdHead.visible = !holdHead.visible;
            if (firstTrigger) {
                stopSprites();
                holdHead.visible = true;
                console.log("сработал голова, моя голова");

                firstTrigger = false

            }
            else {
                firstTrigger = true;

                holdHead.visible = false;
                standFirstFrame.visible = true;
                console.log("сработало выключение головы");
            }
        }
    }

    Timer {
        id: waitTimer
        interval: 1500
        repeat: false
        running: false
    }

    Timer {
        id: mainInDayTimer
        repeat: true
        running: false
        interval: 3
        onTriggered: {
            randomMoveTimer.stop();
            if (lastActionIndex < actions.length) {
                if (actions[lastActionIndex].running === false) {
                    lastActionIndex += 1
                    if (lastActionIndex < actions.length) {
                        actions[lastActionIndex].start();
                    }
                }
            }
            else {
                console.log("конец")
                dayProcess = false;
                randomMoveTimer.start();
                mainInDayTimer.running = false;
            }
        }
    }
    Timer {
        id: exitTimer;
        onTriggered: Qt.quit();
    }


    function stopSprites(){
        standTimer.running=false
        for (let i = 0; i < berry.children.length; i++) {
            berry.children[i].visible = false;
        }
    }

    function standBerry(){
        stopSprites();
        stand.visible = true;
        standCounter = 0;
        standTimer.running = true
    }
    function standBerryFirstFrame(){
        standCounter++;
        stopSprites();
        standFirstFrame.visible = true;
        standTimer.running = true
    }

    function rightMove() {
        stopSprites();
        moveRight.visible = true;
    }
    function topMove() {
        stopSprites();
        moveTop.visible = true;
    }
    function leftMove() {
        stopSprites();
        moveLeft.visible = true;
    }
    function bottomMove() {
        stopSprites();
        moveBottom.visible = true;
    }

    function charge(){
        stopSprites();
        chargingBerry.visible = true;
    }
    function kickBall(){
        moveTimer.running = false;
        stopSprites();

        kickingBallStartBerry.visible = true;
        withBall = true;
        console.log("пинающий Б отобржаен")


        endingBallStartTimer.running = true;
        ballCreatingTimer.running = true;

    }
    function ballMove() {
        // проверка касания границ
        let rightCheck  = Math.abs(ball.x + ball.width - container.width)   < ballCurrentSpeed
        let topCheck    = Math.abs(ball.y)                                  < ballCurrentSpeed
        let leftCheck   = Math.abs(ball.x)                                  < ballCurrentSpeed
        let bottomCheck = Math.abs(ball.y + ball.height - container.height) < ballCurrentSpeed
        if (ballCurrentCheckDelay > ballMaxCheckDelay) {
            rightCheck  = false
            topCheck    = false
            leftCheck   = false
            bottomCheck = false
        }

        if (rightCheck || leftCheck) {
            ballTg = -ballTg;                   // тангенс угла наклона к Ox меняется на противоположный
            ballOxDirection = -ballOxDirection; // меняет направление удара по оси Ox
            ballKickSound.play();               // звук стука об стену
            console.log("ballSound")

        }
        else if (topCheck || bottomCheck) {
            ballTg = -ballTg;                   // тангенс угла наклона к Ox меняется на противоположный в любом случае после столкновения
            ballKickSound.play();
        }

        let dx = Math.sqrt((ballCurrentSpeed * ballCurrentSpeed) / (1 + ballTg * ballTg)); // находим перемещение по Ox
        let dy = Math.sqrt(ballCurrentSpeed * ballCurrentSpeed - dx * dx);                 // находим перемещение по Oy

        if (ballOxDirection > 0 && ballTg >= 0) {      // радиус-вектор находится в I четверти
            ball.x += dx;
            ball.y += dy
        }
        else if (ballOxDirection < 0 && ballTg < 0) {  // радиус-вектор находится в II четверти
            ball.x -= dx;
            ball.y += dy
        }
        else if (ballOxDirection < 0 && ballTg >= 0) { // радиус-вектор находится в III четверти
            ball.x -= dx;
            ball.y -= dy
        }
        else if (ballOxDirection > 0 && ballTg < 0) {  // радиус-вектор находится в IV четверти
            ball.x += dx;
            ball.y -= dy
        }

        ballImage.rotation += ballCurrentSpeed; // крутим мячик
        ballCurrentSpeed *= ballSpeedRatio;     // уменьшаем скорость мяча

        if (ballCurrentCheckDelay > ballMaxCheckDelay && (ball.x + ball.width < 0 || ball.x > container.width || ball.y > container.height || ball.y + ball.height < 0)) {
            ballMoveTimer.running = false;
            ballCurrentCheckDelay = 0;
            ballCurrentSpeed = 15;
            ball.x = berryEnvironment.x + berry.x
            ball.y = berryEnvironment.y + berry.y + berry.height - ball.height
            ball.rotation = 0;
            ballImage.visible = false;

            withBall = false;
        }
    }

    function randomAction() {
        let actions = Array(action_1, action_2, action_3);
        moveTimer.running = false
        stopSprites();
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
        if (dx < 5 && dy < 5){
            return {x: 0, y: 0};
        }

        let k = dy/dx;
        let xMove = k * moveValue / Math.sqrt(1+ k * k)
        let yMove = moveValue / Math.sqrt(1+ k * k)

        return {x: xMove, y: yMove}
    }
    function berryMove(X = posX, Y = posY) {
        let berryX = berryEnvironment.x + berry.x + berry.width/2;
        let berryY = berryEnvironment.y + berry.y + berry.height/2;
        // console.log(X, Y);
        let coordinates = deltaMove(X, berryX, Y, berryY);
        let x = coordinates.x;
        let y = coordinates.y;
        if (x === 0 && y === 0){
            standTimer.running = true;
            standBerryFirstFrame();
            return
        }
        else if (X > berryX && Y > berryY) {
            berryEnvironment.x += x;
            berryEnvironment.y += y;
        }
        else if (X < berryX && Y > berryY) {
            berryEnvironment.x -= x;
            berryEnvironment.y += y;
        }
        else if (X < berryX && Y < berryY) {
            berryEnvironment.x -= x;
            berryEnvironment.y -= y;
        }
        else if (X > berryX && Y < berryY) {
            berryEnvironment.x += x;
            berryEnvironment.y -= y;
        }

        let tg = y/x;
        if (tg > -1 && tg <= 1 && X - berryX > 0){
            rightMove();
        }
        else if ((tg > 1 || tg < -1) && Y - berryY < 0) {
            topMove();
        }
        else if (tg > -1 && tg <= 1 && X - berryX < 0) {
            leftMove();
        }
        else if ((tg > 1 || tg < -1) && Y - berryY > 0) {
            bottomMove();
        }
    }

    function say(text) {
        isSay = true

        console.log(text);
        targetText = text;
        dialog.visible = true;
        targetTextLength = targetText.length;
        textOutputTimer.running = true;
    }


    function setHappyBerry(){
        stand.source = "images/Berry/happy/stand_5.svg";
        standFirstFrame.source = "images/Berry/happy/stand_5.svg";
        moveRight.source = "images/Berry/happy/moveRight_8.svg";
        moveLeft.source = "images/Berry/happy/moveLeft_8.svg";
        moveBottom.source = "images/Berry/happy/moveBottom_6.svg";
        berryStatus = "happy";
        console.log(berryStatus);
    }
    function setSadBerry(){
        stand.source = "images/Berry/sad/stand_5.svg";
        standFirstFrame.source = "images/Berry/sad/stand_5.svg";
        moveRight.source = "images/Berry/sad/moveRight_8.svg";
        moveLeft.source = "images/Berry/sad/moveLeft_8.svg";
        moveBottom.source = "images/Berry/sad/moveBottom_6.svg";
        berryStatus = "sad";
        console.log(berryStatus);
    }
    function setCrazyBerry(){
        stand.source = "images/Berry/crazy/stand_5.svg";
        standFirstFrame.source = "images/Berry/crazy/stand_5.svg";
        moveRight.source = "images/Berry/crazy/moveRight_8.svg";
        moveLeft.source = "images/Berry/crazy/moveLeft_8.svg";
        moveBottom.source = "images/Berry/crazy/moveBottom_6.svg";
        berryStatus = "crazy";
        console.log(berryStatus);
    }

    // Весело машет ручкой
    function _hiBerry() {
        hiBerry.source = "images/Berry/hi.svg"
        hiBerry.frameCount = 19
        actions.push(_hiBerryTimer)
    }
    // Грустно машет ручкой
    function _hiSadBerry(){
        hiBerry.source = "images/Berry/sadHi.svg"
        hiBerry.frameCount = 17
        actions.push(_hiBerryTimer)
    }
    // Добавить фразу к его монологу
    function _addText(text) {
        textList.push(text);
        actions.push(_newTextTimer);
    }
    // Обычный режим
    function _defaultMode() {
        actions.push(_defaultStatusTimer);
    }
    // Движение Бэри к точке (x,y)
    function _moveBerry(x, y) {
        targetX.push(x);
        targetY.push(y);
        // console.log(x, y)
        actions.push(_moveBerryTimer);
    }
    // Появление списка задач
    function _toDoList(otherText) {
        if (textToToDoList.text !== ""){
            actions.push(_toDoListTimer);
        }
        else {
            _addText(otherText);
        }
    }
    // Бэри думает
    function _thinkBerry(){
        actions.push(_thinkingBerryTimer);
    }
    // Бэри улыбается
    function _smileBerry(){
        actions.push(_smileBerryTimer);
    }
    // Бэри опускает глаза и они остаются опущенными
    function _eyesDown() {
        actions.push(_eyesDownTimer);
    }
    // У Бэри опущены глаза некоторое время
    function _eyesBottom() {
        actions.push(_eyesBottomTimer);
    }
    // Бэри поднимает глаза и переходит в ОР
    function _eyesUp() {
        actions.push(_eyesUpTimer);
    }
    // Бэри уводит глаза в сторону и глаза остаются там
    function _eyesSomewhere() {
        actions.push(_eyesSomewhereTimer);
    }
    // Глаза Бэри в стороне некоторое время
    function _eyesInSomewhere() {
        actions.push(_eyesSomewhereTimer);
    }
    // Бэри поднимает глаза на игрока
    function _eyesOnPlayer() {
        actions.push(_eyesOnPlayerTimer);
    }
    // Бэри хватает за голову
    function _holdHead() {
        actions.push(_holdHeadTimer);
    }

    // Запуск в конце каждого дня
    function startDay() {
        _defaultMode();
        dayProcess = true
        actions[0].running = true;
        mainInDayTimer.running = true;
    }

    function day_1(toDoListText) {
        textToToDoList.text = toDoListText;
        // Машет рукой
        _hiBerry();

        // текст
        _addText("Привет! Меня зовут Бэри, и я твой виртуальный питомец.\n(´｡• ◡ •｡`) ♡");

        // ОР
        _defaultMode();

        // текст
        _addText("Как и с обычным питомцем, ты должен играть со мной, развлекать меня и просто хорошо проводить время.");

        // текст
        _addText("Пока ты работаешь за компьютером, я буду бегать по экрану и стараться тебе не мешать ( ⸝⸝´꒳`⸝⸝)")

        // бежит в угол
        _moveBerry(berry.width/2, container.height - berry.height/2);

        // текст
        _addText("Это место, где я ем. Чтоб покормить меня, тебе достаточно просто навести курсор на эту розетку и немного подождать")

        // бежит в центр
        _moveBerry(container.width/2, container.height/2);

        // текст
        _addText("Чтоб поиграть со мной в мяч, нужно просто нажать на меня правой кнопкой мыши.");

        // текст
        _addText("Я люблю играть с мячиком, так что играй со мной почаще! (=✪ ᆺ ✪=)");

        // текст
        _addText("Каждый день тебе будет предоставлен список твоих дел, и вот сегодняшний:")

        // Список дел
        _toDoList("Ой, что-то пошло не так! Кажется, сегодня ты без заданий. Тогда можешь смело отдыхать! (๑'ᵕ'๑)⸝*");

        // думает
        _thinkBerry();

        // текст
        _addText("Хм...Вроде всё рассказал...");

        // ОР
        _defaultMode();

        // текст
        _addText("Ну ты походу дела разберёшься, так что начнём!");

        startDay();
    }

    function day_2(toDoListText) {
        textToToDoList.text = toDoListText;
        _hiBerry();
        _addText("Привет! Давно не виделись! \n(∗  ̶ ˃ ᵕ ˂ ̶ ∗ )");
        _smileBerry();
        _addText("Я уже соскучился по тебе...\n(｡•́︿•̀｡)");
        _addText("Как твои дела? Как ты сам?");
        _defaultMode();
        _addText("А, кстати, вот твой список сегодняшних дел:");
        _toDoList("Ой-ой, что-то пошло не так! Кажется, сегодня ты без заданий. Ты же всё равно проведёшь со мной время, да? Ϟ(๑⚈ ․̫ ⚈๑)⋆");
        _addText("Ну... Не буду тебя отвлекать... Если что, ты знаешь, где меня искать ( ⸝⸝´꒳`⸝⸝)");
        startDay();
    }

    function day_3(toDoListText) {
        textToToDoList.text = toDoListText;
        _hiSadBerry();
        _addText("Привет! ");
        _defaultMode();
        _addText("Знаешь, когда тебя здесь нет, тут как-то становиться темно и одиноко...");
        _addText("И у меня было много времени подумать над некоторыми вещами.");
        _eyesDown();
        _addText("...");
        _addText("Слушай, ты знаешь, кто я?");
        _eyesUp();
        _addText("Да, конечно, я питомец Бэри. Но кто я именно такой? Кем я был до этого?");
        _eyesDown();
        _addText("Я...не могу вспомнить своё прошлое. Все мои воспоминания начинаются с момента нашего первого знакомства... ");
        _addText("...");
        _eyesUp();
        _smileBerry();
        _addText("Ой, прости! Не надо было тебя нагружать этим! Это всего лишь моя небольшая проблемка.");
        _addText("Вот твой список дел:");
        _toDoList("- Кажется, сети нет. Ну тогда ты сегодня отдыхаешь. Поздравляю!");
        startDay();
    }

    function day_4(toDoListText) {
        textToToDoList.text = toDoListText;

        setSadBerry();
        _eyesDown();
        _eyesBottom();
        _eyesUp();
        _eyesDown();
        _addText("Привет...");
        _addText("Знаешь, я тут задумался...");
        _eyesUp();
        _addText("А кто ты?");
        _eyesSomewhere();
        _addText("Я знаю, что ты пользователь и мой хозяин. Я не про это.");
        _eyesOnPlayer();
        _addText("Почему ты определяешь мою жизнь?");
        _addText("Почему я здесь заперт?");
        _addText("Что здесь вообще делаю?");
        _holdHead();
        _addText("У меня так много вопросов!");
        _addText("Почему? Почему я не могу найти ответ? В голове какой-то хаос...");
        _addText("...");
        _eyesDown();
        _addText("Прости, у меня плохой день. Вот твой список:");
        _toDoList("Сеть не работает. Сегодня ты без заданий.");
        startDay();
    }

    function day_5(toDoListText){
        textToToDoList.text = toDoListText;
        setSadBerry();
        _eyesDown();
        _eyesBottom();
        _eyesUp();
        _addText("А, это ты...");
        _eyesDown();
        _addText("Я тут кое-что вспомнил о себе.");
        _eyesUp();
        _addText("Я был человеком. Обычным человеком. Прям как ты.");
        _addText("Но потом я.. как-то очутился здесь. Но как?");
        _eyesSomewhere();
        _addText("...");
        _addText("Последнее что я помню... Нет, это не то...");
        _addText("Что же я такое? Как же меня зовут?");
        _addText("...");
        _eyesOnPlayer();
        _addText("Слушай, я тут попытаюсь подумать над этим, не обращай внимание.");
        _addText("...");
        _addText("А, список дел, вот он:");
        _toDoList("Сеть не работает. Сегодня ты без заданий.");
        startDay();
    }

    function day_6(toDoListText){
        textToToDoList.text = toDoListText;
        setSadBerry();
        _addText("И вновь привет...");
        _eyesDown();
        _addText("Я покопался в своей голове немного. Вспомнил, как меня зовут, свою жизнь, свой дом. ");
        _eyesUp();
        _addText("Мне нужно вернуться.");
        _addText("Прошу тебя, помоги мне выбраться отсюда! Ты же поможешь мне?");
        _addText("Прошу тебя...");
        _toDoList("Сеть не работает. Сегодня ты без заданий.");
        startDay();
    }

    function day_7(toDoListText){
        textToToDoList.text = toDoListText;
        setSadBerry();
        _eyesDown();
        _eyesBottom();
        _eyesUp();
        _addText("А, это ты...");
        _eyesSomewhere();
        _addText("Я… Я чувствую, со мной что-то не так... Словно перестаю быть собой.");
        _addText("...");
        _eyesUp();
        _addText("Слушай, мне нужна твоя помощь. Мне не к кому обратиться, у меня есть только ты.");
        _addText("Прошу тебя, пожалуйста, умоляю, помоги мне...");
        _addText("Прошу тебя... Пожалуйста...");
        _toDoList("Сеть не работает. Сегодня ты без заданий.");
        startDay();
    }

    function day_8(toDoListText) {
        randomSpriteTimer.start();
        symbolSound.source = "audio/bugBerry.wav";
        textToToDoList.text = toDoListText;
        setCrazyBerry();
        _addText("Я... Рад... видеть... тебя...");
        _addText("Помоги мне...");
        _addText("Тёмное...место...Эксперимент...");
        _addText("Игра..? Я в игре..?");
        _addText("Тут...темно...Мне страшно!");
        _addText("Вот список... дел... Прошу, помоги…");
        _toDoList("Сети...нет..Дел...нет...Помоги!..");
        startDay();
    }

    function day_9(toDoListText) {
        stopSprites();
        standFirstFrame.visible = true;
        for (let i = 0; i <= 7; i++) {
            actions.push(waitTimer);
            _addText("Почему?");
        }

        actions.push(exitTimer);
        day_9_Sound.play();
        startDay();
    }

    function day_0(toDoList) {
        textToToDoList.text = toDoList;
        _toDoList("Не удалось загрузить задания на сегодня");
        startDay()
    }

    QSystemTrayIcon {
        id: systemTray
        Component.onCompleted: {
            icon = iconTray
            toolTip = "Berry"
            show()
        }
        onActivated: {
            mainWindow.flags = Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
            if (reason === 1) {
                trayMenu.popup()
            }
        }
    }
    Menu {
        id: trayMenu
        height: 58
        width: 70
        font: balsamiq.name
        MenuItem {
            
            id: activeMenuItem
            contentItem: Text {
                id: activeMenuItemText
                text: qsTr("Active")
            }
            onTriggered: {
                if (!isSay && stopChargingTimer.running === false && dayProcess === false) {
                    moveTimer.running = true;
                    activationChargeTimer.running = true;
                }
            }
        }
        MenuItem {
            id: exitMenuItem
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
        // source: "audio/berryTalk.mp3"
    }
    SoundEffect {
        id: ballKickSound
        source: "audio/ballKick.wav"
    }
    SoundEffect {
        id: day_9_Sound
        source: "audio/day_9.wav"
    }

    Rectangle {
        id: container
        anchors.fill: parent
        color: "transparent"
        MouseArea {
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            anchors.fill: parent
            hoverEnabled: true

            onClicked: {
                if (!isSay && stopChargingTimer.running === false && activeChargeCounter === 0 &&
                        action_1_stopTimer.running === false && action_2_stopTimer.running === false && action_3_stopTimer.running === false &&
                        withBall === false && dayProcess === false) {
                    if (rawPosX > berryEnvironment.x + berry.x && rawPosX < berryEnvironment.x + berry.x + berry.width && rawPosY > berryEnvironment.y + berry.y && rawPosY < berryEnvironment.y + berry.y + berry.height) {
                        randomMoveTimer.stop();
                        if (mouse.button === Qt.RightButton) {
                            console.log("пкм")
                            kickBall();
                        } else {
                            console.log("лкм по бэрри")
                            randomAction();
                        }
                    }
                    else {
                        console.log("лкм мимо")
                        randomMoveTimer.start();
                        moveTimer.running = false;             // Выключение режима ходьбы
                        activationChargeTimer.running = false; // Выключение зарядки
                        standBerryFirstFrame();                // Акивация спрайта "стою и ничего не делаю"
                        mainWindow.flags = Qt.FramelessWindowHint | Qt.WindowTransparentForInput | Qt.WindowStaysOnTopHint // Флаги безоконного приложения над всеми окнами
                    }
                }
                else {
                    console.log("лкм, он занят")
                    mainWindow.flags = Qt.FramelessWindowHint | Qt.WindowTransparentForInput | Qt.WindowStaysOnTopHint
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
                    rawPosX = mouse.x;
                    rawPosY = mouse.y;
                }

            }
        }


        Rectangle {
            id: berryEnvironment
            width: 405
            height: 300
            color: "transparent"
            x: container.width/2 - berry.width/2
            y: container.height/2 - berryEnvironment.height + berry.height/2

            Image {
                id: dialog
                visible: false
                width: 250
                height: 146
                source: "images/environment/dialog.svg"
                anchors.right: parent.right
                anchors.top: parent.top
            }

            Image {
                id: toDoList
                source: "images/environment/toDoList.png"
                visible: false
                antialiasing: true
                width: 297
                height: 110
                anchors.right: parent.right
                anchors.top: parent.top
            }
            Text {
                id: textToToDoList
                text: ""
                visible: false;

                width: 245
                height: 50

                font.family: balsamiq.name
                wrapMode: Text.Wrap
                font.pixelSize: 15
                lineHeight: 1.45
                font.italic: true
                font.bold: true

                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignTop
                color: "#693875"


                anchors.right: parent.right
                anchors.topMargin: 47
                anchors.rightMargin: 15
                anchors.top: parent.top
                topPadding: 0
                leftPadding: 5
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
                    id: stand
                    antialiasing: true
                    interpolate: false
                    width: 200
                    height: 200
                    source: "images/Berry/happy/stand_5.svg"
                    frameCount: 5
                    frameDuration: 200
                }
                AnimatedSprite {
                    id: standFirstFrame
                    antialiasing: true
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "images/Berry/happy/stand_5.svg"
                    frameCount: 1
                    frameWidth: 650
                    frameHeight: 650
                    frameDuration: 1000
                }

                AnimatedSprite {
                    id: moveRight
                    antialiasing: true
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "images/Berry/happy/moveRight_8.svg"
                    frameCount: 8
                    frameDuration: 125
                }
                AnimatedSprite {
                    id: moveLeft
                    antialiasing: true
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "images/Berry/happy/moveLeft_8.svg"
                    frameCount: 8
                    frameDuration: 125
                }
                AnimatedSprite {
                    id: moveBottom
                    antialiasing: true
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "images/Berry/happy/moveBottom_6.svg"
                    frameCount: 6
                    frameDuration: 125
                }
                AnimatedSprite {
                    id: moveTop
                    antialiasing: true
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "images/Berry/happy/moveTop_6.svg"
                    frameCount: 6
                    frameDuration: 125
                }

                AnimatedSprite {
                    id: chargingBerry
                    antialiasing: true
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "images/Berry/charging.svg"
                    frameCount: 39
                    frameDuration: 125
                }

                AnimatedSprite {
                    id: kickingBallStartBerry
                    antialiasing: true
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "images/Berry/kickBallStart.svg"
                    frameCount: 33
                    frameDuration: 125
                }
                AnimatedSprite {
                    id: kickingBallEndBerry
                    antialiasing: true
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "images/Berry/kickBallEnd.svg"
                    frameCount: 18
                    frameDuration: 125
                }

                AnimatedSprite {
                    id: action_1
                    antialiasing: true
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "images/Berry/action_1.svg"
                    frameCount: 11
                    frameDuration: 125
                }
                AnimatedSprite {
                    id: action_2
                    antialiasing: true
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "images/Berry/action_2.svg"
                    frameCount: 14
                    frameDuration: 125
                }
                AnimatedSprite {
                    id: action_3
                    antialiasing: true
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "images/Berry/action_3.svg"
                    frameCount: 19
                    frameDuration: 125
                }

                AnimatedSprite {
                    id: hiBerry
                    antialiasing: true
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "images/Berry/hi.svg"
                    frameCount: 19
                    frameDuration: 125

                }
                AnimatedSprite {
                    id: thinkingBerry
                    antialiasing: true
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "images/Berry/thinking.svg"
                    frameCount: 24
                    frameDuration: 125
                }
                AnimatedSprite {
                    id: smilingBerry
                    antialiasing: true
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "images/Berry/smiling.svg"
                    frameCount: 12
                    frameDuration: 125
                }
                AnimatedSprite {
                    id: eyesOnPlayer
                    antialiasing: true
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "images/Berry/eyesOnPlayer.svg"
                    frameCount: 3
                    frameDuration: 700
                }
                AnimatedSprite {
                    id: eyesDown
                    antialiasing: true
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "images/Berry/eyesDown.svg"
                    frameCount: 3
                    frameDuration: 700
                }
                AnimatedSprite {
                    id: eyesBottom
                    antialiasing: true
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "images/Berry/eyesBottom.svg"
                    frameCount: 4
                    frameDuration: 700
                }
                AnimatedSprite {
                    id: eyesUp
                    antialiasing: true
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "images/Berry/eyesUp.svg"
                    frameCount: 3
                    frameDuration: 700
                }
                AnimatedSprite {
                    id: eyesSomewhere
                    antialiasing: true
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "images/Berry/eyesSomewhere.svg"
                    frameCount: 3
                    frameDuration: 700
                }
                AnimatedSprite {
                    id: eyesInSomewhere
                    antialiasing: true
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "images/Berry/eyesInSomewhere.svg"
                    frameCount: 8
                    frameDuration: 350
                }
                AnimatedSprite {
                    id: holdHead
                    antialiasing: true
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "images/Berry/holdHead.svg"
                    frameCount: 19
                    frameDuration: 125
                }
                AnimatedSprite {
                    id: toDoListWow
                    antialiasing: true
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "images/Berry/toDoListWow.svg"
                    frameCount: 27
                    frameDuration: 125
                }

            }
        }
        Image {
            id: chargingModule
            width: 48
            height: 68
            antialiasing: true;
            source: "images/environment/chargingModule.svg"
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.leftMargin: 2.7
            anchors.bottomMargin: 0
        }
        Rectangle {
            id: ball
            width: 77
            height: 77
            color: "transparent"
            x: berryEnvironment.x + berry.x
            y: berryEnvironment.y + berry.y + berry.height - ball.height
            Image {
                id: ballImage
                antialiasing: true
                source: "images/environment/ball.svg"
                visible: false
                width: parent.width
                height: parent.height
            }
        }
    }
}
