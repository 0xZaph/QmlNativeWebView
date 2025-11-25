// customwebview.mm
#include "customwebview.h"

#ifdef Q_OS_MAC
#include <QGuiApplication>
#include <QWindow>
#import <WebKit/WebKit.h>

@interface CustomWebViewDelegate : NSObject <WKNavigationDelegate, WKScriptMessageHandler> {
  CustomWebView *qWebView;
}
- (CustomWebViewDelegate *)initWithWebView:(CustomWebView *)webViewPrivate;
- (void)webView:(WKWebView *)webView
    didFinishNavigation:(WKNavigation *)navigation;
- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message;
@end

@implementation CustomWebViewDelegate

- (CustomWebViewDelegate *)initWithWebView:(CustomWebView *)webViewPrivate {
  if ((self = [super init])) {
    Q_ASSERT(webViewPrivate);
    qWebView = webViewPrivate;
  }
  return self;
}

- (void)webView:(WKWebView *)webView
    didFinishNavigation:(WKNavigation *)navigation {
  Q_UNUSED(webView);
  Q_UNUSED(navigation);
  qDebug() << "didFinishNavigation called";
  Q_EMIT qWebView->urlChanged(qWebView->url());
  Q_EMIT qWebView->navigationCompleted(true);
}

- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
  Q_UNUSED(userContentController);
  if ([message.body isKindOfClass:[NSString class]]) {
    QString msg = QString::fromNSString((NSString *)message.body);
    Q_EMIT qWebView->messageReceived(msg);
  }
}

@end

CustomWebView::CustomWebView(QWindow *parent)
    : QWindow(parent), m_isInitialized(false), m_childWindow(nullptr),
      _wkWebView(nil) {
  setFlags(Qt::FramelessWindowHint);
}

CustomWebView::~CustomWebView() { cleanup(); }

void CustomWebView::initialize() {
  if (!m_isInitialized) {
    try {
      WKWebView *webView =
          [[WKWebView alloc] initWithFrame:NSMakeRect(0, 0, width(), height())];
#ifdef DEBUG
      [webView.configuration.preferences setValue:@YES
                                           forKey:@"developerExtrasEnabled"];
#endif

      _wkWebView = webView;
      _wkWebView.navigationDelegate =
          [[CustomWebViewDelegate alloc] initWithWebView:this];

      WKUserContentController *userContentController =
          _wkWebView.configuration.userContentController;
      [userContentController
          addScriptMessageHandler:[[CustomWebViewDelegate alloc]
                                      initWithWebView:this]
                             name:@"messageHandler"];

      // Create a child QWindow from the WKWebView
      m_childWindow = QWindow::fromWinId(WId(_wkWebView));
      if (m_childWindow) {
        m_childWindow->setParent(this);
        m_childWindow->setFlags(Qt::WindowType::Widget);
      }

      m_isInitialized = true;
      Q_EMIT isInitializedChanged();

      // Load the pending URL if it exists
      if (!m_pendingUrl.isEmpty()) {
        setUrl(m_pendingUrl);
        m_pendingUrl.clear();
      }

    } catch (const std::exception &e) {
      qDebug() << __FUNCTION__ << e.what();
    }
  }
}

void CustomWebView::cleanup() {
  if (_wkWebView) {
    [_wkWebView removeFromSuperview];
    [_wkWebView release];
    _wkWebView = nil;
  }

  if (m_childWindow) {
    m_childWindow->setParent(nullptr);
    delete m_childWindow;
    m_childWindow = nullptr;
  }

  m_isInitialized = false;
  Q_EMIT isInitializedChanged();
}

void CustomWebView::reset() {
  cleanup();
  initialize();
}

void CustomWebView::setUrl(const QUrl &url) {
  if (m_isInitialized && _wkWebView) {
    NSURL *nsurl = url.toNSURL();
    wkNavigation = [_wkWebView loadRequest:[NSURLRequest requestWithURL:nsurl]];
    qDebug() << __FUNCTION__ << "Navigated to: " << url;
  } else {
    m_pendingUrl = url;
  }
}

void CustomWebView::evaluateJavaScript(const QString &script,
                                       const QJSValue &callback) {
  if (m_isInitialized && _wkWebView) {
    NSString *nsScript = script.toNSString();
    QJSValue cb = callback;
    [_wkWebView evaluateJavaScript:nsScript
                 completionHandler:^(id _Nullable result,
                                     NSError *_Nullable error) {
                   if (cb.isCallable()) {
                     QJSValueList args;
                     if (error) {
                       args << QJSValue(QString::fromNSString(
                                   error.localizedDescription));
                       args << QJSValue(true); // isError
                     } else {
                       // Convert result to string using description
                       QString resultStr;
                       if (result != nil) {
                         resultStr = QString::fromNSString([result description]);
                       }
                       args << QJSValue(resultStr);
                       args << QJSValue(false); // isError
                     }
                     const_cast<QJSValue &>(cb).call(args);
                   }
                 }];
  }
}

void CustomWebView::clearBrowsingData() {
  WKWebsiteDataStore *dataStore = [WKWebsiteDataStore defaultDataStore];
  NSSet *websiteDataTypes = [WKWebsiteDataStore allWebsiteDataTypes];
  NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
  [dataStore removeDataOfTypes:websiteDataTypes
                 modifiedSince:dateFrom
             completionHandler:^{
               qDebug() << "Browsing data cleared";
             }];
}

void CustomWebView::updateWebViewBounds(int width, int height) {
  if (_wkWebView) {
    [_wkWebView setFrame:NSMakeRect(0, 0, width, height)];
  }

  if (m_childWindow) {
    m_childWindow->setGeometry(0, 0, width, height);
  }
}

void CustomWebView::resizeEvent(QResizeEvent *event) {
  QWindow::resizeEvent(event);
  updateWebViewBounds(event->size().width(), event->size().height());
}

#endif // Q_OS_MAC
