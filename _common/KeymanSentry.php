<?php
  declare(strict_types=1);

  namespace Keyman\Site\Common;

  use \Keyman\Site\Common\KeymanHosts;

  class KeymanSentry {
    static function init($dsn) {
      \Sentry\init([
        'dsn' => $dsn,
        'environment' => KeymanHosts::Instance()->TierName();
      ]);
    }
  }