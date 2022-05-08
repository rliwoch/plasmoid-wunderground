/*
 * Copyright 2021-2022  Kevin Donnelly
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

/**
 * Pull the most recent observation from the selected weather station.
 *
 * This handles setting errors and making the loading screen appear.
 */

var modelTemplate = {
	temperature: {
		name: "temperature",
	},
	cloudCover: {
		name: "cloudCover",
	},
	humidity: {
		name: "humidity",
	},
	precipitationChance: {
		name: "precipitationChance",
	},
	precipitationRate: {
		name: "precipitationRate",
	},
	snowPrecipitationRate: {
		name: "snowPrecipitationRate",
	},
	wind: {
		name: "wind",
	},
	num: {
		name: "num"
	}
}
var modelDict = {
	temperature: "temp",
	cloudCover: "clds",
	humidity: "rh",
	precipitationChance: "pop",
	precipitationRate: "qpf",
	snowPrecipitationRate: "snow_qpf",
	wind: "wspd",
	num: "num"
}

function getCurrentUnitsSettings() {
	if (plasmoid.configuration.unitsChoice === 0) {
		return "m";
	} else if (plasmoid.configuration.unitsChoice === 1) {
		return "e";
	} else {
		return "h";
	}
}
function getDefaultParams() {
	return {
		location: null,
		station: !plasmoid.configuration.isAutoLocation ? plasmoid.configuration.stationID : plasmoid.configuration.altStationID,
		lat: !plasmoid.configuration.isAutoLocation ? plasmoid.configuration.latitude : plasmoid.configuration.altLatitude,
		long: !plasmoid.configuration.isAutoLocation ? plasmoid.configuration.longitude : plasmoid.configuration.altLongitude,
		units: getCurrentUnitsSettings(),
		language: currentLocale,
	}
}

function getApiUrlForTypeAndPeriod(type, period, params) {
	var apiKey = "6532d6454b8aa370768e63d6ba5a832e";
	var url;

	var effectiveParams = getDefaultParams();

	if (params !== undefined) {
		printDebug(`Params override exists: ${JSON.stringify(params, null, 2)}`, "api", "getApiUrlForTypeAndPeriod");

		Object.keys(params).forEach((k, i) => {
			printDebug(`Overriding parameter: ${k}`, "api", "getApiUrlForTypeAndPeriod");
			effectiveParams[k] = params[k];
		});
	}

	printDebug(`Effective params used for URL ceation: ${JSON.stringify(effectiveParams, null, 2)}`, "api", "getApiUrlForTypeAndPeriod");

	if (type === "current") {
		url = 'https://api.weather.com/v2/pws/observations/current'
		url += `?stationId=${effectiveParams.station}&format=json&units=${effectiveParams.units}&apiKey=${apiKey}&numericPrecision=decimal`;
	} else if (type === "daily" || type === "hourly") {
		var queryInterval = type === "daily" ? "day" : "hour";
		url = `https://api.weather.com/v1/geocode/${effectiveParams.lat}/${effectiveParams.long}/forecast/${type}/${period}${queryInterval}.json`;
		url += `?apiKey=${apiKey}&language=${effectiveParams.language}&units=${effectiveParams.units}`;
		printDebug(url, "api", "getApiUrlForTypeAndPeriod");
	} else if (type === "station-near") {
		var url = "https://api.weather.com/v3/location/near";
		url += `?geocode=${effectiveParams.lat},${effectiveParams.long}&product=pws&format=json&apiKey=${apiKey}`;
	} else if (type === "current-v3") {
		var url = "https://api.weather.com/v3/wx/observations/current";
		url += `?geocode=${effectiveParams.lat},${effectiveParams.long}&apiKey=${apiKey}&language=${effectiveParams.language}&units=${effectiveParams.units}&format=json`;
	} else if (type === "identity") {
		var url = "https://api.weather.com/v2/pwsidentity";
		url += `?apiKey=${apiKey}&stationId=${effectiveParams.station}&format=json&units=${effectiveParams.units}`
	} else if (type === "location") {
		var url = "https://api.weather.com/v3/location/search"
		url += `?query=${effectiveParams.location}&locationType=city&language=${effectiveParams.language}&format=json&apiKey=${apiKey}`
	} else {
		printDebug(`Sorry, ${type} not recognised.`, "api", "getApiUrlForTypeAndPeriod");
	}

	printDebug(`Constructed URL: ${url}`, "api", "getApiUrlForTypeAndPeriod");

	return url;
}

function getForUrl(url, isAsync, callback) {
	printDebug(`Will be getting URL: ${url}`, "api", "getForUrl", true);

	var req = new XMLHttpRequest();
	req.open("GET", url, isAsync);
	req.setRequestHeader("Accept-Encoding", "gzip");
	req.setRequestHeader("Origin", "https://www.wunderground.com");

	req.onreadystatechange = function () {
		if (req.readyState == 4) {
			if (req.status == 200) {
				//console.log("------------------------>" + req.status);
				printDebug(`200 | ${url}`, "api", "getForUrl");
				var res = JSON.parse(req.responseText);

				//todo enable on tickbox in settings - that's very chatty
				//printDebug(`FULL RESPONSE | ${url}: ${JSON.stringify(res, null, 2)}`, "api", "getForUrl");

				if (callback)
					callback(res, req.status);
			} else if (req.status == 204) {
				//console.log("------------------------>" + req.status);
				printDebug(`NOT 200 | URL ${url} State: ${req.readyState} Status: ${req.status}`, "api", "getForUrl");

				if (callback)
					callback(res, req.status);
			} else {
				//console.log("------------------------>" + req.status);
				//implement retry
				handleError(url, req);
			}
		}
	}
	req.onerror = function () {
		//let's hope for the best and retry
		//printDebug("------------------------> RETRY", "api", "getForUrl");
		//getForUrl(url, isAsync, callback);
	}

	req.send();
}

function handleError(url, req) {
	errorStr = i18n("Request to %1 couldn't be sent %2. Manual refresh might help (top right corner)", url, req.responseText);
	appState = showERROR;

	printDebug(`ERROR: ${errorStr} status: ${req.status}`, "api", "getForUrl", true);
}

function getCurrentData() {
	//for station or for location
	var isRequestForStation = plasmoid.configuration.weatherProviderConfig != 3 

	if(isRequestForStation && !plasmoid.configuration.isAutoLocation) {	
		var url = getApiUrlForTypeAndPeriod("current")
		printDebug(`Getting Current Weather Data for Station ID`, "api", "getCurrentData", true);

		getForUrl(url, true, function (res, status) {
			if (status == 200) {

				flattenResponse(res, function(flatWeatherDataTmp){
					flatWeatherData = flatWeatherDataTmp;

					currentDetailsModel.clear()
					currentDetailsModel.append({ name: "windDirection", val: flatWeatherData["winddir"], val2: flatWeatherData["windSpeed"]});
					currentDetailsModel.append({ name: "wind", val: flatWeatherData["windSpeed"], val2: flatWeatherData["windGust"] });
					currentDetailsModel.append({ name: "dewPoint", val: flatWeatherData["dewpt"] });
					currentDetailsModel.append({ name: "precipitationRate", val: flatWeatherData["precipRate"] });
					currentDetailsModel.append({ name: "pressure", val: flatWeatherData["pressure"] });
					currentDetailsModel.append({ name: "humidity", val: flatWeatherData["humidity"] });
					currentDetailsModel.append({ name: "precipitationAcc", val: flatWeatherData["precipTotal"] });
					currentDetailsModel.append({ name: "uvIndex", val: flatWeatherData["uv"] });

					//getCurrentDataV3();
					appState = showDATA;
					printDebug(`Current Weather Data updated`, "api", "getCurrentData", true);
				});
				

			} else if (status == 204) {
				errorStr = i18n("Station not found or station not active");
				printDebug(`ERROR: ${errorStr}`, "api", "getCurrentData");
			} else {
				//todo
				printDebug(`Current Weather Data update problem`, "api", "getCurrentData", true);
			}
		});
	} else {
		var url = getApiUrlForTypeAndPeriod("current-v3");
		printDebug(`Getting Current Weather Data for Location`, "api", "getCurrentData", true);
		
		getForUrl(url, true, function (res, status) {
			if (status == 200) {

				flatWeatherData = {
					"stationID": "n/a",
					"obsTimeUtc": new Date(res["validTimeLocal"]),
					"obsTimeLocal": new Date(res["validTimeUtc"]),
					//"neighborhood": "n/a",
					//"softwareType": "n/a",
					//"country": "n/a",
					//"solarRadiation": "n/a",
					//"lon": 11.995,
					//"realtimeFrequency": null,
					//"epoch": 1651146095,
					//"lat": 48.379,
					"uv": res["uvIndex"],
					"winddir": res["windDirection"],
					"humidity": res["relativeHumidity"],
					//"qcStatus": 1,
					"temp": res["temperature"],
					"heatIndex": res["temperatureHeatIndex"],
					"dewpt": res["temperatureDewPoint"],
					"windChill": res["temperatureWindChill"],
					"windSpeed": res["windSpeed"],
					"windGust": res["windGust"],
					"pressure": res["pressureAltimeter"],
					"precipRate": res["precip1Hour"],
					"precipTotal": res["precip24Hour"],
					"elev": "n/a",
					"iconCode": res["iconCode"],
					"wxPhraseLong": res["wxPhraseLong"],
					//only new API below
					"windDirCardinal": res["windDirectionCardinal"], 
					"visibility": res["visibility"],
					"tempMax": res["temperatureMax24Hour"],
					"tempMin": res["temperatureMin24Hour"],
					"uvDesc":  res["uvDescription"],
					"pressureTendencyCode": res["pressureTendencyCode"],
					"pressureTendency": res["pressureTendencyTrend"]
				  }
				printDebug(`flatWeatherData is ${JSON.stringify(flatWeatherData)}`, "api", "getCurrentData");
				
				currentDetailsModel.clear()
				currentDetailsModel.append({ name: "windDirection", val: flatWeatherData["winddir"], val2: flatWeatherData["windSpeed"], val3: flatWeatherData["windDirCardinal"]});
				currentDetailsModel.append({ name: "wind", val: flatWeatherData["windSpeed"], val2: flatWeatherData["windGust"] === null ? 0 : flatWeatherData["windGust"] });
				currentDetailsModel.append({ name: "dewPoint", val: flatWeatherData["dewpt"] });
				currentDetailsModel.append({ name: "precipitationRate", val: flatWeatherData["precipRate"] });
				currentDetailsModel.append({ name: "pressure", val: flatWeatherData["pressure"], val2: flatWeatherData["pressureTendencyCode"] });
				currentDetailsModel.append({ name: "humidity", val: flatWeatherData["humidity"] });
				currentDetailsModel.append({ name: "precipitationAcc", val: flatWeatherData["precipTotal"] });
				currentDetailsModel.append({ name: "uvIndex", val: flatWeatherData["uv"], val3: flatWeatherData["uvDesc"] });

				appState = showDATA;
				printDebug(`Current Weather Data updated`, "api", "getCurrentData", true);
			} else if (status == 204) {
				errorStr = i18n("Station not found or station not active");
				printDebug(`ERROR: ${errorStr}`, "api", "getCurrentData");
			} else {
				printDebug(`Current Weather Data update problem`, "api", "getCurrentData", true);
				//todo
			}
		});
	}

}

function flattenResponse(apiResponse, callback) {
	var sectionName = "";

	if (unitsChoice === 0) {
		sectionName = "metric";
	} else if (unitsChoice === 1) {
		sectionName = "imperial";
	} else {
		sectionName = "uk_hybrid";
	}

	var details = apiResponse["observations"][0][sectionName];

	var flatWeatherDataTmp = apiResponse["observations"][0];
	delete flatWeatherDataTmp[sectionName];
	Object.entries(details).forEach(entry => {
		var [key, value] = entry;
		flatWeatherDataTmp[key] = value;
	});
	
	printDebug(JSON.stringify(flatWeatherDataTmp, null, 2), "api", "flattenResponse");

	getCurrentDataV3(function(res){
		printDebug(JSON.stringify("Augmenting flat weather structure", null, 2), "api", "flattenResponse", true);
		flatWeatherDataTmp["iconCode"] = res["iconCode"];
		flatWeatherDataTmp["wxPhraseLong"] = res["wxPhraseLong"];

		//new vals
		flatWeatherDataTmp["visibility"] = res["visibility"];
		flatWeatherDataTmp["tempMax"] = res["temperatureMax24Hour"];
		flatWeatherDataTmp["tempMin"] = res["temperatureMin24Hour"];
		flatWeatherDataTmp["uvDesc"] = res["uvDescription"];
		printDebug(`After augmentation, flatWeatherDataTmp is: ${JSON.stringify(flatWeatherDataTmp, null, 2)}`, "api", "flattenResponse");

		callback(flatWeatherDataTmp);
	});
	
}

function getCurrentDataV3(callback) {
	printDebug(`STARTED`, "api", "getCurrentDataV3");

	var url = getApiUrlForTypeAndPeriod("current-v3");
	printDebug(`URL ${url}`, "api", "getCurrentDataV3");

	getForUrl(url, true, function (res, status) {
		if (status == 200) {
			//iconCode = res["iconCode"];
			//conditionNarrative = res["wxPhraseLong"];
			callback(res);
		}
	});
}

/**
 * Fetch the forecast data and place it in the forecast data model.
 *
 * @todo Incorporate a bitmapped appState field so an error with forecasts
 * doesn't show an error screen for entire widget.
 */
function getForecastData(periodInterval, periodLength) {
	var url = getApiUrlForTypeAndPeriod(periodInterval, periodLength);
	printDebug(`Updating Forecast data`, "api", "getForecastData", true);

	getForUrl(url, true, function (res, status) {
		if (status == 200) {
			var forecasts = res["forecasts"];
			printDebug(`Processing ${periodInterval} forecasts`, "api", "getForecastData", true);

			if (periodInterval === "daily") {
				processDailyForecasts(forecasts)
			} else if (periodInterval === "hourly") {
				createHourlyChartModel(forecasts)
			} else {
				printDebug(`Unrecognised period`, "api", "getForecastData");
			}
		} else {
			errorStr = i18n("Could not fetch forecast data");
			printDebug(`ERROR: ${errorStr}`, "api", "getForecastData");

			appState = showERROR;
		}

	});
}

/**
 * Find the nearest PWS with the choosen coordinates.
 */
function getNearestStations(coord, callback) {
	var url = getApiUrlForTypeAndPeriod("station-near", null, coord);
	printDebug(`URL: ${url}`, "api", "getNearestStations");

	getForUrl(url, true, function (res, status) {
		if (res["location"]["stationId"].length > 0) {
			printDebug(`NEAREST STATIONS: ${res["location"]["stationId"]}`, "api", "getNearestStations");
			if (callback)
				callback(res["location"]);
		} else {
			//todo
		}
	});
}

function getNearestStation(coord, callback) {
	getNearestStations(coord, function (stationsPayload) {

		printDebug(`Stations payload: ${JSON.stringify(stationsPayload, null, 2)}`, "api", "getNearestStation");
		findFirstActiveStation(0, stationsPayload["stationId"], function (isActiveFound, foundId) {
			if (isActiveFound) {
				printDebug(`Active station found: ${isActiveFound}, index: ${foundId}`, "api", "getNearestStation");
				var newStationID = stationsPayload["stationId"][foundId];
				var newLatitude = stationsPayload["latitude"][foundId];
				var newLongitude = stationsPayload["longitude"][foundId];


				printDebug(`Updating alternative location with StationID: ${newStationID} LAT: ${newLatitude} LONG: ${newLongitude}`, "api", "getNearestStation");

				plasmoid.configuration.altStationID = newStationID;
				plasmoid.configuration.altLatitude = newLatitude;
				plasmoid.configuration.altLongitude = newLongitude;

				//currentStationId = newStationID;
				if (callback) {
					printDebug(`CALLING BACK`, "api", "getNearestStation");
					callback(true, newStationID)
				}

			} else {
				errorStr = i18n("No active stations nearby - try selecting a different location in your proximity.");
				printDebug(`ERROR: ${errorStr}`, "api", "getNearestStation");
				appState = showERROR;

				if (callback) { callback(false) }
			}
		});
	});
}

//todo rename
function refreshIPandStation(callback) {
	var url = "https://ipinfo.io/json"
	printDebug(`URL: ${url}`, "api", "refreshIPandStation");

	printDebug("Refreshing public IP and getting location", "api", "refreshIPandStation", true)

	getForUrl(url, true, function (res, status) {
		if (status == 200) {
			printDebug(`Returned body: ${JSON.stringify(res, null, 2)}`, "api", "refreshIPandStation");

			var location = res["loc"].split(",")

			//getNearestStation({ lat: location[0], long: location[1] }, callback);
			plasmoid.configuration.altLatitude = location[0];
			plasmoid.configuration.altLongitude = location[1];
			plasmoid.configuration.altLocation = `${res["city"]}, ${res["region"]}, ${res["country"]}`

			printDebug(`Location established ${res["city"]},${res["country"]}`, "api", "refreshIPandStation", true)
			callback(true);
		} else {
			printDebug("There was an issue in obtaining your location", "api", "refreshIPandStation", true)
			if (callback) { callback(false) };
		}
	});
}

function findFirstActiveStation(id, stationsArr, callback) {
	if (id < stationsArr.length) {
		var url = getApiUrlForTypeAndPeriod("current", null, { station: stationsArr[id] });
		printDebug(`URL: ${url}`, "api", "findFirstActiveStation");

		getForUrl(url, true, function (res, status) {
			printDebug(`Station ${stationsArr[id]} is ${status == 200}`, "api", "findFirstActiveStation");

			if (status == 200) {
				if (callback) { callback(true, id) }
			} else {
				findFirstActiveStation(id + 1, stationsArr, callback);
			}
		});
	} else {
		if (callback) { callback(false, null) }
	}
}

function getStationIdent(tempStationId, callback) {
	printDebug("Getting Station Identification now", "api", "getStationIdent", true)

	var url = getApiUrlForTypeAndPeriod("identity", null, { station: tempStationId });
	printDebug(`URL: ${url}`, "api", "getStationIdent");

	getForUrl(url, true, function (res, status) {
		if (status == 200) {
			if (tempStationId === plasmoid.configuration.stationID) {
				plasmoid.configuration.location = buildLocationText(res)
			} else if (tempStationId === plasmoid.configuration.altStationID) {
				plasmoid.configuration.altLocation = buildLocationText(res)
			} else {
				//just return
				if(callback) {callback(buildLocationText(res))};
			}
		} else {
			//todo
		}
	});
}

function getLocations(cityLookupPhrase, model) {
	printDebug("Getting Locations now", "api", "getLocations", true)

	var url = getApiUrlForTypeAndPeriod("location", null, { location: cityLookupPhrase });
	printDebug(`URL: ${url}`, "api", "getLocation");

	getForUrl(url, true, function (res, status) {
		if (status == 200) {
			var loc = res["location"];
			model.clear();

			loc["address"].forEach((address, index) => {
				model.append({
					address: address,
					adminDistrict: loc["adminDistrict"][index],
					city: loc["city"][index],
					country: loc["country"][index],
					countryCode: loc["countryCode"][index],
					displayName: loc["displayName"][index],
					latitude: loc["latitude"][index],
					longitude: loc["longitude"][index]
				})
			})
			printDebug("Locations have been updated", "api", "getLocations", true)
		}
	});
}


function isStationActive(id, callback) {
	var url = getApiUrlForTypeAndPeriod("current", null, { station: id });
	printDebug(`URL: ${url}`, "api", "isStationActive");

	getForUrl(url, true, function (res, status) {
		printDebug(`Station ${id} is ${status == 200}`, "api", "isStationActive");

		if (callback) {
			if (status == 200) {
				callback(true, id, res["observations"][0])
			} else {
				callback(false, id);
			}
		}
	});
}

function getNearestStationsForConfig(coord, model) {
	printDebug("Finding nearest station now", "api", "getNearestStationsForConfig", true)

	printDebug(`coordinates received: ${coord}`, "api", "getNearestStationsForConfig");
	getNearestStations(coord, function (stationsPayload) {
		model.clear();
		stationsPayload["stationId"].forEach((stationCode, index) => {
			model.append({
				text: stationCode + " - " + stationsPayload["stationName"][index],
				stationName: stationsPayload["stationName"][index],
				stationId: stationCode,
				latitude: stationsPayload["latitude"][index],
				longitude: stationsPayload["longitude"][index]
			})
			printDebug("Nearest station found and added to model", "api", "getNearestStationsForConfig", true)
		});
	})
}
/*-----------------------------------------------------*/


function processDailyForecasts(forecasts) {
	printDebug("------------- PROCESSING DAILY FORECASTS ---------------");
	forecastModel.clear();
	forecastDetailsModel.clear();
	dailyChartModel.clear();

	printDebug("Processing daily forecasts now", "api", "processDailyForecasts", true)

	forecasts.forEach((f,i) => {
		createDailyDetailModel(f)

		var day = f["day"];
		var night = f["night"];
		var hasDay = day !== undefined;
		var timeOfDay = hasDay ? day : night;

		var forecastForDay = new Date(f["fcst_valid_local"]);
		var now = new Date()

		if(forecastForDay.getDate() == now.getDate() && forecastForDay.getMonth() == now.getMonth()) {
			dayInfo = extractGenericInfo(f);
		}

		var temps = prepTemps(f, hasDay);
		if (i == 0) {
			// These are placed seperate from forecastModel since items part of ListModels
			// cannot be property bound
			currentDayName = timeOfDay["long_daypart_name"];
			currDayHigh = temps.max;
			currDayLow = temps.min;
			narrativeText = `${timeOfDay["alt_daypart_name"]}: ${timeOfDay["narrative"]}`
		}
		

		forecastModel.append({
			date: forecastForDay,
			dayPartName: timeOfDay["alt_daypart_name"],
			dayOfWeek: timeOfDay["long_daypart_name"],
			iconCode: timeOfDay["icon_code"],
			narrative: timeOfDay["narrative"],
			high: temps.max,
			low: temps.min,
			//feelsLike: temps.feelsLike,
			shortDesc: timeOfDay["phrase_32char"],
			longDesc: timeOfDay["narrative"],
			winDesc: timeOfDay["wind_phrase"],
			golfDesc: hasDay ? day["golf_category"] : "Don't play golf at night.",
			sunrise: extractTime(f["sunrise"]),
			sunset: extractTime(f["sunset"]),
			fullForecast: f,
		});
	});



	// Hack to update "on hover" details in the Forecast view when plasmoid is first loaded
	singleDayModel.clear()
	singleDayModel.append(Object.values(forecastDetailsModel.get(0)))

	printDebug("Daily forecasts have been processed", "api", "processDailyForecasts", true)

	showForecast = true;
	printDebug("------------- DAILY FORECASTS FINISHED ---------------");
}

function prepTemps(f, hasDay) {
	if(hasDay) {
		return {
			max: f["day"]["temp"],
			min: f["night"]["temp"],
			feelsLike: f["hi"]
		}
	} else {
		return {
			max: f["night"]["hi"],
			min: f["night"]["temp"],
			feelsLike: f["hi"]
		}
	}
}

function extractGenericInfo(forecast) {
	return {
		"sunrise": new Date(forecast["sunrise"]),
		"sunset": new Date(forecast["sunset"]),
		"moonrise": new Date(forecast["moonrise"]),
		"moonset": new Date(forecast["moonset"]),
		"lunarPhaseCode": forecast["lunar_phase_code"],
		"lunarPhaseDay": forecast["lunar_phase_day"],
		"lunarPhase": forecast["lunar_phase"]
	}
}

function extractTime(date) {
	if (!date) {
		return i18nc("not applicable. KEEP SHORT", "n/a");
	}
	var date = new Date(date);

	return Qt.formatDateTime(new Date(date), plasmoid.configuration.timeFormatChoice)
}

function handleMissingData(timeOfDay, dataPoint) {
	return timeOfDay !== undefined ? timeOfDay[dataPoint] : -1000;
}

function createHourlyChartModel(forecasts) {
	printDebug("Processing hourly forecasts now", "api", "createHourlyChartModel", true)
	printDebug("------------- PROCESSING HOURLY FORECASTS ---------------", "api", "createHourlyChartModel");
	hourlyChartModel.clear()

	var forecastsCount = forecasts.length

	forecasts.forEach((period,index) => {
		//limiting the number of results to fit nicely on the chart
		if(!(period.num == 23 || period.num == 24)) {
			var date = new Date(period.fcst_valid_local);
			var hourModel = {
				date: date,
				time: date, //todo remove
				iconCode: period["icon_code"]
			};
			Object.values(modelTemplate).forEach(reading => {
				hourModel[reading.name] = period[modelDict[reading.name]];
			});

			hourModel.golfIndex = period["golf_index"] !== null ? period["golf_index"] : 0;
			hourModel.uvIndex = period["uv_index"];
			hourModel.pressure = period["mslp"];

			printDebug("HOURLY MODEL: " + JSON.stringify(hourModel, null, 2), "api", "createHourlyChartModel");

			hourlyChartModel.append(hourModel);
		}
	});

	printDebug("Hourly forecasts have been processed", "api", "createHourlyChartModel", true)
	printDebug("------------- HOURLY FORECASTS FINISHED ---------------", "api", "createHourlyChartModel");
}

function createDailyDetailModel(forecastElem) {
	var day = forecastElem["day"];
	var night = forecastElem["night"];
	var date = new Date(forecastElem.fcst_valid_local);
	var nightIconCode = night["icon_code"];
	var dayIconCode = day !== undefined ? day["icon_code"] : "wi-na";

	var newModel = {};
	Object.values(modelTemplate).forEach(reading => {
		newModel[reading.name] = reading;
		newModel[reading.name].dayVal = handleMissingData(day, modelDict[reading.name]);
		newModel[reading.name].nightVal = handleMissingData(night, modelDict[reading.name]);
	});

	printDebug("DAILY TEMP MODEL: " + JSON.stringify(newModel, null, 2), "api", "createDailyDetailModel");

	createDailyChartModel(date, newModel, day !== undefined, nightIconCode, dayIconCode);

	//num only needed in creatDailyChartModel
	delete newModel.num

	forecastDetailsModel.append(newModel);

}

function createDailyChartModel(date, forecastDetailsModel, hasDay, nightIconCode, dayIconCode) {
	var day = {
		date: date.setHours(12),
		time: "12:00",
		iconCode: dayIconCode,
		isDay: true
	};
	var night = {
		date: date.setHours(23),
		time: "00:00",
		iconCode: nightIconCode,
		isDay: false
	};

	Object.values(forecastDetailsModel).forEach(condition => {
		if (hasDay) {
			day[condition.name] = condition.dayVal;
		}
		night[condition.name] = condition.nightVal;
	});

	//excluding today's day - as we have a 24h chart for that. Ultimately we need 15 elements for the chart.
	if(hasDay) {
		if(day["num"] != 1) {
			printDebug("DAILY MODEL: " + JSON.stringify(day, null, 2), "api", "createDailyChartModel");
			dailyChartModel.append(day);	
		}
	}
	printDebug("DAILY MODEL: " + JSON.stringify(night, null, 2), "api", "createDailyChartModel");
	dailyChartModel.append(night);
}

function isToday(someDate) {
	const today = new Date()
	return someDate.getDate() == today.getDate() &&
		someDate.getMonth() == today.getMonth() &&
		someDate.getFullYear() == today.getFullYear();
}

function buildLocationText(currentStationDetails) {
	if (currentStationDetails.state.length != 0) {
		return `${currentStationDetails.city}, ${currentStationDetails.state}, ${currentStationDetails.country}`;
	} else {
		return `${currentStationDetails.city}, ${currentStationDetails.country}`;
	}
}
