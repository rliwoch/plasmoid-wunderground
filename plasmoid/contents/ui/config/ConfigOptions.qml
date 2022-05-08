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
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.kirigami 2.4 as Kirigami
import "../../code/pws-api.js" as API
import "../lib"

ColumnLayout {
    id: optionsConfig

    //vars only for settings 
    property string currentLocale: "en-US";
    property int unitsChoice: 0;

    property alias cfg_refreshPeriod: refreshPeriod.value
    property int cfg_locationIntervalRefreshMins: 30
    property int cfg_forecastIntervalRefreshMins: 30
    
    Kirigami.FormLayout {
        id: optionsForm
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

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


    }
}
