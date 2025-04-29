(function initializeSentry() {
  if(!window.Sentry) {
    // Sentry scripts may have been blocked by client browser;
    // we won't be reporting errors to Sentry, but we don't
    // want to throw other errors
    return;
  }

  //
  // Tags all exceptions with the active KeymanWeb instance's metadata, if
  // KeymanWeb is loaded. Compare against the definition in the main repo:
  // - keymanapp/keyman/web/src/engine/sentry-manager/src/index.ts
  //
  // In the future we may use sentry-manager directly when it is available.
  //

  const prepareEvent = function(event) {
    // Make sure the metadata-generation function actually exists... (14.0+)
    try {
      if(window.keyman?.getDebugInfo) {
        event.extra = event.extra || {};
        event.extra.keymanState = window.keyman.getDebugInfo();
        event.extra.keymanHostPlatform = window.location.hostname;
      }
    } catch (ex) { /* Swallow any errors produced here */ }

    return event;
  };

  //
  // Initialize Sentry for this site
  //

  const options = {
    beforeSend: prepareEvent,
    dsn: sentryEnvironment.dsn,
    integrations: [
      Sentry.httpClientIntegration(),
      Sentry.captureConsoleIntegration({
        levels: ['error', 'warning']
      })
    ],
    environment: sentryEnvironment.environment,
  };

  if(sentryEnvironment.release) {
    options.release = sentryEnvironment.release;
  }

  Sentry.init(options);

  //
  // Capture resource load errors
  // per https://docs.sentry.io/platforms/javascript/troubleshooting/#capturing-resource-404s
  //

  // In case of failure, try and retrieve the referenced resource again so that
  // we can get more information about the error
  async function verifyTarget(type, src) {
    try {
      const result = await fetch(src);
      if(result.status < 200 || result.status > 399) {
        console.error(`Failed to load ${type} ${src}: HTTP status ${result.status} (${result.statusText})`);
      } else {
        // We'll log this locally but not to Sentry because there's nothing we
        // can do with the result in the majority of cases
        console.log(`Failed to load ${type} ${src}: verification attempt succeeded (${result.status}); possibly network instability?`);
      }
    } catch(e) {
      console.error(`Failed to load ${type} ${src}: error '${(e??'unknown error').toString()}'`);
    }
  }

  window.addEventListener(
    "error",
    (event) => {
      if (!event.target) return;
      if (event.target.tagName === "IMG") {
        verifyTarget('image', event.target.src);
        } else if (event.target.tagName === "LINK" && event.target.rel === "stylesheet") {
        verifyTarget('external stylesheet', event.target.href);
        } else if (event.target.tagName === "SCRIPT") {
        verifyTarget('external script', event.target.src);
      }
    },
    true, // useCapture - necessary for resource loading errors
  );
  console.log(`Sentry initialization complete: environment=${sentryEnvironment.environment}`);
})();
