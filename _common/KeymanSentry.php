<?php
  declare(strict_types=1);

  namespace Keyman\Site\Common;

  // Don't use autoloader here because we may be pre-autoloader setup
  require_once __DIR__ . '/KeymanHosts.php';
  require_once __DIR__ . '/Assets.php';

  if(KeymanHosts::Instance()->Tier() == KeymanHosts::TIER_DEVELOPMENT ||
     KeymanHosts::Instance()->Tier() == KeymanHosts::TIER_TEST) {
    // For testing broken pages, we want to send HTTP 500 so that
    // broken-link-checker will report it; in order to do this we
    // need to cache the page output so that headers are not sent
    // too early
    ob_start();
  }

  class KeymanSentry {
    static function init($dsn) {
      \Sentry\init([
        'dsn' => $dsn,
        'environment' => KeymanHosts::Instance()->TierName(),
        'before_send' => function (\Sentry\Event $event) {
          // Don't send events from localhost or dev environments
          if (KeymanHosts::Instance()->Tier() == KeymanHosts::TIER_DEVELOPMENT ||
              KeymanHosts::Instance()->Tier() == KeymanHosts::TIER_TEST) {
             if(headers_sent()) {
              echo "<p>Fatal error: not setting 500 because headers already sent.</p>";
             } else {
              header("HTTP/1.1 500 Internal Server Error");
             }
            return null;
          }
          return $event;
        },
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

      // Parse out the DSN short string from DSN like:
      // 'https://44d5544d7c45466ba1928b9196faf67e@o1005580.ingest.sentry.io/5983516'
      // (this one was for keyman.com)
      if(!preg_match('/\/\/(.+)@/', $dsn, $matches)) {
        // invalid sentry DSN, so just don't load Sentry on client
        return '';
      }
      $dsn_id = $matches[1];

      return <<<END
        <script
          src="https://js.sentry-cdn.com/$dsn_id.min.js"
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