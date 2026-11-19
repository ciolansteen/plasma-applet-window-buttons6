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
        if (index < 0 || index >= combobox.count)
            return ;

        if (index === 0) {
            if (typeof root !== "undefined") {
                root.useCurrent = true;
                root.selectedPlugin = "";
                root.selectedTheme = "";
            }
            return ;
        }
        var idx = combobox.model.index(index, 0);
        var p = combobox.model.data(idx, Qt.UserRole + 4);
        var t = combobox.model.data(idx, Qt.UserRole + 5);
        if (typeof root !== "undefined") {
            root.useCurrent = false;
            root.selectedPlugin = p;
            root.selectedTheme = t;
        }
    }

    model: decorations
    textRole: "display"
    popup.width: Math.max(combobox.width, popup.implicitWidth)
    popup.height: Math.min(Kirigami.Units.gridUnit * 20, Math.max(popup.implicitHeight, popup.contentHeight))
    popup.onAboutToShow: {
        if (popup.contentItem)
            popup.contentItem.interactive = true;

    }
    onActivated: function(index) {
        selectIndex(index);
    }
    Component.onCompleted: {
        currentIndex = (typeof root !== "undefined" && root.useCurrent) ? 0 : decorations.indexOf(root.selectedPlugin, root.selectedTheme);
    }

    Connections {
        function onUseCurrentChanged() {
            if (root.useCurrent && combobox.currentIndex !== 0)
                combobox.currentIndex = 0;

        }

        target: typeof root !== "undefined" ? root : null
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
