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

    property real         moveValue:                3       // скорость перемещения berry за итерацию

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
    // property int          ballCheckDelay:           250     //
    property int          ballCurrentCheckDelay:    0       // текущее время нахождения ball внутри container
    property int          ballMaxCheckDelay:        9000    // максимальное время нахождения ball внутри container, по окончании ball уходит за границы

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
            //TODO добавить анимцию ухода chargingModule
            activationChargeTimer.running = false;
            waitChargingTimer.running = true;
        }
    }
    Timer {
        id: waitChargingTimer
        running: false
        repeat: false
        interval: disabledChargindInterval * 1000
        onTriggered: {
            if (posX > berryEnvironment.x + berry.x && posX < berryEnvironment.x + berry.x + berry.width && posY > berryEnvironment.y + berry.y && posY < berryEnvironment.y + berry.y + berry.height) {
                if (rawPosX > chargingModule.x && rawPosX < chargingModule.x + chargingModule.width && rawPosY > chargingModule.y && rawPosY < chargingModule.y + chargingModule.height){
                    waitChargingTimer.interval += disabledChargindInterval;
                    console.log("chargind block");
                }
            }
            else {
                console.log("charging enabled");
                activationChargeTimer.running = true;
                //TODO добавить анимцию появления chargingModule
                chargingModule.visible = true;
            }
        }
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
            // console.log(ballCheckDelay, ballCurrentSpeed);
            // console.log(ballCurrentCheckDelay);
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
            //TODO animation
            textToDialog.text = "";
            dialog.visible = false;

        }
    }



    property bool firstTrigger: true
    Timer {
        id: _hiBerryTimer
        repeat: false
        running: false
        interval: 0/*hiBerry.frameCount * hiBerry.frameDuration*/
        // triggeredOnStart: true
        onTriggered: {
            console.log("сработал таймер hiBerry");
            // console.log("hiBerry visible");
            stopSprits();
            hiBerry.visible = true;
            // if (firstTrigger) {

            //     firstTrigger = false;
            // } else {
            //     firstTrigger = true

            //     // standCounter = 0;
            //     // standBerryFirstFrame();
            // }

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
        interval: 0/*stand.frameCount * stand.frameDuration*/
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
        interval: 15
        onTriggered: {
            console.log("сработал таймер toDo");
        }
    }
    Timer {
        id: _thinkingBerryTimer
        repeat: false
        running: false
        interval: 0
        onTriggered: {
            stopSprits();
            thinkingBerry.visible = true;
            console.log("сработал таймер thinkBerry");
        }
    }

    Timer {
        id: mainInDayTimer
        repeat: true
        running: false
        interval: 16
        onTriggered: {
            if (lastActionIndex < actions.length) {
                if (actions[lastActionIndex].running === false) {
                    lastActionIndex += 1
                    if (lastActionIndex < actions.length) {
                        actions[lastActionIndex].running = true;
                    }
                }
            }
            else {
                console.log("конец")
                dayProcess = false;
                mainInDayTimer.running = false;
            }
        }
    }

    function stopSprits(){
        standTimer.running=false
        for (let i = 0; i < berry.children.length; i++) {
            berry.children[i].visible = false;
        }
    }

    function standBerry(){
        stopSprits();
        stand.visible = true;
        standCounter = 0;
        standTimer.running = true
    }
    function standBerryFirstFrame(){
        standCounter++;
        stopSprits();
        standFirstFrame.visible = true;
        standTimer.running = true
    }

    function rightMove() {
        stopSprits();
        moveRight.visible = true;
    }
    function topMove() {
        stopSprits();
        moveTop.visible = true;
    }
    function leftMove() {
        stopSprits();
        moveLeft.visible = true;
    }
    function bottomMove() {
        stopSprits();
        moveBottom.visible = true;
    }

    function charge(){
        stopSprits();
        chargingBerry.visible = true;
    }
    function kickBall(){
        moveTimer.running = false;
        stopSprits();

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
        // console.log(rightCheck, topCheck, leftCheck, bottomCheck);

        // // проверка касания границы Berry
        // let rightBerryCheck  = Math.abs(ball.x + ball.width - berryEnvironment.x - berry.x)   < ballCurrentSpeed && berryEnvironment.y + berry.y - berry.height/10 < ball.y + ball.height/2 && ball.y + ball.height/2 < berryEnvironment.y + berry.y + berry.height*11/10 && ball.x < berryEnvironment.x + berry.x
        // let topBerryCheck    = Math.abs(ball.y - berryEnvironment.y - berry.y - berry.height) < ballCurrentSpeed && berryEnvironment.x + berry.x - berry.width/10  < ball.x + ball.widht/2  && ball.x + ball.widht/2  < berryEnvironment.x + berry.x + berry.width *11/10 && ball.y > berryEnvironment.y + berry.y + berry.height
        // let leftBerryCheck   = Math.abs(ball.x - berryEnvironment.x - berry.x - berry.width)  < ballCurrentSpeed && berryEnvironment.y + berry.y - berry.height/10 < ball.y + ball.height/2 && ball.y + ball.height/2 < berryEnvironment.y + berry.y + berry.height*11/10 && ball.x > berryEnvironment.x + berry.x + berry.width
        // let bottomBerryCheck = Math.abs(ball.y + ball.height - berryEnvironment.x - berry.x)  < ballCurrentSpeed && berryEnvironment.x + berry.x - berry.width/10  < ball.x + ball.widht/2  && ball.x + ball.widht/2  < berryEnvironment.x + berry.x + berry.width *11/10 && ball.y < berryEnvironment.y + berry.y

        // // проверка касания блока зарядки (может коснуться только сверху и справа)
        // let leftChargeCheck   = Math.abs(ball.x - chargingModule.x - chargingModule.width)                < ballCurrentSpeed && chargingModule.y < ball.y && ball.y < chargingModule.y + chargingModule.height
        // let bottomChargeCheck = Math.abs(ball.y + ball.height - chargingModule.y - chargingModule.height) < ballCurrentSpeed && chargingModule.x < ball.x && ball.x < chargingModule.x + chargingModule.width

        // // console.log(Math.abs(ball.y + ball.height - container.height));
        // // console.log(rightBerryCheck, topBerryCheck, leftBerryCheck, bottomBerryCheck, ballCurrentCheckDelay, ballCheckDelay);
        // // console.log(Math.abs(ball.y - berryEnvironment.y - berry.y - berry.height));


        // if (ballCurrentCheckDelay > ballCheckDelay) {
        //     if (rightBerryCheck || topBerryCheck || leftBerryCheck || bottomBerryCheck) {
        //         console.log(rightBerryCheck, topBerryCheck, leftBerryCheck, bottomBerryCheck);
        //         // console.log(Math.abs(ball.x + ball.width - berryEnvironment.x - berry.x), ballCurrentSpeed)
        //         // console.log(berryEnvironment.y + berry.y - berry.height/4, ball.y,  ball.y,  berryEnvironment.y + berry.y + berry.height*5/4);
        //         // ballMoveTimer.running = false;
        //     }
        //     if (leftCheck || rightCheck || leftBerryCheck || rightBerryCheck || leftChargeCheck) {
        //         ballTg = -ballTg;                   // тангенс угла наклона к Ox меняется на противоположный
        //         ballOxDirection = -ballOxDirection; // меняет направление удара по оси Ox
        //     }
        //     else if (topCheck || bottomCheck || topBerryCheck || bottomBerryCheck || bottomChargeCheck) {
        //         ballTg = -ballTg;                   // тангенс угла наклона к Ox меняется на противоположный в любом случае после столкновения
        //     }
        // }
        // else {
        // }
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
            ballImage.visible = false;
            withBall = false;
        }
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
        stand.source = "images/Berry/happy/stand_5.png";
        standFirstFrame.source = "images/Berry/happy/stand_5.png";
        moveRight.source = "images/Berry/happy/moveRight_8.png";
        moveLeft.source = "images/Berry/happy/moveLeft_8.png";
        moveBottom.source = "images/Berry/happy/moveBottom_6.png";
        berryStatus = "happy";
        console.log(berryStatus);
    }
    function setSadBerry(){
        stand.source = "images/Berry/sad/stand_5.png";
        standFirstFrame.source = "images/Berry/sad/stand_5.png";
        moveRight.source = "images/Berry/sad/moveRight_8.png";
        moveLeft.source = "images/Berry/sad/moveLeft_8.png";
        moveBottom.source = "images/Berry/sad/moveBottom_6.png";
        berryStatus = "sad";
        console.log(berryStatus);
    }
    function setCrazyBerry(){
        stand.source = "images/Berry/crazy/stand_5.png";
        standFirstFrame.source = "images/Berry/crazy/stand_5.png";
        moveRight.source = "images/Berry/crazy/moveRight_8.png";
        moveLeft.source = "images/Berry/crazy/moveLeft_8.png";
        moveBottom.source = "images/Berry/crazy/moveBottom_6.png";
        berryStatus = "crazy";
        console.log(berryStatus);
    }


    function _hiBerry() {
        actions.push(_hiBerryTimer)
    }

    function _addText(text) {
        textList.push(text);
        actions.push(_newTextTimer);
    }

    function _defaultMode() {
        actions.push(_defaultStatusTimer);
    }

    function _moveBerry(x, y) {
        targetX.push(x);
        targetY.push(y);
        // console.log(x, y)
        actions.push(_moveBerryTimer);
    }
    function _toDoList() {
        actions.push(_toDoListTimer);
    }
    function _thinkBerry(){
        actions.push(_thinkingBerryTimer);
    }

    function startDay() {
        _defaultMode();
        dayProcess = true
        actions[0].running = true;
        mainInDayTimer.running = true;
    }


    function day_1() {
        console.log("activate day_1");
        // for (let i = 0; i < actions.length; i++) {
        //     console.log(actions[i].running);
        // }

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
        _toDoList();

        // думает
        _thinkBerry();

        // текст
        _addText("Хм...Вроде всё рассказал...");

        // ОР
        _defaultMode();

        // текст
        _addText("Ну ты походу дела разберёшься, так что начнём!");
        startDay();

        // TODO передать C++, что сюжет рассказан до конца
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
            if (reason === 1) {
                // menuVisible = true
                trayMenu.popup()
            }
        }
    }
    Menu {
        id: trayMenu
        height: 58
        width: 70
        font: balsamiq.name


        // Timer {
        //     id: activeMenuItemTimer
        //     interval: 10
        //     repeat: true
        //     running: true
        //     onTriggered: {
        //         console.log(menuVisible, activeMenuItem.x + trayMenu.x, menuPosX, activeMenuItem.x + trayMenu.x + activeMenuItem.width);
        //         if (menuVisible === true) {
        //             if (menuPosX > activeMenuItem.x + trayMenu.x && menuPosX < activeMenuItem.x + trayMenu.x + trayMenu.width && menuPosY > activeMenuItem.y + trayMenu.y && menuPosY < activeMenuItem.y + trayMenu.y + trayMenu.height) {
        //                 console.log("внутри актива");
        //             }
        //         }

        //     }
        // }

        MenuItem {
            // MouseArea {
            //     onPositionChanged: {
            //         console.log(mouse.x)
            //         console.log(mouse.y)
            //         menuPosX = mouse.x + rawPosX;
            //         menuPosY = mouse.y + rawPosY;
            //     }
            // }
            id: activeMenuItem
            // background: Rectangle {
            //     id: activeMenuItemBackground
            //     color: "#EEE3FA"
            //     width: parent.width
            //     height: parent.height
            // }
            contentItem: Text {
                id: activeMenuItemText
                text: qsTr("Active")
                // color: "#4F0063"
            }
            onTriggered: {
                // menuVisible = false
                if (!isSay && stopChargingTimer.running === false) {
                    moveTimer.running = true;
                    activationChargeTimer.running = true;
                }
            }
        }
        MenuItem {
            id: exitMenuItem
            text:qsTr("Exit")
            // background: Rectangle {
            //     color: "#EEE3FA"
            // }
            onTriggered: {
                // menuVisible = false
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

    Rectangle {
        id: container
        anchors.fill: parent
        color: "transparent"
        // border.color: "red"
        // border.width: 2
        MouseArea {
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            anchors.fill: parent
            hoverEnabled: true

            onClicked: {
                // menuVisible = false
                // console.log("CLICK:");
                // console.log(!isSay && stopChargingTimer.running === false && activeChargeCounter === 0 && action_1_stopTimer.running === false && action_2_stopTimer.running === false && action_3_stopTimer.running === false)
                if (!isSay && stopChargingTimer.running === false && activeChargeCounter === 0 &&
                        action_1_stopTimer.running === false && action_2_stopTimer.running === false && action_3_stopTimer.running === false &&
                        /*withBall === false &&*/ dayProcess === false) {
                    if (rawPosX > berryEnvironment.x + berry.x && rawPosX < berryEnvironment.x + berry.x + berry.width && rawPosY > berryEnvironment.y + berry.y && rawPosY < berryEnvironment.y + berry.y + berry.height) {
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
                        moveTimer.running = false; // Включение режима ходьбы
                        activationChargeTimer.running = false; // Выключение зарядки
                        standBerryFirstFrame(); // Акивация спрайта "стою и ничего не делаю"
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
            // border.color: "green"
            // border.width: 2
            x: container.width/2 - berry.width/2
            y: container.height/2 - berryEnvironment.height + berry.height/2

            Image {
                id: dialog
                visible: false
                width: 250
                height: 146
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
                // border.color: "green"
                // border.width: 3
                anchors.left: parent.left
                anchors.bottom: parent.bottom

                AnimatedSprite {
                    id: stand
                    antialiasing: false
                    interpolate: false
                    width: 200
                    height: 200
                    source: "images/Berry/happy/stand_5.png"
                    frameWidth: 650
                    frameHeight: 650
                    frameCount: 5
                    frameDuration: 200
                }
                AnimatedSprite {
                    id: standFirstFrame
                    antialiasing: false
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "images/Berry/happy/stand_5.png"
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
                    source: "images/Berry/happy/moveRight_8.png"
                    frameCount: 8
                    frameWidth: 650
                    frameHeight: 650
                    frameDuration: 125
                }
                AnimatedSprite {
                    id: moveLeft
                    antialiasing: true
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "images/Berry/happy/moveLeft_8.png"
                    frameCount: 8
                    frameWidth: 650
                    frameHeight: 650
                    frameDuration: 125
                }
                AnimatedSprite {
                    id: moveBottom
                    antialiasing: true
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "images/Berry/happy/moveBottom_6.png"
                    frameCount: 6
                    frameWidth: 650
                    frameHeight: 650
                    frameDuration: 125
                }
                AnimatedSprite {
                    id: moveTop
                    antialiasing: true
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "images/Berry/happy/moveTop_6.png"
                    frameCount: 6
                    frameWidth: 650
                    frameHeight: 650
                    frameDuration: 125
                }

                AnimatedSprite {
                    id: chargingBerry
                    antialiasing: true
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "images/Berry/charging.png"
                    frameCount: 39
                    frameWidth: 650
                    frameHeight: 650
                    frameDuration: 125
                }

                AnimatedSprite {
                    id: kickingBallStartBerry
                    antialiasing: true
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "images/Berry/kickBallStart.png"
                    frameCount: 33
                    frameWidth: 650
                    frameHeight: 650
                    frameDuration: 125
                }
                AnimatedSprite {
                    id: kickingBallEndBerry
                    antialiasing: true
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "images/Berry/kickBallEnd.png"
                    frameCount: 18
                    frameWidth: 650
                    frameHeight: 650
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
                    frameWidth: 650
                    frameHeight: 650
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
                    frameWidth: 650
                    frameHeight: 650
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
                    frameWidth: 650
                    frameHeight: 650
                    frameDuration: 125
                }

                AnimatedSprite {
                    id: hiBerry
                    antialiasing: true
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "images/Berry/hi.png"
                    frameCount: 19
                    frameWidth: 650
                    frameHeight: 650
                    frameDuration: 125

                }
                AnimatedSprite {
                    id: thinkingBerry
                    antialiasing: true
                    interpolate: false
                    visible: false
                    width: 200
                    height: 200
                    source: "images/Berry/thinking.png"
                    frameCount: 24
                    frameWidth: 650
                    frameHeight: 650
                    frameDuration: 125
                }

            }

        }

        Image {
            id: chargingModule
            width: 48
            height: 68
            antialiasing: true;
            source: "images/environment/chargingModule.png"
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.leftMargin: 2
        }

        Rectangle {
            id: ball
            width: 77
            height: 77
            color: "transparent"
            // border.color: "red"
            // border.width: 2
            x: berryEnvironment.x + berry.x
            y: berryEnvironment.y + berry.y + berry.height - ball.height
            Image {
                id: ballImage
                antialiasing: true
                source: "images/environment/ball.png"
                visible: false
                width: parent.width
                height: parent.height
            }
        }
    }
}
