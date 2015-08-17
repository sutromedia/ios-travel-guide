#!/usr/bin/php

<?php

$ch = curl_init();

define('THUMBS_HEIGHT', 100); // as of 10/6/2011 - we also generate these on the server, so it's probably not a great idea to change it here-only

function kdebug($message) 
{
  echo $message . '
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


function downloadThumbPhoto($photoId, $photoFolder, $thumbFolder, $appContentFolder) {

	 $downloadStatus = downloadPhoto($photoId, $photoFolder, null); // last null => don't copy the full-sized photo to the app folder
	 if($downloadStatus) return $downloadStatus;
	 else {
	 	$archivedFullSizedPhoto = $photoFolder . $photoId . '.jpg';
	 	$archivedThumbSizedPhoto = $thumbFolder . $photoId . '_x' . THUMBS_HEIGHT . '.jpg';
//kdebug('archivedThumbSizedPhoto = ' . $archivedThumbSizedPhoto);
		if(!file_exists($archivedThumbSizedPhoto) || jpeg_file_is_corrupted($archivedThumbSizedPhoto))
			ksystem('convert -limit area 64mb -limit memory 64mb -limit map 64mb ' . escapeshellarg($archivedFullSizedPhoto) . ' -colorspace RGB -quality 80 -profile graphics/AppleRGB.icc -strip -resize x' . THUMBS_HEIGHT . ' ' . escapeshellarg($archivedThumbSizedPhoto));

		$thumbTarget = $appContentFolder . $photoId . '_x' . THUMBS_HEIGHT . '.jpg';
		copy($archivedThumbSizedPhoto, $thumbTarget);
		return jpeg_file_is_corrupted($thumbTarget);
	 }
}

function downloadPhoto($photoId, $photoFolder, $appContentFolder) {
	 $filename = $photoId . '.jpg';
	 $url = 'http://sutromedia.com/published/480-sized-photos/' . $filename;
	 $archivedFile = $photoFolder . $filename;
	 $appInstallFile = empty($appContentFolder) ? null : $appContentFolder . $filename;

	 if(file_exists($archivedFile) && jpeg_file_is_corrupted($archivedFile)) unlink($archivedFile); // if identification fails 

	 downloadFile($url, $appInstallFile, $archivedFile);


	 return jpeg_file_is_corrupted($archivedFile);
}

function downloadFile($url, $installFile, $archivedFile) {

	 $tmpFile = $installFile . '.tmp';

	 if(!file_exists($archivedFile) || filesize($archivedFile) == 0) 
	 {
		global $ch;

		if(file_exists($archivedFile)) unlink($archivedFile);
		if(file_exists($tmpFile)) unlink($tmpFile);

		kdebug('Trying to download url = '. $url . ', to file = ' . $installFile . ', with archivedFile = ' . $archivedFile);

		$fp = fopen($tmpFile, "w");
  		curl_setopt($ch, CURLOPT_FILE, $fp);
  		curl_setopt($ch, CURLOPT_URL, $url);
  		curl_setopt($ch, CURLOPT_HEADER, 0);
  		curl_exec($ch);
//  		curl_close($ch);
  		fclose($fp);
		rename($tmpFile, $archivedFile);
	 }
	 
	 if(file_exists($installFile)) unlink($installFile);
	 
	 if(!empty($installFile))
	 {
		link($archivedFile, $installFile);
	 	kdebug('link(' . $archivedFile . ', ' . $installFile . ')');
	 }
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

$appId = (int) 1;
echo 'Running build for Sutro World';
	
else echo("\n\n******************************************\n\n  ******** Build script updates made without full validation. Double check changed markeed below ************\n\n******************************************\n\n");

$allAppsFolder = '../app-installs/';
if(! file_exists($allAppsFolder)) mkdir($allAppsFolder);

$allPhotosFolder = '../480-sized-photos/';
if(! file_exists($allPhotosFolder)) mkdir($allPhotosFolder);


$allThumbsFolder = '../' . THUMBS_HEIGHT . '-sized-photos/';
if(! file_exists($allThumbsFolder)) mkdir($allThumbsFolder);

$allContentFolder = '../content/';
if(! file_exists($allContentFolder)) mkdir($allContentFolder);

$appFolder = $allAppsFolder . $appId;

$contentFolder = $allContentFolder . $appId;

rmDashRF($contentFolder);

//rmDashRF($appFolder);

rmDashRF($appFolder);

if(file_exists($appFolder)) deleteDirectory($appFolder);

system('svn export . ' . $appFolder);

$screenshotFolder = $appFolder . '/screenshots/';
$appStaticContentFolder = $appFolder . '/' . $appId . ' Static Content/';

$imagesFolder = $appStaticContentFolder . '/images/';

mkdir($screenshotFolder, 0777, true);
mkdir($appStaticContentFolder, 0777, true);

	     $SQLLiteFileZippedURL = 'http://sutromedia.com/published/content/' . 1 . '.v3.sqlite3.zip';
     	     $dbZipFile = $appFolder . '/' . $appId . '.v3.sqlite3.zip';
     	     $dbFile = $appStaticContentFolder . '.v3.sqlite3';

     	     if(file_exists($dbZipFile)) unlink($dbZipFile);

     	     system('wget ' . escapeshellarg($SQLLiteFileZippedURL) . ' -O ' . escapeshellarg($dbZipFile));
     	     kdebug('unzip -q ' . escapeshellarg($dbZipFile) . ' -d ' . escapeshellarg($appStaticContentFolder));

     	     system('unzip -q ' . escapeshellarg($dbZipFile) . ' -d ' . escapeshellarg($appStaticContentFolder));

     	     kdebug('unzip -q ' . escapeshellarg($dbZipFile) . ' -d ' . escapeshellarg($appStaticContentFolder) . ' completes');

     	     unlink($dbZipFile);
/*
     	     kdebug('cpDashR(' . $contentFolder . ', ' . $appFolder . ') called');
     	     cpDashR($contentFolder, $appFolder);
     	     kdebug('cpDashR(' . $contentFolder . ', ' . $appFolder . ') completes');
*/

//     	     system('wget ' . escapeshellarg('http://sutroproject.com/published-content/3/Info.plist'));

//     	     rename('Info.plist', $appFolder . '/Info.plist');

//     	     copy('Sutroworld.Info.plist', $appFolder . '/Info.plist');

//     	     rename('Icon_512x512.png', $contentFolder . '/Icon_512x512.png');

//     	     copy('Sutroworld.Icon_512x512.png', $fullSizedIcon);
	
	//TF added - double check that this section isn't accidentally overwritting anything
	
	//*** need to figure out how to remove the full rez icon files ****
	$staticContentZipURL = 'http://sutroproject.com/published-content/1/1 Static Content.zip';
	$staticContentZipFile = $contentFolder . '/' . $appId . '.zip';
	
	if(file_exists($staticContentZipFile)) unlink($staticContentZipFile);
	
	system('wget ' . escapeshellarg($staticContentZipURL) . ' -O ' . escapeshellarg($staticContentZipFile));
	system('unzip -q ' . escapeshellarg($staticContentZipFile) . ' -d ' . escapeshellarg($contentFolder));
	
	unlink($staticContentZipFile);
	cpDashR($contentFolder, $appFolder);
	
	
	     $fullSizedIcon = $screenshotFolder . '/Icon_512x512.png';

     	     system('wget ' . escapeshellarg('http://sutromedia.com/Sutroworld.Icon_512x512.png') . ' -O ' . escapeshellarg($fullSizedIcon));

kdebug('about to create smaller icons');
	     ksystem('convert -limit area 64mb -limit memory 64mb -limit map 64mb ' . escapeshellarg($fullSizedIcon) . ' -resize 29x29! ' . escapeshellarg($appStaticContentFolder . '/Icon-Small.png'));

kdebug('done creating first small icon');

    	     ksystem('convert -limit area 64mb -limit memory 64mb -limit map 64mb ' . escapeshellarg($fullSizedIcon) . ' -resize 50x50! ' . escapeshellarg($appStaticContentFolder . '/Icon-Small-50.png'));
	     
kdebug('done creating second small icon');

    	     ksystem('convert -limit area 64mb -limit memory 64mb -limit map 64mb ' . escapeshellarg($fullSizedIcon) . ' -resize 57x57! ' . escapeshellarg($appStaticContentFolder . '/Icon.png'));

kdebug('done creating third small icon');

   	     ksystem('convert -limit area 64mb -limit memory 64mb -limit map 64mb ' . escapeshellarg($fullSizedIcon) . ' -resize 58x58! ' . escapeshellarg($appStaticContentFolder . '/Icon-Small@2x.png'));

kdebug('done creating fourth small icon');

   	     ksystem('convert -limit area 64mb -limit memory 64mb -limit map 64mb ' . escapeshellarg($fullSizedIcon) . ' -resize 72x72! ' . escapeshellarg($appStaticContentFolder . '/Icon-72.png'));

kdebug('done creating fifth small icon');

    	     kdebug('convert -limit area 64mb -limit memory 64mb -limit map 64mb ' . escapeshellarg($fullSizedIcon) . ' -resize 114x114! ' . escapeshellarg($appStaticContentFolder . '/Icon@2x.png'));
    	     ksystem('convert -limit area 64mb -limit memory 64mb -limit map 64mb ' . escapeshellarg($fullSizedIcon) . ' -resize 114x114! ' . escapeshellarg($appStaticContentFolder . '/Icon@2x.png'));

kdebug('done creating smaller icons');

     	     $dbFile = $appStaticContentFolder . '/' . $appId . '.v3.sqlite3';
     	     rename($dbFile, $appStaticContentFolder . '/content.sqlite3');
	     $dbFile = $appStaticContentFolder . '/content.sqlite3';

kdebug('dbFile = ' . $dbFile);


	     try {
     	     	 $db = new PDO('sqlite:' . $dbFile);
     		 $db->exec('DELETE FROM app_properties WHERE key = "svn_revision"');
     		 $db->exec('INSERT INTO app_properties (key, value) VALUES ("svn_revision", ' . (int) getSubversionRevisionNumber() . ')');

		 $appProperties = array();
		 $results = $db->query('SELECT key as key, value AS value FROM app_properties');

     		 foreach($results as $row) $appProperties[$row['key']] = $row['value'];

//		 var_dump($appProperties);

		 if(!empty($appProperties['bundle_version']))
		 {
			$infoDotPlistContent = file_get_contents('Sutroworld.Info.plist');
			$infoDotPlistContent = preg_replace('/SUTRO_BUNDLE_VERSION/', $appProperties['bundle_version'], $infoDotPlistContent);
			file_put_contents($appFolder . '/Info.plist', $infoDotPlistContent);
		}

		 if(!empty($appProperties['app_name'])) 
		 {
			$appName = $appProperties['app_name'];
	     		echo 'appName = ' . $appName . '
';
			$cleanProductName = cleanForBundleIdentifier($appName);
	     		echo 'appName as PRODUCT_NAME = ' . $cleanProductName . '
';

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

			$buildSyncLevel = (int) $appProperties['build_sync_level'];
kdebug('found build_sync_level property = ' . $buildSyncLevel);
//			if($buildSyncLevel > 0) 
			{
kdebug('downloading photos for sutro world...');
				if(!file_exists($imagesFolder)) mkdir($imagesFolder);

//				$results2 = $db->query('SELECT DISTINCT(photoid) FROM ((SELECT DISTINCT(icon_photo_id) AS photoid, 1 AS download_priority FROM entries UNION SELECT DISTINCT(icon_photo_id) AS photoid, 2 AS download_priority FROM demo_entries)) ORDER BY download_priority, photoid LIMIT 0, 2650');
				$results2 = $db->query('SELECT photoid FROM (SELECT icon_photo_id AS photoid, 1 AS download_priority, 0 AS sibling_index, 0 AS linked_from_pitch FROM entries UNION SELECT icon_photo_id AS photoid, 2 AS download_priority, sibling_index, linked_from_pitch FROM demo_entries) ORDER BY download_priority, linked_from_pitch DESC, sibling_index LIMIT 0, 10000');
				foreach($results2 as $row2) 
				{
					$downloadStatus = downloadThumbPhoto($row2['photoid'], $allPhotosFolder, $allThumbsFolder, $imagesFolder);
					if($downloadStatus) array_push($brokenImages, $row2['photoid']);
					else $db->exec('UPDATE photos SET downloaded_x100px_photo = 1 WHERE rowid = ' . (int) $row2['photoid']);
//					kdebug('UPDATE photos SET downloaded_x100px_photo = 1 WHERE rowid = ' . (int) $row2['photoid']);
				}
//				$db->exec("END TRANSACTION");
			}


			$results2 = $db->query('SELECT app_id, photos.rowid AS photoid FROM demo_entries, photos WHERE demo_entries.icon_photo_id = photos.rowid AND demo_entries.app_id NOT IN (SELECT entryid from entry_photos WHERE entry_photos.photoid = photos.rowid)');

			foreach($results2 as $row2) 
			{
				$db->exec('INSERT OR IGNORE INTO entry_photos (entryid, photoid, awesome, slideshow_order) VALUES (' . (int) $row2['app_id'] . ', ' . (int) $row2['photoid'] . ', 1, 0)');
//				kdebug('INSERT OR IGNORE INTO entry_photos (entryid, photoid, awesome, slideshow_order) VALUES (' . (int) $row2['app_id'] . ', ' . (int) $row2['photoid'] . ', 1, 0)');
			}


			//system('wget http://sutromedia.com/published/sutro-map-tiles/hardcoded-map-tiles-for-sutro-world.sqlite3 -O ' . escapeshellarg($appStaticContentFolder) . 'hardcoded-map-tiles-for-sutro-world.sqlite3');

/*
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
*/

	     		//system('open ' . $appSpecificProjectFolder);
     	     	//	sleep(5);
     	     	//	system('open ' . $appFolder);

      		}
      		$db = null;
	    } catch(PDOException $e) { echo $e->getMessage(); }
	

$brokenImageMessage = count($brokenImages) == 0 ? ' with no broken images' : ' with the following broken images => ' . join (', ', $brokenImages);

kdebug('Building completes for apps ' . join(', ', $argv) . $brokenImageMessage);


// create new app-folder with code/resources from current folder

// copy app-specific content into app-folder

// copy Info.plist into app-folder

// rename xcode file with app-name

// open xcode with project file?  open finder with static content at-hand?

?>
