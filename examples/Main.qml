import QtQuick
import NativeWebView

Window {
    width: 800
    height: 600
    visible: true
    title: qsTr("Example App")

    NativeWebView {
        anchors.fill: parent
        url: "https://www.google.com"
    }
}
