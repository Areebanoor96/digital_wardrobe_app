import {
  buildOpenWeatherUrl,
  CURRENT_WEATHER_ENDPOINT,
  FORECAST_ENDPOINT,
  normalizeWeather,
} from "./normalizer.ts";

type WeatherRequest = {
  latitude?: number;
  longitude?: number;
  target_date?: string;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const TARGET_DATE_PATTERN = /^\d{4}-\d{2}-\d{2}$/;

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  let body: WeatherRequest;
  try {
    body = (await req.json()) as WeatherRequest;
  } catch (_) {
    return json({ error: "Request body must be valid JSON." }, 400);
  }

  const latitude = Number(body.latitude);
  const longitude = Number(body.longitude);

  if (
    !Number.isFinite(latitude) ||
    !Number.isFinite(longitude) ||
    latitude < -90 ||
    latitude > 90 ||
    longitude < -180 ||
    longitude > 180
  ) {
    return json({ error: "Valid latitude and longitude are required." }, 400);
  }

  const apiKey = Deno.env.get("OPENWEATHER_API_KEY");
  if (!apiKey) {
    return json({ error: "OPENWEATHER_API_KEY is not configured." }, 500);
  }

  const currentUrl = buildOpenWeatherUrl(
    CURRENT_WEATHER_ENDPOINT,
    latitude,
    longitude,
    apiKey,
  );
  const forecastUrl = buildOpenWeatherUrl(
    FORECAST_ENDPOINT,
    latitude,
    longitude,
    apiKey,
  );

  let currentResponse: Response;
  try {
    currentResponse = await fetch(currentUrl);
  } catch (_) {
    return json({ error: "Current weather provider request failed." }, 502);
  }

  if (!currentResponse.ok) {
    return json(
      {
        error: "Current weather provider request failed.",
        status: currentResponse.status,
      },
      currentResponse.status,
    );
  }

  let currentPayload: unknown;
  try {
    currentPayload = await currentResponse.json();
  } catch (_) {
    return json({ error: "Current weather provider payload is malformed." }, 502);
  }

  let forecastPayload: unknown;
  try {
    const forecastResponse = await fetch(forecastUrl);
    if (forecastResponse.ok) {
      forecastPayload = await forecastResponse.json();
    }
  } catch (_) {
    forecastPayload = null;
  }

  const targetDate = typeof body.target_date === "string" ? body.target_date : null;
  if (
    targetDate != null &&
    !TARGET_DATE_PATTERN.test(targetDate)
  ) {
    return json({ error: "target_date must be an ISO date (YYYY-MM-DD)." }, 400);
  }

  const normalized = normalizeWeather({
    currentPayload,
    forecastPayload,
    latitude,
    longitude,
    targetDate,
  });

  if (normalized == null) {
    return json({ error: "Current weather provider payload is malformed." }, 502);
  }

  return json(normalized);
});

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}
