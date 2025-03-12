(function initializeSentry() {
  if(!window.Sentry) {
    // Sentry scripts may have been blocked by client browser;
    // we won't be reporting errors to Sentry, but we don't
    // want to throw other errors
    return;
  }

  //
  // Initialize Sentry for this site
  //

  Sentry.init({
    dsn: sentryEnvironment.dsn,
    integrations: [
      Sentry.httpClientIntegration(),
      Sentry.captureConsoleIntegration({
        levels: ['error', 'warning']
      })
    ],
    environment: sentryEnvironment.tier,
  });

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
        console.error(`Failed to load ${type} ${src}: verification attempt succeeded (${result.status}); possibly network instability?`);
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
  console.log(`Sentry initialization complete: tier=${sentryEnvironment.tier}`);
})();
