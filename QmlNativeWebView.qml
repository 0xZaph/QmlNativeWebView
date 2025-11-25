import QtQuick

WindowContainer {
    id: windowContainer
    property url url

    CustomWebView {
        id: webView
    }

    window: webView

    Component.onCompleted: {
        console.log("WindowContainer - component completed");
        webView.reset();
    }

    signal navigationCompleted(bool success)
    signal messageReceived(string message)

    function evaluateJavaScript(script, callback) {
        webView.evaluateJavaScript(script, callback);
    }

    function clearBrowsingData() {
        webView.clearBrowsingData();
    }

    Connections {
        target: webView
        function onIsInitializedChanged() {
            if (webView.isInitialized) {
                console.log("NativeWebView is properly initalized now...");
                webView.updateWebViewBounds(width, height);
            }
        }
        function onNavigationCompleted(success) {
            navigationCompleted(success);
        }
        function onMessageReceived(message) {
            messageReceived(message);
        }
    }

    onUrlChanged: {
        webView.url = url;
    }
}
