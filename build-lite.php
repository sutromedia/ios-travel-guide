#!/usr/bin/php

<?php
    
	//TF - Change to specific number to use an older version of the code
    $svnRevisionNumber = 2062;
    //$svnRevisionNumber = (int) getSubversionRevisionNumber();
	
	//Set whether we want to automatically install app on simulator and create distribution build
	$doAutoInstall = TRUE;
	
	//Sets if the app content is synced before content is downloaded. This should be set to true for most app store submissions
	$syncContent = TRUE;
    
    //** Set sizes of different types of content **
	//Total of 50 mb allowed
    $overheadSize = 5000; ////3 mb for binary and 2 mb extra room to play it safe
	$maxContentSize = 50000 - $overheadSize;
    $mapContentSize = 10000;
    //$iconPhotoContentSize = 10000; //not used at the moment, as we just add icon photos until we hit the max
    
	
    date_default_timezone_set('America/Los_Angeles');
    
    $ch = curl_init();
    
    function kdebug($message) 
    {
        echo date('Y/m/d H:i:s') . ': ' . $message . '
        ';
    }
    
    function disk_usage_kilobytes($d, $depth = NULL) {
        
        $command = "du -sk " . escapeshellarg($d);
        $retVal  = exec($command);
        $usage = split("\t", $retVal);
        //  kdebug("disk_usage_kilobytes returning <" . $usage[0] . "> for folder $d");
        return (int) $usage[0];
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
        $ctx = stream_context_create(array('http' => array('timeout' => 300)));
        
        $appSyncURL = 'http://sutroproject.com/admin-lite/remote-sync-apps.php?appids=' . $appId;
        kdebug('Syncing server content for App ID = ' . $appId . ', url = ' . $appSyncURL);
        $syncOutput = file_get_contents($appSyncURL, 0, $ctx);
        
        while(strpos($syncOutput, 'App syncing succeeds for all apps') === FALSE) 
        {
            kdebug('Syncing server content failed for App ID = ' . $appId . ', url = ' . $appSyncURL . ' - sleeping and retrying.. Output => 
                   ' . $syncOutput);
                   sleep(120);
                   $syncOutput = file_get_contents($appSyncURL);
                   }
                   kdebug('Syncing server content succeeds for App ID = ' . $appId);
                   }
                   
                   function download100pxPhoto($photoId, $photoFolder, $appContentFolder) {
                   $filename = $photoId . '_x100.jpg';
                   $url = 'http://sutromedia.com/published/dynamic-photos/height/100/' . $photoId . '.jpg';
                   $archivedFile = $photoFolder . $filename;
                   $appInstallFile = $appContentFolder . $filename;
                   
                   if(file_exists($archivedFile) && jpeg_file_is_corrupted($archivedFile)) unlink($archivedFile); // if identification fails 
                   
                   downloadFile($url, $appInstallFile, $archivedFile);
                   
                   
                   return jpeg_file_is_corrupted($archivedFile);
                   }
                   
                   function download1024pxPhoto($photoId, $photoFolder, $appContentFolder) {
                   $filename = $photoId . '_768.jpg';
                   $url = 'http://sutromedia.com/published/ipad-sized-photos/' . $photoId . '.jpg';
                   $archivedFile = $photoFolder . $filename;
                   $appInstallFile = $appContentFolder . $filename;
                   
                   if(file_exists($archivedFile) && jpeg_file_is_corrupted($archivedFile)) unlink($archivedFile); // if identification fails 
                   
                   downloadFile($url, $appInstallFile, $archivedFile);
                   
                   
                   return jpeg_file_is_corrupted($archivedFile);
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
                   
                   function tile2path($tilex, $tiley, $zoom) {                                                                                                                                                                                                                                                                                 
                   return "$zoom/$tilex/$tiley.png";                                                                                                                                                                                                                                                                                   
                   }
                   
                   function downloadMapTile($urlPrefix, $zoom, $row, $col, $allMapTilesFolder) {
                   $filename = tile2path($col, $row, $zoom);
                   $url = 'http://' . $urlPrefix . $filename;
                   $archivedFile = $allMapTilesFolder . $filename;
                   
                   if(!file_exists(dirname($archivedFile))) mkdir(dirname($archivedFile), 0777, true);
                   
                   // 12/16/2011 kevin removing for png map tiles => if(file_exists($archivedFile) && jpeg_file_is_corrupted($archivedFile)) unlink($archivedFile); // if identification fails 
                   
                   downloadFile($url, null, $archivedFile);
                   
                   return $archivedFile;
                   
                   }
                   
                   function downloadFile($url, $installFile, $archivedFile) {
                   global $ch;
                   
                   $tmpFile = ($installFile ? $installFile : $archivedFile) . '.tmp';
                   
                   if(!file_exists($archivedFile) || filesize($archivedFile) == 0) 
                   {
                   if(file_exists($installFile)) unlink($installFile);
                   if(file_exists($tmpFile)) unlink($tmpFile);
                   
                   kdebug('Downloading ' . $url . ', to ' . $archivedFile);
                   
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
                   
                   if(!empty($installFile))link($archivedFile, $installFile);
                   
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
				   
				   if ($syncContent) syncApp($appId);
                   else echo("\n\n******************************************\n\n  ******** APP SYNCING OFF ************\n\n******************************************\n\n");
                   
                   
                   $allAppsFolder = '../app-installs/';
                   if(! file_exists($allAppsFolder)) mkdir($allAppsFolder);
                   
                   $allPhotosFolder = '../480-sized-photos/';
                   if(! file_exists($allPhotosFolder)) mkdir($allPhotosFolder);
                   
                   $allIPadPhotosFolder = '../1024-sized-photos/';
                   if(! file_exists($allIPadPhotosFolder)) mkdir($allIPadPhotosFolder);
                   
                   $allContentFolder = '../content/';
                   if(! file_exists($allContentFolder)) mkdir($allContentFolder);
                   
                   $appFolder = $allAppsFolder . $appId;
                   $contentFolder = $allContentFolder . $appId;
                   
                   rmDashRF($contentFolder);
                   rmDashRF($appFolder);
                   
                   if(file_exists($appFolder)) deleteDirectory($appFolder);
                   
                   //system('svn export . ' . $appFolder);      
                   //system('svn export -r 1792 -q . ' . $appFolder);
				   kdebug('svn export -r ' . $svnRevisionNumber . ' -q . ' . $appFolder);
                   system('svn export -r ' . $svnRevisionNumber . ' -q . ' . $appFolder);
                   
				   
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
				   system('convert ' . escapeshellarg($screenshotFolder . '/Icon_512x512.png') . ' -resize 1024x1024! ' . escapeshellarg($screenshotFolder . '/Icon_1024x1024.png')); 
				   
                   
                   $dbFile = $appFolder . '/' . $appId . ' Static Content/content.sqlite3';
                   kdebug('dbFile = ' . $dbFile);
                   try {
                   $db = new PDO('sqlite:' . $dbFile);
                   $db->exec('DELETE FROM app_properties WHERE key = "svn_revision"');
                   $db->exec('INSERT INTO app_properties (key, value) VALUES ("svn_revision", ' . $svnRevisionNumber . ')');
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
				   
				   //Get the 1024 icon
				   $appIconPhotoId = $appProperties['app_icon_photo_id'];
				   echo ("app icon ID = ".$appIconPhotoId."\n");
				   $appIconJPG = $screenshotFolder . '/' . $appIconPhotoId . '_1024.jpg';
				   echo ("app icon jpg = ".$appIconJPG."\n");
				   $appIconPNG = $screenshotFolder . '/Icon_1024x1024.png';
				   echo ("app icon png = ".$appIconPNG."\n");
				   
				   $downloadStatus = download1024pxPhoto($appIconPhotoId, $allIPadPhotosFolder, $screenshotFolder);
				   if($downloadStatus) array_push($brokenImages, $appIconPhotoId);
				   else {
				   echo("Download unsuccessful\n");
				   system('convert ' . escapeshellarg($appIconJPG) . ' -resize 1024x1024! ' . escapeshellarg($appIconPNG)); 
				   }

                  
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
                   
				   // ****** Delete offline media folder *********
				   $dirPath = $staticContentFolder . "/offline-media/";
				   echo ("directory = " . $dirPath . "\n");
				   $files = glob($dirPath . '*', GLOB_MARK);
				   foreach ($files as $file) unlink($file);
				   //foreach ($files as $file) echo($file . "\n");
				   

				   rmdir($dirPath);

                   
				   // ****** Download and populate offline map database ***********
				   
				   $allMapTilesFolder = '../map-tile-cache-take2/' . $appProperties['map_tile_url_prefix'];
                   if(! file_exists($allMapTilesFolder)) mkdir($allMapTilesFolder, 0777, true);
                   
                   $offlineMapDB = $staticContentFolder . '/offline-map-tiles.sqlite3';
                   $db2 = new PDO('sqlite:' . $offlineMapDB);
                   $db2->exec('ALTER TABLE tiles ADD COLUMN downloaded INTEGER');
                   $result = $db2->query('SELECT COUNT(1) AS row_count FROM TILES');
                   foreach($result as $row) $db2->exec('INSERT INTO preferences (name, value) VALUES ("initial_tile_row_count", ' . (int) $row['row_count'] . ')');
                   
                   $result = $db2->query('SELECT * FROM tiles WHERE zoom <= 16'); // download tiles for top N rows
                   foreach($result as $row) 
                   {
                   if (disk_usage_kilobytes($offlineMapDB) > $mapContentSize) break;
                   $imageFile = downloadMapTile($appProperties['map_tile_url_prefix'], (int) $row['zoom'], (int) $row['row'], (int) $row['col'], $allMapTilesFolder);
                   $imageFD = fopen($imageFile, 'r');
                   $q = $db2->prepare('UPDATE tiles SET image = ?, downloaded = 1 WHERE tilekey = ' . (int) $row['tilekey']);
                   $q->bindParam(1, $imageFD, PDO::PARAM_LOB);
                   $q->execute();
                   fclose($imageFD);
                   }
                   
                   //     		        $db2->exec('UPDATE tiles SET image = NULL');
                   
                   //			$db2->exec('VACUUM');
                   
                   /*			
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
                    $db2->exec('UPDATE tiles SET image = NULL WHERE zoom > 14');
                    $db2->exec('UPDATE tiles SET downloaded = 1 WHERE zoom <= 14');
                    $result = $db2->query('SELECT COUNT(1) AS row_count FROM TILES');
                    foreach($result as $row) $db2->exec('INSERT INTO preferences (name, value) VALUES ("initial_tile_row_count", ' . (int) $row['row_count'] . ')');
                    
                    $db2->exec('VACUUM');
                    }
                    */
                   
                   
                   // generate splash screens... now on the client
                   
                   echo 'about to generate splash screens...
                   ';
                   $srcSplashFilename = $appFolder . '/' . $appId . ' Static Content/Default.jpg';
                   $iPhoneSplashFilename = $appFolder . '/' . $appId . ' Static Content/Default.png';
                   $iPadSplashFilename = $appFolder . '/' . $appId . ' Static Content/Default-Portrait.png';
				   $iPhone5SplashFilename = $appFolder . '/' . $appId . ' Static Content/Default-568h.png';
                   
                   echo 'about to run... convert ' . escapeshellarg($srcSplashFilename) . ' -resize 640x960! -depth 7 -quality 80% ' . escapeshellarg($iPhoneSplashFilename) . '
                   ';
                   system('convert ' . escapeshellarg($srcSplashFilename) . ' -resize 640x960! -depth 7 -quality 80% ' . escapeshellarg($iPhoneSplashFilename));
                   echo 'about to run... convert ' . escapeshellarg($srcSplashFilename) . ' -resize 768x1024! -depth 7 -quality 80% ' . escapeshellarg($iPadSplashFilename) . '
                   ';
                   system('convert -limit area 512mb -limit memory 512mb -limit map 512mb ' . escapeshellarg($srcSplashFilename) . ' -resize 768x1024! -depth 7 -quality 80% ' . escapeshellarg($iPadSplashFilename));
				   
				   system('convert -limit area 512mb -limit memory 512mb -limit map 512mb ' . escapeshellarg($srcSplashFilename) . ' -resize 640x1136! -depth 7 -quality 80% ' . escapeshellarg($iPhone5SplashFilename));
                   
                   echo 'splash screens generated... removing splash screen source file
                   ';
                   if(file_exists($srcSplashFilename)) unlink($srcSplashFilename);
                   
                   //var_dump($appProperties);
                   $buildSyncLevel = (int) $appProperties['build_sync_level'];
                   kdebug('found build_sync_level property = ' . $buildSyncLevel);
                   if($buildSyncLevel > 0) 
                   {
                   kdebug('buildSyncLevel > 0');
                   
                   
                   //***** add 100px icon photos *****
                   
                   $results2 = $db->query('SELECT DISTINCT(icon_photo_id) AS photoid FROM entries ORDER BY name');
                   $entryIconPhotoIdsOrderByEntryName = array();
                   foreach($results2 as $row2) 
                   {
                   array_push($entryIconPhotoIdsOrderByEntryName, $row2['photoid']);
                   $downloadStatus = download100pxPhoto($row2['photoid'], $allPhotosFolder, $appFolder . '/' . $appId . ' Static Content/images/');
                   if($downloadStatus) array_push($brokenImages, $row2['photoid']);
                   }
                   
                   $db->exec('UPDATE photos SET downloaded_x100px_photo = 1 WHERE rowid IN (SELECT icon_photo_id FROM entries)');
                   
                   
                   //***** Add 2000 additional icon photos *****
                   
                   $results2 = $db->query('SELECT DISTINCT(rowid) as photo_id FROM photos WHERE downloaded_x100px_photo IS NULL LIMIT 1500');
               
                   foreach($results2 as $row2) {
                   
                    $photoId = $row2['photo_id'];
                   if (disk_usage_kilobytes($appFolder . '/' . $appId . ' Static Content/') > $maxContentSize) break;
                    $downloadStatus = download100pxPhoto($photoId, $allPhotosFolder, $appFolder . '/' . $appId . ' Static Content/images/');
                    if($downloadStatus) array_push($brokenImages, $photoId);
                    else {$db->exec('UPDATE photos SET downloaded_x100px_photo = 1 WHERE rowid ='.$photoId);
                    //echo 'Adding 100 pix photo for '.$photoId."\n";
                    }
                    
                   }
                   
                   
                   //***** add 768px photos for the intro entries *****
                   
                   $results2 = $db->query('SELECT DISTINCT(icon_photo_id) AS photoid FROM entries, groups WHERE entries.rowid = groups.intro_entry_id');
                   $introIconPhotoIds = array();
                   foreach($results2 as $row2) 
                   {
                   array_push($introIconPhotoIds, $row2['photoid']);
                   $downloadStatus = download1024pxPhoto($row2['photoid'], $allIPadPhotosFolder, $appFolder . '/' . $appId . ' Static Content/images/');
                   if($downloadStatus) array_push($brokenImages, $row2['photoid']);
                   }
                   
                   $db->exec('UPDATE photos SET downloaded_768px_photo = 1 WHERE rowid IN (' . implode(',', $introIconPhotoIds) . ')');
                   
                   
                   //***** add 768px photo for the main intro entry *****
                   
                   //$result = $db->query('SELECT value FROM app_properties WHERE key = "top_level_intro_entry_id"');
                   $result = $db->query('SELECT icon_photo_id as value FROM entries WHERE rowid = (SELECT value as value from app_properties WHERE key = "top_level_intro_entry_id")');
                   
                   foreach ($result as $row3) {
                   $photoId = $row3['value'];
                   $downloadStatus = download1024pxPhoto($photoId, $allIPadPhotosFolder, $appFolder . '/' . $appId . ' Static Content/images/');
                   if($downloadStatus) array_push($brokenImages, $photoId);
                   
                   else $db->exec('UPDATE photos SET downloaded_768px_photo = 1 WHERE rowid ='.$photoId);
                   }
                   
                   
                   //***** Add as many icon photos as possible until the folder hits the max content size *****
                   $results2 = $db->query('SELECT DISTINCT(icon_photo_id) FROM entries, photos WHERE icon_photo_id = photos.rowid');
                   $iconPhotoCount = 0;
                   //$maxNumberOfIconPhotos = 200;
                   foreach($results2 as $row2) 
                   {
                   $iconPhotoCount ++;
                   $photoId = $row2['icon_photo_id'];
                   if (disk_usage_kilobytes($appFolder . '/' . $appId . ' Static Content/') > $maxContentSize){
                    echo "Hit size limit adding icon photos after " . $iconPhotoCount . " photos \n";
                    break;
                   }
                   $downloadStatus = downloadPhoto($photoId, $allPhotosFolder, $appFolder . '/' . $appId . ' Static Content/images/');
                   if($downloadStatus) array_push($brokenImages, $photoId);
                   else {$db->exec('UPDATE photos SET downloaded_320px_photo = 1 WHERE rowid ='.$photoId);
                    //echo 'Adding 320 pix photo for '.$photoId."\n";
                   }
                   //if($iconPhotoCount > $maxNumberOfIconPhotos) break;
                   }
                   
                   
                
                   //***** Get screen shots *****
                   $iPhoneScreenshotPhotoIds = explode(',', $appProperties['iphone_screenshot_ordering']);
                   
                   $screenshotCounter = 1;
                   
                   foreach($iPhoneScreenshotPhotoIds as $iPhoneScreenshotPhotoId) 
                   {
					$imageFilename = $screenshotFolder . '/' . $screenshotCounter .'-iphone' . '.jpg';
					downloadFile('http://sutromedia.com/published/ipad-sized-photos/' . $iPhoneScreenshotPhotoId . '.jpg', $imageFilename, $allPhotosFolder . '/' . $iPhoneScreenshotPhotoId . '_iphone_retinal_screenshot.jpg');
					$imageSize = getimagesize($imageFilename);
					if((int)$imageSize[0] != 640) system('convert ' . escapeshellarg($imageFilename) . ' -resize 640x960! -depth 7 -quality 100% ' . escapeshellarg($imageFilename)); 
					$screenshotCounter++;
                   }
                   
                   copy($iPhoneSplashFilename, $screenshotFolder . '/Default.jpg');
				   
				   //Convert the splash screenshot from jpg to png in order to deal with weirdness from iTunesConnect in not accepting the jpg
				   $convertCommand = 'convert ' . $screenshotFolder . '/Default.jpg ' . $screenshotFolder . '/Default.png';
				   system($convertCommand);
				   
				   $deleteFileCommand = ' rm ' . $screenshotFolder . '/Default.jpg';
				   system($deleteFileCommand);
                   
                   $iPadScreenshotPhotoIds = explode(',', $appProperties['ipad_screenshot_ordering']);
                   
                   $screenshotCounter = 1;
                   foreach($iPadScreenshotPhotoIds as $iPadScreenshotPhotoId) 
                   {
                   downloadFile('http://sutromedia.com/published/ipad-sized-photos/' . $iPadScreenshotPhotoId . '.jpg', $screenshotFolder . '/' . $screenshotCounter++ .'-ipad'.'.jpg', $allPhotosFolder . '/' . $iPadScreenshotPhotoId . '_ipad_screenshot.jpg');
                   }
                   
                   }
                   
                   //****** Compile a distribution build *****
                   if ($doAutoInstall) {
				   kdebug("Building distribution version of ".$appId."\n"); 
				   $originalDir = getcwd();
				   
				   chdir($appFolder);
				   $buildConfiguration = $iTunesAccountName."_Distribution";
				   
                   //Version to use on iMac with xCode 4.5 installed
                   //$buildCommand = 'xcodebuild clean build -sdk iphoneos6.0 -configuration ' . $buildConfiguration . ' -project ' . $cleanProductName . '.xcodeProj';
                   
                   //Version to use on Mac Mini - looks like this version might work for all configurations and be more robust
                   $buildCommand = 'xcodebuild clean build -configuration ' . $buildConfiguration . ' -project ' . $cleanProductName . '.xcodeProj';
                   
				   kdebug($buildCommand);
				   ksystem($buildCommand); 
				   
				   $lastDirectory = getcwd(); //we'll need to go back here after zipping to build the simulator version
				   
                   
				   //Need to zip before building the simulator version as building the sim version overwrites the distribution version
				   kdebug("Zipping distribution version of ".$appId."\n");
				   $distAppFilePath = '../' . $appFolder . '/build/'.$buildConfiguration.'-iphoneos/' . $cleanProductName . '.app';
				   kdebug("distAppFilePath = " . $distAppFilePath);
				   $distAppFile = realpath($distAppFilePath);
				   kdebug("real path = " . $distAppFile);
				   $distAppParentFolder = realpath(dirname($distAppFile));
				   kdebug("distAppFolder = " . $distAppParentFolder);
				   
				   chdir($distAppParentFolder);
				   
				   kdebug("Command = zip -y -r " . $cleanProductName . ".zip " . $cleanProductName . ".app");
				   
				   ksystem('zip -r ' . $cleanProductName . '.zip ' . $cleanProductName . '.app');
				   
				   
				   //Move file to centralized upload directory
				   $filesForUpload = dirname($originalDir).'/app-installs/_apps-to-upload';
				   
				   if(! file_exists($filesForUpload)) mkdir($filesForUpload);
				   
				   $accountFolder = $filesForUpload.'/'.$iTunesAccountName;
				   if(! file_exists($accountFolder)) mkdir($accountFolder);
				   
				   rename($cleanProductName.'.zip', $accountFolder."/".$cleanProductName.'.zip');
				   
				   chdir($lastDirectory);
				   
				   kdebug("Building simulator version of ".$appId."\n");
				   
                   //Version to use on iMac with xCode 4.5 installed
				   ksystem('xcodebuild clean install -target SutroWorld -sdk iphonesimulator7.0 -arch i386 -configuration Debug_copy -project ' . $cleanProductName . '.xcodeProj');
				   
				   kdebug("Installing ".$appId." in simulator with ios-sim \n");
				   kdebug('Path = build/Debug-iphonesimulator/' . $cleanProductName . '.app');
				   //kdebug('Realpath = '.realpath('/Users/tobin1/Dropbox/Sutro\ Project/iPhone\ Guides/app-installs/3/build/Debug-iphonesimulator/' . $cleanProductName . '.app '));
				   $command = 'ios-sim launch ../'.$appFolder.'/build/Debug_copy-iphonesimulator/' . $cleanProductName . '.app --exit > /dev/null &';
				   kdebug("Command = ".$command);
				   ksystem($command);
				   
				   chdir($originalDir);
				
				   }

                   
                   kdebug("Building completes for ".$appId."\n");
                   }
                   
                   $db = null;
                   } catch(PDOException $e) { echo $e->getMessage(); }
					
                }
            }
                   
        $brokenImageMessage = count($brokenImages) == 0 ? ' with no broken images' : ' with the following broken images => ' . join (', ', $brokenImages);
                   
        kdebug('Building completes for apps ' . join(', ', $argv) . $brokenImageMessage);
                   
    ?>
