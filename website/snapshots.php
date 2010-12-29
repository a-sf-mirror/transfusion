<?php
	$page_title = "Snapshots";
	$page_topic = "Snapshots";
	$page_links = array (
		"Transfusion" => array ("Address" => "#transfusion-section", "Text" => "Transfusion files"),
		"ReBUILD" => array ("Address" => "#rebuild-section", "Text" => "ReBUILD files"),
		"Other" => array ("Address" => "#other-section", "Text" => "Other files")
	);
	$snapshots_dir = "snapshots/";

	require ("header.php");
?>

<?php

	// Fill the "$files" array with all items from the snapshots directory (except dotfiles)
	$files = array ();
	if ($handle = opendir ($snapshots_dir)) {
		while ($file = readdir ($handle))
			if ($file{0} != ".")
				 $files[] = $file;

		closedir ($handle);
	}
	rsort ($files);


	// ----- PrintAndExtractFilesByVersion ----- //

	function PrintAndExtractFilesByVersion ($text, $filter) {
		global $files, $snapshots_dir;

		$remaining = array ();
		$ind = 0;

		reset ($files);
		foreach ($files as $file) {
			if (!strncmp ($filter, $file, strlen ($filter))) {
				if ($ind == 0) {
					echo ("<li><span class=\"boldtitle\">$text:</span>&nbsp; <a href=\"$snapshots_dir" . "$file\">$file</a> (" .
							(int)(filesize ($snapshots_dir . $file) / 1024) . " KB)");
				}
				else {
					// Compute the version (or timestamp)
					$filter_length = strlen ($filter);
					$version = substr ($file, $filter_length, strlen ($file) - $filter_length - 4);  // 4 = strlen (".zip")

					if ($ind == 1)
						echo (".\nOlder versions: <a href=\"$snapshots_dir$file\">$version</a>");
					else
						echo (", <a href=\"$snapshots_dir$file\">$version</a>");
				}
				$ind++;
			}
			else
				array_push ($remaining, $file);
		}

		if ($ind)
			echo ("<p />\n</li>\n");
		$files = $remaining;
	}


	// ----- PrintAndExtractFilesByFormat ----- //

	function PrintAndExtractFilesByFormat ($text, $filter) {
		global $files, $snapshots_dir;

		$remaining = array ();
		$ind = 0;

		reset ($files);
		foreach ($files as $file) {
			if (!strncmp ($filter, $file, strlen ($filter))) {
				$filter_length = strlen ($filter);
				$format = substr ($file, $filter_length + 1, strlen ($file) - $filter_length - 1);
				if ($ind == 0) {
					echo ("<li><span class=\"boldtitle\">$text:</span>&nbsp; $filter.{<a href=\"$snapshots_dir" . "$file\">$format</a>");
				}
				else {
					echo (", <a href=\"$snapshots_dir" . "$file\">$format</a>");
				}
				$ind++;
			}
			else
				array_push ($remaining, $file);
		}

		if ($ind)
			echo ("}<p />\n</li>\n");
		$files = $remaining;
	}


	// ----- PrintAllFiles ----- //

	function PrintAllFiles () {
		global $files, $snapshots_dir;

		sort ($files);
		reset ($files);
		foreach ($files as $file) {
			echo ("<li><a href=\"$snapshots_dir" . "$file\">$file</a> (" . (int)(filesize ($snapshots_dir . $file) / 1024) . " KB)</li>\n");
		}
	}

?>

<!-- Transfusion files -->
<div class="section">
	<h2 id="transfusion-section" class="section">Transfusion files</h2>
	<ul>
	<?php PrintAndExtractFilesByFormat ("Manual", "manual"); ?>
	<?php PrintAndExtractFilesByVersion ("Patch", "qblood-patch-"); ?>
	<?php PrintAndExtractFilesByVersion ("Game code", "qblood-progs-"); ?>
	<?php PrintAndExtractFilesByVersion ("Source code", "qblood-CVS-"); ?>
	<?php PrintAndExtractFilesByVersion ("Win32 binaries", "qblood-bin-win32-"); ?>
	<?php PrintAndExtractFilesByVersion ("Linux binaries", "qblood-bin-linux.i386-"); ?>
	<?php PrintAndExtractFilesByVersion ("Engine source code", "darkplaces-CVS-"); ?>
	</ul>
</div>

<!-- ReBUILD files -->
<div class="section">
	<h2 id="rebuild-section" class="section">ReBUILD files</h2>
	<ul>
	<?php PrintAndExtractFilesByVersion ("Win32 binaries", "rebuild-bin-win32-"); ?>
	<?php PrintAndExtractFilesByVersion ("Linux binaries", "rebuild-bin-linux.i386-"); ?>
	<?php PrintAndExtractFilesByFormat ("ART Tools HOWTO", "ART-Tools-HOWTO"); ?>
	<?php PrintAndExtractFilesByVersion ("Source code", "rebuild-src-"); ?>
	</ul>
</div>

<!-- Other files -->
<div class="section">
	<h2 id="other-section" class="section">Other files</h2>
	<ul>
	<?php PrintAllFiles (); ?>
	</ul>
</div>

<br />
<br />

<?php
	require ("footer.php");
?>
