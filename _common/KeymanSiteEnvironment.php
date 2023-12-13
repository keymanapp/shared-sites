<?php
  declare(strict_types=1);

  namespace Keyman\Site\Common;

  class KeymanSiteEnvironment {

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

    public static function IsSet($name) {
      if (isset(self::$instance->$name) && self::$instance->$name != '') {
        return true;
      }
      return false;
    }
  }
