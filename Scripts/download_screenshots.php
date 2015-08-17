#!/usr/bin/php

<?php

function kdebug($message) 
{
  echo $message . '
';
}

function downloadPhoto($photoId, $photoFolder, $appContentFolder) {
	 $filename = $photoId . '.jpg';
	 $url = 'http://www.sutromedia.com/published/iphone-sized-photos/' . $filename;
	 $archivedFile = $photoFolder . $filename;
	 $appInstallFile = $appContentFolder . $filename;
	 return downloadFile($url, $appInstallFile, $archivedFile);
}

function downloadFile($url, $installFile, $archivedFile) {

	 $tmpFile = $installFile . '.tmp';

	 if(!file_exists($archivedFile) || filesize($archivedFile) == 0) 
	 {
		if(file_exists($installFile)) unlink($archivedFile);
		if(file_exists($tmpFile)) unlink($tmpFile);

		$ch = curl_init($url);
		$fp = fopen($tmpFile, "w");
  		curl_setopt($ch, CURLOPT_FILE, $fp);
  		curl_setopt($ch, CURLOPT_HEADER, 0);
  		curl_exec($ch);
  		curl_close($ch);
  		fclose($fp);
		rename($tmpFile, $archivedFile);
	 }
	 
	 if(file_exists($installFile)) unlink($installFile);
	 
	 link($archivedFile, $installFile);
	 kdebug('link(' . $archivedFile . ', ' . $installFile . ')');
}

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

// pull the app-id from the command line 

array_shift($argv);
	
while($arg = array_shift($argv)) 
{
	if(0 == (int) $arg) echo 'Could not parse ' . $arg . ' as an App ID
';	
	else {
	     $appId = (int) $arg;
     	     echo 'Running build for App ID = ' . $appId . '
';

	     $allAppsFolder = '../app-installs/';
     	     if(! file_exists($allAppsFolder)) mkdir($allAppsFolder);

	     $allPhotosFolder = '../iphone-sized-photos/';
     	     if(! file_exists($allPhotosFolder)) mkdir($allPhotosFolder);

	     $allContentFolder = '../content/';
	     if(! file_exists($allContentFolder)) mkdir($allContentFolder);

	     $appFolder = $allAppsFolder . $appId."_screenshots";
	     $contentFolder = $allContentFolder . $appId;

	     rmDashRF($contentFolder);
	     rmDashRF($appFolder);
	     
	     if(file_exists($appFolder)) deleteDirectory($appFolder);

	     system('svn export . ' . $appFolder);
        
	$screenshotFolder = $appFolder . '/screenshots/';
	    mkdir($screenshotFolder, 0777, true);

	    // $staticContentZipURL = 'http://sutroproject.com/published-content/' . $appId . '/' . $appId . ' Static Content.zip';
     	     //$staticContentZipFile = $contentFolder . '/' . $appId . '.zip';

     	   //  if(file_exists($staticContentZipFile)) unlink($staticContentZipFile);

     	   //  system('wget ' . escapeshellarg($staticContentZipURL) . ' -O ' . escapeshellarg($staticContentZipFile));
     	   //  system('unzip -q ' . escapeshellarg($staticContentZipFile) . ' -d ' . escapeshellarg($contentFolder));

     	    // unlink($staticContentZipFile);

     	    // cpDashR($contentFolder, $appFolder);

     	     //system('wget ' . escapeshellarg('http://sutroproject.com/published-content/' . $appId . '/Info.plist'));

     	     //rename('Info.plist', $appFolder . '/Info.plist');

     	    // system('wget ' . escapeshellarg('http://sutroproject.com/published-content/' . $appId . '/Icon_512x512.png'));

     	    // rename('Icon_512x512.png', $contentFolder . '/Icon_512x512.png');
            // copy ($contentFolder . '/Icon_512x512.png', $screenshotFolder . '/Icon_512x512.png');

     	     $dbFile = $appFolder . '/' . $appId . ' Static Content/content.sqlite3';
	     kdebug('dfFile = ' . $dbFile);
	     
	     try {
     	     	 $db = new PDO('sqlite:' . $dbFile);
     		 $db->exec('DELETE FROM app_properties WHERE key = "svn_revision"');
     		 $db->exec('INSERT INTO app_properties (key, value) VALUES ("svn_revision", ' . (int) getSubversionRevisionNumber() . ')');

		 $appProperties = array();
		 $results = $db->query('SELECT key as key, value AS value FROM app_properties');

     		 foreach($results as $row) $appProperties[$row['key']] = $row['value'];

//		 var_dump($appProperties);

		 if(!empty($appProperties['app_name'])) 
		 {
			$appName = $appProperties['app_name'];
	     		echo 'appName = ' . $appName . '';
			$cleanProductName = cleanForBundleIdentifier($appName);
	     		echo 'appName as PRODUCT_NAME = ' . $cleanProductName . '';


// generate splash screens... now on the client

echo 'about to generate splash screens...
';
   	    	   	$srcSplashFilename = $appFolder . '/' . $appId . ' Static Content/Default.jpg';
   	    	   	$iPhoneSplashFilename = $appFolder . '/' . $appId . ' Static Content/Default.png';
   	    	   	$iPadSplashFilename = $appFolder . '/' . $appId . ' Static Content/Default-Portrait.png';

   	    	   	echo 'about to run... convert ' . escapeshellarg($srcSplashFilename) . ' -resize 320x480! -depth 7 -quality 80% ' . escapeshellarg($iPhoneSplashFilename) . '
';
   	    	   	system('convert ' . escapeshellarg($srcSplashFilename) . ' -resize 320x480! -depth 7 -quality 80% ' . escapeshellarg($iPhoneSplashFilename));
   	    	   	echo 'about to run... convert ' . escapeshellarg($srcSplashFilename) . ' -resize 768x1024! -depth 7 -quality 80% ' . escapeshellarg($iPadSplashFilename) . '
';
   	    	   	system('convert -limit area 512mb -limit memory 512mb -limit map 512mb ' . escapeshellarg($srcSplashFilename) . ' -resize 768x1024! -depth 7 -quality 80% ' . escapeshellarg($iPadSplashFilename));

echo 'splash screens generated... removing splash screen source file
';
			unlink($srcSplashFilename);

var_dump($appProperties);
            $buildSyncLevel = (int) $appProperties['build_sync_level'];
kdebug('found build_sync_level property = ' . $buildSyncLevel);
			if($buildSyncLevel > 0) 
			{
kdebug('buildSyncLevel > 0');
				$results2 = $db->query('SELECT DISTINCT(photoid) FROM (SELECT rowid AS photoid FROM photos UNION SELECT DISTINCT(icon_photo_id) AS photoid FROM entries)');
				foreach($results2 as $row2) downloadPhoto($row2['photoid'], $allPhotosFolder, $appFolder . '/' . $appId . ' Static Content/images/');
			}

			$iPhoneScreenshotPhotoIds = explode(',', $appProperties['iphone_screenshot_ordering']);

			$screenshotCounter = 1;
		
            foreach($iPhoneScreenshotPhotoIds as $iPhoneScreenshotPhotoId) 
			{
				downloadFile('http://www.sutromedia.com/published/iphone-sized-photos/' . $iPhoneScreenshotPhotoId . '.jpg', $screenshotFolder . '/' . $screenshotCounter++ .'-iphone' . '.jpg', $allPhotosFolder . '/' . $iPhoneScreenshotPhotoId . '_iphone_screenshot.jpg');
			}

            copy($iPhoneSplashFilename, $screenshotFolder . '/Default.jpg');

			$iPadScreenshotPhotoIds = explode(',', $appProperties['ipad_screenshot_ordering']);

			$screenshotCounter = 1;
			foreach($iPadScreenshotPhotoIds as $iPadScreenshotPhotoId) 
			{
				downloadFile('http://www.sutromedia.com/published/ipad-sized-photos/' . $iPadScreenshotPhotoId . '.jpg', $screenshotFolder . '/' . $screenshotCounter++ .'-ipad'.'.jpg', $allPhotosFolder . '/' . $iPadScreenshotPhotoId . '_ipad_screenshot.jpg');
			}

	     		system('open ' . $appSpecificProjectFolder);
     	     		sleep(5);
     	     		system('open ' . $appFolder); 
      		}
      		$db = null;
	    } catch(PDOException $e) { echo $e->getMessage(); }
	}
}



// create new app-folder with code/resources from current folder

// copy app-specific content into app-folder

// copy Info.plist into app-folder

// rename xcode file with app-name

// open xcode with project file?  open finder with static content at-hand?

?>
