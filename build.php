#!/usr/bin/php

<?php

date_default_timezone_set('America/Los_Angeles');

$ch = curl_init();
//$buildConfiguration = "KevinCollins_Distribution";
//$buildConfiguration = "KimGrant_Distribution";
//$buildConfiguration = "SutroMedia_Distribution";
//$buildConfiguration = "TobinFisher_Distribution";
//$buildConfiguration = "KarenBrown_Distribution";

function kdebug($message) 
{
  echo date('Y/m/d H:i:s') . ': ' . $message . '
';
}

function jpeg_file_is_complete($path) {
    if (!is_resource($file = fopen($path, 'rb'))) {
        return FALSE;
    }
    // check for the existence of the EOI segment header at the end of the file
    if (0 !== fseek($file, -2, SEEK_END) || "\xFF\xD9" !== fread($file, 2)) {
        fclose($file);
        return FALSE;
    }
    fclose($file);
    return TRUE;
}

function jpeg_file_is_corrupted($path) {
	 return !jpeg_file_is_complete($path);
}

function syncApp($appId)
{
        $appSyncURL = 'http://sutroproject.com/admin/remote-sync-apps.php?appids=' . $appId;
	kdebug('Syncing server content for App ID = ' . $appId . ', url = ' . $appSyncURL);
	$syncOutput = file_get_contents($appSyncURL);

	while(strpos($syncOutput, 'App syncing succeeds for all apps') === FALSE) 
	{
		kdebug('Syncing server content failed for App ID = ' . $appId . ', url = ' . $appSyncURL . ' - sleeping and retrying.. Output => 
' . $syncOutput);
		sleep(120);
		$syncOutput = file_get_contents($appSyncURL);
	}
	kdebug('Syncing server content succeeds for App ID = ' . $appId);
}

function downloadPhoto($photoId, $photoFolder, $appContentFolder) {
	 $filename = $photoId . '.jpg';
	 $url = 'http://sutromedia.com/published/480-sized-photos/' . $filename;
	 $archivedFile = $photoFolder . $filename;
	 $appInstallFile = $appContentFolder . $filename;

	 if(file_exists($archivedFile) && jpeg_file_is_corrupted($archivedFile)) unlink($archivedFile); // if identification fails 

	 downloadFile($url, $appInstallFile, $archivedFile);


	 return jpeg_file_is_corrupted($archivedFile);
}

function downloadFile($url, $installFile, $archivedFile) {
	 global $ch;

	 $tmpFile = $installFile . '.tmp';

	 if(!file_exists($archivedFile) || filesize($archivedFile) == 0) 
	 {
		if(file_exists($installFile)) unlink($installFile);
		if(file_exists($tmpFile)) unlink($tmpFile);

kdebug('About to download ' . $url . ', to ' . $archivedFile);

	        if($curlErrno = curl_errno($ch)) 
		{
			kdebug('curl_errno() returns ' . $curlErrno . ', re-initializing');
			$ch = curl_init();
		}
		$fp = fopen($tmpFile, "w");
  		curl_setopt($ch, CURLOPT_URL, $url);
  		curl_setopt($ch, CURLOPT_FILE, $fp);
  		curl_setopt($ch, CURLOPT_HEADER, 0);
  		curl_exec($ch);
//  		curl_close($ch);
  		fclose($fp);
		rename($tmpFile, $archivedFile);
	 }
	 
	 if(file_exists($installFile)) unlink($installFile);
	 
	 link($archivedFile, $installFile);
	 //kdebug('link(' . $archivedFile . ', ' . $installFile . ')');
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

$brokenImages = array();

array_shift($argv);
	
//while($arg = array_shift($argv)) 
foreach($argv as $arg)
{
	if(0 == (int) $arg) echo 'Could not parse ' . $arg . ' as an App ID
';	
	else {
	     $appId = (int) $arg;

     	     kdebug('Running build for App ID = ' . $appId);
	     syncApp($appId);

	     $allAppsFolder = '../app-installs/';
     	     if(! file_exists($allAppsFolder)) mkdir($allAppsFolder);

	     $allPhotosFolder = '../480-sized-photos/';
     	     if(! file_exists($allPhotosFolder)) mkdir($allPhotosFolder);

	     $allContentFolder = '../content/';
	     if(! file_exists($allContentFolder)) mkdir($allContentFolder);

	     $appFolder = $allAppsFolder . $appId;
	     $contentFolder = $allContentFolder . $appId;

	     rmDashRF($contentFolder);
	     rmDashRF($appFolder);
	     
	     if(file_exists($appFolder)) deleteDirectory($appFolder);

	     system('svn export . ' . $appFolder);
        
        $screenshotFolder = $appFolder . '/screenshots/';
	    mkdir($screenshotFolder, 0777, true);

	     $staticContentZipURL = 'http://sutroproject.com/published-content/' . $appId . '/' . $appId . ' Static Content.zip';
     	     $staticContentZipFile = $contentFolder . '/' . $appId . '.zip';

     	     if(file_exists($staticContentZipFile)) unlink($staticContentZipFile);

     	     system('wget ' . escapeshellarg($staticContentZipURL) . ' -O ' . escapeshellarg($staticContentZipFile));
     	     system('unzip -q ' . escapeshellarg($staticContentZipFile) . ' -d ' . escapeshellarg($contentFolder));

     	     unlink($staticContentZipFile);

     	     cpDashR($contentFolder, $appFolder);

     	     system('wget ' . escapeshellarg('http://sutroproject.com/published-content/' . $appId . '/Info.plist'));

     	     rename('Info.plist', $appFolder . '/Info.plist');

     	     system('wget ' . escapeshellarg('http://sutroproject.com/published-content/' . $appId . '/Icon_512x512.png'));

     	     rename('Icon_512x512.png', $contentFolder . '/Icon_512x512.png');
             copy ($contentFolder . '/Icon_512x512.png', $screenshotFolder . '/Icon_512x512.png');

     	     $dbFile = $appFolder . '/' . $appId . ' Static Content/content.sqlite3';
kdebug('dbFile = ' . $dbFile);
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
	     		echo 'appName = ' . $appName . "\n";
			
             $cleanProductName = cleanForBundleIdentifier($appName);
	     		echo 'appName as PRODUCT_NAME = ' . $cleanProductName . "\n";
             
             $iTunesAccountName = $appProperties['itunes_account_name'];
                echo 'Account Name = ' . $iTunesAccountName . "\n";

			$genericProjectFolder = $appFolder . '/TheProject.xcodeproj';
	     		$genericProjectFile = $genericProjectFolder . '/project.pbxproj';

	     		$projectContents = file_get_contents($genericProjectFile);
	     		$projectContents = preg_replace('/PRODUCT_NAME = .*;/', 'PRODUCT_NAME = ' . $cleanProductName . ';', $projectContents);
	     		$projectContents = preg_replace('/BestofSF/', $cleanProductName, $projectContents);
	     		file_put_contents($genericProjectFile, $projectContents);


	     		$appSpecificProjectFolder = $appFolder . '/' . $cleanProductName . '.xcodeproj';
     	     		echo 'appSpecificProjectFolder = ' . $appSpecificProjectFolder . '
';

			cpDashR($genericProjectFolder, $appSpecificProjectFolder); 
	     		rmDashRF($genericProjectFolder);

			$staticContentFolder = $appFolder . '/' . $appId . ' Static Content';

			putenv("SUTRO_STATIC_CONTENT_ROOT=" . realpath($staticContentFolder));
			
			$offlineMapFolder = $staticContentFolder . '/offline-map-tiles';

echo 'offlineMapFolder = ' . $offlineMapFolder . '
';

			if(file_exists($offlineMapFolder)) {
echo 'offlineMapFolder found.. about to run map2sqlite
';
				system('./bin/map2sqlite -db ' . escapeshellarg($offlineMapFolder . '.sqlite3') . ' -mapdir ' . escapeshellarg($offlineMapFolder));
				$exitCode = system('rm -rf ' . escapeshellarg($offlineMapFolder));
                $db2 = new PDO('sqlite:' . $offlineMapFolder . '.sqlite3');
                    $db2->exec('ALTER TABLE tiles ADD COLUMN downloaded INTEGER');
                    $db2->exec('UPDATE tiles SET downloaded = 1');

			}

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
			if(file_exists($srcSplashFilename)) unlink($srcSplashFilename);

//var_dump($appProperties);
			$buildSyncLevel = (int) $appProperties['build_sync_level'];
kdebug('found build_sync_level property = ' . $buildSyncLevel);
			if($buildSyncLevel > 0) 
			{
kdebug('buildSyncLevel > 0');
				$results2 = $db->query('SELECT DISTINCT(photoid) FROM (SELECT rowid AS photoid FROM photos UNION SELECT DISTINCT(icon_photo_id) AS photoid FROM entries)');
				foreach($results2 as $row2) 
				{
					$downloadStatus = downloadPhoto($row2['photoid'], $allPhotosFolder, $appFolder . '/' . $appId . ' Static Content/images/');
					if($downloadStatus) array_push($brokenImages, $row2['photoid']);
				}
			}

			$iPhoneScreenshotPhotoIds = explode(',', $appProperties['iphone_screenshot_ordering']);

			$screenshotCounter = 1;
		
            foreach($iPhoneScreenshotPhotoIds as $iPhoneScreenshotPhotoId) 
			{
				downloadFile('http://sutromedia.com/published/iphone-sized-photos/' . $iPhoneScreenshotPhotoId . '.jpg', $screenshotFolder . '/' . $screenshotCounter++ .'-iphone' . '.jpg', $allPhotosFolder . '/' . $iPhoneScreenshotPhotoId . '_iphone_screenshot.jpg');
			}

            copy($iPhoneSplashFilename, $screenshotFolder . '/Default.jpg');

			$iPadScreenshotPhotoIds = explode(',', $appProperties['ipad_screenshot_ordering']);

			$screenshotCounter = 1;
			foreach($iPadScreenshotPhotoIds as $iPadScreenshotPhotoId) 
			{
				downloadFile('http://sutromedia.com/published/ipad-sized-photos/' . $iPadScreenshotPhotoId . '.jpg', $screenshotFolder . '/' . $screenshotCounter++ .'-ipad'.'.jpg', $allPhotosFolder . '/' . $iPadScreenshotPhotoId . '_ipad_screenshot.jpg');
			}
			
            kdebug("Building distribution version of ".$appId."\n"); 
			$originalDir = getcwd();

			chdir($appFolder);
            $buildConfiguration = $iTunesAccountName."_Distribution";
            $buildCommand = 'xcodebuild clean install -target ' . $cleanProductName . ' -sdk iphoneos4.3 ARCHS="armv6 armv7" -configuration '.$buildConfiguration.' -project ' . $cleanProductName . '.xcodeProj';
            kdebug($buildCommand);
			ksystem($buildCommand); 
            
             $lastDirectory = getcwd(); //we'll need to go back here after zipping to build the simulator version
             
             //Need to zip before building the simulator version as building the sim version overwrites the distribution version
             kdebug("Zipping distribution version of ".$appId."\n");
             $distAppFilePath = '../' . $appFolder . '/build/'.$buildConfiguration.'-iphoneos/' . $cleanProductName . '.app';
             $distAppFile = realpath($distAppFilePath);
             $distAppParentFolder = realpath(dirname($distAppFile));
             
             chdir($distAppParentFolder);
             
             ksystem('zip -r ' . $cleanProductName . '.zip ' . $cleanProductName . '.app');
             
             //Move file to centralized upload directory
             $filesForUpload = dirname($originalDir).'/app-installs/_apps-to-upload';
             
             if(! file_exists($filesForUpload)) mkdir($filesForUpload);
             
             $accountFolder = $filesForUpload.'/'.$iTunesAccountName;
             if(! file_exists($accountFolder)) mkdir($accountFolder);
             
             rename($cleanProductName.'.zip', $accountFolder."/".$cleanProductName.'.zip');
             
             chdir($lastDirectory);
             
             kdebug("Building simulator version of ".$appId."\n");
             ksystem('xcodebuild clean install -target ' . $cleanProductName . ' -sdk iphonesimulator4.3 -configuration Debug -project ' . $cleanProductName . '.xcodeProj');
             
             kdebug("Installing ".$appId." in simulator \n");
             ksystem('bin/iphonesim launch ' . escapeshellarg(realpath('build/Debug-iphonesimulator/' . $cleanProductName . '.app')) . ' > /dev/null &');
             
             chdir($originalDir);
            
             kdebug("Building completes for ".$appId."\n");
      		}
             
      		$db = null;
	    } catch(PDOException $e) { echo $e->getMessage(); }
	}
}

$brokenImageMessage = count($brokenImages) == 0 ? ' with no broken images' : ' with the following broken images => ' . join (', ', $brokenImages);

kdebug('Building completes for apps ' . join(', ', $argv) . $brokenImageMessage);

?>
