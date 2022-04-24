/*
 * Copyright 2022  Rafal (Raf) Liwoch
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
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
import org.kde.plasma.components 2.0 as PlasmaComponents
import "circular-slider"
import "../code/utils.js" as Utils

Item {
    id: detailsRoot

    anchors.centerIn: parent
    height: childrenRect.height

    //CURRENT SUN/MOON
    Item {
        id: topRow
        width: parent.width
        height: mainTempDisplay.height

        Item {
            id: mainTempDisplay

            width: parent.width / 3
            height: childrenRect.height
            
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
            }

            GridLayout {
                id: temperatureCol
                Layout.columnSpan: 2
                columns: 2
                rows: 2

                anchors.centerIn: parent

                PlasmaCore.SvgItem {
                    Layout.rowSpan:2
                    id: temperatureIcon
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                    svg: PlasmaCore.Svg {
                        id: temperatureIconSvg
                        imagePath: plasmoid.file("", Utils.getIconForCodeAndStyle(iconCode, plasmoid.configuration.iconStyleChoice))
                    }

                    Layout.minimumWidth: units.iconSizes.huge
                    Layout.minimumHeight: units.iconSizes.huge
                    Layout.preferredWidth: Layout.minimumWidth
                    Layout.preferredHeight: Layout.minimumHeight
                }
                ColumnLayout {
                    Layout.rowSpan:2
                    PlasmaComponents.Label {
                        id: temp
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                        text: Utils.currentTempUnit(weatherData["details"]["temp"])
                        font {
                            pointSize: plasmoid.configuration.propPointSize * 3
                        }
                        color: Utils.heatColor(weatherData["details"]["temp"])
                    }


                    PlasmaComponents.Label {
                        id: feelsLike
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                        text: i18n("Feels like %1", Utils.currentTempUnit(Math.round(Utils.feelsLike(weatherData["details"]["temp"], weatherData["humidity"], weatherData["details"]["windSpeed"]))))
                        font {
                            weight: Font.Bold
                            pointSize: plasmoid.configuration.propPointSize
                        }
                    }

                    PlasmaComponents.Label {
                        id: currStation
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                        
                        text: conditionNarrative ? conditionNarrative : i18n("Loading...")

                        font {
                            pointSize: plasmoid.configuration.propPointSize
                        }
                    }
                }   
            }
        }
        Item {
            id: sunRiseSetBox
            width: childrenRect.width
            height: childrenRect.height
        
            anchors {
                left: parent.left
                right: mainTempDisplay.left
                verticalCenter: mainTempDisplay.verticalCenter
            }
        
            ColumnLayout {
                id: sunRiseSetCol
                anchors.horizontalCenter: parent.horizontalCenter
        
                RowLayout {
                    width: childrenRect.width
                    height: childrenRect.height
            
                    PlasmaCore.SvgItem {
                        id: sunRiseIcon
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                        svg: PlasmaCore.Svg {
                            id: sunRiseSvg
                            imagePath: plasmoid.file("", "icons/fullRepresentation/wi-sunrise.svg")
                        }
        
                        Layout.minimumWidth: units.iconSizes.smallMedium
                        Layout.minimumHeight: units.iconSizes.smallMedium
                        Layout.preferredWidth: Layout.minimumWidth
                        Layout.preferredHeight: Layout.minimumHeight
                    }
        
                    PlasmaComponents.Label {
                        id: sunRiseData
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                        text: Qt.formatDateTime(dayInfo["sunrise"], plasmoid.configuration.timeFormatChoice)
                        font {
                            pointSize: plasmoid.configuration.propPointSize
                        }
                    }
                }
                RowLayout {
                    width: childrenRect.width
                    height: childrenRect.height
                    PlasmaCore.SvgItem {
                        id: sunSetIcon
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                        svg: PlasmaCore.Svg {
                            id: sunSetSvg
                            imagePath: plasmoid.file("", "icons/fullRepresentation/wi-sunset.svg")
                        }
        
                        Layout.minimumWidth: units.iconSizes.smallMedium
                        Layout.minimumHeight: units.iconSizes.smallMedium
                        Layout.preferredWidth: Layout.minimumWidth
                        Layout.preferredHeight: Layout.minimumHeight
                    }
        
                    PlasmaComponents.Label {
                        id: sunSetData
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                        text: Qt.formatDateTime(dayInfo["sunset"], plasmoid.configuration.timeFormatChoice)
                        font {
                            pointSize: plasmoid.configuration.propPointSize
                        }
                    }
                }
            }
        }        
        Item {

            width: childrenRect.width
            height: childrenRect.height

            anchors {
                right: parent.right
                left: mainTempDisplay.right
                verticalCenter: mainTempDisplay.verticalCenter
            }

            ColumnLayout {
                id: moonRiseSetCol
                anchors.horizontalCenter: parent.horizontalCenter

                RowLayout {
                    width: childrenRect.width
                    height: childrenRect.height
            
                    PlasmaCore.SvgItem {
                        id: moonRiseIcon
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                        svg: PlasmaCore.Svg {
                            id: moonRiseSvg
                            imagePath: plasmoid.file("", "icons/fullRepresentation/wi-moonrise.svg")
                        }

                        Layout.minimumWidth: units.iconSizes.smallMedium
                        Layout.minimumHeight: units.iconSizes.smallMedium
                        Layout.preferredWidth: Layout.minimumWidth
                        Layout.preferredHeight: Layout.minimumHeight
                    }

                    PlasmaComponents.Label {
                        id: moonRiseData
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                        text: Qt.formatDateTime(dayInfo["moonrise"], plasmoid.configuration.timeFormatChoice)
                        font {
                            pointSize: plasmoid.configuration.propPointSize
                        }
                    }
                }
                RowLayout {
                    width: childrenRect.width
                    height: childrenRect.height
                    PlasmaCore.SvgItem {
                        id: moonSetIcon
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                        svg: PlasmaCore.Svg {
                            id: moonSetSvg
                            imagePath: plasmoid.file("", "icons/fullRepresentation/wi-moonset.svg")
                        }

                        Layout.minimumWidth: units.iconSizes.smallMedium
                        Layout.minimumHeight: units.iconSizes.smallMedium
                        Layout.preferredWidth: Layout.minimumWidth
                        Layout.preferredHeight: Layout.minimumHeight
                    }

                    PlasmaComponents.Label {
                        id: moonSetData
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                        text: Qt.formatDateTime(dayInfo["moonset"], plasmoid.configuration.timeFormatChoice)
                        font {
                            pointSize: plasmoid.configuration.propPointSize
                        }
                    }
                }
            }
        }
    }

    //NARRATIVE
    Item {
        id: narrativeTextRow

        width: parent.width
        height: narrative.height

        anchors {
            top: topRow.bottom
            topMargin: 2 * units.gridUnit
            horizontalCenter: parent.horizontalCenter
        }


        PlasmaComponents.Label {
            id: narrative
            text: narrativeText

            anchors.fill: parent
            font {
                pointSize: plasmoid.configuration.propPointSize
            }
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }
    }

    //GRID
    GridView {
        id: dayDetailsView

        width: parent.width
        height: childrenRect.height

        anchors {
            top: narrativeTextRow.bottom
            topMargin: 2 * units.gridUnit
            horizontalCenter: parent.horizontalCenter
        }

        model: currentDetailsModel

        cellWidth: detailsRoot.width / 4
        cellHeight: singleMetricDelegate.height
        
        
        delegate: singleMetricDelegate
    }
    Component {
        id: singleMetricDelegate
          
        ColumnLayout {
            width: detailsRoot.width/4
            
            spacing: 5

            PlasmaCore.SvgItem {
                id: windDirectionIcon
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                svg: PlasmaCore.Svg {
                    id: svg
                    imagePath: getImage(name, val, val2)
                }

                rotation: name === "windDirection" ? val - 270 : 0

                Layout.minimumWidth: units.iconSizes.medium
                Layout.minimumHeight: units.iconSizes.medium
                Layout.preferredWidth: Layout.minimumWidth
                Layout.preferredHeight: Layout.minimumHeight
            }

        
            PlasmaComponents.Label {          
                id: windDirectionLabel1
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                horizontalAlignment: Text.AlignHCenter
                text: dictVals[name].name 
                font {
                    pointSize: textSize.small
                }
            }
            PlasmaComponents.Label {                
                id: windDirectionData
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                Layout.fillWidth: true
                Layout.fillHeight: true            
                horizontalAlignment: Text.AlignHCenter
                text: (val2 !== null ? Utils.getValue(name, val, val2) : Utils.getValue(name, val))
                font {
                    weight: Font.Bold
                    pointSize: plasmoid.configuration.propPointSize
                }
            }

            function getImage(metricName, val, val2)
            {
                if(metricName ==="windDirection") {
                    return plasmoid.file("", "icons/wind-barbs/" + Utils.getWindBarb(val2) + ".svg")
                } else if (metricName === "windSpeed") {
                    return plasmoid.file("", "icons/fullRepresentation/" + dictVals[metricName].icon)
                } else {
                    return plasmoid.file("", "icons/fullRepresentation/" + dictVals[metricName].icon)
                }
            }

        }
    }
}
