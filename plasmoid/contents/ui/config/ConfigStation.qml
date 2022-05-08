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
import org.kde.plasma.core 2.0 as PlasmaCore
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.kirigami 2.4 as Kirigami
import "../../code/pws-api.js" as API
import "../../code/utils.js" as Utils
import "../lib"

ColumnLayout {
    id: stationConfig

    //vars only for settings 
    property string currentLocale: "en-US";
    property int unitsChoice: 0;
    property var locationsModel: ListModel{
        ListElement {
            address: "-----------"
        }
    }
    property var locationsForStationsModel: ListModel{
        ListElement {
            address: "-----------"
        }
    }
    property var stationsModel: ListModel{
        ListElement {
            text: "-----------"
        }
    }

    //property alias cfg_stationID: stationID.text
    property bool isForcedReconfigure: false
    
    //1: wunderground ID, 2: guided wunderground ID, 3: location
    //property int cfg_weatherProviderConfig;
    property int configSelection: plasmoid.configuration.weatherProviderConfig
    //property int weatherProviderConfig: plasmoid.configuration.weatherProviderConfig

    function printDebug(msg) {
        if (plasmoid.configuration.logConsole) {console.log("[debug] [ConfigStation.qml] " + msg)}
    }

    function isConfigured() {
        if(isForcedReconfigure) {
            return false;
        } else if((plasmoid.configuration.weatherProviderConfig !=3 && plasmoid.configuration.stationID !== "") || 
        (plasmoid.configuration.weatherProviderConfig == 3 && plasmoid.configuration.location !== "")) {
            return true;
        } else {
            return false;
        }
    }

    Kirigami.InlineMessage {
        id: inlineMessage
        visible: isConfigured()
        Layout.fillWidth: true
        text: i18n("Plugin is configured correctly. If you want to change the configuration, click below.")
        type: Kirigami.MessageType.Positive

        actions: [
			Kirigami.Action {
				enabled: true
				text: i18n("Reconfigure")
				icon.name: "settings"
				onTriggered: {
					isForcedReconfigure = true;
				}
			}
		]
    }

    Kirigami.InlineMessage {
        id: tabInfo
        visible: !isConfigured()
        Layout.fillWidth: true
        text: i18n("Here you can either manually enter the weather station ID from https://www.wunderground.com/wundermap (search for a city that interests you, then on a map click on a location bubble and note down the station ID) or use the lookup tool and dropdowns to discover the weather station.\nYou need to test the station every time you make changes. Some of them may be offline.")
        type: Kirigami.MessageType.Information
    }
    
    Kirigami.FormLayout {
        id: form
        visible: !isConfigured()
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter


        ColumnLayout {
            Layout.rowSpan: 3
            Kirigami.FormData.label: "Use:"
            Kirigami.FormData.buddyFor: wundergroundRadio//firstRadio
            RadioButton {
                id: wundergroundRadio
                checked: configSelection == 1
                text: "Wunderground ID (Manual entry)"

                onCheckedChanged: {
                    configSelection = 1
                    clearAllInput();
                }
            }
            RadioButton {
                id: wundergroundRadioGuided
                checked: configSelection == 2
                text: "Wunderground ID (Guided setup)"

                onCheckedChanged: {
                    configSelection = 2
                    clearAllInput();
                }
            }            
            RadioButton {
                id: locationRadio
                checked: configSelection == 3
                text: "Location"

                onCheckedChanged: {
                    configSelection = 3
                    clearAllInput();
                }
            }
        }

        //--------------------------------------------------------- 1 Start -------------------------------------
        Kirigami.Separator {
            id: separator
            visible: configSelection == 1
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Enter Station")
        }

        ClearableField {
            id: stationID
            visible: configSelection == 1

            placeholderText: i18nc("placeholder text alternatively 'example: IFRAUN2'", "e.g. IFRAUN2")

            Kirigami.FormData.label: i18n("Weatherstation ID:")
            text: plasmoid.configuration.stationID
        }
        Button {
            visible: (configSelection == 1)
            text: i18n("Test station")
            onClicked: {
                validateWeatherStation(stationID.text, function(result, retrunedStationId){                             
                    //stationID.text = retrunedStationId;
                    plasmoid.configuration.weatherProviderConfig = 1
                });
            }
        }
        //--------------------------------------------------------- 2 Start -------------------------------------
        Kirigami.Separator {
            visible: configSelection == 2
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Get Nearest Station")
        }

        ClearableField {
            visible: configSelection == 2
            id: cityLookup
            placeholderText: i18nc("plaseholder text, example London", "e.g. London")

            Kirigami.FormData.label: i18n("Look for location:")
        }
        Button {
            visible: configSelection == 2
            text: i18n("Find Station")
            onClicked: {                
                API.getLocations(cityLookup.text, locationsForStationsModel);
                stationsModel.clear();
                
            }
        }
        ComboBox {
            visible: configSelection == 2
            id: pickerLocation
            editable: false
            model: locationsForStationsModel
            textRole: "address"
        
            onCurrentIndexChanged: doOnSelect(currentIndex)
            Kirigami.FormData.label: i18n("Select City:")

            function doOnSelect(currentIndex) {
                var currentObj = locationsForStationsModel.get(currentIndex)
                if(currentObj != null && currentObj["latitude"] != undefined) {
                    console.log(JSON.stringify({lat: currentObj["latitude"], long: currentObj["longitude"]}, null, 2))
                    API.getNearestStationsForConfig({lat: currentObj["latitude"], long: currentObj["longitude"]}, stationsModel);
                }
            }
        }
        ComboBox {
            visible: configSelection == 2
            id: pickerStation
            editable: false
            model: stationsModel
            textRole: "text"
        
            onCurrentIndexChanged: doOnSelectStation(currentIndex)
            Kirigami.FormData.label: i18n("Select Station:")

            function doOnSelectStation(currentIndex) {
                var currentObj = stationsModel.get(currentIndex)
                if(currentObj != null && currentObj["stationId"] != undefined) {

                    validateWeatherStation(currentObj["stationId"], function(result){
                        //stationID.text = currentObj["stationId"];

                        plasmoid.configuration.weatherProviderConfig = 2
                    });
                }
            }
        }
        //--------------------------------------------------------- 3 Start -------------------------------------
        Kirigami.Separator {
            visible: configSelection == 3
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Find location")
        }

        ClearableField {
            visible: configSelection == 3
            id: locationCityLookup
            placeholderText: i18nc("plaseholder text, example London", "e.g. London")

            Kirigami.FormData.label: i18n("Look for location:")
        }
        Button {
            visible: configSelection == 3
            text: i18n("Find Location")
            onClicked: {
                API.getLocations(locationCityLookup.text, locationsModel);                
            }
        }
        ComboBox {
            visible: configSelection == 3
            id: locationPickerLocation
            editable: false
            model: locationsModel
            textRole: "address"
        
            onCurrentIndexChanged: doOnSelect(currentIndex)
            Kirigami.FormData.label: i18n("Select City:")

            signal locationConfigSignal

            function doOnSelect(currentIndex) {
                
                var currentObj = locationsModel.get(currentIndex)
                if(currentObj != null && currentObj["latitude"] != undefined) {
                    plasmoid.configuration.weatherProviderConfig = 3
                    stationID.text = ""
                    
                    console.log(JSON.stringify(currentObj, null, 2))
                    console.log(JSON.stringify({lat: currentObj["latitude"], long: currentObj["longitude"]}, null, 2))
                    plasmoid.configuration.stationID = "";
                    plasmoid.configuration.latitude = currentObj["latitude"];
                    plasmoid.configuration.longitude = currentObj["longitude"];
                    plasmoid.configuration.location = `${currentObj["displayName"]}, ${currentObj["countryCode"]}`

                    

                    statusMessage.text = i18n("Location %1 activated successfully", currentObj["address"]);
                    statusMessage.type = Kirigami.MessageType.Positive;
                    statusMessage.visible = true;

                    locationPickerLocation.locationConfigSignal();
                    //API.getNearestStationsForConfig({lat: currentObj["latitude"], long: currentObj["longitude"]});
                }
            }
        }

        //--------------------------------------------------------------END ---------------------------------------------------------------------

    }

    Connections {
        target: locationPickerLocation
        function onLocationConfigSignal() { 
            console.log("SIGNAL SIGNAL SIGNAL");
        }
    }
    Kirigami.InlineMessage {
        id: statusMessage
        Layout.fillWidth: true
        text: i18nc("Text shown until a station is chosen from the dropdown", "Pending selection")
    }
    
    Kirigami.FormLayout {
        visible: isConfigured()
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

        RowLayout {
            
            PlasmaComponents.Label {
                Layout.minimumWidth: 150
                horizontalAlignment: Text.AlignHCenter
                font.weight: Font.Bold
                text: i18n("Home Location")
            }
            PlasmaComponents.Label {
                Layout.minimumWidth: 150
                horizontalAlignment: Text.AlignHCenter
                font.weight: Font.Bold
                text: i18n("Currently Used")
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Latitude:")
            PlasmaComponents.Label {
                horizontalAlignment: Text.AlignHCenter
                Layout.minimumWidth: 150
                text: plasmoid.configuration.latitude
            }
            PlasmaComponents.Label {
                horizontalAlignment: Text.AlignHCenter
                Layout.minimumWidth: 150
                text:  plasmoid.configuration.isAutoLocation ? plasmoid.configuration.altLatitude : plasmoid.configuration.latitude
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Longitude")
            PlasmaComponents.Label {
                horizontalAlignment: Text.AlignHCenter
                Layout.minimumWidth: 150
                text: plasmoid.configuration.longitude
            }
            PlasmaComponents.Label {
                horizontalAlignment: Text.AlignHCenter
                Layout.minimumWidth: 150
                text:  plasmoid.configuration.isAutoLocation ? plasmoid.configuration.altLongitude : plasmoid.configuration.longitude
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Station")
            PlasmaComponents.Label {
                horizontalAlignment: Text.AlignHCenter
                Layout.minimumWidth: 150
                text: plasmoid.configuration.weatherProviderConfig != 3 ? plasmoid.configuration.stationID : "---"
            }
            PlasmaComponents.Label {
                horizontalAlignment: Text.AlignHCenter
                Layout.minimumWidth: 150
                text:  plasmoid.configuration.isAutoLocation ? "---" : plasmoid.configuration.stationID
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Location")
            PlasmaComponents.Label {
                horizontalAlignment: Text.AlignHCenter
                Layout.minimumWidth: 150
                elide: Text.ElideRight
                text: plasmoid.configuration.location
            }
            PlasmaComponents.Label {
                horizontalAlignment: Text.AlignHCenter
                Layout.minimumWidth: 150
                elide: Text.ElideRight
                text:  plasmoid.configuration.isAutoLocation ? plasmoid.configuration.altLocation : plasmoid.configuration.location
            }
        }
    }
    Kirigami.InlineMessage {
        id: summaryInfo
        visible: isConfigured()
        Layout.fillWidth: true
        text: i18n("When `I'm travelling`/tracking mode is enabled, the plasmoid will actively track your location and pick the nearest station near you. It does not collect any data about you, however it does use a public service ipinfo.io to obtain your public IP address and approximate location.")
        type: Kirigami.MessageType.Information
    }

    Kirigami.Heading {
        Layout.fillWidth: true
        
        Layout.topMargin: 2 * units.gridUnit
        horizontalAlignment: Text.AlignHCenter
        text: "Version 0.7.0"
        level: 4
    }

    function clearAllInput(){
        //1
        stationID.text = "";
        //2
        cityLookup.text = "";
        locationsForStationsModel.clear();
        stationsModel.clear();
        //3
        locationCityLookup.text = "";
        locationsModel.clear();

        statusMessage.text = ""
        statusMessage.visible = false
    }

    function validateWeatherStation(stationId, callback){
        
        API.isStationActive(stationId, function(isActive, stationId, fullDetails){

            if(isActive) {
                console.log("field: " + fullDetails.stationID)

                //we need to set it up here, otherwise some weird hack would be required. 
                plasmoid.configuration.stationID = fullDetails.stationID;
                plasmoid.configuration.latitude = fullDetails.lat;
                plasmoid.configuration.longitude = fullDetails.lon;
                
                API.getStationIdent(fullDetails.stationID, function(location) {
                    plasmoid.configuration.location = location
                });

                statusMessage.text = `${i18n("Station %1 is active and can be used", stationId)}\n ${i18n("Latitude:")} ${fullDetails.lat}, ${i18n("Longitude")}: ${fullDetails.lon}`;
                statusMessage.type = Kirigami.MessageType.Positive;
                statusMessage.visible = true;
                
                if(callback) {callback(true, fullDetails.stationID)};
            } else {
                statusMessage.text = i18n("Station %1 is NOT active. Please select a different station.", stationId);
                statusMessage.type = Kirigami.MessageType.Error;
                statusMessage.visible = true;
                
                if(callback) {callback(false)};
            }
        })
    }
}
