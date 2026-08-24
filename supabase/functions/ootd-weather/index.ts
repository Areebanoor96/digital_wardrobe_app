type WeatherRequest = {
  latitude?: number;
  longitude?: number;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const apiKey = Deno.env.get("OPENWEATHER_API_KEY");
    if (!apiKey) {
      return json({ error: "OPENWEATHER_API_KEY is not configured." }, 500);
    }

    const body = (await req.json()) as WeatherRequest;
    const latitude = Number(body.latitude);
    const longitude = Number(body.longitude);

    if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
      return json({ error: "latitude and longitude are required." }, 400);
    }

    const url = new URL("https://api.openweathermap.org/data/3.0/onecall");
    url.searchParams.set("lat", latitude.toString());
    url.searchParams.set("lon", longitude.toString());
    url.searchParams.set("units", "metric");
    url.searchParams.set("exclude", "minutely,alerts");
    url.searchParams.set("appid", apiKey);

    const response = await fetch(url);
    if (!response.ok) {
      return json(
        { error: "Weather provider request failed.", status: response.status },
        response.status,
      );
    }

    const provider = await response.json();
    const current = provider.current ?? {};
    const today = Array.isArray(provider.daily) ? provider.daily[0] ?? {} : {};
    const weather = Array.isArray(current.weather)
      ? current.weather[0] ?? {}
      : {};

    const normalized = {
      temperature: nullableNumber(current.temp),
      feels_like: nullableNumber(current.feels_like),
      min_temperature: nullableNumber(today.temp?.min),
      max_temperature: nullableNumber(today.temp?.max),
      humidity: nullableNumber(current.humidity),
      rain_probability: nullableNumber(today.pop) == null
        ? null
        : nullableNumber(today.pop)! * 100,
      wind_speed: nullableNumber(current.wind_speed),
      uv_index: nullableNumber(current.uvi),
      condition: typeof weather.main === "string" ? weather.main : null,
      has_rain_or_snow:
        Boolean(current.rain) ||
        Boolean(current.snow) ||
        String(weather.main ?? "").toLowerCase().includes("rain") ||
        String(weather.main ?? "").toLowerCase().includes("snow"),
      fetched_at: new Date().toISOString(),
      latitude,
      longitude,
    };

    return json(normalized);
  } catch (error) {
    return json({ error: String(error) }, 500);
  }
});

function nullableNumber(value: unknown): number | null {
  return typeof value === "number" && Number.isFinite(value) ? value : null;
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}
