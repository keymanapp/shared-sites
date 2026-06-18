<?php
declare(strict_types=1);

namespace Keyman\Site\Common;

class ImageRandomizer {
  static function randomizer() {
    $filenames = [
      "sil-logo-abbysinica.f1b63893af9963b15b643b033ae522b52f28134b.png",
      "sil-logo-annapurna.c85665d2aa7ed9dd919a5f6044336a13d17e0c2a.png",
      "sil-logo-andika-v2.d93c755ddb2056b304d6f8be5adff568ea86c00d.png",
      "sil-logo-andika-v1.e53568611d3460322856840078f18d507c7832a6.png",
      "sil-logo-tai-heritage-pro.0cd269e5adefc991b75d32cb359c23b2fe10cc03.png",
    ];

    $n = random_int(0, sizeof($filenames) - 1);
    $imgDir =  '/_common/assets/sil-logos-2024/';
    return $imgDir . $filenames[$n];
  }
}
