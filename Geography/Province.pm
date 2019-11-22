package Porkchop::Geography::Province;

sub new {
	my $package = shift;
	my $options = shift;

	my $self = { };
	bless $self, $package;

	return $self;
}

sub code {
	my ($self) = @_;
	return $self->{code};
}

sub error {
	my $self = shift;
	return $self->{_error};
}

1