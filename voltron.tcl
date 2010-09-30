# Usage: 
# tclsh ./voltron.tcl ./yourconfig

# author: Olexandr Sydorchuk

proc showHelp {} {
    puts "Usage: $::argv0 filename"
}

if {$::argc != 1} {
    showHelp
    exit
}
set config_file [lindex $::argv 0]

#----------------------------------------
# init default vars
#----------------------------------------
set bind_keys {1 2 3 4 5 6 7 8 9 0 - =}

set fileSplitSize 16000

# you can redefine this var in your cfg
set menu_spectator_tmpl "    rect 6 210 400 190
    visible 1
    decoration
    forecolor 45 45 45 1
    textscale 0.25
    autowrapped
    textstyle ITEM_TEXTSTYLE_SHADOWED"

set menu_alien_tmpl $menu_spectator_tmpl
set menu_human_tmpl $menu_spectator_tmpl

set chatmenu_teama "chatmenu_alien.cfg"
set chatmenu_teamb "chatmenu_human.cfg"
set chatmenu_spect "chatmenu_spec.cfg"
set binds_install "chatmenu_install.cfg"
set binds_teama_install "chatmenu_alien_install.cfg"
set binds_teamb_install "chatmenu_human_install.cfg"
set binds_spect_install "chatmenu_spect_install.cfg"

set backspace_cmd "play sound/misc/menu4.wav"

# other usefull default bind
set postInstall "
seta cg_tutorial 0

vstr menu0

bind \"v\" \"vstr +flash\"
bind \"\]\" \"vstr Volt_vol+\"
bind \"\[\" \"vstr Volt_vol-\"
bind \\ \"set s_volume 0.0; set Volt_vol- vstr Volt_vol+-; set Volt_vol+ vstr Volt_vol01;  echo ^2Sound ^2Volume ^2|^1^3**********^2| (Muted);\"

set +flash \"vstr flash05;\"
set flash05 \"set r_lightmap 1; set cg_flashlight 1;play sound/misc/menu3; set +flash vstr flash06;\"
set flash06 \"set r_lightmap 0;set cg_flashlight 2;play sound/misc/menu3; set -flash vstr flash05; set +flash vstr flash05;\"
set Volt_vol- \"vstr Volt_vol03;\"
set Volt_vol+ \"vstr Volt_vol05;\"
set Volt_vol+- \"set s_volume 0.0; set Volt_vol- vstr Volt_vol+-; set Volt_vol+ vstr Volt_vol01; echo ^2Sound ^2Volume ^2|^1^3**********^2| (Muted);s_volume;\"
set Volt_vol01 \"set s_volume 0.2; set Volt_vol- vstr Volt_vol+-; set Volt_vol+ vstr Volt_vol02; echo ^2Sound ^2Volume ^2|^1*^3*********^2|;s_volume;\"
set Volt_vol02 \"set s_volume 0.4; set Volt_vol- vstr Volt_vol01; set Volt_vol+ vstr Volt_vol03; echo ^2Sound ^2Volume ^2|^1**^3********^2|;s_volume;\"
set Volt_vol03 \"set s_volume 0.6; set Volt_vol- vstr Volt_vol02; set Volt_vol+ vstr Volt_vol04; echo ^2Sound ^2Volume ^2|^1***^3*******^2|;s_volume;s_volume;\"
set Volt_vol04 \"set s_volume 0.8; set Volt_vol- vstr Volt_vol03; set Volt_vol+ vstr Volt_vol05; echo ^2Sound ^2Volume ^2|^1****^3******^2| (Default);s_volume;\"
set Volt_vol05 \"set s_volume 1.0; set Volt_vol- vstr Volt_vol04; set Volt_vol+ vstr Volt_vol06; echo ^2Sound ^2Volume ^2|^1*****^3*****^2|;s_volume;\"
set Volt_vol06 \"set s_volume 1.2; set Volt_vol- vstr Volt_vol05; set Volt_vol+ vstr VOlt_vol07; echo ^2Sound ^2Volume ^2|^1******^3****^2|;s_volume;\"
set Volt_vol07 \"set s_volume 1.4; set Volt_vol- vstr Volt_vol06; set Volt_vol+ vstr Volt_vol08; echo ^2Sound ^2Volume ^4|^1*******^3***^4|;s_volume;\"
set Volt_vol08 \"set s_volume 1.6; set Volt_vol- vstr Volt_vol07; set Volt_vol+ vstr Volt_vol09; echo ^2Sound ^2Volume ^2|^1********^3**^2|;s_volume;\"
"
# return 1 if element in list
proc in {list element} {expr [lsearch -exact $list $element] >= 0}

#----------------------------------------
# create msg list and bind to key
# @varname - q3 variable name (you can bind to him: bind KEY "vstr VARNAME")
# @f_source - source file of msg (line with # is comment)
# @f_dest - script name of generated file
# @execpath - path where to script in quake space (like ui/hus/common/msg.cfg)
# @prefix - prefix for msg, it will be added to each msg
# @sufix - sufix for msg
# @command - command for message (default `say`)
#----------------------------------------
# msgexec contain varname source file  and execpath for msg file
variable msgexec {}
proc messages-from-file {varname f_source f_dest execpath {prefix {}} {sufix {}} {command {"say"}}} {
    global msgexec config_file
    catch {file mkdir [file dirname  $f_dest]}
    if {![file exist $f_source]} {
	set f_s [file join [file dirname $config_file] $f_source]
	if {![file exist $f_s]} {
	    puts "Error: Message file not found: $f_source"
	    exit
	} else {
	    set f_source $f_s
	}
    }
    set fs [open $f_source r]
    set fd [open $f_dest w]
    lappend msgexec $varname
    lappend msgexec $f_source
    lappend msgexec $execpath
    puts "==> Build msg list $f_dest from $f_source"
    set i 1
    puts $fd "// generated by [file tail $::argv0]  from [file tail $f_source]"
    puts $fd {}
    puts $fd "set ${varname} \"vstr ${varname}1\"" 
    puts $fd {}

    set msg {}
    while {![eof $fs]} {
	set text [gets $fs]
	# skip space comment
	if [regexp {^\s*$} $text] {
	    continue
	}
	# skip comments
	if [regexp {^\s*#.*$} $text] {
	    continue
	}
	if {$msg != ""} {
	    puts $fd "$msg set ${varname} vstr ${varname}$i\""
	}
	set msg "set ${varname}$i \"$command $prefix$text$sufix;"

	incr i
    }
    puts $fd "$msg set ${varname} vstr ${varname}1\""
    puts $fd "// end."
    close $fs
    close $fd
}

#----------------------------------------
# quake like unbind
#----------------------------------------
proc unbind  {key} {
    global unbinds
    lappend unbinds $key
}

#----------------------------------------
# Team specified binds
# usage:
#  unbindTeams key team_list
#
# where team list may be:
# ali, alien, a, 1 -- alien team
# hum, human, b, 2 -- human team
# spec, spectator, 3 -- spectator team
# Example unbind `v` key for ali and hum only
# unbindTeams v {alien human}; 
#----------------------------------------
proc unbindTeams  {key teams} {
    global team_unbinds
    set team_unbinds($key) $teams
}

#----------------------------------------
# quake like bind
#----------------------------------------
proc bind  {key command} {
    global binds
    set binds($key) $command
}

#----------------------------------------
# Team specified binds
# usage:
# bindTeams key {
#     commandForAll
#     commandForTeamA
#     commandForTeamB
#     commandForTeamSpec
# }
#----------------------------------------
proc bindTeams  {key binds} {
    global team_binds
    set team_binds($key) $binds
}

proc split-file {filename fileSplitSize} {
    global config_file
    if {[file size $filename] > $fileSplitSize} {
	puts "File [file tail $filename] is too large, will be split."
	set s [split [file tail $filename] .]
	set fname {}
	# get name w/o extension
	for {set i 0} {$i < [expr [llength $s] -1]} {incr i} {
	    set fname $fname[lindex $s $i]
	}
	set extension [file extension $filename]

	set fid [open $filename r]
	
	set i 1

	set fod [open [file join [file dirname $filename] \
			  $fname$i$extension] w]
	# size of cirrent split file
	set fsize 0
	while {![eof $fid]} {
	    set data [gets $fid]
	    if {$fsize > [expr $fileSplitSize - \
			      [string length $data]]} {
		# file is full, need create new
		close $fod
		incr i
		set fod [open [file join [file dirname $filename] \
				   $fname$i$extension] w]
		set fsize 0
	    }
	    # copy data
	    puts $fod $data
	    incr fsize [string length $data]
	    # when puts called than \r\n is added need correct it
	    incr fsize
	}
	close $fod	
	close $fid
		
	set fod [open $filename w]
	puts $fod "// generated by [file tail $::argv0] from [file tail $config_file]\n"
	puts $fod "// This file was bigger $fileSplitSize bytes, so it was splitted by $i files"
	puts $fod "// load splitted files"
	set quakebase  {}
	# usually users scripts is in base dir
	regexp {^.*/base/(.*)} [file dirname $filename] -> quakebase
	if {$quakebase != ""} {
	    set quakebase $quakebase/
	}
	for {set fn 1} {$fn <= $i} {incr fn} {
	    puts $fod "exec \"${quakebase}$fname$fn$extension\""
	}
	close $fod
    }
}

# you can source file inside config now
lappend auto_path [file dirname $config_file]

#----------------------------------------
# load cfg file
source $config_file
#----------------------------------------

# open files
set chatTeamA [open $chatmenu_teama w]
set chatTeamB [open $chatmenu_teamb w]
set chatTeamSpec [open $chatmenu_spect w]

#----------------------------------------
# == NOW GENERATE ==
#----------------------------------------

puts "==> Generate menu:"
puts "Hud file: $chatmenu_teama"
puts "Hud file: $chatmenu_teamb"
puts "Hud file: $chatmenu_spect"

# == root menu ==
#clear team index
set i 0
# each team
foreach {fh tmpl}  " $chatTeamA menu_alien_tmpl 
		    $chatTeamB menu_human_tmpl 
		    $chatTeamSpec menu_spectator_tmpl" {
    set template [eval "set $tmpl"]
    puts $fh "// generated by [file tail $::argv0] from [file tail $config_file]\n"
    puts $fh "// Root chat menu"
    puts $fh "itemDef\n\{"
    puts $fh "    name \"menuRoot\""
    puts $fh $template
    puts $fh "    cvartest cg_chatmenu"
    puts $fh "    showCvar \{ mroot \}"
    set text {"Sub Menus:\n"}
    foreach x $bind_keys {
	if {![info exist $x.]} { continue }
    	set val [eval "set $x."]
    	if {$val == ""} { continue }

	set teamMenu [lindex [lindex $val 0] 0]
	set teamMenu $teamMenu[lindex [lindex $val [expr $i*2+2]] 0]
	if {$teamMenu != ""} {
	    set text "$text\n      \"$x. $teamMenu\\n\""
	}
    }
    puts $fh "    text  $text"
    puts $fh "\}\n"

    incr i
}

# == other menus ==
# clear index
set i 0
# each team
foreach {fh tmpl}  " $chatTeamA menu_alien_tmpl 
		    $chatTeamB menu_human_tmpl 
		    $chatTeamSpec menu_spectator_tmpl" {
    set template [eval "set $tmpl"]

    foreach x $bind_keys {
	set text {}
	set found no
	# take menu header from root level as second params
	if {[info exist $x.]} {
	    set val [eval "set $x."]
	    if {$val != ""} {
		set text [lindex [lindex $val 0] 1]
		set text "\"$text[lindex [lindex $val [expr $i*2+2]] 1]\\n\""
	    }
	}
	
	# menu items
	foreach y $bind_keys {
	    if {![info exist $x.$y.]} { continue }
	    set val [eval "set $x.$y."]
	    if {$val == ""} { continue }
	    set teamMenu [lindex $val 0]
	    set teamMenu $teamMenu[lindex $val [expr $i*2+2]]
	    if {$teamMenu != ""} {
		set text "$text\n      \"$y. $teamMenu\\n\""
		set found yes
	    }
	}
	if {!$found} {
	    continue
	}
	puts $fh "// menu for $x key"
	puts $fh "itemDef\n\{"
	puts $fh "    name \"menu$x\""
	puts $fh $template
	puts $fh "    cvartest cg_chatmenu"
	puts $fh "    showCvar \{ menu$x \}"
	puts $fh "    text  $text"
	puts $fh "\}\n"
    }
    incr i
}

close $chatTeamA
close $chatTeamB
close $chatTeamSpec

# == exec scripts ==
set fh_m [open $binds_install w]
set fh_a [open $binds_teama_install w]
set fh_b [open $binds_teamb_install w]
set fh_s [open $binds_spect_install w]

puts "==> Generate exec scripts:"
proc puts2All {text} {
    global fh_m fh_a fh_b fh_s
    puts $fh_m $text
    puts $fh_a $text
    puts $fh_b $text
    puts $fh_s $text
}

puts "EXEC script for all: $binds_install"
puts "EXEC script team a: $binds_teama_install"
puts "EXEC script team b: $binds_teamb_install"
puts "EXEC script team s: $binds_spect_install"
puts2All "// Generated by [file tail $::argv0] from [file tail $config_file]\n"
foreach x $bind_keys {
    puts2All "seta n$x \"\""
}
puts2All ""
foreach x $bind_keys {
    puts2All "bind \"$x\" \"vstr n$x\""
}

puts2All "bind \"BACKSPACE\" \"vstr RootMenu;$backspace_cmd\""
puts2All ""
puts2All "seta cg_chatmenu \"mroot\""

# gen root menu cmds
set rootmenu {}
foreach x $bind_keys {
    if {[info exist $x.]} {
	set val [eval "set $x."]
	# substitude strings
	eval set rootmenuCMD \"[lindex $val 1]\"
	eval set rootmenuCMDA \"[lindex $val 3]\"
	eval set rootmenuCMDB \"[lindex $val 5]\"
	eval set rootmenuCMDS \"[lindex $val 7]\"
	puts $fh_m "seta m0n$x \"$rootmenuCMD;$rootmenuCMDA;$rootmenuCMDB$rootmenuCMDS;vstr menu$x\""
	puts $fh_a "seta m0n$x \"$rootmenuCMD;$rootmenuCMDA;vstr menu$x\""
	puts $fh_b "seta m0n$x \"$rootmenuCMD;$rootmenuCMDB;vstr menu$x\""
	puts $fh_s "seta m0n$x \"$rootmenuCMD;$rootmenuCMDS;vstr menu$x\""
	set rootmenu "${rootmenu}set n$x vstr m0n$x; "
    } else {
	set rootmenu "${rootmenu}set n$x -1; "
    }    
}

puts2All "\nseta RootMenu \"set cg_chatmenu mroot; $rootmenu\""
puts2All ""

# gen submenus cmds
foreach x $bind_keys {
    if {![info exist $x.]} {
	# no root menu, skip this key than
	continue;
    }
    puts2All ""
    puts2All "// key $x"
    set menuX {}
    foreach y $bind_keys {
	set menuX "${menuX}set n$y vstr m${x}k${y}; "
	if {[info exist $x.$y.]} {
	    set val [eval "set $x.$y."]
	    eval set menuCMD \"[lindex $val 1]\"
	    eval set menuCMDA \"[lindex $val 3]\"
	    eval set menuCMDB \"[lindex $val 5]\"
	    eval set menuCMDS \"[lindex $val 7]\"
	    puts $fh_m "seta m${x}k${y} \"$menuCMD;$menuCMDA;$menuCMDB;$menuCMDS;vstr RootMenu;\""
	    puts $fh_a "seta m${x}k${y} \"$menuCMD;$menuCMDA;vstr RootMenu;\""
	    puts $fh_b "seta m${x}k${y} \"$menuCMD;$menuCMDB;vstr RootMenu;\""
	    puts $fh_s "seta m${x}k${y} \"$menuCMD;$menuCMDS;vstr RootMenu;\""
	} else {
	    puts2All "seta m${x}k${y} \"\""
	}
    }
    puts2All "\nseta menu$x \"set cg_chatmenu menu$x; $menuX\""
}

puts2All "\n// boot"
puts2All "vstr RootMenu"

puts2All "\n// other binds"
puts2All $postInstall

puts2All ""

# unbinds before binds
if [info exist unbinds] {
    if {[llength $unbinds] > 0} {
	puts2All "// user's unbinds"
	foreach key $unbinds {
	    puts2All "unbind \"$key\""
	}
	puts2All ""
    }
}

# teams specified unbinds
set team_keys [array names team_unbinds]
if {[llength $team_keys] >0} {
    puts2All "// team specified unbinds"
    foreach key $team_keys {
	set ali no
	set hum no
	set spec no
	foreach team $team_unbinds($key) {
	    if [in "ali alien a 1" $team] {
		set ali yes
	    }
	    if [in "hum human b 2" $team] {
		set hum yes
	    }
	    if [in "spec spectator 3" $team] {
		set spec yes
	    }
	}
	if $ali {
	    puts $fh_a "bind $key"
	}
	if $hum {
	    puts $fh_b "bind $key"
	}
	if $spec {
	    puts $fh_s "bind $key"
	}
    }
    puts2All "// end team specified keys"
    puts2All ""
}

# binds
set keys [array names binds]
if {[llength $keys] > 0} {
    puts2All "// user's binds"
    foreach key $keys {
	puts2All "bind \"$key\" \"$binds($key)\""
    }
    puts2All ""
}

# teams specified binds
set team_keys [array names team_binds]
if {[llength $team_keys] >0} {
    puts2All "// team specified binds"
    foreach tb $team_keys {
	set key [lindex [split $tb :] 0]
	eval set cmdAll \"[lindex $team_binds($tb) 0]\"
	eval set cmdTeamA \"[lindex $team_binds($tb) 1]\"
	eval set cmdTeamB \"[lindex $team_binds($tb) 2]\"
	eval set cmdSpec \"[lindex $team_binds($tb) 3]\"
	puts $fh_m "bind $key \"$cmdAll;$cmdTeamA;$cmdTeamB;$cmdSpec\""
	puts $fh_a "bind $key \"$cmdAll;$cmdTeamA\""
	puts $fh_b "bind $key \"$cmdAll;$cmdTeamB\""
	puts $fh_s "bind $key \"$cmdAll;$cmdSpec\""
    }
    puts2All "// end team specified keys"
    puts2All ""
}
# msg file
foreach {var src exec} $msgexec {
    puts2All "// msg list from [file tail $src], variable for vstr: $var"
    puts2All "exec $exec"
}

close $fh_m
close $fh_a
close $fh_b
close $fh_s

# do split files
split-file $chatmenu_teama $fileSplitSize
split-file $chatmenu_teamb $fileSplitSize
split-file $chatmenu_spect $fileSplitSize
split-file $binds_install $fileSplitSize
split-file $binds_teama_install $fileSplitSize
split-file $binds_teamb_install $fileSplitSize
split-file $binds_spect_install $fileSplitSize