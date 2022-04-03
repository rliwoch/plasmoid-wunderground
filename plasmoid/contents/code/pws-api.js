/*
 * Copyright 2021-2022  Kevin Donnelly
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

/**
 * Pull the most recent observation from the selected weather station.
 *
 * This handles setting errors and making the loading screen appear.
 */

var modelTemplate = {
	temperature: {
		name: "temperature",
		icon: "wi-thermometer.svg",
	},
	cloudCover: {
		name: "cloudCover",
		icon: "wi-cloud.svg",
		units: "%"
	},
	humidity: {
		name: "humidity",
		icon: "wi-humidity.svg",
		units: "%"
	},
	precipitationChance: {
		name: "precipitationChance",
		icon: "wi-umbrella.svg",
		units: "%"
	},
	precipitationRate: {
		name: "precipitationRate",
		icon: "wi-rain.svg",
	},
	snowPrecipitationRate: {
		name: "snowPrecipitationRate",
		icon: "wi-snow.svg",
	},
	wind: {
		name: "wind",
		icon: "wi-strong-wind.svg",
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

function weatherAPIUrl(type, period) {
	var apiKey = "6532d6454b8aa370768e63d6ba5a832e";
	var lat = plasmoid.configuration.latitude;
	var long = plasmoid.configuration.longitude;

	var url;
	var units;
	var language = "en-US";

	if (unitsChoice === 0) {
		units = "m";
	} else if (unitsChoice === 1) {
		units = "e";
	} else {
		units = "h";
	}

	if(type === "current") {
		url = 'https://api.weather.com/v2/pws/observations/current'
		url += `?stationId=${stationID}&format=json&units=${units}&apiKey=${apiKey}&numericPrecision=decimal`;
	} else if (type === "daily" || type === "hourly") {
		var queryInterval = type === "daily" ? "day": "hour";
		url = `https://api.weather.com/v1/geocode/${lat}/${long}/forecast/${type}/${period}${queryInterval}.json`;
		url += `?apiKey=${apiKey}&language=${language}&units=${units}`;
		console.log(url);
	} else {
		console.log(`Sorry, ${type} not recognised.`);
	}

	return url;
}

function getCurrentData() {
	var req = new XMLHttpRequest();
	var url = weatherAPIUrl("current");

	printDebug("[pws-api.js] " + url);

	req.open("GET", url);

	req.setRequestHeader("Accept-Encoding", "gzip");
	req.setRequestHeader("Origin", "https://www.wunderground.com");

	req.onerror = function () {
		errorStr = "Request couldn't be sent" + req.statusText;

		appState = showERROR;

		printDebug("[pws-api.js] " + errorStr);
	};

	req.onreadystatechange = function () {
		if (req.readyState == 4) {
			if (req.status == 200) {
				var sectionName = "";

				if (unitsChoice === 0) {
					sectionName = "metric";
				} else if (unitsChoice === 1) {
					sectionName = "imperial";
				} else {
					sectionName = "uk_hybrid";
				}

				var res = JSON.parse(req.responseText);

				var tmp = {};
				var tmp = res["observations"][0];

				var details = res["observations"][0][sectionName];
				tmp["details"] = details;

				weatherData = tmp;

				plasmoid.configuration.latitude = weatherData["lat"];
				plasmoid.configuration.longitude = weatherData["lon"];

				printDebug("[pws-api.js] Got new current data");

				findIconCode();

				appState = showDATA;
			} else {
				if (req.status == 204) {
					errorStr = "Station not found or station not active";

					printDebug("[pws-api.js] " + errorStr);
				} else {
					errorStr = "Request failed: " + req.responseText;

					printDebug("[pws-api.js] " + errorStr);
				}

				appState = showERROR;
			}
		}
	};

	req.send();
}

/**
 * Fetch the forecast data and place it in the forecast data model.
 *
 * @todo Incorporate a bitmapped appState field so an error with forecasts
 * doesn't show an error screen for entire widget.
 */
function getForecastData(periodInterval, periodLength) {
	var req = new XMLHttpRequest();
	var url = weatherAPIUrl(periodInterval, periodLength);

	printDebug("[pws-api.js] " + url);

	req.open("GET", url);

	req.setRequestHeader("Accept-Encoding", "gzip");

	req.onreadystatechange = function () {
		if (req.readyState == 4) {
			if (req.status == 200) {
				var res = JSON.parse(req.responseText);

				var forecasts = res["forecasts"];
				if(periodInterval === "daily") {
					processDailyForecasts(forecasts)
				} else if (periodInterval === "hourly") {
					createHourlyDetailModel(forecasts)
				} else {
					console.log("Unrecognised period");
				}
			} else {
				errorStr = "Could not fetch forecast data";

				printDebug("[pws-api.js] " + errorStr);

				appState = showERROR;
			}
		}
	};

	req.send();
}

function processDailyForecasts(forecasts) {
	forecastModel.clear();
	detailsModel.clear();
	plotModel.clear();

	dayInfo = extractGenericInfo(forecasts[0]);

	for (var period = 0; period < forecasts.length; period++) {
		var forecast = forecasts[period];

		createDetailModel(forecast)

		var day = forecast["day"];
		var night = forecast["night"];

		var isDay = day !== undefined;

		var fullDateTime = forecast["fcst_valid_local"];
		var date = parseInt(
			fullDateTime.split("T")[0].split("-")[2]
		);


		if (period == 0)
		{
			if(!isDay) {
				narrativeText = night["narrative"];
			} else {
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
			dayOfWeek: isDay ? forecast["dow"] : "Tonight",
			iconCode: isDay ? day["icon_code"] : night["icon_code"],
			high: isDay ? forecast["max_temp"] : night["hi"],
			low: forecast["min_temp"],
			feelsLike: isDay ? day["hi"] : night["hi"],
			shortDesc: isDay
			? day["phrase_12char"]
			: night["phrase_12char"],
			longDesc: isDay ? day["narrative"] : night["narrative"],
			thunderDesc: isDay
			? day["thunder_enum_phrase"]
			: night["thunder_enum_phrase"],
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

	printDebug("[pws-api.js] Got new forecast data");

	showForecast = true;
}

function processHourlyForecasts(forecast) {
}
/**
 * Find the nearest PWS with the choosen coordinates.
 */
function getNearestStation() {
	var long = plasmoid.configuration.longitude;
	var lat = plasmoid.configuration.latitude;

	var req = new XMLHttpRequest();

	var url = "https://api.weather.com/v3/location/near";
	url += "?geocode=" + lat + "," + long;
	url += "&product=pws";
	url += "&format=json";
	url += "&apiKey=6532d6454b8aa370768e63d6ba5a832e";

	printDebug("[pws-api.js] " + url);

	req.open("GET", url);

	req.setRequestHeader("Accept-Encoding", "gzip");

	req.onreadystatechange = function () {
		if (req.readyState == 4) {
			if (req.status == 200) {
				var res = JSON.parse(req.responseText);

				var stations = res["location"]["stationId"];
				if (stations.length > 0) {
					var closest = stations[0];
					stationID.text = closest;
				}
			} else {
				printDebug("[pws-api.js] " + req.responseText);
			}
		}
	};

	req.send();
}

function findIconCode() {
	var req = new XMLHttpRequest();

	var long = plasmoid.configuration.longitude;
	var lat = plasmoid.configuration.latitude;

	var url = "https://api.weather.com/v3/wx/observations/current";

	url += "?geocode=" + lat + "," + long;
	url += "&apiKey=6532d6454b8aa370768e63d6ba5a832e";
	url += "&language=en-US";

	if (unitsChoice === 0) {
		url += "&units=m";
	} else if (unitsChoice === 1) {
		url += "&units=e";
	} else {
		url += "&units=h";
	}

	url += "&format=json";

	req.open("GET", url);

	req.setRequestHeader("Accept-Encoding", "gzip");
	req.setRequestHeader("Origin", "https://www.wunderground.com");

	req.onerror = function () {
		printDebug("[pws-api.js] " + req.responseText);
	};

	printDebug("[pws-api.js] " + url);

	req.onreadystatechange = function () {
		if (req.readyState == 4) {
			if (req.status == 200) {
				var res = JSON.parse(req.responseText);

				iconCode = res["iconCode"];
				conditionNarrative = res["wxPhraseLong"];

				// Determine if the precipitation is snow or rain
				// All of these codes are for snow
				if (
					iconCode === 5 ||
					iconCode === 13 ||
					iconCode === 14 ||
					iconCode === 15 ||
					iconCode === 16 ||
					iconCode === 42 ||
					iconCode === 43 ||
					iconCode === 46
				) {
					isRain = false;
				}
			}
		}
	};

	req.send();
}

function extractGenericInfo(forecast) {
	return {
		"sunrise": extractTime(forecast["sunrise"], true),
		"sunset": extractTime(forecast["sunset"], true),
		"moonrise": extractTime(forecast["moonrise"], true),
		"moonset": extractTime(forecast["moonset"], true),
		"lunarPhase": forecast["lunar_phase"]
	}
}

function extractTime(date, includeSeconds) {
	if(!date) {
		return "n/a";
	}
	var date = new Date(date);

	var hhMM = addLeadingZeros(date.getHours()) + ":" + addLeadingZeros(date.getMinutes())

	return  includeSeconds ? hhMM + ":" + addLeadingZeros(date.getSeconds()) : hhMM;
}

function addLeadingZeros(integer) {
	if (integer < 10) {
		return "0" + integer;
	} else {
		return integer;
	}
}

function handleMissingData(timeOfDay, dataPoint) {
	return timeOfDay !== undefined ? timeOfDay[dataPoint] : "n/a";
}

function createHourlyDetailModel(forecasts){
	console.log("------------- PROCESSING HOURLY FORECASTS ---------------");
	hourlyChartModel.clear()

	forecasts.forEach(function (period) {
		var date = new Date(period.fcst_valid_local);
			var hourModel = {
				date: addLeadingZeros(date.getDate()) + "/" + (addLeadingZeros(date.getMonth() + 1)),
				time: date.getHours() +":00",
				iconCode: period["icon_code"]
			};
		Object.values(modelTemplate).forEach(reading => {
			hourModel[reading.name] = period[modelDict[reading.name]];
		});

		hourModel.golfIndex = period["golf_index"] !== null ? period["golf_index"] : 0;
		hourModel.uvIndex = period["uv_index"];
		hourModel.pressure = period["mslp"];

		console.log("HOURLY MODEL: " + JSON.stringify(hourModel));

		hourlyChartModel.append(hourModel);
	});
	console.log("------------- HOURLY FORECASTS FINISHED ---------------");
}

function createDetailModel(forecastElem) {
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

	console.log("NEW MODEL: " + JSON.stringify(newModel));

	// 	var model = {
	// 		temperature: {
	// 			name: "temperature",
	// 			icon: "wi-thermometer.svg",
	// 			dayVal: handleMissingData(day, "temp"),
	// 			nightVal: handleMissingData(night, "temp")
	// 		},
	// 		cloudCover: {
	// 			name: "cloudCover",
	// 			icon: "wi-cloud.svg",
	// 			dayVal: handleMissingData(day, "clds"),
	// 			nightVal: handleMissingData(night, "clds"),
	// 			units: "%"
	// 		},
	// 		humidity: {
	// 			name: "humidity",
	// 			icon: "wi-humidity.svg",
	// 			dayVal: handleMissingData(day, "rh"),
	// 			nightVal: handleMissingData(night, "rh"),
	// 			units: "%"
	// 		},
	// 		precipitationChance: {
	// 			name: "precipitationChance",
	// 			icon: "wi-umbrella.svg",
	// 			dayVal: handleMissingData(day, "pop"),
	// 			nightVal: handleMissingData(night, "pop"),
	// 			units: "%"
	// 		},
	// 		precipitationRate: {
	// 			name: "precipitationRate",
	// 			icon: "wi-rain.svg",
	// 			dayVal: handleMissingData(day, "qpf"),
	// 			nightVal: handleMissingData(night, "qpf")
	// 		},
	// 		snowPrecipitationRate: {
	// 			name: "snowPrecipitationRate",
	// 			icon: "wi-snow.svg",
	// 			dayVal: handleMissingData(day,"snow_qpf"),
	// 			nightVal: handleMissingData(night,"snow_qpf"),
	// 		},
	// 		wind: {
	// 			name: "wind",
	// 			icon: "wi-strong-wind.svg",
	// 			dayVal: handleMissingData(day, "wspd"),
	// 			nightVal: handleMissingData(night, "wspd")
	// 		}
	// 	};

	createPlotModel(date, newModel, day !== undefined, nightIconCode, dayIconCode);

	detailsModel.append(newModel);

}

function createPlotModel(date, detailsModel, hasDay, nightIconCode, dayIconCode) {
	var day = {
		date: addLeadingZeros(date.getDate()) + "/" + (addLeadingZeros(date.getMonth() + 1)),
		time: "12:00",
		iconCode: dayIconCode,
		isDay: true
	};
	var night = {
		date: addLeadingZeros(date.getDate()) + "/" + (addLeadingZeros(date.getMonth() + 1)),
		time: "00:00",
		iconCode: nightIconCode,
		isDay: false
	};

	console.log("Creating plot model");

	Object.values(detailsModel).forEach(condition => {
		if(hasDay) {
			day[condition.name] = condition.dayVal;
		}
		night[condition.name] = condition.nightVal;
	});

	if(hasDay){
		console.log(JSON.stringify(day));
		plotModel.append(day);
	}
	console.log(JSON.stringify(night));
	plotModel.append(night);
}
