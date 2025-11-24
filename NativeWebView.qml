import QtQuick
import NativeWebView

WindowContainer {
    property url url

    CustomWebView {
        id: webView
    }

    window: webView

    Component.onCompleted: {
        console.log("WindowContainer - component completed");
        webView.reset();
    }

    Connections {
        target: webView
        function onIsInitializedChanged() {
            if (webView.isInitialized) {
                console.log("NativeWebView is properly initalized now...");
                webView.updateWebViewBounds(width, height);
            }
        }
    }

    onUrlChanged: {
        webView.url = url;
    }
}
