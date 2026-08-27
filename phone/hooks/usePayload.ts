import { useEffect, useState } from "react";

import { buildPayloadFromConfig, minuteCounter } from "../lib/payload";
import type { AppSettings } from "../lib/settings";

type PayloadState = {
  payload: string | null;
  minuteIndex: number;
  secondsUntilRefresh: number;
  error: string | null;
};

function computeState(settings: AppSettings, nowSeconds: number): PayloadState {
  if (!settings.secretB32.trim()) {
    return {
      payload: null,
      minuteIndex: minuteCounter(nowSeconds),
      secondsUntilRefresh: 60 - (nowSeconds % 60),
      error: null,
    };
  }

  try {
    const payload = buildPayloadFromConfig(
      nowSeconds,
      settings.secretB32,
      settings.memberSuffix,
    );
    return {
      payload,
      minuteIndex: minuteCounter(nowSeconds),
      secondsUntilRefresh: 60 - (nowSeconds % 60),
      error: null,
    };
  } catch (err) {
    return {
      payload: null,
      minuteIndex: minuteCounter(nowSeconds),
      secondsUntilRefresh: 60 - (nowSeconds % 60),
      error: err instanceof Error ? err.message : "Invalid configuration",
    };
  }
}

export function usePayload(settings: AppSettings): PayloadState {
  const [state, setState] = useState<PayloadState>(() =>
    computeState(settings, Math.floor(Date.now() / 1000)),
  );

  useEffect(() => {
    const tick = () => {
      setState(computeState(settings, Math.floor(Date.now() / 1000)));
    };

    tick();
    const timer = setInterval(tick, 1000);
    return () => clearInterval(timer);
  }, [settings.secretB32, settings.memberSuffix]);

  return state;
}
