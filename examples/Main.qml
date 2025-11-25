import QtQuick
import QtQuick.Controls
import NativeWebView

Window {
    width: 1024
    height: 768
    visible: true
    title: qsTr("QmlNativeWebView Example")

    Column {
        anchors.fill: parent

        // Simple toolbar
        Rectangle {
            width: parent.width
            height: 50
            color: "#2c3e50"

            Row {
                anchors.centerIn: parent
                spacing: 10

                TextField {
                    id: urlField
                    width: 600
                    text: "https://example.com"
                    placeholderText: "Enter URL..."
                    onAccepted: webView.url = text
                }

                Button {
                    text: "Go"
                    onClicked: webView.url = urlField.text
                }

                Button {
                    text: "Evaluate JS"
                    onClicked: {
                        webView.evaluateJavaScript("document.title", function(result, isError) {
                            if (!isError) {
                                console.log("Page title:", result);
                            }
                        });
                    }
                }
            }
        }

        // Native WebView
        QmlNativeWebView {
            id: webView
            width: parent.width
            height: parent.height - 50
            url: "https://example.com"

            onNavigationCompleted: (success) => {
                if (success) {
                    console.log("Navigation completed:", webView.url);
                }
            }

            onMessageReceived: (message) => {
                console.log("Message from WebView:", message);
            }
        }
    }
}
