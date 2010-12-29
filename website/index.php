<?php
	$page_title = "Development Page";
	$page_topic = "The Transfusion Project";
	$page_links = array (
		"About" => array ("Address" => "#about-section", "Text" => "About this page"),
		"News" => array ("Address" => "#news-section", "Text" => "News"),
		"Links" => array ("Address" => "#links-section", "Text" => "Useful links"),
		"Contacts" => array ("Address" => "#contacts-section", "Text" => "Contacts")
	);

	require ("header.php");
?>

<!-- About -->
<div class="section">
	<h2 id="about-section" class="section">About this page</h2>
	This website is the home of the Transfusion Project development. Please, go to
	<a href="http://www.transfusion-game.com/">our main website</a> for
	general information about the project.<br />
</div>

<!-- News -->
<div class="section">
	<h2 id="news-section" class="section">News</h2>
	<ul>
		<li>
			<span class="title">December 29, 2010:</span> (by Elric)<br />
			Our RFF unpacker now has support for RFF format 3.0, used on the original
			Blood CD, thanks to recent works by Barry Duncan. You can find the source
			code and the Win32 binary of this new version (0.2) in the
			<a href="snapshots.php#rebuild-section">ReBUILD snapshots</a>, as usual.<br />
			The section devoted to the RFF file format on our <a href="rebuild.php">ReBUILD page</a>
			has also been corrected and updated accordingly.<p />
		</li>
		<li>
			<span class="title">November 21, 2010:</span> (by Elric)<br />
			Our Blood-to-BUILD map conversion tool Blud2B has finally reached
			version 1.0. Aside from a lot of code cleaning, this new version adds support
			for the unencrypted Blood map format (6.3), used by BB9.<br />
			Blud2B source code and Win32 binary are part of
			the <a href="snapshots.php#rebuild-section">ReBUILD snapshots</a>.<p />
		</li>
		<li>
			<span class="title">December 18, 2006:</span> (by Elric)<br />
			The project now uses Subversion (SVN) as its version control system.<p />
		</li>
		<li>
			<span class="title">July 12, 2005:</span> (by Elric)<br />
			GroupSPR has been updated to version 1.0, with support for DarkPlaces' SPR32 format.<p />
		</li>
	</ul>
</div>

<!-- Useful links -->
<div class="section">
	<h2 id="links-section" class="section">Useful links</h2>
	<ul>
		<li>
			Home page: <?php ExplicitURL ("http://www.transfusion-game.com/"); ?><p />
		</li>
		<li>
			SourceForge page: <?php ExplicitURL ("http://sourceforge.net/projects/blood/"); ?><p />
		</li>
		<li>
			Mailing lists: <?php ExplicitURL ("http://sourceforge.net/mail/?group_id=22136"); ?><p />
		</li>
		<li>
			SVN repository: <?php ExplicitURL ("http://sourceforge.net/svn/?group_id=22136"); ?><p />
		</li>
		<li>
			DarkPlaces home page: <?php ExplicitURL ("http://icculus.org/twilight/darkplaces/"); ?><p />
		</li>
	</ul>
</div>

<!-- Contacts -->
<div class="section">
	<h2 id="contacts-section" class="section">Contacts</h2>
	You can find the list of all team members on our main website.<br />
	The Transfusion Project has also a mailing list:
	<a href="mailto:blood-devel (at) lists.sourceforge.net">blood-devel at lists dot
	sourceforge dot net</a>. It is quite programming oriented, but we don't
	mind other Transfusion related topics. A part of its traffic is made of SVN
	update messages that are automatically send each time our code base is
	updated. All mails are archived, and the "Mailing lists" link at the
	beginning of this page allows you to browse them or to subscribe to the
	blood-devel list.<br />
	Finally, you can join <a href="irc://irc.anynet.org/transfusion">our IRC
	channel</a> (#transfusion on "irc.anynet.org") for some interactive
	discussions.<br />
</div>

<br />
<br />

<?php
	require ("footer.php");
?>
