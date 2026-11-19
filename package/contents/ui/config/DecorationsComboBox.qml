/*
 *  SPDX-FileCopyrightText: 2018 Michail Vourlakos <mvourlakos@gmail.com>
 *
 *  This file is part of applet-window-buttons
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

ComboBox {
    id: combobox

    function selectIndex(index) {
        if (index < 0 || index >= sortedDecorations.rowCount())
            return ;

        var idx = sortedDecorations.index(index, 0);
        var p = sortedDecorations.data(idx, Qt.UserRole + 4);
        var t = sortedDecorations.data(idx, Qt.UserRole + 5);
        if (typeof root !== "undefined") {
            root.useCurrent = false;
            root.selectedPlugin = p;
            root.selectedTheme = t;
        }
    }

    function findDecorationIndex(plugin, theme) {
        for (var i = 0; i < sortedDecorations.rowCount(); i++) {
            var idx = sortedDecorations.index(i, 0);
            var p = sortedDecorations.data(idx, Qt.UserRole + 4);
            var t = sortedDecorations.data(idx, Qt.UserRole + 5);
            if (p === plugin && t === theme)
                return i;

        }
        return -1;
    }

    model: sortedDecorations
    textRole: "display"
    popup.width: Math.max(combobox.width, popup.implicitWidth)
    popup.height: Math.min(Kirigami.Units.gridUnit * 20, Math.max(popup.implicitHeight, popup.contentHeight))
    onActivated: function(index) {
        selectIndex(index);
    }
    Component.onCompleted: {
        currentIndex = findDecorationIndex(root.currentPlugin, root.currentTheme);
    }

    delegate: ItemDelegate {
        id: itemDelegate

        required property int index
        required property var model

        visible: !(parent && parent.contentItem !== undefined)
        width: ListView.view ? ListView.view.width : (parent ? parent.width : implicitWidth)
        text: model.display
        highlighted: combobox.highlightedIndex === index
        onClicked: {
            combobox.currentIndex = index;
            selectIndex(index);
            combobox.popup.close();
        }
    }

}
