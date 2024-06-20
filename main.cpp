#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QApplication>
#include <QSystemTrayIcon>

#include <QIcon>
#include <QQuickWidget>
#include <QSystemTrayIcon>
#include <QQmlContext>

#include <functions.h>

// Объявляем пользовательский тип данных для работы с иконкой в QML
Q_DECLARE_METATYPE(QSystemTrayIcon::ActivationReason)

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    QQmlApplicationEngine engine;


    // Регистрируем QSystemTrayIcon в качестве типа объекта в Qml
    qmlRegisterType<QSystemTrayIcon>("QSystemTrayIcon", 1, 0, "QSystemTrayIcon");
    // Регистрируем в QML тип данных для работы с получаемыми данными при клике по иконке
    qRegisterMetaType<QSystemTrayIcon::ActivationReason>("ActivationReason");
    // Устанавливаем Иконку в контекст движка
    engine.rootContext()->setContextProperty("iconTray", QIcon("Images/appIcons/trayIcon.png"));
    engine.rootContext()->setContextProperty("colorVar", "transparent");


    const QUrl url(u"/Berry/Main.qml"_qs);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.load(url);

    // QObject *rootObject = engine.rootObjects().value(0);
    // QQuickWindow *qmlWindow = qobject_cast<QQuickWindow *>(rootObject);

    // if (qmlWindow) {
    //     // Устанавливаем нужные флаги окна
    //     qmlWindow->setFlags(Qt::FramelessWindowHint | Qt::WindowTransparentForInput | Qt::WindowStaysOnTopHint);
    // }


    return app.exec();
}
