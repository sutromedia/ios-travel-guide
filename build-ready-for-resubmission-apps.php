#!/usr/bin/php

<?php

$appIdData = json_decode(file_get_contents('http://sutroproject.com/admin/remote-list-apps-by-status.php?status_id=35'));

$sutroAppIds = array();

foreach($appIdData as $appData) array_push($sutroAppIds, $appData->{'sutro_app_id'});

system('php build.php ' . join(' ', $sutroAppIds));

?>
