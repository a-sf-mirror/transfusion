<?php
	$page_title = "The ReBUILD Project";
	$page_topic = "The ReBUILD Project";
	$page_cvs = "rebuild";
	$page_links = array (
		"Introduction" => array ("Address" => "#introduction-section", "Text" => "Introduction"),
		"Downloads" => array ("Address" => "#downloads-section", "Text" => "Downloads")
	);

	require ("header.php");
?>

<!-- Introduction -->
<div class="section">
	<h2 id="introduction-section" class="section">Introduction</h2>
	ReBUILD is a project founded in August 2000 by Timothy Hale and Mathieu Olivier,
	with the valuable help of Greg Enright of <a href="bloodsource.php">the BloodSource
	campaign</a>. Those 3 fans of <a href="http://blood.lith.com/">Monolith Productions'
	3D-shooter Blood</a> wanted to revitalize/modernize the editing tools for
	<a href="http://www.advsys.net/ken/build.htm">BUILD</a>, the engine on which Blood
	is based, and to gather <a href="bloodsource.php#techinfo-section">technical
	informations</a> about Blood, so people would have a set of good tools to work with
	when the Blood source code would finally be released.<br />
	<br />
	At this time, Ken Silverman had just released the source code of his BUILD engine,
	and so many people thought the Blood source code release was a matter of weeks.
	Unfortunately, this release didn't happen. Timothy, Mathieu and Greg then decided to
	move on and founded qBlood (now known as
	<a href="http://transfusion.deathmask.net/">the Transfusion Project</a>) in March 2001.
	As a consequence, there isn't much activity on ReBUILD nowadays, although the project
	isn't officially dead. If you want to get support or information about the ReBUILD
	Project, contact Timothy Hale or Mathieu Olivier via the Transfusion Project.<br />
</div>

<!-- Downloads -->
<div class="section">
	<h2 id="downloads-section" class="section">Downloads</h2>
	The utilities marked with an empty dot are now maintained in the Transfusion project's
	CVS tree and are the only ones that are really supported. Their source codes and binaries
	can be found <a href="snapshots.php#rebuild-section">here</a>. Below is the complete list
	of the utilities the ReBUILD Project has created or modified:<br />
	<br />
	<span class="boldtitle">Tools released under the
	<a href="http://www.gnu.org/copyleft/gpl.html">GNU GPL</a></span> (source code and Win32
	binaries are in the ZIP files)<br />
	<ul>
		<li style="list-style-type: circle;">
			<a href="snapshots.php#rebuild-section">The ART tools</a> - 2 tools and their
			documentation to convert ART files into a series of TGA pictures, and the opposite
		</li>
		<li style="list-style-type: circle;">
			<a href="snapshots.php#rebuild-section">RFF</a> - Allows you to read RFF files
			and to extract their contents. Supports Version 2.0 and 3.1 RFF files
		</li>
		<li style="list-style-type: circle;">
			<a href="snapshots.php#rebuild-section">Sfx2Wav</a> - Convert a SFX/RAW pair into
			a WAV file
		</li>
		<li style="list-style-type: circle;">
			<a href="snapshots.php#rebuild-section">Blud2B</a> - This will take an encrypted
			Blood map, and convert it to a plain BUILD map
		</li>
		<li>
			<a href="files/loader.zip">Blood Loader</a> - Blood launcher with a nice GUI and
			many options
		</li>
		<li>
			<a href="files/wart2tga.zip">Windows art to tga converter</a> - Win32 GUI version
			of Art2Tga
		</li>
		<li>
			<a href="files/winbarf.zip">WinBarf</a> - Win32 GUI version of RFF
		</li>
		<li>
			<a href="files/xtract.zip">Xtract</a> - Art and map extraction utility for GRP
			packages. Closed source program "dukeconv" included (BUILD->Quake map converter)
		</li>
		<li>
			<a href="files/episodes.zip">Episodes</a> - INI file generator for Blood
		</li>
	</ul>
	<br />
	<span class="boldtitle">Tools released under the
	<a href="http://www.advsys.net/ken/build.htm">BUILD</a> license</span> (source code and Win32
	binaries are in the ZIP files)<br />
	<ul>
		<li>
			<a href="files/ktools.zip">KTools</a> - Kextract and Kgroup Win32 binaries.
			Handle BUILD group files (*.GRP)
		</li>
		<li>
			<a href="files/convmap.zip">BUILD map converters</a> - converts between
			map version 5, 6 and 7
		</li>
	</ul>
	<span class="boldtitle">Other goodies</span> (no source code here)<br />
	<ul>
		<li>
			<a href="files/palette.zip">palette.dat (zipped)</a> - Blood's palette file.
			Some BUILD or Blood utilities out there require it
		</li>
		<li>
			<a href="files/wtga2art.zip">Windows tga to art converter</a> - Win32 GUI version
			of Tga2Art. You need the animdata.ini file if you intend to use animations.
			Create your own art files!
		</li>
		<li>
			<a href="files/wsfx2wav.zip">Windows Sfx2Wav utility</a> - Win32 GUI version of
			Sfx2Wav. You need to have all your raw/sfx files in the same directory.
			Single file selection only with this release
		</li>
	</ul>
	Finally, you may want to take a look at Timothy Hale's web page
	<a href="http://www.planetduke.com/convertcentral/mapconverter.html">at Convert Central</a>.
	You'll find several other conversion tools there.<br />
</div>

<br />
<br />

<?php
	require ("footer.php");
?>
