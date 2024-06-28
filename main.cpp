#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QApplication>
#include <QSystemTrayIcon>

#include <QIcon>
#include <QQuickWidget>
#include <QSystemTrayIcon>
#include <QQmlContext>

#include <cpr/cpr.h>
#include <thread>

std::string response;
const std::string link = "php-docker.local:8080/berry.php";
const int id = 1;

void request() {
    qDebug() << "the request has been sent";
    try {
        auto r = cpr::Get(cpr::Url{link},
                          cpr::Parameters{{"id", std::to_string(id)}});
        response = r.text;

    } catch (const std::exception &e) {
        qDebug() << e.what();
    }
}


// Объявляем пользовательский тип данных для работы с иконкой в QML
Q_DECLARE_METATYPE(QSystemTrayIcon::ActivationReason)

int main(int argc, char *argv[])
{
    std::thread th1(request);

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



    th1.join();

    qDebug() << "response: " << response;
    std::vector<std::string> values{};
    std::string temp = "";
    for (int i = 0; i < response.length(); i++) {
        if (response[i] == '<') {
            values.push_back(temp);
            temp = "";
            if (i + 4 == response.length()){
                break;
            } else {
                i += 4;
            }
        }
        if (response[i] != '<') {
            temp += response[i];
        }
    }
    std::string functionName = "day_"; functionName += values[0];
    std::string toDoList = std::string("Нужно зарядиться: ") + values[1] + std::string("\nНужно пнуть мяч: ") + values[2];
    QMetaObject::invokeMethod(engine.rootObjects().first(), functionName.c_str(), Q_ARG(QVariant, toDoList.c_str()));

    // QObject* window = engine.rootObjects().first()->findChild<QObject*>("container")->findChild<QObject*>("berryEnvironment");
    // QObject* object = window->findChild<QObject*>("textToToDoList");
    // object->setProperty("text", QVariant(toDoList.c_str()));

    // engine.rootContext()->setContextProperty("toDoListText", toDoList.c_str());

    // QMetaObject::invokeMethod(engine.rootObjects().first(), "say", Q_ARG(QVariant, "Как и с обычным питомцем, ты должен играть со мной, развлекать меня и просто хорошо проводить время. Буль-буль, бла бла бла бла"));
    return app.exec();
}
