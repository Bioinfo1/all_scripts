#!/usr/bin/perl -w

=head1 NAME

reorder_multi_fasta_karyotype.pl - This script takes the whole genome as a single fasta file and creates a database of the Fasta file, and outputs multi-fasta file in the query order.

=head1 AUTHOR

Mani Mudaliar

Glasgow Polyomics, University of Glasgow
 
22 December 2014

=cut

use strict;
use diagnostics;
use Getopt::Long;
use Pod::Usage;
use Pod::Checker;
use Bio::DB::Fasta;
use Bio::SeqIO;

my $inFasta;
my $fastaHeader;
my $outFasta;
my $header;
my $VERBOSE = 1;
my $DEBUG = 0;
my $help;
my $man;

GetOptions (
	'in=s'      => \$inFasta,
	'head=s'    => \$fastaHeader,
	'out=s'     => \$outFasta,
	'verbose!'  => \$VERBOSE,
	'debug!'    => \$DEBUG,
	'man'       => \$man,
	'help|?'    => \$help,
) or pod2usage();

pod2usage(-verbose => 2) if ($man);
pod2usage(-verbose => 1) if ($help);
pod2usage(-msg => 'Please supply a valid input fasta filename.') unless ($inFasta && -s $inFasta);
pod2usage(-msg => 'Please supply a valid fasta headers filename.') unless ($fastaHeader && -s $fastaHeader);
pod2usage(-msg => 'Please supply a valid output fasta filename.') unless ($outFasta);

my $tempFasta = "temp.fasta";
my $db = Bio::DB::Fasta->new($inFasta);

open (OUTFILE, ">$outFasta") or die "Cannot open $outFasta to write.\n";
open (TEMPFILE, ">$tempFasta") or die "Cannot open $tempFasta to write.\n";
open (IDFILE, "<$fastaHeader") or die "Cannot open $fastaHeader to read.\n";

while (<IDFILE>){
	chomp; 
	$header = $_;	
	my($seq_id, $rest) = split(/\s/, $_, 2);
	my $sequence = $db->seq($seq_id);
	if  (!defined($sequence)) {
		die "Sequence $header not found. \n" 
	}   
	print TEMPFILE ">$header\n", "$sequence\n";
}

close (TEMPFILE);

my $seqio_object = Bio::SeqIO->new(-file => $tempFasta, -format => 'Fasta');
my $seqio_out = Bio::SeqIO->new('-format' => 'Fasta','-fh' => \*OUTFILE);

while (my $seq_object = $seqio_object->next_seq()) {	
	$seqio_out->write_seq($seq_object);		
	}

close(IDFILE);
close(OUTFILE);
unlink($tempFasta) or die "Could not delete $tempFasta file!\n";

=head1 SYNOPSIS

perl reorder_multi_fasta_karyotype.pl --in <input fasta file> --head <input fasta headers text file - sorted> --out <output fasta file> [--verbose|--no-verbose] [--debug|--no-debug] [--man] [--help]

=head1 DESCRIPTION

This script takes the whole genome as a single fasta file and creates a database of the fasta sequences, create index of the fasta file for fast access, and outputs multi-fasta file in the query order. This script is useful to sort (Karyotype order) multi-fasta reference files downloaded from ENSEMBL. This script can be used to retrive canonical chromosomes in Karyotype order.

This script requires scafold (chromosome) numbers (one line per scafold number) in a separate text file ($fastaHeader). This can be generated from the $inFasta file as shown below.
 
#less Canis_familiaris.CanFam3.1.dna.toplevel.fa | grep -e '>' | sort -V >headers_karyotype_sorted.txt ($fastaHeader)

#vim headers_karyotype_sorted.txt

#:%s/>//g

#copy X and MT manualy and paste below 38

#gg

#dd X and MT

#:wq

=over 6

=item B<Output>

The output generated is a (multi-)fasta file with sequences ordered according to the supplied fasta header file

=back

=head1 OPTIONS

=over 6

=item B<--in>

Fasta file (e.g., whole genome reference fasta file downloaded from ENSEMBL) 

=item B<--head>

Scafold (chromosome) numbers (one line per scafold) in a separate text file.

=item B<--out>

Output fasta filename.

=item B<--verbose|--no-verbose>

Toggle verbosity. [default: verbose]

=item B<--debug|--no-debug>

Toggle debugging output. [default:none]

=item B<--help>

Brief help.

=item B<--man>

Full manpage of program.

=back

=cut

