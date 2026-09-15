#include <QGuiApplication>
#include <QQuickView>
#include <QQmlContext>
#include <QProcess>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDebug>
#include <QAbstractListModel>
#include <QVector>
#include <QStringList>

struct Task
{
    QString title;
    int level;
    int duration;
};

class TaskModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum Roles {
        TitleRole = Qt::UserRole + 1,
        LevelRole,
        DurationRole
    };

    explicit TaskModel(QObject *parent = nullptr)
        : QAbstractListModel(parent)
    {
    }

    int rowCount(const QModelIndex &parent = QModelIndex()) const override
    {
        if (parent.isValid())
            return 0;
        return m_tasks.size();
    }

    QVariant data(const QModelIndex &index,
                  int role = Qt::DisplayRole) const override
    {
        if (!index.isValid() || index.row() >= m_tasks.size())
            return QVariant();

        const Task &task = m_tasks.at(index.row());

        switch (role) {
        case TitleRole:
            return task.title;
        case LevelRole:
            return task.level;
        case DurationRole:
            return task.duration;
        }

        return QVariant();
    }

    QHash<int, QByteArray> roleNames() const override
    {
        return {
            { TitleRole, "title" },
            { LevelRole, "level" },
            { DurationRole, "duration" }
        };
    }

public slots:
    void addTask(const QString &title, int level, int duration)
    {
        if (title.trimmed().isEmpty())
            return;

        const int row = m_tasks.size();

        beginInsertRows(QModelIndex(), row, row);

        m_tasks.append({
            title.trimmed(),
            level,
            duration
        });

        endInsertRows();
    }

    void removeTask(int index)
    {
        if (index < 0 || index >= m_tasks.size())
            return;

        beginRemoveRows(QModelIndex(), index, index);
        m_tasks.removeAt(index);
        endRemoveRows();
    }

    void clear()
    {
        if (m_tasks.isEmpty())
            return;

        beginResetModel();
        m_tasks.clear();
        endResetModel();
    }

private:
    QVector<Task> m_tasks;
};


class SyncManager : public QObject
{
    Q_OBJECT

public:
    explicit SyncManager(TaskModel *taskModel,
                         QObject *parent = nullptr)
        : QObject(parent),
          m_taskModel(taskModel)
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

    void loadWebDeTasks(const QString &username,
                        const QString &password)
    {
        loadTasksFromCalDav(
            "https://caldav.web.de:443/begenda/dav/bofhdd@web.de/calendar/",
            username,
            password);
    }

    void loadTasksFromCalDav(const QString &calendarUrl,
                             const QString &username,
                             const QString &password)
    {
        emit outputChanged(
            "\n========================================\n"
            "TB-Planner: VTODOs über Python/CalDAV lesen\n"
            "========================================\n");

        const QString pythonScript =
            QCoreApplication::applicationDirPath()
            + "/python/planner.py";

        QJsonObject request;
        request["calendar_url"] = calendarUrl;
        request["username"] = username;
        request["password"] = password;
        request["operation"] = "list";

        QProcess *process = new QProcess(this);

        connect(process, &QProcess::readyReadStandardOutput,
                this, [this, process]() {
            const QString text =
                QString::fromUtf8(
                    process->readAllStandardOutput());

            qDebug().noquote() << "Planner Python:" << text;

            QJsonParseError error;
            const QJsonDocument document =
                QJsonDocument::fromJson(text.toUtf8(), &error);

            if (error.error != QJsonParseError::NoError) {
                emit outputChanged(
                    QString("\nFEHLER: Ungültige JSON-Antwort: %1\n")
                    .arg(error.errorString()));
                return;
            }

            const QJsonObject root = document.object();

            if (!root["success"].toBool()) {
                emit outputChanged(
                    QString("\nFEHLER von planner.py: %1\n")
                    .arg(root["error"].toString()));
                return;
            }

            const QJsonArray tasks = root["tasks"].toArray();

            if (m_taskModel)
                m_taskModel->clear();

            emit outputChanged(
                QString("\n--- %1 Tasks gefunden ---\n")
                .arg(tasks.size()));

            for (const QJsonValue &value : tasks) {
                const QJsonObject task = value.toObject();

                const QString title =
                    task["summary"].toString();

                const QString wbs =
                    task["wbs"].toString();

                const int level =
                    wbs.isEmpty() ? 0 : wbs.count('.');

                if (m_taskModel) {
                    m_taskModel->addTask(
                        title,
                        level,
                        1);
                }

                emit outputChanged(
                    QString("Task: %1 | WBS=%2 | Ebene=%3\n")
                    .arg(title)
                    .arg(wbs)
                    .arg(level));
            }
        });

        connect(process, &QProcess::readyReadStandardError,
                this, [this, process]() {
            const QString text =
                QString::fromUtf8(
                    process->readAllStandardError());

            if (!text.trimmed().isEmpty())
                emit outputChanged(
                    "\nPython stderr:\n" + text);
        });

        connect(process,
                QOverload<int, QProcess::ExitStatus>::of(
                    &QProcess::finished),
                this,
                [this, process](int exitCode,
                                QProcess::ExitStatus) {
            emit outputChanged(
                QString(
                    "\n--- planner.py beendet: Exit-Code %1 ---\n")
                .arg(exitCode));

            process->deleteLater();
        });

        process->setEnvironment(
            QProcess::systemEnvironment()
            << "PYTHONPATH="
               + QCoreApplication::applicationDirPath()
               + "/python");

        process->start(
            "python3",
            QStringList() << pythonScript,
            QProcess::ReadWrite);

        if (!process->waitForStarted(3000)) {
            emit outputChanged(
                QString(
                    "\nFEHLER: planner.py konnte nicht gestartet werden.\n"
                    "Fehler: %1\n")
                .arg(process->errorString()));

            process->deleteLater();
            return;
        }

        process->write(
            QJsonDocument(request)
            .toJson(QJsonDocument::Compact));

        process->closeWriteChannel();
    }

signals:
    void outputChanged(const QString &text);
    void finished(const QString &peer, int exitCode);

private:
    void loadTasks(const QString &peer,
                   const QString &source)
    {
        emit outputChanged(
            QString(
                "\n========================================\n"
                "Vorhandene VTODOs lesen: %1 / %2\n"
                "========================================\n")
                .arg(peer)
                .arg(source));

        QProcess *process = new QProcess(this);

        connect(process,
                &QProcess::readyReadStandardOutput,
                this,
                [this, process, peer, source]() {
            const QString text =
                QString::fromLocal8Bit(
                    process->readAllStandardOutput());

            qDebug().noquote() << text;

            parsePrintItems(text, peer, source);
        });

        connect(process,
                &QProcess::readyReadStandardError,
                this,
                [this, process]() {
            const QString text =
                QString::fromLocal8Bit(
                    process->readAllStandardError());

            qDebug().noquote() << text;

            if (!text.trimmed().isEmpty())
                emit outputChanged(text);
        });

        connect(process,
                QOverload<int, QProcess::ExitStatus>::of(
                    &QProcess::finished),
                this,
                [this, process](int exitCode,
                                QProcess::ExitStatus) {
            emit outputChanged(
                QString(
                    "\n--- VTODO-Lesen beendet: "
                    "Exit-Code %1 ---\n")
                    .arg(exitCode));

            process->deleteLater();
        });

        process->start(
            "syncevolution",
            QStringList()
                << "--print-items"
                << peer
                << source
        );

        if (!process->waitForStarted(3000)) {
            emit outputChanged(
                QString(
                    "\nFEHLER: syncevolution konnte "
                    "nicht gestartet werden.\n"
                    "Fehler: %1\n")
                    .arg(process->errorString()));

            process->deleteLater();
        }
    }

    void parsePrintItems(const QString &text,
                         const QString &peer,
                         const QString &source)
    {
        const QStringList lines = text.split('\n');

        int count = 0;

        emit outputChanged(
            "\n--- Gefundene Kalenderobjekte ---\n");

        for (const QString &line : lines) {
            const QString trimmed = line.trimmed();

            if (trimmed.isEmpty())
                continue;

            const int separator = trimmed.indexOf(": ");

            if (separator < 0)
                continue;

            const QString luid =
                trimmed.left(separator).trimmed();

            const QString title =
                trimmed.mid(separator + 2).trimmed();

            if (luid.isEmpty())
                continue;

            emit outputChanged(
                QString(
                    "Objekt: %1\n"
                    "  UID: %2\n")
                .arg(title)
                .arg(luid));

            exportItem(peer, source, luid, title);

            ++count;
        }

        emit outputChanged(
            QString(
                "\n%1 Kalenderobjekt(e) gefunden.\n")
            .arg(count));
    }

    void exportItem(const QString &peer,
                    const QString &source,
                    const QString &luid,
                    const QString &title)
    {
        QProcess *process = new QProcess(this);

        connect(process,
                &QProcess::readyReadStandardOutput,
                this,
                [this, process, luid, title]() {
            const QString text =
                QString::fromLocal8Bit(
                    process->readAllStandardOutput());

            qDebug().noquote()
                << "Export" << luid << ":" << text;

            const bool isVtodo =
                text.contains("BEGIN:VTODO");

            const bool isVevent =
                text.contains("BEGIN:VEVENT");

            if (isVtodo || isVevent) {

                const QString type =
                    isVtodo ? "VTODO" : "VEVENT";

                emit outputChanged(
                    QString(
                        "\nKalenderobjekt erkannt:\n"
                        "  Typ:   %1\n"
                        "  Titel: %2\n"
                        "  UID:   %3\n")
                    .arg(type)
                    .arg(title)
                    .arg(luid));

                if (m_taskModel) {
                    m_taskModel->addTask(
                        title,
                        0,
                        1);
                }

                emit outputChanged(
                    "  -> in App-Liste übernommen.\n");
            }
            else {
                emit outputChanged(
                    QString(
                        "\nUnbekanntes Kalenderobjekt:\n"
                        "  Titel: %1\n"
                        "  UID:   %2\n")
                    .arg(title)
                    .arg(luid));
            }
        });

        connect(process,
                &QProcess::readyReadStandardError,
                this,
                [this, process]() {
            const QString text =
                QString::fromLocal8Bit(
                    process->readAllStandardError());

            if (!text.trimmed().isEmpty())
                emit outputChanged(text);
        });

        connect(process,
                QOverload<int, QProcess::ExitStatus>::of(
                    &QProcess::finished),
                this,
                [process](int, QProcess::ExitStatus) {
            process->deleteLater();
        });

        process->start(
            "syncevolution",
            QStringList()
                << "--export"
                << "-"
                << peer
                << source
                << luid
        );

        if (!process->waitForStarted(3000)) {
            emit outputChanged(
                QString(
                    "FEHLER beim Export von %1: %2\n")
                .arg(luid)
                .arg(process->errorString()));

            process->deleteLater();
        }
    }

    void runSync(const QString &peer,
                 const QString &source)
    {
        qDebug() << "Starting SyncEvolution:"
                 << peer << source;

        emit outputChanged(
            QString(
                "\n========================================\n"
                "Synchronisation: %1\n"
                "========================================\n")
                .arg(peer));

        QProcess *process = new QProcess(this);

        connect(process,
                &QProcess::readyReadStandardOutput,
                this,
                [this, process]() {
            const QString text =
                QString::fromLocal8Bit(
                    process->readAllStandardOutput());

            qDebug().noquote() << text;
            emit outputChanged(text);
        });

        connect(process,
                &QProcess::readyReadStandardError,
                this,
                [this, process]() {
            const QString text =
                QString::fromLocal8Bit(
                    process->readAllStandardError());

            qDebug().noquote() << text;
            emit outputChanged(text);
        });

        connect(process,
                QOverload<int, QProcess::ExitStatus>::of(
                    &QProcess::finished),
                this,
                [this, process, peer](int exitCode,
                                      QProcess::ExitStatus) {
            emit outputChanged(
                QString(
                    "\n--- %1 beendet: "
                    "Exit-Code %2 ---\n")
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
                QString(
                    "\nFEHLER: syncevolution konnte "
                    "nicht gestartet werden.\n"
                    "Fehler: %1\n")
                .arg(process->errorString()));

            process->deleteLater();
        }
    }

    TaskModel *m_taskModel;
};


#include "main.moc"


int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    TaskModel taskModel;
    SyncManager syncManager(&taskModel);

    QQuickView view;

    view.rootContext()->setContextProperty("taskModel", &taskModel);
    view.rootContext()->setContextProperty("syncManager", &syncManager);

    view.setSource(QUrl(QStringLiteral("qrc:/Main.qml")));

    if (view.status() == QQuickView::Error)
        return -1;

    view.show();

    return app.exec();
}
