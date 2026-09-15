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
#include <QSettings>

struct Task
{
    QString uid;
    QString title;
    int level;
    int duration;
    bool synced;

    QString wbs;
    QString parent;
    int order;
};

class TaskModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum Roles {
        TitleRole = Qt::UserRole + 1,
        LevelRole,
        DurationRole,
        SyncedRole,
        UidRole,
        WbsRole,
        ParentRole,
        OrderRole
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
        case SyncedRole:
            return task.synced;
        case UidRole:
            return task.uid;
        case WbsRole:
            return task.wbs;
        case ParentRole:
            return task.parent;
        case OrderRole:
            return task.order;
        }

        return QVariant();
    }

    QHash<int, QByteArray> roleNames() const override
    {
        return {
            { TitleRole, "title" },
            { LevelRole, "level" },
            { DurationRole, "duration" },
            { SyncedRole, "synced" },
            { UidRole, "uid" },
            { WbsRole, "wbs" },
            { ParentRole, "parent" },
            { OrderRole, "taskOrder" }
        };
    }

public slots:
    void addTask(const QString &title,
                 int level,
                 int duration,
                 bool synced = false,
                 const QString &uid = QString(),
                 const QString &wbs = QString(),
                 const QString &parent = QString(),
                 int order = -1)
    {
        if (title.trimmed().isEmpty())
            return;

        const int row = m_tasks.size();

        beginInsertRows(QModelIndex(), row, row);

        m_tasks.append({
            uid,
            title.trimmed(),
            level,
            duration,
            synced,
            wbs,
            parent,
            order
        });

        endInsertRows();
    }

    void setTaskTitle(int index, const QString &title)
    {
        if (index < 0 || index >= m_tasks.size())
            return;

        const QString trimmed = title.trimmed();

        if (trimmed.isEmpty())
            return;

        Task &task = m_tasks[index];

        if (task.title == trimmed)
            return;

        task.title = trimmed;
        task.synced = false;

        const QModelIndex modelIndex = this->index(index);

        emit dataChanged(
            modelIndex,
            modelIndex,
            { TitleRole, SyncedRole }
        );
    }

    void moveTaskUp(int index)
    {
        if (index <= 0 || index >= m_tasks.size())
            return;

        beginMoveRows(
            QModelIndex(),
            index,
            index,
            QModelIndex(),
            index - 1
        );

        qSwap(m_tasks[index], m_tasks[index - 1]);

        endMoveRows();

        markAllUnsynced();
    }

    void moveTaskDown(int index)
    {
        if (index < 0 || index >= m_tasks.size() - 1)
            return;

        beginMoveRows(
            QModelIndex(),
            index,
            index,
            QModelIndex(),
            index + 2
        );

        qSwap(m_tasks[index], m_tasks[index + 1]);

        endMoveRows();

        markAllUnsynced();
    }

    void indentTask(int index)
    {
        if (index <= 0 || index >= m_tasks.size())
            return;

        Task &task = m_tasks[index];

        if (task.level >= 4)
            return;

        task.level++;
        task.synced = false;

        const QModelIndex modelIndex = this->index(index);

        emit dataChanged(
            modelIndex,
            modelIndex,
            { LevelRole, SyncedRole }
        );
    }

    void outdentTask(int index)
    {
        if (index < 0 || index >= m_tasks.size())
            return;

        Task &task = m_tasks[index];

        if (task.level <= 0)
            return;

        task.level--;
        task.synced = false;

        const QModelIndex modelIndex = this->index(index);

        emit dataChanged(
            modelIndex,
            modelIndex,
            { LevelRole, SyncedRole }
        );
    }

    void removeTask(int index)
    {
        if (index < 0 || index >= m_tasks.size())
            return;

        beginRemoveRows(QModelIndex(), index, index);
        m_tasks.removeAt(index);
        endRemoveRows();
    }

    void setTaskSynced(int index, bool synced)
    {
        if (index < 0 || index >= m_tasks.size())
            return;

        m_tasks[index].synced = synced;

        const QModelIndex modelIndex = this->index(index);

        emit dataChanged(
            modelIndex,
            modelIndex,
            { SyncedRole }
        );
    }

    void markAllUnsynced()
    {
        for (int i = 0; i < m_tasks.size(); ++i)
            m_tasks[i].synced = false;

        if (!m_tasks.isEmpty()) {
            emit dataChanged(
                this->index(0),
                this->index(m_tasks.size() - 1),
                { SyncedRole }
            );
        }
    }

    int taskCount() const
    {
        return m_tasks.size();
    }

    QVariantMap taskData(int index) const
    {
        QVariantMap result;

        if (index < 0 || index >= m_tasks.size())
            return result;

        const Task &task = m_tasks.at(index);

        result["uid"] = task.uid;
        result["summary"] = task.title;
        result["level"] = task.level;
        result["duration"] = task.duration;
        result["synced"] = task.synced;
        result["wbs"] = task.wbs;
        result["parent"] = task.parent;
        result["order"] = task.order;

        return result;
    }

    void setTaskUid(int index, const QString &uid)
    {
        if (index < 0 || index >= m_tasks.size())
            return;

        Task &task = m_tasks[index];

        task.uid = uid;

        const QModelIndex modelIndex = this->index(index);

        emit dataChanged(
            modelIndex,
            modelIndex,
            { UidRole }
        );
    }

    void setTaskPlannerData(int index,
                            const QString &uid,
                            const QString &wbs,
                            const QString &parent,
                            int order)
    {
        if (index < 0 || index >= m_tasks.size())
            return;

        Task &task = m_tasks[index];

        task.uid = uid;
        task.wbs = wbs;
        task.parent = parent;
        task.order = order;
        task.synced = true;

        const QModelIndex modelIndex = this->index(index);

        emit dataChanged(
            modelIndex,
            modelIndex,
            {
                UidRole,
                WbsRole,
                ParentRole,
                OrderRole,
                SyncedRole
            }
        );
    }

    void markAllSynced()
    {
        if (m_tasks.isEmpty())
            return;

        for (Task &task : m_tasks)
            task.synced = true;

        emit dataChanged(
            index(0),
            index(m_tasks.size() - 1),
            { SyncedRole }
        );
    }

    QJsonArray taskArray() const
    {
        QJsonArray array;

        for (const Task &task : m_tasks) {
            QJsonObject obj;

            obj["uid"] = task.uid;
            obj["summary"] = task.title;
            obj["level"] = task.level;
            obj["duration"] = task.duration;
            obj["wbs"] = task.wbs;
            obj["parent"] = task.parent;
            obj["order"] = task.order;

            array.append(obj);
        }

        return array;
    }

    void applySyncResult(int index,
                         const QString &uid,
                         const QString &wbs,
                         const QString &parent,
                         int order)
    {
        if (index < 0 || index >= m_tasks.size())
            return;

        Task &task = m_tasks[index];

        if (!uid.isEmpty())
            task.uid = uid;

        task.wbs = wbs;
        task.parent = parent;
        task.order = order;
        task.synced = true;

        const QModelIndex modelIndex = this->index(index);

        emit dataChanged(
            modelIndex,
            modelIndex,
            {
                SyncedRole,
                UidRole,
                WbsRole,
                ParentRole,
                OrderRole
            }
        );
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

    Q_INVOKABLE QVariantMap loadConnectionSettings()
    {
        QSettings settings(
            "com.tino",
            "tb-planner"
        );

        QVariantMap result;

        result["url"] = settings.value(
            "caldav/url",
            "https://caldav.web.de:443/begenda/dav/4369253c-5ad8-4f96-a511-5b8952097a87/calendar/"
        );

        result["username"] = settings.value(
            "caldav/username",
            ""
        );

        return result;
    }

    Q_INVOKABLE void saveConnectionSettings(
        const QString &url,
        const QString &username)
    {
        QSettings settings(
            "com.tino",
            "tb-planner"
        );

        settings.setValue(
            "caldav/url",
            url
        );

        settings.setValue(
            "caldav/username",
            username
        );

        settings.sync();

        emit outputChanged(
            "\nVerbindungseinstellungen gespeichert.\n"
            "Passwort wird nicht gespeichert.\n"
        );
    }

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

    void syncTasks(const QString &calendarUrl,
                   const QString &username,
                   const QString &password)
    {
        if (!m_taskModel) {
            emit outputChanged(
                "\nFEHLER: TaskModel nicht verfügbar.\\n");
            return;
        }

        emit outputChanged(
            "\n========================================\\n"
            "TB-Planner: Tasks synchronisieren\\n"
            "========================================\\n");

        const QString pythonScript =
            QCoreApplication::applicationDirPath()
            + "/python/planner.py";

        QJsonArray tasks;

        for (int i = 0; i < m_taskModel->taskCount(); ++i) {

            const QVariantMap data =
                m_taskModel->taskData(i);

            QJsonObject task;

            task["uid"] =
                data.value("uid").toString();

            task["summary"] =
                data.value("summary").toString();

            task["level"] =
                data.value("level").toInt();

            task["duration"] =
                data.value("duration").toInt();

            tasks.append(task);
        }

        QJsonObject request;

        request["calendar_url"] = calendarUrl;
        request["username"] = username;
        request["password"] = password;
        request["operation"] = "sync";
        request["tasks"] = tasks;

        QProcess *process = new QProcess(this);

        connect(process,
                &QProcess::readyReadStandardOutput,
                this,
                [this, process]() {

            const QString text =
                QString::fromUtf8(
                    process->readAllStandardOutput());

            qDebug().noquote()
                << "Planner Python sync:" << text;

            QJsonParseError error;

            const QJsonDocument document =
                QJsonDocument::fromJson(
                    text.toUtf8(),
                    &error);

            if (error.error !=
                QJsonParseError::NoError) {

                emit outputChanged(
                    QString(
                        "\nFEHLER: Ungültige JSON-Antwort: %1\\n")
                    .arg(error.errorString()));

                return;
            }

            const QJsonObject root =
                document.object();

            if (!root["success"].toBool()) {

                emit outputChanged(
                    QString(
                        "\nFEHLER von planner.py: %1\\n")
                    .arg(
                        root["error"].toString()));

                return;
            }

            const QJsonArray results =
                root["results"].toArray();

            int successful = 0;

            for (int i = 0;
                 i < results.size();
                 ++i) {

                const QJsonObject result =
                    results.at(i).toObject();

                if (!result["success"].toBool())
                    continue;

                if (i >= m_taskModel->taskCount())
                    continue;

                const QString uid =
                    result["uid"].toString();

                const QString wbs =
                    result["wbs"].toString();

                const QString parent =
                    result["parent"].toString();

                const int order =
                    result["order"].toInt(-1);

                m_taskModel->setTaskPlannerData(
                    i,
                    uid,
                    wbs,
                    parent,
                    order);

                ++successful;

                emit outputChanged(
                    QString(
                        "Sync: %1 | WBS=%2 | Parent=%3\\n")
                    .arg(uid)
                    .arg(wbs)
                    .arg(parent));
            }

            emit outputChanged(
                QString(
                    "\n--- Synchronisation abgeschlossen: "
                    "%1/%2 Tasks ---\\n")
                .arg(successful)
                .arg(results.size()));
        });

        connect(process,
                &QProcess::readyReadStandardError,
                this,
                [this, process]() {

            const QString text =
                QString::fromUtf8(
                    process->readAllStandardError());

            if (!text.trimmed().isEmpty())
                emit outputChanged(
                    "\nPython stderr:\n" + text);
        });

        connect(process,
                QOverload<int,
                          QProcess::ExitStatus>::of(
                    &QProcess::finished),
                this,
                [this, process](int exitCode,
                                QProcess::ExitStatus exitStatus) {

            if (exitStatus !=
                QProcess::NormalExit ||
                exitCode != 0) {

                emit outputChanged(
                    QString(
                        "\nFEHLER: planner.py beendet "
                        "mit Exit-Code %1.\\n")
                    .arg(exitCode));
            }

            // Debug: tatsächliches Ende des QProcess sichtbar machen.
            emit outputChanged(
                "\n[DEBUG C++] QProcess finished erreicht.\n");

            // QML darüber informieren, dass der Task-Sync
            // unabhängig vom Ergebnis beendet wurde.
            emit taskSyncFinished();

            process->deleteLater();
        });

        const QByteArray input =
            QJsonDocument(request)
            .toJson(QJsonDocument::Compact);

        process->setProgram("python3");

        process->setArguments({
            pythonScript
        });

        process->start();

        if (!process->waitForStarted(3000)) {

            emit outputChanged(
                "\nFEHLER: python3 konnte nicht gestartet werden.\\n");

            emit taskSyncFinished();

            process->deleteLater();
            return;
        }

        process->write(input);
        process->closeWriteChannel();
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
                        1,
                        true,
                        task["uid"].toString(),
                        wbs,
                        task["parent"].toString(),
                        task["order"].toInt(-1));
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
    void taskSyncFinished();
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
                        1,
                        true);
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
