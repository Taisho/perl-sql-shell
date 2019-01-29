#!/bin/perl

use DBI;
use Text::Table;
use Term::ReadLine;   # Do not "use Term::ReadLine::Gnu;"
use strict;

use Credentials;
my %creds = get_credentials("SQL-SHELL");

my $dbh = DBI->connect('dbi:mysql:database='.$creds{database}.';host='.$creds{host}, $creds{user}, $creds{pass}, { RaiseError => 2, PrintError => 1, AutoCommit => 1});
my $term = new Term::ReadLine 'SQShell';
$term->AddHistory("SELECT * FROM shellHistory LIMIT 2");

my ($dbname) = $dbh->selectrow_array("select DATABASE()");
#TODO Get database name from the DBI handler
#TODO Try/Catch SQL statements
#DONE Support less as paginator
#DONE Put border around table cells
    #FIXME Borders look "fizzy" around table corners. Fix that
#TODO Store and retreive command line history like Bash does it.
#TODO Filter command lines for specific queries like "USE dbname" which will change the database.
    #This should reflect the database name in the prompt, for example.
#TODO Allow for multiple queries to be specified, like the stock MySQL shell (using ';' as delimiter)
#TODO Implement custom non-SQL commands like 'status', 'exit', etc.
#FIXME Don't call pager when exit is called

while ( defined (my $cmd = $term->readline('SQL ['.$dbname.']> ')))
{
    #print $cmd;
    #print "\n";
    #next;

    open(my $fhPager, "| less -Sin");

    my $sth = $dbh->prepare($cmd);
    $sth->execute();
    #print $sth->rows . "\n";
    my @header;

    foreach my $col (@{$sth->{NAME}})
    {
        push @header, \' | ', $col;
    }
    push @header, \' | ';

    my $table = Text::Table->new(@header);

    while(my $row = $sth->fetchrow_arrayref)
    {
        $table->load($row);
    }

    print $fhPager $table->rule('-', '+');
    my @headerLines = $table->title;
    foreach my $line (@headerLines)
    {
        #print $fhPager $table->rule('-', '+');
        print $fhPager $line;
    }
    print $fhPager $table->rule('-', '+');

    my @lines = $table->body;
    foreach my $line (@lines)
    {
        #print $fhPager $table->rule('-', '+');
        print $fhPager $line;
    }

    print $fhPager $table->rule('-', '+');
    close ($fhPager);

    print "\n";
}
