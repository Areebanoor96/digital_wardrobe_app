import {
  CURRENT_WEATHER_ENDPOINT,
  deriveForecastForDate,
  deriveTodayForecast,
  FORECAST_ENDPOINT,
  normalizeWeather,
} from "./normalizer.ts";

Deno.test("current and forecast payloads normalize into weather contract", () => {
  const normalized = normalizeWeather({
    currentPayload: currentWeather(),
    forecastPayload: forecastWeather(),
    latitude: 33.6844,
    longitude: 73.0479,
    fetchedAt: new Date("2026-08-24T07:00:00.000Z"),
  });

  assertEquals(normalized?.temperature, 31);
  assertEquals(normalized?.feels_like, 34);
  assertEquals(normalized?.humidity, 55);
  assertEquals(normalized?.wind_speed, 4.2);
  assertEquals(normalized?.condition, "Clear");
  assertEquals(normalized?.min_temperature, 26);
  assertEquals(normalized?.max_temperature, 36);
  assertEquals(normalized?.rain_probability, 80);
  assertEquals(normalized?.uv_index, null);
  assertEquals(normalized?.has_rain_or_snow, true);
});

Deno.test("forecast derives target local day from timezone offset", () => {
  const result = deriveTodayForecast(
    {
      city: { timezone: 5 * 60 * 60 },
      list: [
        {
          dt: Date.parse("2026-08-24T18:00:00.000Z") / 1000,
          main: { temp: 29, temp_min: 28, temp_max: 30 },
          weather: [{ main: "Clouds" }],
          pop: 0.1,
        },
        {
          dt: Date.parse("2026-08-24T21:00:00.000Z") / 1000,
          main: { temp: 27, temp_min: 26, temp_max: 28 },
          weather: [{ main: "Clouds" }],
          pop: 0.25,
        },
        {
          dt: Date.parse("2026-08-25T06:00:00.000Z") / 1000,
          main: { temp: 34, temp_min: 33, temp_max: 36 },
          weather: [{ main: "Rain" }],
          pop: 0.7,
        },
      ],
    },
    new Date("2026-08-24T20:30:00.000Z"),
  );

  assertEquals(result.minTemperature, 26);
  assertEquals(result.maxTemperature, 36);
  assertEquals(result.rainProbability, 70);
  assertEquals(result.hasRainOrSnow, true);
});

Deno.test("forecast failure degrades to current values", () => {
  const normalized = normalizeWeather({
    currentPayload: currentWeather({
      main: {
        temp: 30,
        feels_like: 32,
        temp_min: 28,
        temp_max: 33,
        humidity: 60,
      },
      weather: [{ main: "Clouds" }],
    }),
    forecastPayload: null,
    latitude: 33.6844,
    longitude: 73.0479,
    fetchedAt: new Date("2026-08-24T07:00:00.000Z"),
  });

  assertEquals(normalized?.min_temperature, 28);
  assertEquals(normalized?.max_temperature, 33);
  assertEquals(normalized?.rain_probability, null);
  assertEquals(normalized?.has_rain_or_snow, false);
});

Deno.test("rain and snow flag excludes clouds and mist", () => {
  const dry = normalizeWeather({
    currentPayload: currentWeather({ weather: [{ main: "Mist" }] }),
    forecastPayload: {
      city: { timezone: 0 },
      list: [
        {
          dt: Date.parse("2026-08-24T09:00:00.000Z") / 1000,
          main: { temp: 30 },
          weather: [{ main: "Clouds" }],
          pop: 0,
        },
      ],
    },
    latitude: 33.6844,
    longitude: 73.0479,
    fetchedAt: new Date("2026-08-24T07:00:00.000Z"),
  });

  const snowy = normalizeWeather({
    currentPayload: currentWeather({
      weather: [{ main: "Clouds" }],
      snow: { "3h": 0.5 },
    }),
    forecastPayload: null,
    latitude: 33.6844,
    longitude: 73.0479,
    fetchedAt: new Date("2026-08-24T07:00:00.000Z"),
  });

  assertEquals(dry?.has_rain_or_snow, false);
  assertEquals(snowy?.has_rain_or_snow, true);
});

Deno.test("malformed current payload is unavailable", () => {
  const normalized = normalizeWeather({
    currentPayload: { weather: [] },
    forecastPayload: forecastWeather(),
    latitude: 33.6844,
    longitude: 73.0479,
  });

  assertEquals(normalized, null);
});

Deno.test("free OpenWeather endpoints use current and forecast APIs", () => {
  assertEquals(
    CURRENT_WEATHER_ENDPOINT,
    "https://api.openweathermap.org/data/2.5/weather",
  );
  assertEquals(
    FORECAST_ENDPOINT,
    "https://api.openweathermap.org/data/2.5/forecast",
  );
});

Deno.test("no target date preserves today's behavior and marks available", () => {
  const normalized = normalizeWeather({
    currentPayload: currentWeather(),
    forecastPayload: forecastWeather(),
    latitude: 33.6844,
    longitude: 73.0479,
    fetchedAt: new Date("2026-08-24T07:00:00.000Z"),
  });

  assertEquals(normalized?.available, true);
  assertEquals(normalized?.temperature, 31);
});

Deno.test("target date extracts that day's forecast entry", () => {
  const normalized = normalizeWeather({
    currentPayload: currentWeather(),
    forecastPayload: forecastWeather(),
    latitude: 33.6844,
    longitude: 73.0479,
    fetchedAt: new Date("2026-08-24T07:00:00.000Z"),
    targetDate: "2026-08-25",
  });

  assertEquals(normalized?.available, true);
  assertEquals(normalized?.min_temperature, 24);
  assertEquals(normalized?.max_temperature, 27);
  assertEquals(normalized?.condition, "Clouds");
  assertEquals(normalized?.rain_probability, 10);
  assertEquals(normalized?.humidity, null);
});

Deno.test("target date with no forecast entries is unavailable", () => {
  const normalized = normalizeWeather({
    currentPayload: currentWeather(),
    forecastPayload: forecastWeather(),
    latitude: 33.6844,
    longitude: 73.0479,
    fetchedAt: new Date("2026-08-24T07:00:00.000Z"),
    targetDate: "2026-09-01",
  });

  assertEquals(normalized?.available, false);
  assertEquals(normalized?.temperature, null);
  assertEquals(normalized?.min_temperature, null);
  assertEquals(normalized?.has_rain_or_snow, false);
});

Deno.test("deriveForecastForDate returns unavailable for empty forecast", () => {
  const result = deriveForecastForDate({
    forecastPayload: { city: { timezone: 0 }, list: [] },
    targetDate: "2026-08-24",
    base: {
      fetched_at: new Date("2026-08-24T07:00:00.000Z").toISOString(),
      latitude: 33.6844,
      longitude: 73.0479,
    },
  });

  assertEquals(result.available, false);
  assertEquals(result.temperature, null);
});

Deno.test("forecast entries with rain flag a rain/snow day", () => {
  const normalized = normalizeWeather({
    currentPayload: currentWeather(),
    forecastPayload: {
      city: { timezone: 0 },
      list: [
        {
          dt: Date.parse("2026-08-25T06:00:00.000Z") / 1000,
          main: { temp: 20, temp_min: 18, temp_max: 22, humidity: 80 },
          weather: [{ main: "Rain" }],
          pop: 0.9,
        },
      ],
    },
    latitude: 33.6844,
    longitude: 73.0479,
    fetchedAt: new Date("2026-08-24T07:00:00.000Z"),
    targetDate: "2026-08-25",
  });

  assertEquals(normalized?.available, true);
  assertEquals(normalized?.has_rain_or_snow, true);
  assertEquals(normalized?.rain_probability, 90);
  assertEquals(normalized?.humidity, 80);
});

function currentWeather(overrides: Record<string, unknown> = {}) {
  return {
    main: {
      temp: 31,
      feels_like: 34,
      temp_min: 29,
      temp_max: 35,
      humidity: 55,
    },
    wind: { speed: 4.2 },
    weather: [{ main: "Clear" }],
    ...overrides,
  };
}

function forecastWeather() {
  return {
    city: { timezone: 5 * 60 * 60 },
    list: [
      {
        dt: Date.parse("2026-08-24T03:00:00.000Z") / 1000,
        main: { temp: 28, temp_min: 26, temp_max: 30 },
        weather: [{ main: "Clouds" }],
        pop: 0.2,
      },
      {
        dt: Date.parse("2026-08-24T09:00:00.000Z") / 1000,
        main: { temp: 35, temp_min: 34, temp_max: 36 },
        weather: [{ main: "Rain" }],
        pop: 0.8,
      },
      {
        dt: Date.parse("2026-08-25T03:00:00.000Z") / 1000,
        main: { temp: 25, temp_min: 24, temp_max: 27 },
        weather: [{ main: "Clouds" }],
        pop: 0.1,
      },
    ],
  };
}

function assertEquals(actual: unknown, expected: unknown) {
  if (actual !== expected) {
    throw new Error(
      `Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`,
    );
  }
}
