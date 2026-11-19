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

    valueRole: "file"
    textRole: "display"
    popup.width: Math.max(combobox.width, popup.implicitWidth)
    popup.height: Math.min(Kirigami.Units.gridUnit * 20, Math.max(popup.implicitHeight, popup.contentHeight))
    popup.onAboutToShow: {
        if (popup.contentItem)
            popup.contentItem.interactive = true;

    }
    onActivated: function(index) {
        if (typeof root !== "undefined" && root.hasOwnProperty("selectedScheme"))
            root.selectedScheme = valueAt(index);

    }

    delegate: ItemDelegate {
        id: itemDelegate

        required property int index
        required property var model

        visible: !(parent && parent.contentItem !== undefined)
        width: ListView.view ? ListView.view.width : (parent ? parent.width : implicitWidth)
        highlighted: combobox.highlightedIndex === index
        onClicked: {
            combobox.currentIndex = index;
            combobox.activated(index);
            combobox.popup.close();
        }

        contentItem: RowLayout {
            spacing: Kirigami.Units.smallSpacing

            Item {
                Layout.preferredWidth: 1.25 * label.height
                Layout.preferredHeight: label.height
                opacity: ((model.file === "kdeglobals") || (model.file === "_plasmatheme_")) ? 0 : 1

                Rectangle {
                    width: height
                    height: 0.75 * label.height
                    color: model.backgroundColor
                    border.width: 1
                    border.color: itemDelegate.highlighted ? itemDelegate.palette.highlightedText : itemDelegate.palette.text

                    Rectangle {
                        anchors.horizontalCenter: parent.right
                        anchors.verticalCenter: parent.bottom
                        width: parent.width
                        height: parent.height
                        color: model.textColor
                        border.width: parent.border.width
                        border.color: parent.border.color
                    }

                }

            }

            Label {
                id: label

                text: model.display
                color: itemDelegate.highlighted ? itemDelegate.palette.highlightedText : itemDelegate.palette.text
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

        }

    }

}
