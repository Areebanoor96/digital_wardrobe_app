export const CURRENT_WEATHER_ENDPOINT =
  "https://api.openweathermap.org/data/2.5/weather";
export const FORECAST_ENDPOINT =
  "https://api.openweathermap.org/data/2.5/forecast";

type WeatherCondition = {
  main?: unknown;
};

type CurrentWeatherPayload = {
  main?: {
    temp?: unknown;
    feels_like?: unknown;
    temp_min?: unknown;
    temp_max?: unknown;
    humidity?: unknown;
  };
  wind?: {
    speed?: unknown;
  };
  weather?: WeatherCondition[];
  rain?: unknown;
  snow?: unknown;
};

type ForecastEntry = {
  dt?: unknown;
  main?: {
    temp?: unknown;
    temp_min?: unknown;
    temp_max?: unknown;
  };
  weather?: WeatherCondition[];
  pop?: unknown;
  rain?: unknown;
  snow?: unknown;
};

type ForecastPayload = {
  list?: ForecastEntry[];
  city?: {
    timezone?: unknown;
  };
};

export type NormalizedWeather = {
  temperature: number | null;
  feels_like: number | null;
  min_temperature: number | null;
  max_temperature: number | null;
  humidity: number | null;
  rain_probability: number | null;
  wind_speed: number | null;
  uv_index: null;
  condition: string | null;
  has_rain_or_snow: boolean;
  fetched_at: string;
  latitude: number;
  longitude: number;
};

export function buildOpenWeatherUrl(
  endpoint: string,
  latitude: number,
  longitude: number,
  apiKey: string,
): string {
  const url = new URL(endpoint);
  url.searchParams.set("lat", latitude.toString());
  url.searchParams.set("lon", longitude.toString());
  url.searchParams.set("appid", apiKey);
  url.searchParams.set("units", "metric");
  return url.toString();
}

export function normalizeWeather(params: {
  currentPayload: unknown;
  forecastPayload?: unknown;
  latitude: number;
  longitude: number;
  fetchedAt?: Date;
}): NormalizedWeather | null {
  const current = params.currentPayload as CurrentWeatherPayload;
  const currentMain = current?.main;
  if (!currentMain || typeof currentMain !== "object") {
    return null;
  }

  const temperature = nullableNumber(currentMain.temp);
  const feelsLike = nullableNumber(currentMain.feels_like);
  const humidity = nullableNumber(currentMain.humidity);
  const windSpeed = nullableNumber(current.wind?.speed);
  const condition = firstCondition(current.weather);

  if (
    temperature == null &&
    feelsLike == null &&
    humidity == null &&
    windSpeed == null &&
    condition == null
  ) {
    return null;
  }

  const fetchedAt = params.fetchedAt ?? new Date();
  const forecast = deriveTodayForecast(params.forecastPayload, fetchedAt);

  return {
    temperature,
    feels_like: feelsLike,
    min_temperature: forecast.minTemperature ??
      firstNumber(currentMain.temp_min, currentMain.temp),
    max_temperature: forecast.maxTemperature ??
      firstNumber(currentMain.temp_max, currentMain.temp),
    humidity,
    rain_probability: forecast.rainProbability,
    wind_speed: windSpeed,
    uv_index: null,
    condition,
    has_rain_or_snow: isRainOrSnow(current) || forecast.hasRainOrSnow,
    fetched_at: fetchedAt.toISOString(),
    latitude: params.latitude,
    longitude: params.longitude,
  };
}

export function deriveTodayForecast(
  forecastPayload: unknown,
  now: Date = new Date(),
): {
  minTemperature: number | null;
  maxTemperature: number | null;
  rainProbability: number | null;
  hasRainOrSnow: boolean;
} {
  const forecast = forecastPayload as ForecastPayload | undefined;
  const entries = Array.isArray(forecast?.list) ? forecast.list : [];
  const timezoneOffsetSeconds = nullableNumber(forecast?.city?.timezone) ?? 0;
  const todayKey = localDateKey(now.getTime(), timezoneOffsetSeconds);
  const todaysEntries = entries.filter((entry) => {
    const dt = nullableNumber(entry.dt);
    return dt != null && localDateKey(dt * 1000, timezoneOffsetSeconds) ===
      todayKey;
  });

  let minTemperature: number | null = null;
  let maxTemperature: number | null = null;
  let rainProbability: number | null = null;
  let hasRainOrSnow = false;

  for (const entry of todaysEntries) {
    const entryMin = firstNumber(entry.main?.temp_min, entry.main?.temp);
    const entryMax = firstNumber(entry.main?.temp_max, entry.main?.temp);
    const pop = nullableNumber(entry.pop);

    if (entryMin != null) {
      minTemperature = minTemperature == null
        ? entryMin
        : Math.min(minTemperature, entryMin);
    }

    if (entryMax != null) {
      maxTemperature = maxTemperature == null
        ? entryMax
        : Math.max(maxTemperature, entryMax);
    }

    // OOTD uses a 0-100 rain probability scale. Use the day's max 3-hour pop
    // so brief but meaningful rain chances are not averaged away.
    if (pop != null) {
      const percent = pop <= 1 ? pop * 100 : pop;
      rainProbability = rainProbability == null
        ? percent
        : Math.max(rainProbability, percent);
    }

    hasRainOrSnow = hasRainOrSnow || isRainOrSnow(entry);
  }

  return {
    minTemperature,
    maxTemperature,
    rainProbability,
    hasRainOrSnow,
  };
}

function localDateKey(timestampMillis: number, timezoneOffsetSeconds: number) {
  return new Date(timestampMillis + timezoneOffsetSeconds * 1000)
    .toISOString()
    .slice(0, 10);
}

function firstNumber(...values: unknown[]): number | null {
  for (const value of values) {
    const parsed = nullableNumber(value);
    if (parsed != null) {
      return parsed;
    }
  }

  return null;
}

function firstCondition(conditions: unknown): string | null {
  if (!Array.isArray(conditions)) {
    return null;
  }

  const first = conditions[0] as WeatherCondition | undefined;
  return typeof first?.main === "string" ? first.main : null;
}

function isRainOrSnow(value: {
  weather?: WeatherCondition[];
  rain?: unknown;
  snow?: unknown;
}): boolean {
  if (value.rain != null || value.snow != null) {
    return true;
  }

  const condition = firstCondition(value.weather)?.toLowerCase() ?? "";
  return condition === "rain" ||
    condition === "drizzle" ||
    condition === "snow" ||
    condition === "thunderstorm";
}

function nullableNumber(value: unknown): number | null {
  return typeof value === "number" && Number.isFinite(value) ? value : null;
}
