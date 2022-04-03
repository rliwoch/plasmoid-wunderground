/*
 * Copyright 2021  Kevin Donnelly
 * Copyright 2022  Rafal Liwoch
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
import "../code/utils.js" as Utils
import "../code/pws-api.js" as StationAPI

Item {
    id: root

    property var weatherData: null
    property var currentDetailsModel: ListModel {}
    property var dayInfo: null
    property var singleDayModel: ListModel { }
    property var forecastDetailsModel: ListModel { }
    property var hourlyChartModel: ListModel {
        ListElement {
                date: ""
                time: ""
                iconCode:100
                temperature: 0
                cloudCover: 0
                humidity: 0
                precipitationChance: 0
                precipitationRate: 0
                snowPrecipitationRate: 0
                wind: 0
                golfIndex: 0
                pressure: 0
                uvIndex: 0
            }
        }
    property var dailyChartModel: ListModel {
        ListElement{
                date: ""
                iconCode:100
                temperature: 0
                cloudCover: 0
                humidity: 0
                precipitationChance: 0
                precipitationRate: 0
                snowPrecipitationRate: 0
                wind: 0
                isDay: false
            }
        }
    property var dictVals : ({
        temperature: {
            name: "Temperature",
            code: "temperature",
            icon: "wi-thermometer.svg",
            unit: Utils.currentTempUnit("", false)
        },
        uvIndex: {
            name: "UV Index",
            code: "uvIndex",
            icon: "wi-horizon-alt.svg",
            unit: ""
        },
        pressure: {
            name: "Pressure",
            code: "pressure",
            icon: "wi-barometer.svg",
            unit: Utils.currentPresUnit("", false)
        },
        cloudCover: {
            name: "Cloud Cover",
            code: "cloudCover",
            icon: "wi-cloud.svg",
            unit: "%"
        },
        humidity: {
            name: "Humidity",
            code: "humidity",
            icon: "wi-humidity.svg",
            unit: "%"
        },
        precipitationChance: {
            name: "Precipitation Chance",
            code: "precipitationChance",
            icon: "wi-umbrella.svg",
            unit: "%"
        },
        precipitationRate: {
            name: "Precipitation Rate",
            code: "precipitationRate",
            icon: "wi-rain.svg",
            unit: Utils.currentPrecipUnit("", true, false)
        },
        snowPrecipitationRate: {
            name: "Snow Precipitation Rate",
            code: "snowPrecipitationRate",
            icon: "wi-snow.svg",
            unit: Utils.currentPrecipUnit("", false, false)
        },
        wind: {
            name: "Wind",
            code: "wind",
            icon: "wi-strong-wind.svg",
            unit: Utils.currentSpeedUnit("", false)
        }
    })

    property var textSize: ({
        normal: plasmoid.configuration.propPointSize,
        small: plasmoid.configuration.propPointSize - 1,
        tiny: plasmoid.configuration.propPointSize - 2
    })

    property ListModel forecastModel: ListModel {}
    property string errorStr: ""
    property string toolTipSubText: ""
    property string iconCode: "32" // 32 = sunny
    property string conditionNarrative: ""
    property string narrativeText: ""

    // TODO: add option for showFORECAST and showFORECASTERROR
    property int showCONFIG: 1
    property int showLOADING: 2
    property int showERROR: 4
    property int showDATA: 8

    property int appState: showCONFIG

    // QML does not let you property bind items part of ListModels.
    // The TopPanel shows the high/low values which are items part of forecastModel
    // These are updated in pws-api.js to overcome that limitation
    property int currDayHigh: 0
    property int currDayLow: 0

    property bool showForecast: false

    property string stationID: plasmoid.configuration.stationID
    property int unitsChoice: plasmoid.configuration.unitsChoice

    property bool inTray: false
    // Metric units change based on precipitation type
    property bool isRain: true

    property Component fr: FullRepresentation {
        Layout.minimumWidth: units.gridUnit * 16 *2.6
        Layout.preferredWidth: units.gridUnit * 16 *2.6
        Layout.minimumHeight: units.gridUnit * 12 *2.6
        Layout.preferredHeight: units.gridUnit * 12 *2.6
    }

    property Component cr: CompactRepresentation {
        Layout.minimumWidth: 110
        Layout.preferredWidth: 110
    }

    function printDebug(msg) {
        if (plasmoid.configuration.logConsole) {console.log("[debug] [main.qml] " + msg)}
    }

    function printDebugJSON(json) {
        if (plasmoid.configuration.logConsole) {console.log("[debug] [main.qml] " + JSON.stringify(json))}
    }

    function updateWeatherData() {
        printDebug("Getting new weather data")

        StationAPI.getCurrentData()
        StationAPI.getForecastData("daily", 7);
        StationAPI.getForecastData("hourly", 24);

        updatetoolTipSubText()
    }

    function updateCurrentData() {
        printDebug("Getting new current data")

        StationAPI.getCurrentData()

        updatetoolTipSubText()
    }

    function updateForecastData() {
        printDebug("Getting new forecast data")

        StationAPI.getForecastData("daily", 7);
        StationAPI.getForecastData("hourly", 24);

        updatetoolTipSubText()

        dailyChartModel.sync()
        forecastDetailsModel.sync()
        forecastModel.sync()
    }

    function updatetoolTipSubText() {
        var subText = ""

        subText += i18nc("Do not edit HTML tags. 'Temp' means temperature", "<font size='4'>Temp: %1</font><br />", Utils.currentTempUnit(weatherData["details"]["temp"]))
        subText += i18nc("Do not edit HTML tags.", "<font size='4'>Feels: %1</font><br />", Utils.currentTempUnit(Utils.feelsLike(weatherData["details"]["temp"], weatherData["humidity"], weatherData["details"]["windSpeed"])))
        subText += i18nc("Do not edit HTML tags. 'Wnd Spd' means Wind Speed", "<font size='4'>Wnd spd: %1</font><br />", Utils.currentSpeedUnit(weatherData["details"]["windSpeed"]))
        subText += "<font size='4'>" + weatherData["obsTimeLocal"] + "</font>"

        toolTipSubText = subText;
    }

    onUnitsChoiceChanged: {
        printDebug("Units changed")

        // A user could configure units but not station id. This would trigger improper request.
        if (stationID != "") {
            // Show loading screen after units change
            appState = showLOADING;

            updateWeatherData();
        }
    }

    onStationIDChanged: {
        printDebug("Station ID changed")

        // Show loading screen after ID change
        appState = showLOADING;

        updateWeatherData();
    }

    onWeatherDataChanged: {
        printDebug("Weather data changed")
    }

    onAppStateChanged: {
        printDebug("State is: " + appState)

        // The state could now be an error, the tooltip displays the error
        updatetoolTipSubText()
    }

    Component.onCompleted: {
        inTray = (plasmoid.parent !== null && (plasmoid.parent.pluginName === 'org.kde.plasma.private.systemtray' || plasmoid.parent.objectName === 'taskItemContainer'))

        plasmoid.configurationRequiredReason = i18n("Set the weather station to pull data from.")

        plasmoid.backgroundHints = PlasmaCore.Types.ConfigurableBackground
        //forecastDetailsModel.dynamicRoles = true
    }

    Timer {
        interval: plasmoid.configuration.refreshPeriod * 1000
        running: appState != showCONFIG
        repeat: true
        onTriggered: updateCurrentData()
    }

    Timer {
        interval: 60 * 60 * 1000
        running: appState != showCONFIG
        repeat: true
        onTriggered: updateForecastData()
    }

    Plasmoid.toolTipTextFormat: Text.RichText
    Plasmoid.toolTipMainText: {
        if (appState == showCONFIG) {
            return i18n("Please Configure");
        } else if (appState == showDATA) {
            return stationID;
        } else if (appState == showLOADING) {
            return i18n("Loading...");
        } else if (appState == showERROR) {
            return i18n("Error...");
        }
    }
    Plasmoid.toolTipSubText: toolTipSubText

    // Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation
    Plasmoid.fullRepresentation: fr
    Plasmoid.compactRepresentation: cr

}
