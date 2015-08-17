#!/usr/bin/php

<?php


function downloadFile($url, $installFile) {

	 $tmpFile = $installFile . '.tmp';

    //if(file_exists($installFile)) unlink($archivedFile);
    //if(file_exists($tmpFile)) unlink($tmpFile);
    
    $ch = curl_init($url);
    $fp = fopen($tmpFile, "w");
    curl_setopt($ch, CURLOPT_FILE, $fp);
    curl_setopt($ch, CURLOPT_HEADER, 0);
    curl_exec($ch);
    curl_close($ch);
    fclose($fp);
    rename($tmpFile, $installFile);
	 
	// kdebug('link(' . $archivedFile . ', ' . $installFile . ')');
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
    
    
    /**
     * Function: sanitize
     * Returns a sanitized string, typically for URLs.
     *
     * Parameters:
     *     $string - The string to sanitize.
     *     $force_lowercase - Force the string to lowercase?
     *     $anal - If set to *true*, will remove all non-alphanumeric characters.
     */
    function sanitize($string, $force_lowercase = true, $anal = false) {
        $strip = array("~", "`", "!", "@", "#", "$", "%", "^", "&", "*", "(", ")", "_", "=", "+", "[", "{", "]",
                       "}", "\\", "|", ";", ":", "\"", "'", "&#8216;", "&#8217;", "&#8220;", "&#8221;", "&#8211;", "&#8212;",
                       "â€”", "â€“", ",", "<", ".", ">", "/", "?");
        $clean = trim(str_replace($strip, "", strip_tags($string)));
        $clean = preg_replace('/\s+/', "-", $clean);
        $clean = ($anal) ? preg_replace("/[^a-zA-Z0-9]/", "", $clean) : $clean ;
        return ($force_lowercase) ?
        (function_exists('mb_strtolower')) ?
        mb_strtolower($clean, 'UTF-8') :
        strtolower($clean) :
        $clean;
    }



    $link = mysql_connect("mysql.sutromedia.com", "stats_readonly", "plym0uth") or die(mysql_error());
    echo "Connected to MySQL...\n";
    mysql_select_db("sutroproject", $link) or die(mysql_error());
    
    //array_shift($argv);
    
    $query = 'SELECT id, app_name FROM upclose_apps WHERE id in (619, 736, 589)';
    
    $result = mysql_query($query);
    
    $appIds = array();
    
    while ($row = mysql_fetch_assoc($result)) {
        $appIds[] = $row['id'];
        //echo "Adding app with id =".$row['id']."\n";
    }

    
    foreach($appIds as $appId) {
        
        $query = "SELECT app_name FROM upclose_apps WHERE id =".$appId;
        
        $result = mysql_query($query);
        
        $appName = "";
        
        while ($row = mysql_fetch_assoc($result)) {
            $appName = $row['app_name'];
        }

       // echo 'Downloading images for ' . $appName . "\n";
    
        //date_default_timezone_set('America/Los_Angeles');
        //$date = date("Ymd");
        //$topImageFolder = "../../Icons_and_Splash_Screens/Source_Files";
        $iconAndSplashFolder = "../Icons_and_Splash_Screens";
        if(! file_exists($iconAndSplashFolder)) mkdir($iconAndSplashFolder);
        $sourceFileFolder = $iconAndSplashFolder."/Source_Files";
        if(! file_exists($sourceFileFolder)) mkdir($sourceFileFolder);
        
        $imageFolder = $sourceFileFolder.'/'.sanitize($appName);
        
        //echo($imageFolder."\n");
    
        rmDashRF($imageFolder);
    
        $query = 'SELECT photo_id from upclose_app_icon_candidates WHERE app_id ='.$appId;
    
        $result = mysql_query($query);
    
        // Check result
        // This shows the actual query sent to MySQL, and the error. Useful for debugging.
        if (!$result) {
            $message  = 'Invalid query: ' . mysql_error() . "\n";
            $message .= 'Whole query: ' . $query;
            die($message);
        }
    
        $imageIds = array();
    
        while ($row = mysql_fetch_assoc($result)) {
            $imageIds[] = $row['photo_id'];
        }
        
        // $imageId = 287026;
    
        foreach($imageIds as $imageId) 
        {
            //echo "downloading for ".$imageId."\n";
        
            downloadFile('http://www.sutroproject.com/images/sutro-identified/'.$imageId.'_1024.jpg', $imageFolder.'/'. $imageId.'.jpg');
        }
		
		// Add app and author name to a text file
		$result = mysql_query('SELECT upclose_users.firstname AS firstname, upclose_users.lastname AS lastname FROM upclose_users, upclose_app_users WHERE upclose_app_users.user_id = upclose_users.id AND app_id ='.$appId);
		
		$appInfo = "";
		
		/*$utf8Header="\xEF\xBB\xBF \n"; //used to make utf-8 formatting work
		$myFile = "App Info.txt";
		$fh = fopen($myFile, 'a') or die("can't open file");
		fwrite($fh, $utf8Header);
		fclose($fh);*/
   
    	while ($row = mysql_fetch_assoc($result)) {
      		$authorName = $row['firstname'].' '.$row['lastname'];
			
			if (strlen($appInfo) > 0) $appInfo = $appInfo.' and '.$authorName;
				
			else $appInfo = $appName.' by '.$authorName;
    	}
		
		$appInfo = $appInfo."\n\n";
		
		echo $appInfo;
		
		//Had problems with UTF-8 encoding and had to abandon this for now
		/*$fh = fopen($myFile, 'a') or die("can't open file");
		fwrite($fh, utf8_encode($appInfo));
		fclose($fh);
		*/
    }
    
    //** $db = null;
	
    mysql_close($link);
    
    echo "Downloading complete*********************\n";
    
    ?>
