#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
#hashes and counters
my %hashForward;
my %hashReverse;
my $counter = 1;
#extracting file from bundle
my $genome = "/pine/scr/a/l/ludwig19/Genomes/test/"; #where genomes are
opendir(my $directory, $genome) || die "$genome failed to open";
my @file_list = readdir $directory;
closedir $directory;
#########################################################################################
#pulling fna files to correct location
foreach my $x (@file_list) {
	system("cp /pine/scr/a/l/ludwig19/Genomes/test/$x/$x.genes.fna /pine/scr/a/l/ludwig19/positive_selection");
}
my $temp = "/pine/scr/a/l/ludwig19/positive_selection";
opendir(my $f, $temp) || die "$temp failed to open"; 
my @genome_list = grep{/\.fna$/} readdir $f;
close $f;
#file_list now contains the correct number of genomes and should simplify the process
#########################################################################################
#extracting fna file from numeric file
my $ocounter = 1;
my $icounter = 0;
mkdir (join ("", "batch-holder", $ocounter));
chdir (join ("","batch-holder",$ocounter));
#system("mkdir batch-holder" . $
#system("cd batch-holder" . $ocounter);
open(FILE, ">ANIfile" . $ocounter) || die("ANIfile failed to open");
print FILE ("#!/bin/bash\n#SBATCH -N 1\n#SBATCH -n 1\n#SBATCH --mem 8000\n#SBATCH -J ANIPIPE\n");
foreach my $x (@file_list) {
	system("cp /pine/scr/a/l/ludwig19/Genomes/test/$x/$x.genes.fna /pine/scr/a/l/ludwig19/positive_selection/batch-holder" . $ocounter);
}
foreach my $fna1 (@genome_list) {
	foreach my $fna2 (@genome_list) {
		my $f = "$fna1$fna2";
		my $r = "$fna2$fna1";
		if ($fna1 eq $fna2) {
			#do nothing
		}
		else{
			if($fna1 eq $fna2){
				#do nothing
			}
			if($f eq $r || exists $hashForward{$f} || exists $hashReverse{$f}){
				#do nothing
			} 
			else{
				my $cmd = "ANIcalculator -genome1fna $fna1 -genome2fna $fna2 -outfile out--$fna1--$fna2--out";
				print FILE ($cmd . "\n");
				$hashForward{$f} = $counter;
				$hashReverse{$r} = $counter;
				$counter = $counter + 1;
				$icounter = $icounter + 1;
				if($icounter == 1){
					system("sbatch ANIfile" . $ocounter);
					$ocounter = $ocounter + 1;
					$icounter = 0;
					close FILE;
					chdir "../";
					mkdir (join ("", "batch-holder", $ocounter));
					chdir (join ("","batch-holder",$ocounter));
					open(FILE, ">ANIfile" . $ocounter);
					print FILE ("#!/bin/bash\n#SBATCH -N 1\n#SBATCH -n 1\n#SBATCH --mem 8000\n#SBATCH -J ANIPIPE\n");
					foreach my $x (@file_list) {
						system("cp /pine/scr/a/l/ludwig19/Genomes/test/$x/$x.genes.fna /pine/scr/a/l/ludwig19/positive_selection/batch-holder" . $ocounter);
					}				
				}
			}
		}
	}
}
system("sbatch ANIfile" . $ocounter);
chdir ("../");
close FILE;
#########################################################################################
#determine when all batch files are eone
my $loop = 1;
while ($loop){
	system("squeue -u ludwig19 -h > sleep");
	my $filename = "sleep";
	open(my $sleep, '<:encoding(UTF-8)', $filename);
	while(my $row = <$sleep>){
		if(index($row, "ANIPIPE") == -1){
			$loop = 0;
		}
		else{
			$loop = 1;
			last;
		}
	}	
	close $sleep;
	sleep(20);
}
###########################################################################################

##making page that contains values
my %anihash;
open(PRINTABLE, ">ANIDB.txt");
print PRINTABLE ("Genomes" . "\t\t\t");
foreach my $var (@genome_list){
	print PRINTABLE ($var . "\t");
}
#print PRINTABLE ("\n");
#create list of out--fna1--fna2--out
my $dir = "/pine/scr/a/l/ludwig19/positive_selection";
opendir($directory, $dir) || die("$dir won't open");
my @batch_list = grep{/batch-holder/} readdir $directory;
close $directory;
#create hash that contains [fna1, fna2] as a key and gANI as a value
#foreach my $batch (@batch_list){
#	opendir(my $batch_open, $batch) || die("$batch failed to open");
#	my @out = grep {/^out/} readdir $batch_open;  #contains ANI files
#	closedir($batch_open);
#	chdir("$batch");
#	foreach my $iterO (@out){
#		my @outsplit = split /--/, $;
#		#my @outarray = ($outsplit[1], $outsplit[2]);
#		open(ANIFILE, "<", $out) || die("$out DNE");
#		while ($var = <ANIFILE>)
#			if($var[0:6] eq "GENOME1"){
#				continue;
#			}
#			else{
#				my @ANIsplit = split /\t/, $var;	
#			}
#	$anihash{@outarray} = $outsplit[2];
#	}
#}
#Creating hash of hashes for ANI output
############################################################################################


foreach my $iter1 (@genome_list){
	print PRINTABLE ("\n$iter1\t");
	foreach my $iter2 (@genome_list){
		foreach my $batch (@batch_list){
			opendir(my $batch_open, $batch) || die("$batch failed to open");
			my @out = grep {/^out/} readdir $batch_open;  #contains ANI files
			closedir($batch_open); 
			chdir("$batch");
			foreach my $Oiter (@out){
				my @outsplit = split /--/, $Oiter; #remember these are strings
				my @outarray = ($outsplit[1], $outsplit[2]);
				if (($iter1 eq $outarray[0] && $iter2 eq $outarray[1]) || ($iter1 eq $outarray[1] && $iter2 eq $outarray[0])){
					open(my $ANIfile, "<", $Oiter) || die("$Oiter DNE");
					while (my $var = <$ANIfile>){
						my @attempt = split /\t/, $var;
						if($attempt[0] eq "GENOME1"){
							next;
						}
						else{
							print PRINTABLE ("$attempt[2]\t\t\t");
						}
					}
				}
				elsif ($iter1 eq $iter2){
					print PRINTABLE ("1\t\t\t");
					last;
				}
			}
			chdir("../");
			if($iter1 eq $iter2){
				last;
			}
		}
	}
}
close PRINTABLE;
