#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QApplication>
#include <QSystemTrayIcon>

#include <QIcon>
#include <QQuickWidget>
#include <QSystemTrayIcon>
#include <QQmlContext>

// #include <functions.h>

// Объявляем пользовательский тип данных для работы с иконкой в QML
Q_DECLARE_METATYPE(QSystemTrayIcon::ActivationReason)

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    app.setWindowIcon(QIcon("Images/appIcons/trayIcon.ico"));

    QQmlApplicationEngine engine;


    // Регистрируем QSystemTrayIcon в качестве типа объекта в Qml
    qmlRegisterType<QSystemTrayIcon>("QSystemTrayIcon", 1, 0, "QSystemTrayIcon");
    // Регистрируем в QML тип данных для работы с получаемыми данными при клике по иконке
    qRegisterMetaType<QSystemTrayIcon::ActivationReason>("ActivationReason");
    // Устанавливаем Иконку в контекст движка
    engine.rootContext()->setContextProperty("iconTray", QIcon("Images/appIcons/trayIcon.png"));


    const QUrl url(u"/Berry/Main.qml"_qs);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.load(url);

    QMetaObject::invokeMethod(engine.rootObjects().first(), "say", Q_ARG(QVariant, "Как и с обычным питомцем, ты должен играть со мной, развлекать меня и просто хорошо проводить время. Буль-буль, бла бла бла бла"));

    return app.exec();
}
