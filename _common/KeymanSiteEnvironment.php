<?php
  declare(strict_types=1);

  namespace Keyman\Site\Common;

  // Dynamic properties marked for deprecation: https://wiki.php.net/rfc/deprecate_dynamic_properties
  #[AllowDynamicProperties]
  class KeymanSiteEnvironment {
    private array $data = [];

    private static $instance;

    public static function Instance($class = null): KeymanSiteEnvironment {
      if(!self::$instance)
        self::Rebuild($class);
      return self::$instance;
    }

    public static function Rebuild($class) {
      self::$instance = new KeymanSiteEnvironment($class);
    }

    protected function __construct($class) {
      self::_Init($class);
    }

    protected function _Init($class) {
      $env = getenv();
      $props = get_class_vars($class);
      foreach($props as $key => $value) {
        if (isset($env[$key])) {
          echo "key $key, env[key] $env[$key]\n";
          self::__set($key, $env[$key]);
        }
      }
      var_dump($this);
      echo "__get: " . self::__get('LOGNAME') . "\n";
    }

    public function &__get($name) { return $this->data[$name]; }
    public function __isset($name) { return isset($this->data[$name]); }
    public function __set($name, $value) { $this->data[$name] = $value; }
    public function __unset($name) { unset($this->data[$name]); }

    public static function Debug($class) {
      $props = get_class_vars($class);
      echo "------- Debug -------\n";
      var_dump($props);
      echo "---------------------\n";
    }
  }

  class HelpSiteEnvironment extends KeymanSiteEnvironment {
    public ?string
      // Expected env vars for help.keyman.com
      $HOSTNAME = null, // Do not commit this line
      $KEYMANHOSTS_TIER = null,
      $LOGNAME = null,
      $KEYMAN_COM_PROXY_PORT = null;

    const MY_KEYMAN = null;

    public function __construct() {
      return new KeymanSiteEnvironment(get_class());
    }  

    public static function Init() {
      KeymanSiteEnvironment::Instance(get_class());

      // For troubleshooting
      KeymanSiteEnvironment::Instance()->Debug(get_class());
    }
  }

  // Code for testing
  HelpSiteEnvironment::Init();
  if (HelpSiteEnvironment::Instance()->__isset('LOGNAME')) {
    echo "true\n";
  } else {
    echo "false\n";
  }
  