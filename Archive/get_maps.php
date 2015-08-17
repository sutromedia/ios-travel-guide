#!/usr/bin/php

<?php

function rmDashRF($dir) {
  deleteDirectory($dir);
  mkdir($dir);
}

function cleanForBundleIdentifier($toClean) { // also useful for product name
  $retVal = preg_replace('/[^A-Za-z0-9\-\.]/', '', $toClean);
  return $retVal;
}

function deleteDirectory($dir) {
  if (is_link($dir)) return unlink($dir);
  if (!file_exists($dir)) return true;
  if (!is_dir($dir)) return unlink($dir);
  foreach (scandir($dir) as $item) {
    if ($item == '.' || $item == '..') continue;
    if (!deleteDirectory($dir.DIRECTORY_SEPARATOR.$item)) return false;
  }
  return rmdir($dir);
}

function cpDashR($src,$dst) {
  $dir = opendir($src);
  @mkdir($dst);
  while(false !== ( $file = readdir($dir)) ) {
    if (( $file != '.' ) && ( $file != '..' )) {
      if ( is_dir($src . '/' . $file) ) {
        cpDashR($src . '/' . $file,$dst . '/' . $file);
      }
      else {
        copy($src . '/' . $file,$dst . '/' . $file);
      }
    }
  }
  closedir($dir);
}

function ksystem($command, &$output = null, &$exitStatus = null, $printSuccesses = false) {
  exec($command, $output, $exitStatus);
  if($exitStatus != 0 || $printSuccesses) echo '`' . $command . '` ' . ($exitStatus == 0 ? "succeeds" : "fails with exit code = " . $exitStatus);
  return $exitStatus;
}

function getSubversionRevisionNumber() {
  ksystem('svn info', $output, $exitStatus, true);
  $pattern = '/Last Changed Rev: ([0-9]+)/';
  preg_match($pattern, implode($output), $matches);
//echo 'getSubversionRevisionNumber() returning ' . $matches[1];
  return $matches[1];
}


// var_dump($mapList);

$mapsDir = '../maps.tmp';

//rmDashRF($mapsDir);

if(!file_exists($mapsDir)) mkdir($mapsDir);
else ksystem('scp ' . $mapsDir . '/* ' . 'tobinfisher@sutroproject.com:sutromedia.com/published/maps/original/');

$mapList = json_decode(file_get_contents('http://www.sutromedia.com/published/maps/original/list_failed.php'));

system('cd ' . escapeshellarg($mapsDir));
$counter = 0;

foreach($mapList as $mapParams) {
/*  echo 'id = ' . $mapParams->{'id'} . ', url = ' . $mapParams->{'url'} . '
';
*/
  $mapFile = $mapsDir . '/' . $mapParams->{'filename'};
  ksystem('wget -nv ' . escapeshellarg($mapParams->{'url'}) . ' -O ' . escapeshellarg($mapFile));
  
  $md5sum = md5(file_get_contents($mapFile));

  if(filesize($mapFile) == 0 || strcmp($md5sum, '63bf3bad3a1cf4242d94fb30b98a3550') == 0 || strcmp($md5sum, '0d2024fd8084cfee5ab4d5b85a1c31ba') == 0 || strcmp($md5sum, 'b0d2435450e99e4cb75e3c54e1ee1bb9') == 0)break;
  else {
       usleep(3000000);
       $counter++;
  }
}

if($counter > 0) {
	    $scpRetVal = ksystem('scp ' . $mapsDir . '/* ' . 'tobinfisher@sutroproject.com:sutromedia.com/published/maps/original/');
	    echo $counter . ' maps fixed.
';

// do this to update the server and specifically to remove the resized map files
	    $mapList = json_decode(file_get_contents('http://www.sutromedia.com/published/maps/original/list_failed.php'));

	    if((int) $scpRetVal == 0) deleteDirectory($mapsDir); // only delete the folder if/after the upload succeeds
}
else echo '

No maps fixed

';

?>