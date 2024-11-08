<?php
  declare(strict_types=1);

  namespace Keyman\Site\Common;

  use Keyman\Site\Common\KeymanHosts;

  class MarkdownHost {
    private $content, $pagetitle, $showMenu;

    function PageTitle() {
      return $this->pagetitle;
    }

    function ShowMenu() {
      return $this->showMenu;
    }

    function Content() {
      return $this->content;
    }

    function __construct($file) {
      $this->pagetitle = 'TODO'; // If page title is not set, this hints to the developer to fix it
      $this->showMenu = true;

      $file = realpath(__DIR__ . '/../') . DIRECTORY_SEPARATOR . $file;
      $contents = trim(file_get_contents($file));
      $contents = str_replace("\r\n", "\n", $contents);

      $contents = KeymanHosts::Instance()->fixupHostReferences($contents);

      // This header specification comes from YAML originally and is not common across
      // markdown implementations. While Parsedown does not currently parse this out,
      // it seems a sensible approach to use. The header section is delineated by `---`
      // and `---` must be the first three characters of the file (no BOM!); note that
      // the full spec supports metadata sections anywhere but we only support top-of-file.
      //
      // Currently we support only the 'title', 'redirect', 'showmenu' keywords.
      //
      // title: must be a plain text title
      // redirect: must be a relative or absolute url
      // showmenu: true or false
      //
      // ---
      // keyword: content
      // keyword: content
      // ---
      //
      // source: https://yaml.org/spec/1.2/spec.html#id2760395
      // source: https://pandoc.org/MANUAL.html#extension-yaml_metadata_block
      //

      $lines = explode("\n", $contents);
      $headers = [];

      $found = count($lines) > 3 && rtrim($lines[0]) == '---';
      if($found) {
        for($i = 1; $i < count($lines); $i++) {
          if($lines[$i] == '---') break;
          if(!preg_match('/^([a-z0-9_-]+):(.+)$/', $lines[$i], $match)) {
            $found = false;
            break;
          } else {
            $headers[$match[1]] = trim($match[2]);
          }
        }
        $found = $found && $i < count($lines);
      }

      if(isset($headers['redirect'])) {
        header("Location: {$headers['redirect']}");
        exit;
      }

      if($found) {
        $contents = implode("\n", array_slice($lines, $i));
      } else {
        // We are going to search for the first '#' style heading
        if(preg_match('/^(#)+ (.+)$/m', $contents, $sub)) {
          $headers['title'] = $sub[2];
        }
      }

      $this->pagetitle = isset($headers['title']) ? $headers['title'] : 'Untitled';
      $this->showMenu = isset($headers['showmenu']) ? $headers['showmenu'] == 'true' : true;

      // Performs the parsing + prettification of Markdown for display through PHP.
      $Parsedown = new \ParsedownExtra();
      $Alerts = new \Keyman\Site\Common\GFMAlerts;

      // Does the magic.
       
       $this->content = 
       "<h1>" . htmlentities($this->pagetitle) . "</h1>\n" . 
       "<div class='markdown'>" . 
       $Alerts->text($contents) . 
       "</div>";
    }
  }

