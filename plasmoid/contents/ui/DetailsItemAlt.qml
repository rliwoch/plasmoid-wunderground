/*
 * Copyright 2021  Kevin Donnelly
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

    property var isDaylight: false;
    property int riseSetIconSize: units.iconSizes.smallMedium * 1.25;
    property var arcSize: Math.round(parent.width/3/2.8)

    Timer {
        id: sunTimer
        running: true
        repeat: true
        interval: 60 * 1000
        
        onTriggered: {
            console.log("Updating SUN")
            dayLength.text = Utils.getDayLength()
            dayLightCaption.text = Utils.remainingUntilSinceDaylight()
            circularSlider.value = Utils.calculateNeedlePosition(dayInfo["sunrise"],dayInfo["sunset"])
        }
    }

    Rectangle {
        anchors {            
            right: parent.right
        }
        color: "red"
        radius: units.smallSpacing
        height: childrenRect.height
        width: childrenRect.width + 2 * units.smallSpacing

        PlasmaComponents.Label {

            anchors.centerIn: parent
            color: "white"
            id: beta
            text: "BETA"
            font {
                pointSize: plasmoid.configuration.propPointSize - 1
                weight: Font.Bold
            }
        }
    }


    Item {
        id: mainTempDisplay

        width: parent.width / 3
        height: childrenRect.height + units.smallSpacing
        
        anchors {
            horizontalCenter: parent.horizontalCenter
            //left: parent.left
            
            top: parent.top
            topMargin: units.gridUnit
            
        }

        Rectangle {
            anchors.fill: parent
            color: PlasmaCore.Theme.complementaryFocusColor
            radius: 5
            opacity: 0.3
        }

        GridLayout {
            id: temperatureCol
            Layout.columnSpan: 2
            columns: 2
            rows: 2

            width: parent.width
            height: childrenRect.height

            anchors.centerIn: parent


            // Layout.fillHeight: true
            // Layout.fillWidth: true

            PlasmaCore.SvgItem {
                Layout.rowSpan:2
                id: temperatureIcon
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                svg: PlasmaCore.Svg {
                    id: temperatureIconSvg
                    imagePath: plasmoid.file("", Utils.getIconForCodeAndStyle(iconCode, plasmoid.configuration.iconStyleChoice))//plasmoid.file("", "icons/fullRepresentation/wi-thermometer.svg")
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

    // Rectangle {
    //     id: verticalLine
    //     anchors {
    //         verticalCenter: mainTempDisplay.verticalCenter
    //     }
    //     width: detailsRoot.width
    //     height: 2
    // }

    Item {
        id: sunRiseSetBox

        anchors {
            left: parent.left
            right: mainTempDisplay.left
            //horizontalCenter: parent.horizontalCenter
            verticalCenter: mainTempDisplay.verticalCenter
            //bottom: mainTempDisplay.bottom
        }

        width: parent.width / 3
        height: sliderBox.height

        Item {
            id: sliderBox

            width: parent.width
            height: circularSlider.height/2 + dayLightCaption.height + dayLength.height

            CircularSlider {
                id: circularSlider

                anchors {                    
                    horizontalCenter: parent.horizontalCenter
                    //verticalCenter: parent.verticalCenter
                    top:dayLightCaption.bottom
                    topMargin: units.smallSpacing
                }

                rotation: 270

                width: arcSize
                height: arcSize

                trackWidth: units.iconSizes.small/8
                progressWidth: 2
                handleWidth: units.iconSizes.small/1.5
                handleHeight: handleWidth
                handleRadius: 10
                handleVerticalOffset: 0

                startAngle: 0
                endAngle: 180
                minValue: 0
                maxValue: 100
                snap: false
                stepSize: 1
                value: Utils.calculateNeedlePosition(dayInfo["sunrise"],dayInfo["sunset"]) 

                handleColor: "yellow"
                trackColor: "grey"
                progressColor: "yellow"//PlasmaCore.Theme.complementaryFocusColor

                hideTrack: false
                hideProgress:!isDaylight

                interactive: isDaylight
            }
            PlasmaComponents.Label { 
                id: dayLightCaption
                
                text: Utils.remainingUntilSinceDaylight()//Utils.getSunIndicatorText()
                
                horizontalAlignment: Text.AlignHCenter

                anchors {
                    top: parent.top
                    //bottomMargin: units.smallSpacing
                    horizontalCenter: parent.horizontalCenter
                }

                font {
                    pointSize: plasmoid.configuration.propPointSize - 1
                }
                
            }
            PlasmaComponents.Label { 
                id: dayLength
                
                text: Utils.getDayLength()
                
                horizontalAlignment: Text.AlignHCenter

                anchors {
                    top: sunriseContainer.bottom
                    //topMargin: units.smallSpacing
                    horizontalCenter: parent.horizontalCenter
                }

                font {
                    pointSize: plasmoid.configuration.propPointSize - 1
                    weight: Font.Bold
                }
                
            }

            Item {
                id: sunriseContainer
                anchors {
                    right: circularSlider.left
                    rightMargin: 2 * units.smallSpacing
                    verticalCenter: parent.verticalCenter
                }
                
                width: childrenRect.width
                height: childrenRect.height

                PlasmaCore.SvgItem {
                    id: sunRiseIcon
                    
                    svg: PlasmaCore.Svg {
                        id: sunRiseSvg
                        imagePath: plasmoid.file("", "icons/fullRepresentation/wi-sunrise.svg")
                    }
    
                    width: riseSetIconSize
                    height: width
    
                    anchors {
                        horizontalCenter: sunriseContainer.horizontalCenter
                        bottom:sunRiseData.top
                    }
                }
    
                PlasmaComponents.Label {
                    id: sunRiseData


                    anchors {
                        right: sunriseContainer.right
                        bottom: sunriseContainer.bottom
                    }
                    text: Qt.formatDateTime(dayInfo["sunrise"], plasmoid.configuration.timeFormatChoice)
                    font {
                        pointSize: plasmoid.configuration.propPointSize - 1
                        weight: Font.Bold
                    }
                }
            }  
            Item {
                id: sunsetContainer
                anchors {
                    left: circularSlider.right
                    leftMargin: 2 * units.smallSpacing
                    verticalCenter: parent.verticalCenter
                }
                
                width: childrenRect.width
                height: childrenRect.height

                PlasmaCore.SvgItem {
                    id: sunSetIcon
                    
                    svg: PlasmaCore.Svg {
                        id: sunSetSvg
                        imagePath: plasmoid.file("", "icons/fullRepresentation/wi-sunset.svg")
                    }
    
                    width: riseSetIconSize
                    height: width
    
                    anchors {
                        horizontalCenter: sunsetContainer.horizontalCenter
                        bottom:sunSetData.top
                    }
                }
    
                PlasmaComponents.Label {
                    id: sunSetData
                    anchors {
                        right: sunsetContainer.right
                        bottom: sunsetContainer.bottom
                    }
                    text: Qt.formatDateTime(dayInfo["sunset"], plasmoid.configuration.timeFormatChoice)
                    font {
                        pointSize: plasmoid.configuration.propPointSize - 1
                        weight: Font.Bold
                    }
                }
            }             
        }

      
    }

    Item {
        id: moonRiseSetBox

        width: parent.width / 3
        height: childrenRect.height

        anchors {
            right: parent.right
            //left: sunRiseSetCol.right
            left: mainTempDisplay.right
            verticalCenter: mainTempDisplay.verticalCenter
        }

        Item {
            id: moonRiseSetCol

            anchors.centerIn: parent

            width: childrenRect.width
            height: childrenRect.height

            Item {
                id: moonriseContainer

                anchors {
                    right: moonIcon.left
                    rightMargin: units.gridUnit
                    verticalCenter: parent.verticalCenter
                    // bottom: moonLabel.top
                    // bottomMargin: 2 * units.smallSpacing
                }
                width: childrenRect.width
                height: childrenRect.height

                PlasmaCore.SvgItem {
                    id: moonRiseIcon
                    
                    svg: PlasmaCore.Svg {
                        id: moonRiseSvg
                        imagePath: plasmoid.file("", "icons/fullRepresentation/wi-moonrise.svg")
                    }
    
                    width: riseSetIconSize
                    height: width
    
                    anchors {
                        horizontalCenter: moonriseContainer.horizontalCenter
                        bottom:moonRiseData.top
                    }
                }
    
                PlasmaComponents.Label {
                    id: moonRiseData
                    anchors {
                        right: moonriseContainer.right
                        bottom: moonriseContainer.bottom
                    }
                    text: Qt.formatDateTime(dayInfo["moonrise"], plasmoid.configuration.timeFormatChoice)
                    font {
                        pointSize: plasmoid.configuration.propPointSize - 1
                        weight: Font.Bold
                    }
                }
            }
            
            PlasmaCore.SvgItem {
                id: moonIcon

                width: Math.round(arcSize/2)
                height: width

                anchors {
                    horizontalCenter: parent.horizontalCenter
                    verticalCenter: parent.verticalCenter
                }

                svg: PlasmaCore.Svg {
                    id: moonSvg
                    imagePath: plasmoid.file("", "icons/fullRepresentation/" + Utils.getMoonPhaseIcon(dayInfo["lunarPhaseCode"]))
                }
            }

            Item {
                id: moonsetContainer
                anchors {
                    left: moonIcon.right
                    leftMargin: units.gridUnit
                    //bottom: moonLabel.top
                    //bottomMargin: 2 * units.smallSpacing
                    verticalCenter: parent.verticalCenter
                }
                
                width: childrenRect.width
                height: childrenRect.height

                PlasmaCore.SvgItem {
                    id: moonSetIcon
                    
                    svg: PlasmaCore.Svg {
                        id: moonSetSvg
                        imagePath: plasmoid.file("", "icons/fullRepresentation/wi-moonset.svg")
                    }
    
                    width: riseSetIconSize
                    height: width
    
                    anchors {
                        horizontalCenter: moonsetContainer.horizontalCenter
                        bottom: moonSetData.top
                    }
                }
    
                PlasmaComponents.Label {
                    id: moonSetData
                    anchors {
                        right: moonsetContainer.right
                        bottom: moonsetContainer.bottom
                    }
                    text: Qt.formatDateTime(dayInfo["moonset"], plasmoid.configuration.timeFormatChoice)
                    font {
                        pointSize: plasmoid.configuration.propPointSize - 1
                        weight: Font.Bold
                    }
                }
            }
            PlasmaComponents.Label {
                id: moonLabel
                 
                Layout.columnSpan: 3
                anchors {
                    //bottom: parent.bottom
                    top: moonriseContainer.bottom
                    //verticalCenter: parent.verticalCenter
                    horizontalCenter: parent.horizontalCenter
                }
                text: dayInfo["lunarPhase"]
                font {
                    weight: Font.Bold
                    pointSize: textSize.small
                }
            }            
        }
    }

    Item{
        id: narrativeTextRow

        width: parent.width
        height: 4 * plasmoid.configuration.propPointSize

        anchors {
            top: mainTempDisplay.bottom
            bottom: dayDetailsView.top
            horizontalCenter: parent.horizontalCenter
        }


        PlasmaComponents.Label {
            id: narrative
            text: isNarrativeForDay ? "<b>" + i18nc("Narrative prefix", "Today:") + "</b> " + narrativeText : "<b>" + i18nc("Narrative prefix", "Tonight:") + "</b> " + narrativeText

            anchors.fill: parent
            font {
                //italic: true
                pointSize: plasmoid.configuration.propPointSize
            }
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap


        }
    }

    GridView {
        //Layout.columnSpan:4
        id: dayDetailsView

        width: parent.width
        height: childrenRect.height

        anchors {
            bottom: parent.bottom
            bottomMargin: units.gridUnit
            horizontalCenter: parent.horizontalCenter
        }

        model: currentDetailsModel

        cellWidth: detailsRoot.width/4
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
