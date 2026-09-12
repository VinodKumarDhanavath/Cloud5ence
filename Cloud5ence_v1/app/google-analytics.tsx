"use client";

import { useEffect, useState } from "react";
import Script from "next/script";

/** GA4 is optional and only runs on the public production domain. */
export function GoogleAnalytics({ measurementId }: { measurementId?: string }) {
  const [productionHost, setProductionHost] = useState(false);
  const id = measurementId?.trim();

  useEffect(() => {
    setProductionHost(
      ["cloud5ence.com", "www.cloud5ence.com"].includes(window.location.hostname),
    );
  }, []);

  if (!productionHost || !id || !/^G-[A-Z0-9]+$/.test(id)) return null;

  return (
    <>
      <Script
        id="cloud5ence-ga4-config"
        strategy="afterInteractive"
        dangerouslySetInnerHTML={{
          __html: `window.dataLayer = window.dataLayer || [];
function gtag(){window.dataLayer.push(arguments);}
window.gtag = gtag;
gtag('js', new Date());
gtag('config', '${id}', {
  allow_google_signals: false,
  allow_ad_personalization_signals: false
});`,
        }}
      />
      <Script
        id="cloud5ence-ga4-loader"
        src={`https://www.googletagmanager.com/gtag/js?id=${id}`}
        strategy="afterInteractive"
      />
    </>
  );
}
