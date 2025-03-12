<?php
  declare(strict_types=1);

  namespace Keyman\Site\Common;

  class Assets {
    static private $assets;
    static private function Fill() {
      Assets::$assets = [];
      $registry = explode("\n", file_get_contents(dirname(__DIR__) . "/resources/.bootstrap-registry"));
      foreach($registry as $reg) {
        if(substr($reg, 0, 7) == "assets/") {
          $item = explode(" ",$reg);
          // note: strip 'assets/' off the map
          Assets::$assets[substr($item[0], 7)] = substr($item[1], 7);
        }
      }
    }

    static public function Get($name) {
      if(empty(Assets::$assets)) {
        Assets::Fill();
      }

      if(empty(Assets::$assets[$name])) {
        return '/_common/assets/' . $name;
      }

      return '/_common/assets/' . Assets::$assets[$name];
    }
  }
