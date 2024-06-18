import QtQuick

Window {
    width: 400
    height: 400
    flags: Qt.FramelessWindowHint | Qt.WindowTransparentForInput | Qt.WindowStaysOnTopHint
    visible: true
    // title: qsTr("BarryTest")
    color: "transparent"
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: "red"
        border.width: 0
        AnimatedImage
        {
            width: 200
            height: 200
            antialiasing: true
            // asynchronous: true
            // scale: 1
            // horizontalAlignment: AnimatedImage.AlignHCenter
            // verticalAlignment: AnimatedImage.AlignVCenter

            cache: true
            // source: "../Images/Berry/15-7.gif"
            source: "../Images/Berry/test.gif"
            // anchors.bottom: parent.bottom
            speed: 1
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom

        }
    }


}
