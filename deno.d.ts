/// <reference types="https://esm.sh/@supabase/functions-js/src/edge-runtime.d.ts" />

declare global {
  const Deno: {
    env: {
      get(key: string): string | undefined;
    };
  };
}

export {};
