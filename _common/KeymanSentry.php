<?php
  declare(strict_types=1);

  namespace Keyman\Site\Common;

  // Don't use autoloader here because we may be pre-autoloader setup
  require_once __DIR__ . '/KeymanHosts.php';

  class KeymanSentry {
    static function init($dsn) {
      \Sentry\init([
        'dsn' => $dsn,
        'environment' => KeymanHosts::Instance()->TierName()
      ]);
    }
  }