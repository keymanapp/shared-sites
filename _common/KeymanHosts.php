<?php
  declare(strict_types=1);

  namespace Keyman\Site\Common;

  class KeymanHosts {
    // Four tiers. These use the following rough patterns:
    // * development = [x.]keyman.com.localhost
    // * Staging = [x.]keyman-staging.com
    // * Production = [x.]keyman.com
    // * Test = GitHub actions, localhost:8888 (uses production tier for other hosts)
    const TIER_DEVELOPMENT = "TIER_DEVELOPMENT";
    const TIER_STAGING = "TIER_STAGING";
    const TIER_PRODUCTION = "TIER_PRODUCTION";
    const TIER_TEST = "TIER_TEST";

    private $tierName = [
      'TIER_DEVELOPMENT' => 'development',
      'TIER_STAGING' => 'staging',
      'TIER_PRODUCTION' => 'production',
      'TIER_TEST' => 'test',
    ];

    public
      // major k8s hosted sites
      $s_keyman_com, $api_keyman_com, $help_keyman_com,
      $keyman_com, $keymanweb_com,

      // other sites
      $downloads_keyman_com, $blog_keyman_com, $translate_keyman_com,

      // old endpoints
      $r_keymanweb_com,

      // PHP serverside references only
      $SERVER_s_keyman_com, $SERVER_api_keyman_com, $SERVER_help_keyman_com,
      $SERVER_keyman_com, $SERVER_keymanweb_com,
      $SERVER_downloads_keyman_com;

    public
      // Hostnames for sites -- mostly used for display purposes
      $api_keyman_com_host, $help_keyman_com_host, $keyman_com_host;

    private $tier;

    private static $instance;

    public static function Instance(): KeymanHosts {
      if(!self::$instance)
        self::Rebuild();
      return self::$instance;
    }

    public function Tier() {
      return $this->tier;
    }

    public function TierName() {
      return $this->tierName[$this->tier];
    }

    public static function Rebuild() {
      self::$instance = new KeymanHosts();
    }

    /**
     * Returns $contents after regex'ing the Keyman live hosts for Markdown files
     * @param $contents
     * @return $contents
     */
    public function fixupHostReferences($contents) {
      // Regex Keyman hosts
      $contents = str_replace("https://s.keyman.com", $this->s_keyman_com, $contents);
      $contents = str_replace("https://api.keyman.com", $this->api_keyman_com, $contents);
      $contents = str_replace("https://help.keyman.com", $this->help_keyman_com, $contents);
      $contents = str_replace("https://downloads.keyman.com", $this->downloads_keyman_com, $contents);
      $contents = str_replace("https://keyman.com", $this->keyman_com, $contents);
      $contents = str_replace("https://keymanweb.com", $this->keymanweb_com, $contents);
      $contents = str_replace("https://r.keymanweb.com", $this->r_keymanweb_com, $contents);
      $contents = str_replace("https://blog.keyman.com", $this->blog_keyman_com, $contents);
      $contents = str_replace("https://translate.keyman.com", $this->translate_keyman_com, $contents);

      return $contents;
    }

    public function overrideHost($host, $value) {
      if(empty($this->$host)) {
        // If there's no value set, then we must be overriding something invalid
        die("Expected '\$this->$host' to be a valid host.");
      }
      $this->$host = $value;
      $this->fixupHosts();
    }

    function __construct() {
      $env = getenv();

      if(isset($env['KEYMANHOSTS_TIER']) && in_array($env['KEYMANHOSTS_TIER'],
          [KeymanHosts::TIER_DEVELOPMENT, KeymanHosts::TIER_STAGING,
           KeymanHosts::TIER_PRODUCTION, KeymanHosts::TIER_TEST])) {
        $this->tier = $env['KEYMANHOSTS_TIER'];
      } else if(file_exists(__DIR__ . '/../tier.txt')) {
        $this->tier = trim(file_get_contents(__DIR__ . '/../tier.txt'));
      } else {
        $this->tier = KeymanHosts::TIER_DEVELOPMENT;
      }

      // Following domains always point to production sites:
      $this->blog_keyman_com = "https://blog.keyman.com";
      $this->translate_keyman_com = "https://translate.keyman.com";
      $this->downloads_keyman_com = "https://downloads.keyman.com";
      $this->r_keymanweb_com = "https://r.keymanweb.com";

      if($this->tier == KeymanHosts::TIER_STAGING) {
        $this->s_keyman_com = "https://s.keyman-staging.com";
        $this->api_keyman_com = "https://api.keyman-staging.com";
        $this->help_keyman_com = "https://help.keyman-staging.com";
        $this->keyman_com = "https://keyman-staging.com";
        $this->keymanweb_com = "https://web.keyman-staging.com";
      } else if($this->tier == KeymanHosts::TIER_TEST) {
        // Note, cross-site references on test are always to production sites
        $this->s_keyman_com = "https://s.keyman.com";
        $this->api_keyman_com = "https://api.keyman.com";
        $this->help_keyman_com = "https://help.keyman.com";
        $this->keyman_com = "https://keyman.com";
        $this->keymanweb_com = "https://keymanweb.com";
      } else if($this->tier == KeymanHosts::TIER_DEVELOPMENT) {
        // Note: locally running sites via Docker require website-local-proxy to be running
        // Append reverse-proxy port
        $local_port = isset($env['KEYMAN_COM_PROXY_PORT']) ? ':'.$env['KEYMAN_COM_PROXY_PORT'] : '';
        $this->s_keyman_com = "http://s.keyman.com.localhost$local_port";
        $this->api_keyman_com = "http://api.keyman.com.localhost$local_port";
        $this->help_keyman_com = "http://help.keyman.com.localhost$local_port";
        $this->keyman_com = "http://keyman.com.localhost$local_port";
        $this->keymanweb_com = "http://keymanweb.com.localhost$local_port";

        // These are needed for PHP-side access
        $this->SERVER_s_keyman_com = "http://host.docker.internal:8054";
        $this->SERVER_api_keyman_com = "http://host.docker.internal:8058";
        $this->SERVER_help_keyman_com = "http://host.docker.internal:8055";
        $this->SERVER_keyman_com = "http://host.docker.internal:8053";
        $this->SERVER_keymanweb_com = "http://host.docker.internal:8057";
      } else if($this->tier == KeymanHosts::TIER_PRODUCTION) {
        $this->s_keyman_com = "https://s.keyman.com";
        $this->api_keyman_com = "https://api.keyman.com";
        $this->help_keyman_com = "https://help.keyman.com";
        $this->keyman_com = "https://keyman.com";
        $this->keymanweb_com = "https://keymanweb.com";
      } else {
        die("tier is '$this->tier' which is invalid\n");
      }

      // Currently, we don't locally host downloads.keyman.com, so
      // we always have the same address
      $this->SERVER_downloads_keyman_com = $this->downloads_keyman_com;

      if(empty($this->SERVER_s_keyman_com)) {
        $this->SERVER_s_keyman_com = $this->s_keyman_com;
        $this->SERVER_api_keyman_com = $this->api_keyman_com;
        $this->SERVER_help_keyman_com = $this->help_keyman_com;
        $this->SERVER_keyman_com = $this->keyman_com;
        $this->SERVER_keymanweb_com = $this->keymanweb_com;
      }
      $this->fixupHosts();
    }

    private function fixupHosts() {
      $this->api_keyman_com_host = preg_replace('/^http(s)?:\/\/(.+)$/', '$2', $this->api_keyman_com);
      $this->help_keyman_com_host = preg_replace('/^http(s)?:\/\/(.+)$/', '$2', $this->help_keyman_com);
      $this->keyman_com_host = preg_replace('/^http(s)?:\/\/(.+)$/', '$2', $this->keyman_com);
    }
  }
