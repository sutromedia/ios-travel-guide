#!/usr/local/php5/bin/php
<?php

$print_to_stdout = 1;

$session = array();
$session['userid'] = 1;
$session['username'] = "kevin@sutroproject.com";
$session['user_firstname'] = "Kevin";
$session['user_lastname'] = "Collins";

//ini_set('include_path', '.:php:/usr/local/php5/lib/php:/usr/local/lib/php:/home/tobinfisher/pear/PEAR');

setlocale(LC_CTYPE, "UTF8", "en_US.UTF-8");

$con = null;
$sessionCookieName = "sutromedia_session";

/*
require_once 'util.php';
require_once 'sync.php';
require_once '../admin/db.php';
require_once '../../sutromedia.com/mail.php';
*/

processAuthorizedRequest($session);

function processAuthorizedRequest($session) {
  global $imagesToResync;

  $con = mysql_connect('mysql.motientmedia.com','stats_readonly','plym0uth', true);
  if (!$con) die('Could not connect to database: ' . mysql_error());

  mysql_select_db("sutroproject", $con);

  // resync app icons 

  $result = mysql_query('SELECT apple_app_id, name, app_name, upclose_apps.id AS app_id FROM upclose_apps, itunes_accounts WHERE upclose_apps.itunes_account_id = itunes_accounts.id AND upclose_apps.status_id IN (35, 38) AND apple_app_id <> 0 AND apple_app_id IS NOT NULL ORDER BY name');

  $allSutroAppIds = array();
  $allAppleAppIds = array();

  $sutroAppIds = array();
  $appleAppIds = array();
  $appNames = array();

  $numRows = mysql_num_rows($result); $counter = 0;
  $counter = 1;
  while($row = mysql_fetch_array($result)) {

    array_push($allSutroAppIds, (int) $row['app_id']);  
    array_push($allAppleAppIds, (int) $row['apple_app_id']);  
    if(empty($appleAppIds[stripslashes($row['name'])])) {
      $appleAppIds[$row['name']] = array();
      $sutroAppIds[$row['name']] = array();
      $appNames[$row['name']] = array();
    }     

    array_push($sutroAppIds[stripslashes($row['name'])], (int) $row['app_id']);
    array_push($appleAppIds[stripslashes($row['name'])], (int) $row['apple_app_id']);
    array_push($appNames[stripslashes($row['name'])], stripslashes($row['app_name']));
  }
    

  foreach(array_keys($appleAppIds) as $name)
  echo '
Apple App Ids for ' . $name . ' account => ' . join (', ', $appleAppIds[$name]) . ' (sutro app ids => ' . join(' ', $sutroAppIds[$name]) . ')
';


  echo '
==========

All Apple App Ids are => ' . join(', ', $allAppleAppIds) . '

All Sutro App Ids are => ' . join(' ', $allSutroAppIds) . '

';
//Apple App Ids for ' . $name . ' account => ' . join (', ', $appleAppIds[$name]) . '(aka' . $name . ' account => ' . join (', ', $appNames[$name]) . ')

}
?>