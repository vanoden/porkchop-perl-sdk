package Porkchop::Geography::Country;

sub new {
	my $package = shift;
	my $options = shift;

	my $self = { };
	bless $self, $package;

	return $self;
}

sub id {
	my ($self) = @_;
	return $self->{id};
}

sub error {
	my $self = shift;
	return $self->{_error};
}

1