/*
 * SPDX-FileCopyrightText: 2014 Martin Gräßlin <mgraesslin@kde.org>
 * SPDX-FileCopyrightText: 2018 Michail Vourlakos <mvourlakos@gmail.org>
 *
 * This file is part of the libappletdecoration library
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

#include "decorationsmodel.h"

#include "previewbridge.h"

#include <KConfigGroup>
#include <KDecoration3/Decoration>
#include <KDecoration3/DecorationSettings>
#include <KDecoration3/DecorationThemeProvider>
#include <KDirWatch>
#include <KLocalizedString>
#include <KPluginFactory>
#include <KSharedConfig>
#include <Plasma/PluginLoader>
#include <QDebug>
#include <QDir>
#include <qloggingcategory.h>

Q_LOGGING_CATEGORY(decorations_model, "DecorationsModel");

static const QString s_defaultPlugin = QStringLiteral("org.kde.breeze");
static const QString s_defaultTheme;
static const QString s_auroraePlugin = QStringLiteral("org.kde.kwin.aurorae");
static const QString s_auroraeSvgTheme = QStringLiteral("__aurorae__svg__");

static const QString s_kwinrc = QStringLiteral("kwinrc");
static const QString s_pluginName = QStringLiteral("org.kde.kdecoration3");

DecorationsModel::DecorationsModel(QObject *parent) : QAbstractListModel(parent)
{
    init();
    loadCurrents();

    const auto kwinRc = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + QLatin1Char('/') + s_kwinrc;

    KDirWatch::self()->addFile(kwinRc);

    connect(KDirWatch::self(), &KDirWatch::dirty, this, &DecorationsModel::kwinChanged);
    connect(KDirWatch::self(), &KDirWatch::created, this, &DecorationsModel::kwinChanged);
}

DecorationsModel::~DecorationsModel() = default;

int DecorationsModel::count() const
{
    return m_plugins.size();
}

QString DecorationsModel::currentPlugin() const
{
    return m_currentPlugin;
}

void DecorationsModel::setCurrentPlugin(QString plugin)
{
    if (m_currentPlugin == plugin)
    {
        return;
    }

    m_currentPlugin = plugin;
    emit currentPluginChanged();
}

QString DecorationsModel::currentTheme() const
{
    return m_currentTheme;
}

void DecorationsModel::setCurrentTheme(QString theme)
{
    if (m_currentTheme == theme)
    {
        return;
    }

    m_currentTheme = theme;
    emit currentThemeChanged();
}

int DecorationsModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
    {
        return 0;
    }

    return m_plugins.size();
}

QVariant DecorationsModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.column() != 0 || index.row() < 0 || index.row() >= int(m_plugins.size()))
    {
        return QVariant();
    }

    const Data &d = m_plugins.at(index.row());

    switch (role)
    {
        case Qt::DisplayRole: return d.visibleName;
        case Qt::UserRole + 4: return d.pluginName;
        case Qt::UserRole + 5: return d.themeName;
        case Qt::UserRole + 6: return d.isAuroraeTheme;
        case Qt::UserRole + 7: return d.configuration;
    }

    return QVariant();
}

QHash<int, QByteArray> DecorationsModel::roleNames() const
{
    QHash<int, QByteArray> roles({ { Qt::DisplayRole, QByteArrayLiteral("display") },
                                   { Qt::UserRole + 4, QByteArrayLiteral("plugin") },
                                   { Qt::UserRole + 5, QByteArrayLiteral("theme") },
                                   { Qt::UserRole + 6, QByteArrayLiteral("isAuroraeTheme") },
                                   { Qt::UserRole + 7, QByteArrayLiteral("configureable") } });
    return roles;
}

static bool isThemeEngine(const QVariantMap &decoSettingsMap)
{
    return decoSettingsMap["themes"].toBool();
}

static bool isConfigureable(const QVariantMap &decoSettingsMap)
{
    return decoSettingsMap["kcmodule"].toBool();
}

static QString themeListKeyword(const QVariantMap &decoSettingsMap)
{
    return decoSettingsMap["themeListKeyword"].toString();
}

void DecorationsModel::init()
{
    beginResetModel();
    m_plugins.clear();

    const auto plugins = KPluginMetaData::findPlugins(s_pluginName);
    for (const auto &info : plugins)
    {
        const auto decoSettingsMap = info.rawData().value("org.kde.kdecoration3").toObject().toVariantMap();

        if (isThemeEngine(decoSettingsMap))
        {
            const QString keyword = themeListKeyword(decoSettingsMap);
            if (keyword.isNull())
            {
                // We cannot list the themes
                qWarning() << "No theme list keyword for" << info.pluginId();
                continue;
            }

            const auto themeProvider = KPluginFactory::instantiatePlugin<KDecoration3::DecorationThemeProvider>(info).plugin;
            for (const auto &t : themeProvider->themes())
            {
                Data data;
                data.pluginName = t.pluginId();
                data.themeName = t.themeName();
                data.visibleName = t.visibleName();

                if (data.pluginName.startsWith(s_auroraePlugin) && data.themeName.startsWith(s_auroraeSvgTheme))
                    data.isAuroraeTheme = true;

                if (!data.isAuroraeTheme)
                    continue;

                qCInfo(decorations_model) << "Adding theme" << data.visibleName << "from" << data.pluginName;
                m_plugins.emplace_back(std::move(data));
            }
        }
        else
        {

            const Data data{
                .pluginName = info.pluginId(),
                .themeName = QString(),
                .visibleName = info.name().isEmpty() ? info.pluginId() : info.name(),
                .isAuroraeTheme = false,
                .configuration = isConfigureable(decoSettingsMap),
            };

            qCInfo(decorations_model) << "Adding theme" << data.visibleName << "from" << data.pluginName;
            m_plugins.emplace_back(std::move(data));
        }
    }

    std::sort(m_plugins.begin(), m_plugins.end(), [](const Data &a, const Data &b) { return a.visibleName.localeAwareCompare(b.visibleName) < 0; });

    Data currentData{
        .pluginName = QString(),
        .themeName = QString(),
        .visibleName = i18n("Current"),
        .isAuroraeTheme = false,
        .configuration = false,
    };
    m_plugins.insert(m_plugins.begin(), std::move(currentData));

    endResetModel();
}

void DecorationsModel::loadCurrents()
{
    KConfigGroup config = KSharedConfig::openConfig(s_kwinrc)->group(s_pluginName);
    if (!config.hasKey("library"))
    {
        config = KSharedConfig::openConfig(s_kwinrc)->group(QStringLiteral("org.kde.kdecoration2"));
    }

    const QString plugin = config.readEntry("library", s_defaultPlugin);
    const QString theme = config.readEntry("theme", s_defaultTheme);

    bool exists{ decorationExists(plugin, theme) };

    setCurrentPlugin(exists ? plugin : s_defaultPlugin);
    setCurrentTheme(exists ? theme : s_defaultTheme);
}

void DecorationsModel::kwinChanged(const QString &filename)
{
    if (!filename.endsWith(s_kwinrc))
    {
        return;
    }

    loadCurrents();
}

int DecorationsModel::indexOf(const QString &plugin, const QString &theme) const
{
    if (plugin.isEmpty())
    {
        return 0;
    }

    for (size_t i = 1; i < m_plugins.size(); ++i)
    {
        const auto &d = m_plugins[i];
        if (d.pluginName == plugin)
        {
            if (d.isAuroraeTheme)
            {
                if (d.themeName == theme)
                {
                    return static_cast<int>(i);
                }
            }
            else
            {
                if (d.themeName.isEmpty() || d.themeName == theme)
                {
                    return static_cast<int>(i);
                }
            }
        }
    }

    return 0;
}

bool DecorationsModel::isAurorae(const QString &plugin, const QString &theme)
{
    QString p = plugin;
    QString t = theme;
    if (p.isEmpty())
    {
        p = m_currentPlugin;
        t = m_currentTheme;
    }

    auto it = std::find_if(m_plugins.cbegin(), m_plugins.cend(),
                           [p, t](const Data &d)
                           {
                               if (d.pluginName.isEmpty() || d.pluginName != p)
                               {
                                   return false;
                               }
                               if (d.isAuroraeTheme)
                               {
                                   return d.themeName == t;
                               }
                               return true;
                           });

    if (it == m_plugins.cend())
    {
        return false;
    }

    return (*it).isAuroraeTheme;
}

bool DecorationsModel::decorationExists(const QString &plugin, const QString &theme)
{
    if (plugin.isEmpty())
    {
        return false;
    }

    auto it = std::find_if(m_plugins.cbegin(), m_plugins.cend(),
                           [plugin, theme](const Data &d)
                           {
                               if (d.pluginName.isEmpty() || d.pluginName != plugin)
                               {
                                   return false;
                               }
                               if (d.isAuroraeTheme)
                               {
                                   return d.themeName == theme;
                               }
                               return d.themeName.isEmpty() || d.themeName == theme;
                           });

    return it != m_plugins.cend();
}
