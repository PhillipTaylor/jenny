package Jenkins;

=head1 NAME

	Jenkins - A wrapper for Jenkins calls

=head1 SYNOPSIS

	# create a Jenkin's instance.
	my $jenkins = Jenkins->new({ server_path => 'http://jenkins.gnuviech-server.de/' });

	# list of available jobs on your jenkin's server
	my $jobs = $jenkins->list_jobs();

	foreach my $job (@$jobs) {
		print $job->{'name'} . "\n";
	}

	# fetch the job info
	my $builds = $jenkins->list_builds('my-job');
	foreach my $build (@$builds) {
		print $build->{'number'} . "\n";
	}
	
	# fetch the builds result
	my $build = $jenkins->get_build_information($job, $build_number);
	print $build->{'result'} . "\n";     # <- use data dumper to see all the possible results

=head1 DESCRIPTION

	This module basically uses the JSON Api on a Jenkin's web server and wraps it so you
	can easily and quickly pull out the stats. Work flow is a complicated thing.. so this
	gives you the chance to use your creativity to build and integrate monitoring tools
	into your work life.

=cut

use strict;
use warnings;

use Moose;
use JSON::XS;
use Data::Dump 'pp';
use LWP::Simple;

has 'server_path' => (isa => 'Str', is => 'rw');
has 'cache' => ( is => 'rw', default => sub { {} } );

=head2 list_jobs

	Lists the Jenkin's job on the server.
	returns a ArrayRef of Hashes, one for each job.
	Use Data::Dump on each hash to find out what data is available.

=cut


sub list_jobs {
	my $self = shift;

	my $jobs_url = $self->server_path . '/api/json/'; # essentially the homepage

	my $homepage = $self->_fetch_data($jobs_url);
	
	my $jobs = $homepage->{'jobs'};
	
	# store in cache for later.
	foreach my $job (@$jobs) {
		$self->cache->{ $job->{name} } = $job;
	}

	return $jobs;

}

=head2 list_builds ($job_name)

	Lists the Jenkin's job on the server.
	Takes one argument, the job name as a string.
	returns a ArrayRef of Hashes, one for each build.
	build contains just number and a url

=cut

sub list_builds {
	my ($self, $job_name) = @_;

	# job info in cache?
	if (!exists($self->cache->{ $job_name })) {
		$self->list_jobs();
	}

	if (!exists($self->cache->{ $job_name })) {
		return undef; # job not found
	}

	my $job = $self->cache->{ $job_name };
	my $data = $self->_fetch_data($job->{'url'} . '/api/json');

	# store it in cache.
	$self->cache->{ $job_name }->{'builds'} = {};

	my $builds = $data->{'builds'};
	foreach my $build (@$builds) {
		$self->cache->{ $job_name }->{'builds'}->{ $build->{'number'} } = $build;
	};

	return $data->{'builds'};
}

=head2 get_build_information ($job_name, $build_number)

	Returns a hash of information about the build.
	Use Data::Dump to inspect the returned value.

=cut

sub get_build_information {
	my ($self, $job_name, $build_number) = @_;

	if (!exists($self->cache->{ $job_name })) {
		$self->list_jobs();
	}

	if (!exists($self->cache->{ $job_name })) {
		return undef;
	}
	
	my $job = $self->cache->{ $job_name };

	if (!exists($job->{'builds'})) {
		$self->list_builds($job->{'name'});
	}

	my $build_url = $job->{'builds'}->{ $build_number }->{'url'};
	my $data = $self->_fetch_data($build_url . '/api/json');
	
	return $data;

}

sub _fetch_data {
	my ($self, $url) = @_;

	my $raw_data = get($url);
	my $json_data = decode_json($raw_data);

	return $json_data;
}

=head1 AUTHOR

	Phillip Taylor <perl@philliptaylor.net>

=head1 LICENSE

	This source code is licensed under the GPL version 3.
	http://www.gnu.org/licenses/gpl-3.0.html

=cut

1;
