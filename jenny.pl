#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use Jenkins;
use feature 'switch';

my $server_path = undef;
my $job = undef;
my $build_number = undef;

sub list_jobs {

	my $jenkins = Jenkins->new({
		server_path => $server_path
	});

	my $jobs = $jenkins->list_jobs();

	foreach my $job (@$jobs) {
		print $job->{'name'} . "\n";
	}

}

sub list_builds {
	my $jenkins = Jenkins->new({
		server_path => $server_path
	});

	my $builds = $jenkins->list_builds($job);

	if (!defined($builds)) {
		print "ERR: job not found: $job\n";
		exit 2;
	}

	foreach my $build (@$builds) {
		print $build->{'number'} . "\n";
	}

}

sub build_info {
	my $jenkins = Jenkins->new({
		server_path => $server_path
	});

	my $build = $jenkins->get_build_information($job, $build_number);

	print $build->{'result'} . "\n";

}

sub usage {
	print "Usage:\n";
	print "jenny.pl --server-path <path_to_server> list-jobs\n";
	print "jenny.pl --server-path <path_to_server> --job <job_name> list-builds\n";
	print "jenny.pl --server-path <path_to_server> --job <job_name> --build <build_number> build-info\n";
}

# Parse the users options and run without function is the one they want.
my $results = GetOptions(
	'server-path=s' => \$server_path,
	'job=s' => \$job,
	'build=i' => \$build_number
);

my $operation = $ARGV[0];

given ($operation) {
	when ('list-jobs') { list_jobs(); }
	when ('list-builds') { list_builds(); }
	when ('build-info') { build_info(); }
	default {
		print "unrecognised argument\n";
		usage();
	}
};

1;
