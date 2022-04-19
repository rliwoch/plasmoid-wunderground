/*
* Copyright 2022 Rafal (Raf) Liwoch
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public License as
* published by the Free Software Foundation; either version 2 of
* the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http: //www.gnu.org/licenses/>.
*/

import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.0
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import "../code/utils.js" as Utils

Item {
    id: bottomPanelRoot
    height: units.iconSizes.small

    property var bottomOpacity: 0.75

    Item {
        id: stationElement
        opacity: bottomOpacity

        anchors {
            left: parent.left
            leftMargin: 2 * units.smallSpacing
            top: parent.top
        }
        
        Item {
            anchors.fill: parent
            
            PlasmaCore.SvgItem {
                id: stationIcon

                width: units.iconSizes.small
                height: width

                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }

                svg: PlasmaCore.Svg {
                    id: stationSvg
                    imagePath: plasmoid.file("", "icons/weather-station-2.svg")
                }
            }

            PlasmaComponents.Label {
                id: stationText

                anchors {
                    left: stationIcon.right
                    leftMargin: 2 * units.smallSpacing
                    verticalCenter: parent.verticalCenter
                }

                font {
                    pointSize: textSize.small
                }
                text: weatherData["stationID"]   
            }
            PlasmaComponents.ToolButton {
                width: units.iconSizes.small
                height: width

                opacity: 0.25

                anchors {
                    left: stationText.right
                    leftMargin: 2 * units.smallSpacing
                    verticalCenter: parent.verticalCenter
                }

                icon.name: "draw-arrow"
                onClicked: Qt.openUrlExternally("https://www.wunderground.com/dashboard/pws/" + weatherData["stationID"]);
            }
        }
        
    }

    Item {
        id: locationElement
        opacity: bottomOpacity

        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
        }

        width: childrenRect.width

        Item {
            anchors.fill: parent

            PlasmaCore.SvgItem {
                id: pinIcon

                width: units.iconSizes.small
                height: width

                anchors {
                    right: locationText.left
                    rightMargin: 2 * units.smallSpacing
                    verticalCenter: parent.verticalCenter
                }

                svg: PlasmaCore.Svg {
                    id: pinSvg
                    imagePath: plasmoid.file("", "icons/pin.svg")
                }
            }

            PlasmaComponents.Label {
                id: locationText

                anchors {
                    //horizontalCenter: parent.horizontalCenter
                    verticalCenter: parent.verticalCenter
                }

                font {
                    pointSize: textSize.small
                }
                text: "Reichenkirchen, DE"

            }
        }
    }

    Item {
        id: altitudeElement
        opacity: bottomOpacity

        anchors {
            right: parent.right
            rightMargin: 2 * units.smallSpacing
            top: parent.top
        }

        Item {
            anchors.fill: parent

            PlasmaCore.SvgItem {
                id: altitudeIcon

                width: units.iconSizes.small
                height: width

                anchors {
                    right: altitudeText.left
                    rightMargin: 2 * units.smallSpacing
                    verticalCenter: parent.verticalCenter
                }

                svg: PlasmaCore.Svg {
                    id: altitudeSvg
                    imagePath: plasmoid.file("", "icons/altitude.svg")
                }
            }

            PlasmaComponents.Label {
                id: altitudeText

                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }

                font {
                    pointSize: textSize.small
                }
                text: Utils.currentElevUnit(weatherData["details"]["elev"])

                //weatherData["stationID"] + "   " +
            }
        }
    }
}
