/*
 * Copyright 2021  Kevin Donnelly
 * Copyright 2022 Rafal (Raf) Liwoch
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
import "../code/utils.js" as Utils
import "../code/pws-api.js" as API

Item {
    id: topPanelRoot
    height: todayConditionsElement.height

    property var btnSize: units.iconSizes.medium//Math.round(units.gridUnit * 2)

    Item {
        id: todayConditionsElement
        
        visible: appState == showDATA
        
        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.verticalCenter
        }

        width: childrenRect.width + 4 * units.smallSpacing
        height: childrenRect.height  
        
        Rectangle {
            anchors.fill: parent
            radius: 5
            color: PlasmaCore.Theme.complementaryFocusColor
            opacity: 0.3
        }

        PlasmaComponents.Label {
            id: tempOverview
            anchors.centerIn: parent
            text: showForecast ? currentDayName + " - " + i18n("High: %1 Low: %2", Utils.currentTempUnit(currDayHigh), Utils.currentTempUnit(currDayLow)) : i18n("")
        }
    }

    Item {
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        // "I'm Traveling" Mode
        PlasmaComponents.ToolButton {
            anchors.right: infoBtn.left
            anchors.verticalCenter: parent.verticalCenter
            width: btnSize
            height: width
            checkable: true
            iconSource: "airplane-mode-symbolic"
            checked: plasmoid.configuration.isAutoLocation
            onCheckedChanged: { 
                plasmoid.configuration.isAutoLocation = checked
                if(!checked) {
                    currentStationId = plasmoid.configuration.stationID;
                    API.getStationIdent(API.getDefaultParams().station);
                    updateWeatherData();
                } else {
                    API.refreshIPandStation(function(result, newStationId) {
                        if(result){
                            currentStationId = newStationId;
                            API.getStationIdent(API.getDefaultParams().station);
                            updateWeatherData();
                        }
                    });
                }  

                if(checked == false) {
                    plasmoid.configuration.altLatitude = "";
                    plasmoid.configuration.altLongitude = "";
                    plasmoid.configuration.altStationID = "";
                    plasmoid.configuration.altLocation = "";
                }
            }
            tooltip: i18n("\"I'm travelling\" mode.\n Allows the widget to autodiscover your location based on your public IP address.\n The `Home` station will be ignored when this option is selected.")
        }

        PlasmaComponents.ToolButton {
            visible: false
            id: infoBtn
            anchors.right: refreshBtn.left
            anchors.verticalCenter: parent.verticalCenter
            width: btnSize
            height: width
            checkable: false
            iconSource: "state-information"
            checked: false
            onClicked: {
            }
            tooltip: i18n("Info for nerds")
        }
        PlasmaComponents.ToolButton {
            id: refreshBtn
            anchors.right: stayOnTopBtn.left
            anchors.verticalCenter: parent.verticalCenter
            width: btnSize
            height: width
            checkable: false
            iconSource: "view-refresh"
            onClicked: {
                if(plasmoid.configuration.isAutoLocation) {
                    API.refreshIPandStation(function(result, newStationId) {
                        if(result){
                            API.getStationIdent(API.getDefaultParams().station);
                            currentStationId = newStationId;
                            updateWeatherData();
                        }
                    });
                } else {
                    API.getStationIdent(API.getDefaultParams().station);
                    updateWeatherData();
                }
            }
            tooltip: i18n("Refresh all data")
        }
        // Allows the user to keep the plasmoid open for reference
        PlasmaComponents.ToolButton {
            id: stayOnTopBtn
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: btnSize
            height: width
            checkable: true
            iconSource: "window-pin"
            checked: plasmoid.configuration.pin
            onCheckedChanged: plasmoid.configuration.pin = checked
            tooltip: i18n("Keep Open")
        }

    }

    Binding {
        target: plasmoid
        property: "hideOnWindowDeactivate"
        value: !plasmoid.configuration.pin
    }
}