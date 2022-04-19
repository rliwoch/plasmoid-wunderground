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
	}
}
var modelDict = {
	temperature: "temp",
	cloudCover: "clds",
	humidity: "rh",
	precipitationChance: "pop",
	precipitationRate: "qpf",
	snowPrecipitationRate: "snow_qpf",
	wind: "wspd"
}

//update location
function getLocationDetails() {
	var location = {
		lat: 0,
		long: 0,
		station: ""
	};

	if (!isTraveling) {
		dsLocation = {
			lat: plasmoid.configuration.latitude,
			long: plasmoid.configuration.longitude,
			station: stationID
		}
	} else {
		console.log("getting data from datasource...")
		//get ion
		location.lat = dsLocation.latitude;
		location.long = dsLocation.longitude;
		getNearestStations(location.lat, location.long, function (obtainedStation) {
			location.station = obtainedStation;
			console.log("location object is: " + JSON.stringify(location))
		})



	}
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
		station: plasmoid.configuration.stationID,
		lat: plasmoid.configuration.latitude,
		long: plasmoid.configuration.longitude,
		units: getCurrentUnitsSettings(),
		language: currentLocale,
	}
}

function getApiUrlForTypeAndPeriod(type, period, params) {
	var apiKey = "6532d6454b8aa370768e63d6ba5a832e";
	var url;

	var effectiveParams = getDefaultParams();

	if (params !== undefined) {
		printDebug(`Params override exists: ${JSON.stringify(params)}`, "api", "getApiUrlForTypeAndPeriod");

		Object.keys(params).forEach((k, i) => {
			printDebug(`Overriding parameter: ${k}`, "api", "getApiUrlForTypeAndPeriod");
			effectiveParams[k] = params[k];
		});
	}

	printDebug(`Effective params used for URL ceation: ${JSON.stringify(effectiveParams)}`, "api", "getApiUrlForTypeAndPeriod");

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
	} else {
		printDebug(`Sorry, ${type} not recognised.`, "api", "getApiUrlForTypeAndPeriod");
	}

	printDebug(`Constructed URL: ${url}`, "api", "getApiUrlForTypeAndPeriod");

	return encodeURI(url);
}

function getForUrl(url, isAsync, callback) {
	printDebug(`URL: ${url}`, "api", "getForUrl");

	var req = new XMLHttpRequest();
	req.open("GET", url, isAsync);
	req.setRequestHeader("Accept-Encoding", "gzip");
	req.setRequestHeader("Origin", "https://www.wunderground.com");

	req.onreadystatechange = function () {
		//printDebug(`PERIODIC - STATE: ${req.readyState} for ${url}`, "api", "getForUrl");

		if (req.readyState == 4) {
			if (req.status == 200) {
				console.log("------------------------>" + req.status);
				printDebug(`200 | ${url}`, "api", "getForUrl");
				var res = JSON.parse(req.responseText);

				printDebug(`FULL RESPONSE | ${url}: ${JSON.stringify(res)}`, "api", "getForUrl");

				if (callback)
					callback(res, req.status);
			} else if (req.status == 204) {
				console.log("------------------------>" + req.status);
				printDebug(`NOT 200 | URL ${url} State: ${req.readyState} Status: ${req.status}`, "api", "getForUrl");

				if (callback)
					callback(res, req.status);
				//debug
				//set state to borked
				//retry
			} else {
				console.log("------------------------>" + req.status);
				handleError(url, req);
			}
		}
	}

	req.send();
}

function handleError(url, req) {
	errorStr = `Request to ${url} couldn't be sent ${req.responseText}`;
	appState = showERROR;

	printDebug(`ERROR: ${errorStr} status: ${req.status}`, "api", "getForUrl");
}

function getCurrentData() {
	var url = getApiUrlForTypeAndPeriod("current");
	printDebug(`URL: ${url}`, "api", "getCurrentData");

	//todo add second par to callback
	getForUrl(url, true, function (res, status) {
		if (status == 200) {
			var sectionName = "";

			//todo
			if (unitsChoice === 0) {
				sectionName = "metric";
			} else if (unitsChoice === 1) {
				sectionName = "imperial";
			} else {
				sectionName = "uk_hybrid";
			}

			//TODO
			var tmp = {};
			var tmp = res["observations"][0];

			var details = res["observations"][0][sectionName];

			var flatWeatherDataTmp = res["observations"][0];
			delete flatWeatherDataTmp[sectionName];
			Object.entries(details).forEach(entry => {
				var [key, value] = entry;
				flatWeatherDataTmp[key] = value;
			});
			flatWeatherData = flatWeatherDataTmp;
			printDebug(JSON.stringify(flatWeatherDataTmp));


			tmp["details"] = details;
			weatherData = tmp;

			plasmoid.configuration.latitude = weatherData["lat"];
			plasmoid.configuration.longitude = weatherData["lon"];



			currentDetailsModel.clear()
			currentDetailsModel.append({ name: "windDirection", val: flatWeatherData["winddir"], val2: flatWeatherData["windSpeed"] });
			currentDetailsModel.append({ name: "wind", val: flatWeatherData["windSpeed"], val2: flatWeatherData["windGust"] });
			currentDetailsModel.append({ name: "dewPoint", val: flatWeatherData["dewpt"] });
			currentDetailsModel.append({ name: "precipitationRate", val: flatWeatherData["precipRate"] });
			currentDetailsModel.append({ name: "pressure", val: flatWeatherData["pressure"] });
			currentDetailsModel.append({ name: "humidity", val: flatWeatherData["humidity"] });
			currentDetailsModel.append({ name: "precipitationAcc", val: flatWeatherData["precipTotal"] });
			currentDetailsModel.append({ name: "uvIndex", val: flatWeatherData["uv"] });

			printDebug("Got new current data", "api", "getCurrentData");
			printDebug("Finding Icon...", "api", "getCurrentData");

			getCurrentDataV3();
			appState = showDATA;
		} else if (status == 204) {
			errorStr = "Station not found or station not active";
			printDebug(`ERROR: ${errorStr}`, "api", "getCurrentData");
		} else {
			//todo
		}
	});
}

function getCurrentDataV3() {
	printDebug(`STARTED`, "api", "getCurrentDataV3");

	var url = getApiUrlForTypeAndPeriod("current-v3");
	printDebug(`URL ${url}`, "api", "getCurrentDataV3");

	getForUrl(url, true, function (res, status) {
		if (status == 200) {
			printDebug(`RAW RESPONSE: ${JSON.stringify(res)}`, "api", "getCurrentDataV3");
			iconCode = res["iconCode"];
			conditionNarrative = res["wxPhraseLong"];
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
	printDebug(`[api|getForecastData] URL: ${url}`);

	getForUrl(url, true, function (res, status) {
		if (status == 200) {
			var forecasts = res["forecasts"];
			printDebug(`Processing ${periodInterval} forecasts`, "api", "getForecastData");

			if (periodInterval === "daily") {
				processDailyForecasts(forecasts)
			} else if (periodInterval === "hourly") {
				createHourlyChartModel(forecasts)
			} else {
				printDebug(`Unrecognised period`, "api", "getForecastData");
			}
		} else {
			errorStr = "Could not fetch forecast data";
			printDebug(`ERROR: ${errorStr}`, "api", "getForecastData");

			appState = showERROR;
		}

	});
}

/**
 * Find the nearest PWS with the choosen coordinates.
 */
function getNearestStations(callback) {
	var url = getApiUrlForTypeAndPeriod("station-near");
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

function getNearestStation() {
	getNearestStations(function (stationsPayload) {
		printDebug(`Stations payload: ${JSON.stringify(stationsPayload)}`, "api", "getNearestStation");

		var isStationFound = false;
		var i = 0;
		// while (!isStationFound && i != stationsPayload["stationId"].length) {			
		// 	isStationActive(stationsPayload["stationId"][i], function(stationStatus){				
		// 		printDebug(`Station processed: ${stationsPayload["stationId"][i]}`, "api", "getNearestStation");
		// 		isStationFound = stationStatus;
		// 	});
		// 	printDebug(`Station ${stationsPayload["stationId"][i]} is marked as ${isStationFound}`, "api", "getNearestStation");
		// 	i++;
		// }

	});
}

function recur(isStationFound, currentElement, stationsCount) {
	if(isStationFound || currentElement == stationsCount) {
		return isStationFound;
	} else {
		return recur (isStationFound, currentElement++, stationsCount);
	}
}

//todo rename
function getIpInfo() {
	var url = "https://ipinfo.io/json"
	printDebug(`URL: ${url}`, "api", "getIpInfo");

	getForUrl(url, true, function (res, status) {
		if (status == 200) {
			printDebug(`Returned body: ${JSON.stringify(res)}`, "api", "getIpInfo");

			var location = res["loc"].split(",")
			printDebug(`Updating location with LAT: ${location[0]} LONG: ${location[1]}`, "api", "getIpInfo");
			plasmoid.configuration.latitude = location[0];
			plasmoid.configuration.longitude = location[1];

			getNearestStation();
		} else {
			//todo
		}
	});
}

function isStationActive(stationId, callback) {
	var url = getApiUrlForTypeAndPeriod("current", null, { station: stationId });
	printDebug(`URL: ${url}`, "api", "isStationActive");

	getForUrl(url, false, function (res, status) {
		printDebug(`Station ${stationId} is ${status == 200}`, "api", "isStationActive");
		if(callback) {
			callback(status == 200);
		}
	});
}

/*-----------------------------------------------------*/

function processDailyForecasts(forecasts) {
	printDebug("------------- PROCESSING DAILY FORECASTS ---------------");
	forecastModel.clear();
	forecastDetailsModel.clear();
	dailyChartModel.clear();

	dayInfo = extractGenericInfo(forecasts[0]);

	for (var period = 0; period < forecasts.length; period++) {
		var forecast = forecasts[period];

		createDailyDetailModel(forecast)

		var day = forecast["day"];
		var night = forecast["night"];

		var isDay = day !== undefined;

		var fullDateTime = forecast["fcst_valid_local"];
		var date = parseInt(
			fullDateTime.split("T")[0].split("-")[2]
		);


		if (period == 0) {
			if (!isDay) {
				isNarrativeForDay = false
				narrativeText = night["narrative"];
			} else {
				isNarrativeForDay = true
				narrativeText = day["narrative"];
			}
		}

		var snowDesc = "";
		if (isDay) {
			snowDesc =
				day["snow_phrase"] === ""
					? "No snow"
					: day["snow_phrase"];
		} else {
			snowDesc =
				night["snow_phrase"] === ""
					? "No snow"
					: night["snow_phrase"];
		}

		forecastModel.append({
			date: date,
			dayOfWeek: isDay ? forecast["dow"] : i18n("Tonight"),
			iconCode: isDay ? day["icon_code"] : night["icon_code"],
			high: isDay ? forecast["max_temp"] : night["hi"],
			low: forecast["min_temp"],
			feelsLike: isDay ? day["hi"] : night["hi"],
			shortDesc: isDay
				? day["phrase_32char"]
				: night["phrase_32char"],
			longDesc: isDay ? day["narrative"] : night["narrative"],
			winDesc: isDay
				? day["wind_phrase"]
				: night["wind_phrase"],
			UVDesc: isDay ? day["uv_desc"] : night["uv_desc"],
			snowDesc: snowDesc,
			golfDesc: isDay
				? day["golf_category"]
				: "Don't play golf at night.",
			sunrise: extractTime(forecast["sunrise"], true),
			sunset: extractTime(forecast["sunset"], true),
			fullForecast: forecast,
		});
	}

	// These are placed seperate from forecastModel since items part of ListModels
	// cannot be property bound
	currDayHigh = forecastModel.get(0).high;
	currDayLow = forecastModel.get(0).low;

	// Hack to update "on hover" details in the Forecast view when plasmoid is first loaded
	singleDayModel.clear()
	singleDayModel.append(Object.values(forecastDetailsModel.get(0)))

	printDebug("[pws-api.js] Got new forecast data");

	showForecast = true;
	printDebug("------------- DAILY FORECASTS FINISHED ---------------");
}

function extractGenericInfo(forecast) {
	return {
		"sunrise": extractTime(forecast["sunrise"], true),
		"sunset": extractTime(forecast["sunset"], true),
		"moonrise": extractTime(forecast["moonrise"], true),
		"moonset": extractTime(forecast["moonset"], true),
		"lunarPhaseCode": forecast["lunar_phase_code"],
		"lunarPhase": forecast["lunar_phase"]
	}
}

function extractTime(date, includeSeconds) {
	if (!date) {
		return "n/a";
	}
	var date = new Date(date);

	return Qt.formatDateTime(new Date(date), plasmoid.configuration.timeFormatChoice)
}

function handleMissingData(timeOfDay, dataPoint) {
	return timeOfDay !== undefined ? timeOfDay[dataPoint] : -1000;
}

function createHourlyChartModel(forecasts) {
	printDebug("------------- PROCESSING HOURLY FORECASTS ---------------");
	hourlyChartModel.clear()

	forecasts.forEach(function (period) {
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

		printDebug("HOURLY MODEL: " + JSON.stringify(hourModel));

		hourlyChartModel.append(hourModel);
	});
	printDebug("------------- HOURLY FORECASTS FINISHED ---------------");
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

	printDebug("DAILY TEMP MODEL: " + JSON.stringify(newModel));

	createDailyChartModel(date, newModel, day !== undefined, nightIconCode, dayIconCode);

	forecastDetailsModel.append(newModel);

}

function createDailyChartModel(date, forecastDetailsModel, hasDay, nightIconCode, dayIconCode) {
	var day = {
		date: date,
		time: "12:00",
		iconCode: dayIconCode,
		isDay: true
	};
	var night = {
		date: date,
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

	//excluding today's day - as we have a 24h chart for that
	if (hasDay && !isToday(date)) {
		printDebug("DAILY MODEL: " + JSON.stringify(day));
		dailyChartModel.append(day);
	}
	printDebug("DAILY MODEL: " + JSON.stringify(night));
	dailyChartModel.append(night);
}

function isToday(someDate) {
	const today = new Date()
	return someDate.getDate() == today.getDate() &&
		someDate.getMonth() == today.getMonth() &&
		someDate.getFullYear() == today.getFullYear();
}