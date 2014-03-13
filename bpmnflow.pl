#usage: perl bpmnflow_v0_3.pl bpmnflow_example.bpmn

use strict;
use warnings;
use XML::Simple;

my $namespace = '';
my $descPrefix = '';
my $i18nPrefix  = 'I18N_OPENXPKI_WF';
our @objs = ();

#each element will be maped to an object, consisting of all necessary information and a dumping routine. 
package ObjStateAction;
use Moose;
has type => (is => 'ro', default => 'stateaction');
has name => (is => 'rw',);
has resState => (is => 'rw');
has condition => (is => 'rw', isa => 'ArrayRef');
no Moose;

sub dump {
	my $self = shift;
	my $actionname = $descPrefix."_".$self->{name};
	my $resState = uc($self->{resState});
	$actionname =~ s/\s/_/g;
	$resState =~ s/\s/_/g;
	my @conditions = grep defined, @{$self->{condition}};
	my %action =  (
		name	   		=>	$actionname,
		resulting_state	=>	$resState,
		condition		=>	\@conditions
	);
	return \%action;
}

package ObjState;
use Moose;
use Data::Dumper;
has type => (is => 'ro', default => 'state');
has name => (is => 'rw',);
has id => (is => 'rw',);
has targetRef => (is => 'rw',);
has description => (is => 'rw',);
has action => (is => 'rw', isa => 'ArrayRef');
has counter => (is => 'rw', default => 1);
has autorun => (is => 'rw');
no Moose;

sub dump {
	my $self = shift;
	my $name = $self->name;
	my @conditionnames = ();
	$name =~ s/\s/_/g;
    my $description = $i18nPrefix. '_STATE_'. uc($descPrefix). '_'. uc($name);
    my @actions = map {$_->dump()} grep defined, @{$self->{action}};
    my %state =  (
		name	   		=>	$name,
		autorun			=>	$self->{autorun},
		description		=>	$description,
		action			=>	\@actions
	);
    return \%state;
}

package ObjValidator;
use Moose;
has type => (is => 'ro', default => 'validator');
has name => (is => 'rw',);
has id => (is => 'rw',);
has class => (is => 'rw',);
has args => (is => 'rw', isa => 'ArrayRef');
has params => (is => 'rw', isa => 'ArrayRef');
no Moose;

sub dump {
	my $self = shift;	
	my $name = $namespace . '_' . $self->{name};
	$name =~ s/\s/_/g;
	$name =~ s/\?//g;
	my %validator =  (
		name	   		=>	$name,
		class			=>	$self->{class},
#		param			=>	$self->params,
	);
    return \%validator;
}

package ObjCondition;
use Moose;
has type => (is => 'ro', default => 'condition');
has name => (is => 'rw',);
has id => (is => 'rw',);
has class => (is => 'rw',);
has plist => (is => 'rw', isa => 'HashRef');
has targetRef => (is => 'rw', isa => 'ArrayRef');
has default => (is => 'rw',);
no Moose;

sub dump {
	my $self = shift;
	my $class = "Workflow::Action::Null";
	if ( defined ($self->{class}) ) {
		$class = $self->{class};
	}
	
	my $name = $namespace . '_' . $self->{name};
	$name =~ s/\s/_/g;
	$name =~ s/\?//g;
	my %condition =  (
		name	   		=>	$name,
		class			=>	$self->{class},
	);
	#~ while( my ($k, $v) = each %{$self->{plist}} ) {
		#~ push @out, $indentSpace x $indent , "<param name=", '"', "$k", '" ', "value=", '"', "$v", '"', " />", "\n";
	#~ }
	return \%condition;
}

package ObjAction;
use Moose;
has type => (is => 'ro', default => 'action');
has name => (is => 'rw',);
has id => (is => 'rw',);
has class => (is => 'rw',);
has description => (is => 'rw');
has params => (is => 'rw', isa => 'ArrayRef');
has validators => (is => 'rw', isa => 'ArrayRef');
has condition => (is => 'rw',);
has targetRef => (is => 'rw',);
no Moose;

sub dump {
	my $self = shift;
	my $class = $self->{class} || "Workflow::Action::Null";
	my @params = ();
	my $name = $namespace . '_' . $self->{name};
	$name =~ s/\s/_/g;
	
	my @validator = map {$_->dump()} grep defined, @{$self->{validators}};
    my %action =  (
		name	   		=>	$name,
		class			=>	$class,
#		field			=>	$self->params,
		validator		=>	\@validator
	);
	
	#~ foreach my $param(@params) {
		#~ push @out, $indentSpace x ($indent + 1) , "<field ", $param, "/>", "\n";
	#~ }

	#~ foreach (@{$self->{validators}}) {
		#~ push @out, $indentSpace x ($indent + 1) , '<validator name="', $namespace . '_' . $_->{name}, '"', ">", "\n";
		#~ if (defined $_->{args}) {
			#~ foreach (@{$_->{args}}) {
				#~ push @out, $indentSpace x ($indent + 2) , "<arg>", $_, "</arg>", "\n";
			#~ }
		#~ push @out, $indentSpace x ($indent + 1) , "</validator>", "\n";
		#~ }
	#~ }
	#~ 
	#~ push @out, $indentSpace x $indent, "</action>", "\n";
	return \%action;
}

package ObjRef;
use Moose;
has type => (is => 'ro', default => 'flow');
has id => (is => 'rw',);
has targetRef => (is => 'rw',);
no Moose;

package Main;
use Data::Dumper;

sub getElementById {
	my $id = shift;
	for (grep {$_->{id} eq $id} @objs) {
		return $_;
	}
	return;
}

sub getNextElements {
	my $currElement = getElementById(shift);
	my @nextRefs = ();
	my @targets = ();
	
	if (ref($currElement->{targetRef}) ne 'ARRAY') {
		push @nextRefs, $currElement->{targetRef};
	}
	else {
		@nextRefs = @{$currElement->{targetRef}};
	}
	
	foreach (@nextRefs) {
		my $tempElement = getElementById($_);
		if ($tempElement->{type} eq 'flow') {
			push @targets, getElementById($tempElement->{targetRef});
		}
		else {
			push @targets, $tempElement;
		}
	}
	return \@targets;
}

sub handleAction {
	my $state = shift;
	my $action = shift;
	my $conditions = shift || [];
	my $object = ObjStateAction->new();
	$object->name($action->{name});
	$object->resState(shift(getNextElements($action->{id}))->{name});
	$object->condition($conditions);
	push(@{$state->{action}}, $object);
}

sub handleState {
	my $state = shift;
	my $resState = shift;
	my $conditions = shift || [];
	my $object = ObjStateAction->new();
	$object->name("null".$state->{counter});
	$state->counter($state->{counter} + 1);
	$object->resState($resState->{name});
	$object->condition($conditions);
	push(@{$state->{action}}, $object);
	unless (getElementById($object->{name})) {
		my $action = ObjAction->new;
		$action->id($object->{name});
		$action->name($object->{name});
		push @objs, $action;
	}
}

sub handleCondition {
	my $state = shift;
	my $cond = shift;
	my $condname = $descPrefix."_".$cond->{name};
	$condname=~ s/\s/_/g;
	$condname=~	s/\?//g;
	my $conditions = shift || [];
	my @nodes = @{getNextElements($cond->{id})};
	my $default = getElementById($cond->{default})->{targetRef};
	
	foreach(@nodes) {
		my @temp = ();
		if ($_->{id} eq $default) {
			@temp = @{$conditions};	
			push @temp, $condname;
		}
		else {
			@temp = @{$conditions};	
			push @temp, "!".$condname;
		}
		if ($_->{type} eq 'action') {
			handleAction($state, $_, \@temp);
		}
		elsif ($_->{type} eq 'state') {
			handleState($state, $_, \@temp);
		}
		elsif ($_->{type} eq 'condition') {
			handleCondition($state, $_, \@temp);
		}
	}
}


sub createStateChilds {
	my $state = shift;
	if ($state->{type} eq 'state') {
		#states only have one next element: action or condition
		foreach (@{getNextElements($state->{id})})
		{
			if ($_->{type} eq 'action') {
				handleAction($state, $_);
			}
			#if next element is condition
			elsif ($_->{type} eq 'condition') {
				handleCondition($state, $_);
			}
			else {
				die $_->{type} . " is not allowed after a state (action or condition)";
			}
		}
	}
}

# this routine filters all important objects and refers them to their corresponding procedure
sub parseContent {
	my $content = shift;
	
	foreach my $element (keys %{$content} ) {
		if ($element eq 'ioSpecification' ) {
			foreach my $spec (@{$content->{$element}->[0]->{dataOutput}} ) {
				parseIo($spec);
			}
		}		
	}
	
	foreach my $element (keys %{$content} ) {
		if ( $element eq 'sequenceFlow') {
			foreach my $flow ( @{$content->{$element}} ) {
				parseFlow($flow);
			}
		}
		elsif ( $element eq 'task' ) {
			foreach my $task ( @{$content->{$element}} ) {
				parseTask($task);
			}
		}
		elsif (
				$element eq 'endEvent' ||
				$element eq 'startEvent'||
				$element eq 'intermediateThrowEvent' ||
				$element eq 'intermediateCatchEvent' )
		{
			foreach my $event ( @{$content->{$element}} ) {
				parseEvent($event);
			}
		}
		elsif (	$element eq 'exclusiveGateway' ) {
			foreach my $gateway ( @{$content->{$element}} ) {
				parseGateway($gateway);
			}
		}	
	}
	#remove link events
	foreach my $list1 (grep {$_->{linkEventDefinition}} @{$content->{intermediateThrowEvent}} ) {
		my @incomings = ();
		foreach (@{$list1->{incoming}}) {
			push @incomings, getElementById($_);
		}
		foreach my $list2 (@{$content->{intermediateCatchEvent}}) {
			if ($list2->{name} eq $list1->{name}) {
				my $targetid = getElementById($list2->{outgoing}->[0])->{targetRef};
				foreach (@incomings) {
					$_->{targetRef} = getElementById($targetid)->{id};
				}
				for (grep {$objs[$_]->{id} eq $list1->{id}} 0..$#objs) {
					splice @objs, $_, 1;
				}
				for (grep {$objs[$_]->{id} eq $list2->{id}} 0..$#objs) {
					splice @objs, $_, 1;
				}
			}
		}
	}
	
	foreach (grep {$_->{type} eq 'state'} @objs) {
		if ( defined ($_->{targetRef})) {
			createStateChilds($_);
		}
	}
}

sub parseTask {
	my $task = shift;
	my $object = ObjAction->new;
	$object->id($task->{id});
	$object->name($task->{name});
	$object->class($task->{property}->[0]->{name});
	$object->targetRef($task->{outgoing}->[0]);
	$object->description($task->{documentation}->[0]->{content});
	if (defined $task->{dataOutputAssociation}) {
		foreach my $validator (@{$task->{dataOutputAssociation}}) {
			push @{$object->{validators}}, getElementById($validator->{targetRef}->[0]);
		}	
	}
	#this will just pipe the params of the task
	foreach my $param (@{$task->{ioSpecification}->[0]->{dataInput}}) {
		push @{$object->{params}}, $param->{name};
	}
	push @objs, $object;
}

sub parseFlow {
	my $flow = shift;
	my $object = ObjRef->new;
	$object->id($flow->{id});
	$object->targetRef($flow->{targetRef});
	push @objs, $object;
}

sub parseEvent {
	my $event = shift;
	my $name = $event->{name};
	my $id = $event->{id};	
	my $object = ObjState->new;
	$object->id($id);
	$object->name($name);
	$object->targetRef($event->{outgoing});
	if (defined $event->{property}) {
		my $autorun = $event->{property}->[0]->{name};
		if ($autorun eq "autorun yes") {
			$object->autorun("yes");
		}
	}

	push @objs, $object;
}

sub parseGateway {
	my $gateway = shift;
	my $name = $gateway->{name};
	my $id = $gateway->{id};	
	my $object = ObjCondition->new;
	$object->id($id);
	$object->name($name);
	$object->plist({});
	$object->targetRef($gateway->{outgoing});
	$object->default($gateway->{default});
	
	foreach my $param (@{$gateway->{documentation}}) {
		my ($param1, $param2) = split / /, $param->{content}, 2;
		if ($param1 eq 'class') {
			$object->class($param2);
		}
		elsif ($param1 eq 'name') {
			my ($name, $value) = split /name |; value /, $param2, 2;
			${$object->plist}{$name} = $value;
		}
		else {
			die "Gateway documentation has to start with 'class' or 'name'";
		}
	}
	push @objs, $object;
}

sub parseIo {
	my $dataOutput = shift;
	my $name = $dataOutput->{name};
	my $id = $dataOutput->{id};	
	my $object = ObjValidator->new;
	$object->id($id);
	$object->name($name);
	foreach my $param (@{$dataOutput->{documentation}}) {
		my ($key, $value) = split(/ /,$param->{content}, 2);
		if ($key eq 'arg') {push @{$object->{args}}, $value}
		elsif ($key eq 'class') {$object->class($value);}
		elsif ($key eq 'param') {push @{$object->{params}}, $value;}	
		else {die $key, "does not match any valid validador parameter";}
	}

	push @objs, $object;
}

#main routine starts

use Getopt::Long;
use XML::Simple;
my ($infile, $outfile, $outtype);

my $result = GetOptions(
    "infile=s"    => \$infile,
    "outfile=s"   => \$outfile,
    "outtype=s"   => \$outtype,
    "namespace=s" => \$namespace,
);

$infile ||= $ARGV[0];

unless ( open FILE, $infile ) {
    die("Could not open $infile");
}

my $data = do { local $/; <FILE> };
close FILE;

my $xml = XML::Simple::XMLin($data, ForceArray => 1, keyattr => {});

if ( defined ($xml->{name}) ) {
	$namespace = $xml->{name};
}
if ( defined ($xml->{message}->[0]->{name}) ) {
	$descPrefix = $xml->{message}->[0]->{name};
}

#this will parse the important part of the xml file
parseContent($xml->{process}->[0]);

my $imprint
    = '<!-- Generated by "' 
    . $0 . ' '
    . join( ', ', @ARGV ) . '" -->' . "\n\n";
	
# write action definitions to file
if ( not $outtype or $outtype eq 'actions' ) {
	my $defName = $outfile
		|| 'workflow_activity_' . lc($descPrefix) . '.xml';
	open( DEF, ">$defName" ) or die "Error opening $defName: $!";
	print DEF $imprint;
	my @action = map {$_->dump()} grep{$_->{type} eq 'action'} @objs;
	print DEF XMLout({action => \@action}, RootName => "actions", SuppressEmpty => 1);
	close DEF;
}

# write condition definitions to file
if ( not $outtype or $outtype eq 'conditions' ) {
	my $defName = $outfile
		|| 'workflow_condition_' . lc($descPrefix) . '.xml';
	open( DEF, ">$defName" ) or die "Error opening $defName: $!";
	my @condition = map {$_->dump()} grep{$_->{type} eq 'condition'} @objs;
	print DEF $imprint;
	print DEF XMLout({condition => \@condition}, RootName => "conditions", SuppressEmpty => 1);
	close DEF;
}

# write validator definitions to file
if ( not $outtype or $outtype eq 'validator' ) {
	my $defName = $outfile
		|| 'workflow_validator_' . lc($descPrefix) . '.xml';
	open( DEF, ">$defName" ) or die "Error opening $defName: $!";
	my @validator = map {$_->dump()} grep{$_->{type} eq 'validator'} @objs;
	print DEF $imprint;
	print DEF XMLout({validator => \@validator}, RootName => "validators", SuppressEmpty => 1);
	close DEF;
}

# write state definitions to file
if ( not $outtype or $outtype eq 'states' ) {
	my $defName = $outfile
		|| 'workflow_def_' . lc($descPrefix) . '.xml';
	open( DEF, ">$defName" ) or die "Error opening $defName: $!";
	my @states = map {$_->dump()} grep{$_->{type} eq 'state'} @objs;
	my %def = (
			type 		=> $i18nPrefix.'_TYPE_'.uc($descPrefix),
			description	=> $i18nPrefix.'_DESC_'.uc($descPrefix),,
			persister	=> "OpenXPKI",
			state		=> \@states
	);
	print DEF $imprint;
	print DEF XMLout(\%def, RootName => "Workflow", SuppressEmpty => 1);
	close DEF;
}
