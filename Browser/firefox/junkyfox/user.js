/****************************************************************************
 * SECTION: FASTFOX                                                         *
 ****************************************************************************/
/** GENERAL ***/
user_pref('content.notify.interval', 100000); // Keeps UI responsive without overload

/** GFX ***/
user_pref('gfx.canvas.accelerated.cache-items', 2048);
user_pref('gfx.canvas.accelerated.cache-size', 256);
user_pref('image.mem.decode_bytes_at_a_time', 16384);
user_pref('gfx.content.skia-font-cache-size', 20);

/** DISK CACHE ***/
user_pref('browser.cache.jsbc_compression_level', 3);

/** MEDIA CACHE ***/
user_pref('media.memory_cache_max_size', 32768);
user_pref('media.cache_readahead_limit', 7200);
user_pref('media.cache_resume_threshold', 3600);

/** NETWORK ***/
user_pref('network.http.max-connections', 900);
user_pref('network.http.max-persistent-connections-per-server', 6);
user_pref('network.dns.disablePrefetch', false);
user_pref('network.http.max-urgent-start-excessive-connections-per-host', 5);
user_pref('network.http.pacing.requests.enabled', false);
user_pref('network.dnsCacheExpiration', 3600);
user_pref('network.ssl_tokens_cache_capacity', 10240);

/** SPECULATIVE LOADING ***/
user_pref('network.dns.disablePrefetch', true);
user_pref('network.dns.disablePrefetchFromHTTPS', true);
user_pref('network.prefetch-next', false);
user_pref('network.predictor.enabled', false);
user_pref('network.predictor.enable-prefetch', false);

/****************************************************************************
 * SECTION: SECUREFOX                                                       *
 ****************************************************************************/
/** TRACKING PROTECTION ***/
user_pref('browser.contentblocking.category', 'strict');
user_pref(
  'urlclassifier.trackingSkipURLs',
  '*.reddit.com, *.twitter.com, *.twimg.com, *.tiktok.com',
);
user_pref(
  'urlclassifier.features.socialtracking.skipURLs',
  '*.instagram.com, *.twitter.com, *.twimg.com',
);
user_pref('network.cookie.sameSite.noneRequiresSecure', true);
user_pref('privacy.globalprivacycontrol.enabled', true);

/** OCSP & CERTS / HPKP ***/
user_pref('security.OCSP.enabled', 0);
user_pref('security.pki.crlite_mode', 2);

/** SSL / TLS ***/
user_pref('security.ssl.treat_unsafe_negotiation_as_broken', true);

/** DISK AVOIDANCE ***/
user_pref('browser.privatebrowsing.forceMediaMemoryCache', true);
user_pref('browser.sessionstore.interval', 60000);

/** SEARCH / URL BAR ***/
user_pref('browser.urlbar.trimHttps', true);
user_pref('browser.search.separatePrivateDefault.ui.enabled', true);
user_pref('browser.urlbar.update2.engineAliasRefresh', true);
//user_pref("browser.search.suggest.enabled", false);
//user_pref("browser.urlbar.suggest.quicksuggest.sponsored", false);
//user_pref("browser.urlbar.suggest.quicksuggest.nonsponsored", false);
user_pref('security.insecure_connection_text.enabled', true);
user_pref('network.IDN_show_punycode', true);

/** HTTPS-FIRST POLICY ***/
user_pref('dom.security.https_first', true);

/****************************************************************************
 * SECTION: PESKYFOX                                                        *
 ****************************************************************************/
/** MOZILLA UI ***/
user_pref('browser.shell.checkDefaultBrowser', false);
user_pref('browser.aboutwelcome.enabled', false);
user_pref('browser.preferences.moreFromMozilla', false);

/** THEME ADJUSTMENTS ***/
user_pref('toolkit.legacyUserProfileCustomizations.stylesheets', true);
user_pref('layout.css.prefers-color-scheme.content-override', 2);
user_pref('browser.privateWindowSeparation.enabled', false);

/** COOKIE BANNER HANDLING ***/
user_pref('cookiebanners.service.mode', 1);
user_pref('cookiebanners.service.mode.privateBrowsing', 1);

/** FULLSCREEN NOTICE ***/
user_pref('full-screen-api.transition-duration.enter', '0 0');
user_pref('full-screen-api.transition-duration.leave', '0 0');
user_pref('full-screen-api.warning.delay', -1);
user_pref('full-screen-api.warning.timeout', 0);

/** URL BAR ***/
user_pref('browser.urlbar.suggest.calculator', true);
user_pref('browser.urlbar.unitConversion.enabled', true);

/** NEW TAB PAGE ***/
user_pref('browser.newtabpage.activity-stream.showWeather', true);

/** POCKET ***/
user_pref('extensions.pocket.enabled', false);

/** DOWNLOADS ***/
user_pref('browser.download.manager.addToRecentDocs', false);

/** PDF ***/
user_pref('browser.download.open_pdf_attachments_inline', true);

/** TAB BEHAVIOR ***/
user_pref('sidebar.verticalTabs', true);

/****************************************************************************
 * SECTION: PERFORMANCE                                                     *
 ****************************************************************************/
/** TELEMETRY ***/
user_pref('datareporting.policy.dataSubmissionEnabled', false);
user_pref('toolkit.telemetry.enabled', false);
user_pref('toolkit.telemetry.unified', false);
user_pref('toolkit.telemetry.server', '');
user_pref('toolkit.telemetry.archive.enabled', false);
user_pref('browser.newtabpage.activity-stream.feeds.telemetry', false);
user_pref('browser.newtabpage.activity-stream.telemetry', false);

/** EXPERIMENTS ***/
user_pref('app.normandy.enabled', false);
user_pref('app.shield.optoutstudies.enabled', false);

/** CRASH REPORTS ***/
user_pref('breakpad.reportURL', '');
user_pref('browser.tabs.crashReporting.sendReport', false);
