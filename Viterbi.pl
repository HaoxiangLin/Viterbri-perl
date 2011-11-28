#Viterbi algorithm implementation in Perl
use strict;
open(FE,$ARGV[0]);
my  @lines=<FE>;
my @biword = ();
my %wordwithtagfreq = ();
my %tagfreq = ();
my %tagwithtag = ();
my @tags = ();
my @words = ();
my @eqword = ();
my %bifreq = ();
my %startprob = ();
my %transprob = ();
my %emisprob = ();


#form word/tag
for my $line(@lines)
{
        chomp($line);
        $line=lc($line);
        @biword=split " ",$line;
	my @tempwordtag = ();
	for my $biwordin (0..$#biword)
	{
		$biword[$biwordin] =~ s/(.*)(\/)(.*)/$1 $3/g;
		@tempwordtag = split(" ",$biword[$biwordin]);
		push(@words,$tempwordtag[0]);
		if(exists $tagfreq{$tempwordtag[1]})
		{
			$tagfreq{$tempwordtag[1]} = $tagfreq{$tempwordtag[1]} + 1;
		}
		else
		{
			$tagfreq{$tempwordtag[1]} = 1;
		}
		if(exists $wordwithtagfreq{$tempwordtag[0]}{$tempwordtag[1]})
		{
			$wordwithtagfreq{$tempwordtag[0]}{$tempwordtag[1]} = $wordwithtagfreq{$tempwordtag[0]}{$tempwordtag[1]} + 1;
		}
		else
		{
			$wordwithtagfreq{$tempwordtag[0]}{$tempwordtag[1]} = 1;
		}
		if($biwordin == 0)
		{
			if(exists $tagwithtag{'<s>'}{$tempwordtag[1]})
			{
				$tagwithtag{'<s>'}{$tempwordtag[1]} = $tagwithtag{'<s>'}{$tempwordtag[1]}+1;
			}
			else
			{
				$tagwithtag{'<s>'}{$tempwordtag[1]} =  1;
			}
			
		}
		else
		{
			$biword[$biwordin-1] =~ s/(.*)(\/)(.*)/$1 $3/g;
			my @prvarray = split(" ",$biword[$biwordin-1]);
			if(exists $tagwithtag{$prvarray[1]}{$tempwordtag[1]})
                        {
                                $tagwithtag{$prvarray[1]}{$tempwordtag[1]} = $tagwithtag{$prvarray[1]}{$tempwordtag[1]}+1;
                        }
                        else
                        {
                                $tagwithtag{$prvarray[1]}{$tempwordtag[1]} =  1;
                        }

		}		

	}
}
my %seen = ();
my @uniqwords = grep { ! $seen{$_}++ } @words;

sub startprob
{
	my $tagcount = 0;
	foreach my $key (keys %tagfreq)
	{
		$tagcount = $tagcount + $tagfreq{$key};	
	}
	foreach my $key (keys %tagfreq)
	{
		$startprob{$key} = $tagfreq{$key}/$tagcount;
	}
}

sub transprob
{
	foreach my $key1 (keys %tagfreq)
	{
		foreach my $key2 (keys %tagfreq)
		{
			$transprob{$key1}{$key2} = $tagwithtag{$key1}{$key2}/$tagfreq{$key1};
		}
	}

}

sub emisprob
{
	foreach my $tag (keys %tagfreq)
	{
		foreach my $word(@uniqwords)
		{
			$emisprob{$tag}{$word} = $wordwithtagfreq{$word}{$tag}/$tagfreq{$tag};
		}
	}
}



#print scalar(@words)."\n";
#print scalar(@uniqwords)."\n";
#Run on Test Data
print "Started Training\n";
print "calling start probabilities\n";
&startprob();

print "calling trans probabilities\n";
&transprob();
&emisprob();

print "Finished Training\n";


sub rettagseq()
{
	my @wordseq = @_;
	my @viterbi = ();
	my %path = ();
	my @states = keys %tagfreq;
	#initialize viterbihash
	foreach my $y (@states)
	{

		$viterbi[0]{$y} = $startprob{$y}*($emisprob{$y}{$wordseq[0]}+0.00000001);
		$path{$y} = [$y];
	}
	#Run Viterbi for t > 0
	foreach my $t (1..$#wordseq)
	{
		my %newpath = ();
		foreach my $y (@states)
		{
			my %probtable = ();
			foreach my $ya (@states)
			{
				my $computeval = $viterbi[$t-1]{$ya} * ($transprob{$ya}{$y}+0.00000001) * ($emisprob{$y}{$wordseq[$t]}+0.000000001);
				$probtable{$ya} = $computeval;
			}
			my @sorted =  sort {$probtable{$b} <=> $probtable{$a}} keys %probtable;
			my $state = $sorted[0];
			my $prob = $probtable{$state};
			$viterbi[$t]{$y} = $prob;
			my @tempe=@{$path{$state}};
			push(@tempe,$y);
			$newpath{$y} = \@tempe;
		}
		%path = %newpath;
	} 
	my $max = 0;
	my $finalstate = "";
	foreach my $y (@states)
	{
		
		if($viterbi[$#wordseq]{$y} >= $max)
		{
			$max = $viterbi[$#wordseq]{$y};
			$finalstate = $y;
		}
	}
	#print "\n";
	my $ecount = 1; 
	my @prdtags = @{$path{$finalstate}};
	foreach my $x (@{$path{$finalstate}})
	{
#		print "tag".$ecount." ".$x."\n";
		$ecount++;
	}
	return @prdtags;

}


print "Starting Testing\n Takes approximately few minutes for running on sentences\n Wait..\n"; 

open(TE,$ARGV[1]);
unlink($ARGV[2]);
open (MYFILE, ">>$ARGV[2]");
my @lines=<TE>;
my $totaltags = 0;
my $totcorrtags = 0;
foreach my $line (@lines)
{
	chomp($line);
        $line=lc($line);
        @biword=split " ",$line;
	my @wordseq =();
	my @tagseq = ();
        my @tempwordtag = ();
	foreach my $biwordin (0..$#biword)
        {
		$biword[$biwordin] =~ s/(.*)(\/)(.*)/$1 $3/g;
		@tempwordtag = split(" ",$biword[$biwordin]);
		push(@wordseq,$tempwordtag[0]);
		push(@tagseq,$tempwordtag[1]);
		
	}
	my $wordlen= @wordseq;
	my @prdtags = &rettagseq(@wordseq);
	$totaltags = $totaltags+$wordlen;
	
	foreach my $index (0..$#prdtags)
	{
		if($prdtags[$index] eq $tagseq[$index])
		{
			$totcorrtags++;
		}
		print MYFILE $wordseq[$index]."/".$prdtags[$index]." ";
	}
	print MYFILE "\n";
}
my $accuracy = ($totcorrtags/$totaltags)*100;
print "Finished tagging\n";
print "Writing Output to file".$ARGV[2]."\n";
print "Accuracy=".$accuracy."%\n";	
close(TE);
close(MYFILE);


