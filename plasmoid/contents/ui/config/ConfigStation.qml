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
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.kirigami 2.4 as Kirigami
import "../../code/pws-api.js" as API
import "../lib"

Item {
    id: stationConfig

    //vars only for settings 
    property string currentLocale: "en-US";
    property int unitsChoice: 0;
    property var locationsModel: ListModel{
        ListElement {
            address: "-----------"
        }
    }
    property var stationsModel: ListModel{
        ListElement {
            text: "-----------"
        }
    }

    property alias cfg_stationID: stationID.text
    // property alias cfg_longitude: hiddenLongitude.text
    // property alias cfg_latitude: hiddenLatitude.text
    property alias cfg_refreshPeriod: refreshPeriod.value
    property int cfg_locationIntervalRefreshMins: 30
    property int cfg_forecastIntervalRefreshMins: 30

    function printDebug(msg) {
        if (plasmoid.configuration.logConsole) {console.log("[debug] [ConfigStation.qml] " + msg)}
    }

    // Text {
    //     id: hiddenLongitude
    //     text: ""
    //     visible: false
    // }
    // Text {
    //     id: hiddenLatitude
    //     text: ""
    //     visible: false
    // }

    PlasmaComponents.Label {
        id: infoSettings
        anchors {
            horizontalCenter: form.horizontalCenter
        }

        width: parent.width
        wrapMode: Text.Wrap
        text: i18n("Here you can either manually enter the weather station ID from https://www.wunderground.com/wundermap (search for a city that interests you, then on a map click on a location bubble and note down the station ID) or use the lookup tool and dropdowns to discover the weather station.\nYou need to test the station every time you make changes. Some of them may be offline.")
    }
    Kirigami.FormLayout {
        id: form
        anchors {
            top: infoSettings.bottom
            topMargin: 2 * units.smallSpacing
            left: parent.left
            right: parent.right
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Enter Station")
        }

        ClearableField {
            id: stationID

            placeholderText: i18nc("placeholder text alternatively 'example: IFRAUN2'", "e.g. IFRAUN2")

            Kirigami.FormData.label: i18n("Weatherstation ID:")
        }
        Button {
            text: i18n("Test station")
            onClicked: {
                validateWeatherStation(stationID.text, manualStationStatus, function(result, retrunedStationId){
                    locationsModel.clear();
                    stationsModel.clear();
                    cityLookup.text = "";
                    stationStatus.placeholderText = "";
                    stationID.text = retrunedStationId;
                    //API.getStationIdent(stationID.text)

                });
            }
        }
        TextField {
            id: manualStationStatus
            enabled: false

            horizontalAlignment: Text.AlignHCenter
            placeholderText: i18nc("Text shown until a station is chosen from the dropdown", "Pending selection")

            Kirigami.FormData.label: i18nc("Indicates if the station selected is active or not", "Station status:")
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Get Nearest Station")
        }

        ClearableField {
            id: cityLookup
            placeholderText: i18nc("plaseholder text, example London", "e.g. London")

            Kirigami.FormData.label: i18n("Look for location:")
        }
        Button {
            text: i18n("Find Station")
            onClicked: {
                stationID.text = ""
                manualStationStatus.placeholderText = ""
                API.getLocations(cityLookup.text);
                
            }
        }
        ComboBox {
            id: pickerLocation
            editable: false
            model: locationsModel
            textRole: "address"
        
            onCurrentIndexChanged: doOnSelect(currentIndex)
            Kirigami.FormData.label: i18n("Select City:")

            function doOnSelect(currentIndex) {
                stationID.text = ""
                var currentObj = locationsModel.get(currentIndex)
                if(currentObj != null && currentObj["latitude"] != undefined) {
                    console.log(JSON.stringify({lat: currentObj["latitude"], long: currentObj["longitude"]}, null, 2))
                    API.getNearestStationsForConfig({lat: currentObj["latitude"], long: currentObj["longitude"]});
                }
            }
        }
        ComboBox {
            id: pickerStation
            editable: false
            model: stationsModel
            textRole: "text"
        
            onCurrentIndexChanged: doOnSelectStation(currentIndex)
            Kirigami.FormData.label: i18n("Select Station:")

            function doOnSelectStation(currentIndex) {
                var currentObj = stationsModel.get(currentIndex)
                if(currentObj != null && currentObj["stationId"] != undefined) {

                    validateWeatherStation(currentObj["stationId"], stationStatus, function(result){
                        stationID.text = currentObj["stationId"];
                        //API.getStationIdent(stationID.text)
                        manualStationStatus.placeholderText = "";
                    });
                }
            }
        }
        TextField {
            id: stationStatus
            enabled: false

            horizontalAlignment: Text.AlignHCenter
            placeholderText: i18nc("Text shown until a station is chosen from the dropdown", "Pending selection")

            Kirigami.FormData.label: i18nc("Indicates if the station selected is active or not", "Station status:")
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label:  i18n("Options")
        }

        SpinBox {
            id: refreshPeriod

            from: 1
            editable: true

            validator: IntValidator {
                bottom: refreshPeriod.from
            }

            Kirigami.FormData.label: i18n("Current conditions refresh interval (s):")
        }
        ComboBox {
            id: forecastRefresh
            editable: false
            model: [
                {val: 15}, {val: 30}, {val: 60}, {val: 120}
            ]
            textRole: "val"

            Kirigami.FormData.label: i18n("Forecast refresh interval (minutes):")

            onCurrentIndexChanged: cfg_forecastIntervalRefreshMins = model[currentIndex]["val"]

            Component.onCompleted: {
                for (var i = 0; i < model.length; i++) {
                    if (model[i]["val"] == plasmoid.configuration.forecastIntervalRefreshMins) {
                        forecastRefresh.currentIndex = i;
                    }
                }
            }
        }
        ComboBox {
            id: autoLocRefresh
            editable: false
            model: [
                {val: 15}, {val: 30}, {val: 60}, {val: 120}
            ]
            textRole: "val"

            Kirigami.FormData.label: i18n("Location refresh interval (minutes):")

            onCurrentIndexChanged: cfg_locationIntervalRefreshMins = model[currentIndex]["val"]

            Component.onCompleted: {
                for (var i = 0; i < model.length; i++) {
                    if (model[i]["val"] == plasmoid.configuration.locationIntervalRefreshMins) {
                        autoLocRefresh.currentIndex = i;
                    }
                }
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Summary")
        }


    }
    GridLayout {
        id: summary
        columns: 3
        rows: 5

        anchors {
            top: form.bottom
            topMargin: 4 * units.smallSpacing
            horizontalCenter: form.horizontalCenter
        }

        PlasmaComponents.Label {
            Layout.minimumWidth: 150
            horizontalAlignment: Text.AlignHCenter
        }
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
        PlasmaComponents.Label {
            horizontalAlignment: Text.AlignRight
            Layout.minimumWidth: 150
            font.weight: Font.Bold
            text: i18n("Latitude:")
        }
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
        PlasmaComponents.Label {
            horizontalAlignment: Text.AlignRight
            Layout.minimumWidth: 150
            font.weight: Font.Bold
            text: i18n("Longitude")
        }
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
        PlasmaComponents.Label {
            horizontalAlignment: Text.AlignRight
            Layout.minimumWidth: 150
            font.weight: Font.Bold
            text: i18n("Station")
        }
        PlasmaComponents.Label {
            horizontalAlignment: Text.AlignHCenter
            Layout.minimumWidth: 150
            text: plasmoid.configuration.stationID
        }
        PlasmaComponents.Label {
            horizontalAlignment: Text.AlignHCenter
            Layout.minimumWidth: 150
            text:  plasmoid.configuration.isAutoLocation ? plasmoid.configuration.altStationID : plasmoid.configuration.stationID
        }
        PlasmaComponents.Label {
            horizontalAlignment: Text.AlignRight
            Layout.minimumWidth: 150
            font.weight: Font.Bold
            text: i18n("Location")
        }
        PlasmaComponents.Label {
            horizontalAlignment: Text.AlignHCenter
            Layout.minimumWidth: 150
            text: plasmoid.configuration.location
        }
        PlasmaComponents.Label {
            horizontalAlignment: Text.AlignHCenter
            Layout.minimumWidth: 150
            text:  plasmoid.configuration.isAutoLocation ? plasmoid.configuration.altLocation : plasmoid.configuration.location
        }
    }
    PlasmaComponents.Label {
        id: infoLocation
        anchors {
            top: summary.bottom
            topMargin: 4 * units.smallSpacing
            horizontalCenter: form.horizontalCenter
        }

        width: parent.width
        wrapMode: Text.Wrap
        text: i18n("When `I'm travelling`/tracking mode is enabled, the plasmoid will actively track your location and pick the nearest station near you. It does not collect any data about you, however it does use a public service ipinfo.io to obtain your public IP address and approximate location.")
    }

    PlasmaComponents.Label {
        anchors {
            top: infoLocation.bottom
            topMargin: 4 * units.smallSpacing
            horizontalCenter: form.horizontalCenter
        }
        text: "Version 0.7.1"
    }

    PlasmaComponents.Label {
        anchors {
            top: infoLocation.bottom
            topMargin: 4 * units.smallSpacing
            horizontalCenter: form.horizontalCenter
        }
        text: "Version 0.7.1"
    }
    function validateWeatherStation(stationId, placeholderToUpdate, callback){
        
        API.isStationActive(stationId, function(isActive, stationId, fullDetails){

            if(isActive) {
                console.log("field: " + fullDetails.stationID)
                //plasmoid.configuration.stationID = fullDetails.stationID;

                //we need to set it up here, otherwise some weird hack would be required. 
                plasmoid.configuration.latitude = fullDetails.lat;
                plasmoid.configuration.longitude = fullDetails.lon;
                
                API.getStationIdent(fullDetails.stationID, function(location) {
                    plasmoid.configuration.location = location
                });

                // hiddenLatitude.text = fullDetails.lat;
                // hiddenLongitude.text = fullDetails.lon;


                placeholderToUpdate.placeholderText = `${i18n("Station %1 is active and can be used", stationId)}\n ${i18n("Latitude:")} ${fullDetails.lat}, ${i18n("Longitude")}: ${fullDetails.lon}`;
                placeholderToUpdate.placeholderTextColor = "green";

                if(callback) {callback(true, fullDetails.stationID)};
            } else {
                placeholderToUpdate.placeholderText = i18n("Station %1 is NOT active. Please select a different station.", stationId);
                placeholderToUpdate.placeholderTextColor = "red";
                
                if(callback) {callback(false)};
            }
        })
    }

    Component.onCompleted: {
        if(plasmoid.configuration.stationID === "") {
            plasmoid.configuration.latitude = "";
            plasmoid.configuration.longitude = "";
            plasmoid.configuration.location = "";
        }
    }
}
