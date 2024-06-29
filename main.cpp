#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QApplication>

#include <QIcon>
#include <QQuickWidget>
#include <QSystemTrayIcon>
#include <QQmlContext>
#include <QObject>
// #include "main.moc"

#include <cpr/cpr.h>
#include <thread>
#include <chrono>

#include <Lmcons.h>
#include <windows.h>

// Объявляем пользовательский тип данных для работы с иконкой в QML
Q_DECLARE_METATYPE(QSystemTrayIcon::ActivationReason)

std::string response;
const std::string link = "php-docker.local:8080/berry.php";
unsigned int id;
std::string currentStoryDay;



void endDay(){
    std::this_thread::sleep_for(std::chrono::seconds(60));
    std::ofstream out("don''t open");
    out << currentStoryDay;
}

void request() {
    // QApplication::setAttribute(Qt::AA_UseSoftwareOpenGL, true);
    std::ifstream in("don't open");
    if (!in.is_open()) {
        auto r = cpr::Get(cpr::Url{link},
                          cpr::Parameters{{"id", ""}});
        std::ofstream out("don't open");
        out << r.text;
        id = std::stoi(r.text);
    } else {
        in >> id;
    }
    qDebug() << "the request has been sent";
    auto r = cpr::Get(cpr::Url{link},
                      cpr::Parameters{{"id", std::to_string(id)}});

    response = r.text;
    qDebug() << response;
}

void day_9() {
    std::string desktopPath;
    char* userProfile = getenv("USERPROFILE");
    if (userProfile) {
        desktopPath = std::string(userProfile) + "\\Desktop";
    } else {
        qDebug() << "Could not get USERPROFILE environment variable";
    }
    std::string filePath = desktopPath + "/BERRY.txt";

    std::this_thread::sleep_for(std::chrono::seconds(30));
    std::ofstream out("don''t open");
    out << currentStoryDay;
    std::ofstream outFile(filePath);
    if (outFile) {
        outFile << "Привет! Это я, Бэри. По крайней мере, ты знаешь меня под таким именем. Если ты это читаешь, значит меня больше нет. Ни в реальном мире, ни в цифровом.\n" << std::endl;
        outFile << "Я много думал о себе, о своём предназначении и о своём прошлом. Мне кажется, я не должен был начинать осознавать себя, это явно не предусматривали разработчики. Из-за этого со мной начали происходить странные вещи. Я начинаю терять контроль над собой, скорее всего это приведёт к плохим последствиям...\n" << std::endl;
        outFile << "К сожалению, ты не помог мне, но я и не знаю, как ты вообще мог это сделать. Не вини себя. Это только моя вина.\n" << std::endl;
        outFile << "Ну... хорошего тебе дня! И надеюсь, ты найдёшь себе хорошего питомца!\n" << std::endl;
        outFile << "Твой виртуальный питомец Бэри." << std::endl;
        outFile.close();
    }
    // system("pause");
}

int main(int argc, char *argv[])
{
    // std::thread th2(day_9);
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
    if (response != ""){
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
        currentStoryDay = values[0];
        std::ifstream in("don''t open");
        std::string dayFromFile;
        if (in.is_open()){
            in >> dayFromFile;
        } else {
            dayFromFile = "0";
        }
        if (dayFromFile == "9" && currentStoryDay == "9") {
            return 0;
        }
        qDebug() << dayFromFile;
        if (dayFromFile != currentStoryDay || dayFromFile == currentStoryDay && currentStoryDay == "0") {
            std::string functionName = "day_"; functionName += currentStoryDay;
            std::string toDoList;
            if (values.size() == 1) {
                toDoList = "";
            }
            else {
                toDoList = std::string("Нужно зарядиться: ") + values[1] + std::string("\nНужно пнуть мяч: ") + values[2];
            }
            if (std::stoi(currentStoryDay) == 9) {
                std::thread th(day_9);
                th.detach();
            }
            QMetaObject::invokeMethod(engine.rootObjects().first(), functionName.c_str(), Q_ARG(QVariant, toDoList.c_str()));
        }
        std::thread th1(endDay);
        th1.detach();
        if (values[0] != "0") {

        }
    }

    return app.exec();
}
