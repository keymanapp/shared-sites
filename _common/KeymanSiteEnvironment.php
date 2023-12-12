<?php
  declare(strict_types=1);

  namespace Keyman\Site\Common;

  class HelpSiteEnvironment extends KeymanSiteEnvironment {
    public static
      // help.keyman.com
      $KEYMANHOSTS_TIER = '',
      $KEYMAN_COM_PROXY_PORT = '';

    public static function Init() {
      KeymanSiteEnvironment::_Init(get_class());
    }
  }

  class KeymanSiteEnvironment {

    public static
      // keyman.com
      $API_KEYMAN_COM_INCREMENT_DOWNLOAD_KEY,
      
      // api.keyman.com
      $api_keyman_com_github_user,
      $api_keyman_com_github_repo;

    protected static function _Init($class) {
      $env = getenv();
      $props = get_class_vars($class);
      foreach($props as $name => $value) {
        if (isset($env[$name])) {
          self::$instance->$name = $env[$name];
        }
      }
    }

    public static function Debug($class) {
      $props = get_class_vars($class);
      var_dump($props);
    }
  }

// HelpSiteEnvironment::Debug('Keyman\Site\Common\HelpSiteEnvironment');
// echo HelpSiteEnvironment::$api_keyman_com_github_repo;

HelpSiteEnvironment::Init();