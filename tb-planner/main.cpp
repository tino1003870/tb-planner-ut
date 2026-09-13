#include <QGuiApplication>
#include <QQuickView>
#include <QQmlContext>
#include <QProcess>
#include <QDebug>

class SyncManager : public QObject
{
    Q_OBJECT

public:
    explicit SyncManager(QObject *parent = nullptr)
        : QObject(parent)
    {
    }

public slots:
    void syncGmx()
    {
        runSync("generic-caldav-3", "3calendar");
    }

    void syncWebDe()
    {
        runSync("generic-caldav-5", "5calendar");
    }

    void syncBoth()
    {
        runSync("generic-caldav-3", "3calendar");
        runSync("generic-caldav-5", "5calendar");
    }

signals:
    void outputChanged(const QString &text);
    void finished(const QString &peer, int exitCode);

private:
    void runSync(const QString &peer, const QString &source)
    {
        qDebug() << "Starting SyncEvolution:"
                 << peer << source;

        emit outputChanged(
            QString("\n========================================\n"
                    "Synchronisation: %1\n"
                    "========================================\n")
                .arg(peer));

        QProcess *process = new QProcess(this);

        connect(process, &QProcess::readyReadStandardOutput,
                this, [this, process]() {
            const QString text =
                QString::fromLocal8Bit(process->readAllStandardOutput());

            qDebug().noquote() << text;
            emit outputChanged(text);
        });

        connect(process, &QProcess::readyReadStandardError,
                this, [this, process]() {
            const QString text =
                QString::fromLocal8Bit(process->readAllStandardError());

            qDebug().noquote() << text;
            emit outputChanged(text);
        });

        connect(process,
                QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
                this,
                [this, process, peer](int exitCode,
                                      QProcess::ExitStatus) {

            emit outputChanged(
                QString("\n--- %1 beendet: Exit-Code %2 ---\n")
                    .arg(peer)
                    .arg(exitCode));

            emit finished(peer, exitCode);

            process->deleteLater();
        });

        process->start(
            "syncevolution",
            QStringList() << peer << source
        );

        if (!process->waitForStarted(3000)) {
            emit outputChanged(
                QString("\nFEHLER: syncevolution konnte nicht gestartet werden.\n"
                        "Fehler: %1\n")
                    .arg(process->errorString()));

            process->deleteLater();
        }
    }
};

#include "main.moc"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    app.setApplicationName(
        "tb-planner.com.tino");

    SyncManager syncManager;

    QQuickView view;

    view.rootContext()->setContextProperty(
        "syncManager", &syncManager);

    view.setSource(QUrl("qrc:/Main.qml"));
    view.setResizeMode(
        QQuickView::SizeRootObjectToView);
    view.show();

    return app.exec();
}
