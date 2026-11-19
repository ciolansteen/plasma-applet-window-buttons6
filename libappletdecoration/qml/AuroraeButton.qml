/*
*  SPDX-FileCopyrightText: 2018 Michail Vourlakos <mvourlakos@gmail.com>
*
*  This file is part of the libappletdecoration library
*
*  SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import org.kde.appletdecoration as AppletDecoration
import org.kde.ksvg as KSvg

MouseArea {
    id: button

    property bool isActive: true
    property bool isOnAllDesktops: false
    property bool isKeepAbove: false
    property bool isMaximized: false
    readonly property bool isToggledActivated: {
        return ((isOnAllDesktops && buttonType === AppletDecoration.Types.OnAllDesktops) || (isKeepAbove && buttonType === AppletDecoration.Types.KeepAbove));
    }
    property bool monochromeIconsEnabled: false
    property color monochromeIconsColor: "white"
    property int topPadding: 0
    property int bottomPadding: 0
    property int leftPadding: 0
    property int rightPadding: 0
    property int buttonType: AppletDecoration.Types.Close
    property int duration: auroraeTheme ? auroraeTheme.duration : 0
    property QtObject auroraeTheme: null
    property string buttonImagePath: auroraeTheme ? auroraeTheme.themePath + '/' + auroraeTheme.monochromePrefix + iconName + '.' + auroraeTheme.themeType : ""
    property string iconName: {
        switch (buttonType) {
        case AppletDecoration.Types.Close:
            return "close";
        case AppletDecoration.Types.Minimize:
            return "minimize";
        case AppletDecoration.Types.Maximize:
            return (auroraeTheme.hasRestoreButton && button.isMaximized ? "restore" : "maximize");
        case AppletDecoration.Types.OnAllDesktops:
            return "alldesktops";
        case AppletDecoration.Types.KeepAbove:
            return "keepabove";
        default:
            return "close";
        }
    }
    property string svgNormalElementId: {
        return isActive ? "active-center" : "inactive-center";
    }
    property string svgHoveredElementId: {
        return containsPress || isToggledActivated ? "pressed-center" : "hover-center";
    }

    hoverEnabled: true

    KSvg.Svg {
        id: buttonSvg

        imagePath: buttonImagePath
    }

    // normal icon
    Item {
        id: svgNormalItem

        anchors.fill: parent
        anchors.topMargin: topPadding
        anchors.bottomMargin: bottomPadding
        anchors.leftMargin: leftPadding
        anchors.rightMargin: rightPadding
        opacity: !containsMouse && !containsPress && !isToggledActivated ? 1 : 0

        KSvg.SvgItem {
            readonly property int minimumSide: Math.min(parent.width, parent.height)

            x: (parent.width / 2) - (width / 2)
            y: (parent.height / 2) - (height / 2)
            width: auroraeTheme.buttonRatio * height
            height: minimumSide
            svg: buttonSvg
            elementId: svgNormalElementId
        }

        Behavior on opacity {
            NumberAnimation {
                duration: button.duration
                easing.type: Easing.Linear
            }

        }

    }

    //! monochromize icon
    Loader {
        // sourceComponent:    ColorOverlay {
        //     color: monochromeIconsColor
        //     source: svgNormalItem
        // }

        anchors.fill: svgNormalItem
        active: monochromeIconsEnabled
    }

    // hovered icon
    KSvg.SvgItem {
        id: svgHoveredItem

        anchors.fill: parent
        anchors.topMargin: topPadding
        anchors.bottomMargin: bottomPadding
        anchors.leftMargin: leftPadding
        anchors.rightMargin: rightPadding
        opacity: Math.abs(svgNormalItem.opacity - 1)

        KSvg.SvgItem {
            readonly property int minimumSide: Math.min(parent.width, parent.height)

            x: (parent.width / 2) - (width / 2)
            y: (parent.height / 2) - (height / 2)
            width: auroraeTheme.buttonRatio * height
            height: minimumSide
            svg: buttonSvg
            elementId: svgHoveredElementId
        }

    }

    //! monochromize icon
    Loader {
        // sourceComponent:    ColorOverlay {
        //     color: monochromeIconsColor
        //     source: svgHoveredItem
        // }

        anchors.fill: svgHoveredItem
        active: monochromeIconsEnabled && svgHoveredItem.opacity > 0
    }

}
