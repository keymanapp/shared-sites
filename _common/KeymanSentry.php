<?php
  declare(strict_types=1);

  namespace Keyman\Site\Common;

  // Don't use autoloader here because we may be pre-autoloader setup
  require_once __DIR__ . '/KeymanHosts.php';
  require_once __DIR__ . '/Assets.php';

  class KeymanSentry {
    static function init($dsn) {
      \Sentry\init([
        'dsn' => $dsn,
        'environment' => KeymanHosts::Instance()->TierName()
      ]);
    }

    static function GetBrowserHtml($dsn, $release = null) {

      $asset = Assets::Get('js/sentry.js');
      $tier = KeymanHosts::Instance()->TierName();

      if(empty($release)) {
        $release = '';
      } else {
        $release = `release: '$release',`;
      }

      return <<<END
        <script
          src="https://js.sentry-cdn.com/bba22972ad6b4c2ab03a056f549cc23d.min.js"
          crossorigin="anonymous"
        ></script>
        <script
          src="https://browser.sentry-cdn.com/9.1.0/bundle.tracing.min.js"
          integrity="sha384-MCeGoX8VPkitB3OcF9YprViry6xHPhBleDzXdwCqUvHJdrf7g0DjOGvrhIzpsyKp"
          crossorigin="anonymous"
        ></script>
        <script
          src="https://browser.sentry-cdn.com/9.1.0/captureconsole.min.js"
          integrity="sha384-gkHY/HxnL+vrTN/Dn6S9siimRwqogMXpX4AetFSsf6X2LMQFsuXQGvIw7h2qWCt+"
          crossorigin="anonymous"
        ></script>
        <script
          src="https://browser.sentry-cdn.com/9.1.0/httpclient.min.js"
          integrity="sha384-ZsomH91NyAZy+YSYhJcpL3sSDFlkL310CJnpKNqL9KerB92RvfsH9tXRa2youKLM"
          crossorigin="anonymous"
        ></script>
        <script>
          const sentryEnvironment = {
            dsn: '$dsn',
            environment: '$tier',
            $release
          }
        </script>
        <script src="$asset"></script>
  END;
    }
  }