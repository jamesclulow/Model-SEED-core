use strict;
package ModelSEED::FIGMODEL::FIGMODELreaction;
use Scalar::Util qw(weaken);
use Carp qw(cluck);

=head1 FIGMODELreaction object
=head2 Introduction
Module for holding reaction related access functions
=head2 Core Object Methods

=head3 new
Definition:
	FIGMODELreaction = FIGMODELreaction->new({figmodel => FIGMODEL:parent figmodel object,id => string:reaction id});
Description:
	This is the constructor for the FIGMODELreaction object.
=cut
sub new {
	my ($class,$args) = @_;
	#Must manualy check for figmodel argument since figmodel is needed for automated checking
	if (!defined($args->{figmodel})) {
		print STDERR "FIGMODELreaction->new():figmodel must be defined to create an genome object!\n";
		return undef;
	}
	my $self = {_figmodel => $args->{figmodel}};
    weaken($self->{_figmodel});
	bless $self;
	$args = $self->figmodel()->process_arguments($args,["figmodel"],{id => undef});
	if (defined($args->{id})) {
		$self->{_id} = $args->{id};
		if ($self->id() =~ m/^bio\d+$/) {
			$self->{_ppo} = $self->figmodel()->database()->get_object("bof",{id => $self->id()});
		} else {
			$self->{_ppo} = $self->figmodel()->database()->get_object("reaction",{id => $self->id()});
		}		
		if(!defined($self->{_ppo})){
		    return undef;
		}
	}
	return $self;
}
=head3 figmodel
Definition:
	FIGMODEL = FIGMODELreaction->figmodel();
Description:
	Returns the figmodel object
=cut
sub figmodel {
	my ($self) = @_;
	return $self->{_figmodel};
}
=head3 db
Definition:
	FIGMODEL = FIGMODELreaction->db();
Description:
	Returns the database object
=cut
sub db {
	my ($self) = @_;
	return $self->figmodel()->database();
}
=head3 id
Definition:
	string:reaction ID = FIGMODELreaction->id();
Description:
	Returns the reaction ID
=cut
sub id {
	my ($self) = @_;
	return $self->{_id};
}

=head3 ppo
Definition:
	PPOreaction:reaction object = FIGMODELreaction->ppo();
Description:
	Returns the reaction ppo object
=cut
sub ppo {
	my ($self,$inppo) = @_;
	if (defined($inppo)) {
		$self->{_ppo} = $inppo;
	}
	return $self->{_ppo};
}

=head3 copyReaction
Definition:
	FIGMODELreaction = FIGMODELreaction->copyReaction({
		newid => string:new ID
	});
Description:
	Creates a replica of the reaction
=cut
sub copyReaction {
	my ($self,$args) = @_;
	$args = $self->figmodel()->process_arguments($args,[],{
		newid=>undef,
		owner=> defined($self->ppo()) ? $self->ppo()->owner() : 'master',
	});
	ModelSEED::FIGMODEL::FIGMODELERROR("Cannot call copyReaction on generic reaction") if (!defined($self->id()));
	#Issuing new ID
	if (!defined($args->{newid})) {
		if ($self->id() =~ m/rxn/) {
			$args->{newid} = $self->figmodel()->database()->check_out_new_id("reaction");
		} elsif ($self->id() =~ m/bio/) {
			$args->{newid} = $self->figmodel()->database()->check_out_new_id("bof");
		}
	}
	#Replicating PPO
	if ($self->id() =~ m/rxn/) {
			
	} elsif ($self->id() =~ m/bio/) {
		$self->figmodel()->database()->create_object("bof",{
			owner => $args->{owner},
			name => $self->ppo()->name(),
			public => $self->ppo()->public(),
			equation => $self->ppo()->equation(),
			modificationDate => time(),
			creationDate => time(),
			id => $args->{newid},
			cofactorPackage => $self->ppo()->cofactorPackage(),
			lipidPackage => $self->ppo()->lipidPackage(),
			cellWallPackage => $self->ppo()->cellWallPackage(),
			protein => $self->ppo()->protein(),
			DNA => $self->ppo()->DNA(),
			RNA => $self->ppo()->RNA(),
			lipid => $self->ppo()->lipid(),
			cofactor => $self->ppo()->cofactor(),
			cellWall => $self->ppo()->cellWall(),
			proteinCoef => $self->ppo()->proteinCoef(),
			DNACoef => $self->ppo()->DNACoef(),
			RNACoef => $self->ppo()->RNACoef(),
			lipidCoef => $self->ppo()->lipidCoef(),
			cofactorCoef => $self->ppo()->cofactorCoef(),
			cellWallCoef => $self->ppo()->cellWallCoef(),
			essentialRxn => $self->ppo()->essentialRxn(),
			energy => $self->ppo()->energy(),
			unknownPackage => $self->ppo()->unknownPackage(),
			unknownCoef => $self->ppo()->unknownCoef()
		});
	}
	my $newRxn = $self->figmodel()->get_reaction($args->{newid});
	if (-e $self->filename()) {
		$self->file()->save($newRxn->filename());
	}
	return $newRxn;
}
=head3 filename
Definition:
	string = FIGMODELreaction->filename();
=cut
sub filename {
	my ($self) = @_;
	return $self->figmodel()->config("reaction directory")->[0].$self->id();
}
=head3 file
Definition:
	{string:key => [string]:values} = FIGMODELreaction->file({clear => 0/1});
Description:
	Loads the reaction data from file
=cut
sub file {
	my ($self,$args) = @_;
	$args = $self->figmodel()->process_arguments($args,[],{
		clear => 0,
		filename=>$self->filename()
	});
	delete $self->{_file} if ($args->{clear} == 1);
	if (!defined($self->{_file})) {
		$self->{_file} = ModelSEED::FIGMODEL::FIGMODELObject->new({filename=>$args->{filename},delimiter=>"\t",-load => 1});
		ModelSEED::FIGMODEL::FIGMODELERROR("could not load file") if (!defined($self->{_file}));
	}
	return $self->{_file};
}
=head3 print_file_from_ppo
Definition:
	{success} = FIGMODELreaction->print_file_from_ppo({});
Description:
	Prints the PPO data to the single reaction file
=cut
sub print_file_from_ppo {
	my ($self,$args) = @_;
	$args = $self->figmodel()->process_arguments($args,[],{
		filename => $self->filename()
	});
	ModelSEED::FIGMODEL::FIGMODELERROR("Cannot obtain ppo data for reaction") if (!defined($self->ppo()));
	my $data = {
		DATABASE => [$self->ppo()->id()],
		EQUATION => [$self->ppo()->equation()],
		NAME => [$self->ppo()->name()],
	};
	if ($self->id() =~ m/rxn/) {
		$data->{DEFINITION} = [$self->ppo()->definition()];
		$data->{ENZYME} = [split(/\|/,$self->ppo()->enzyme())];
		$data->{DELTAG} = [$self->ppo()->deltaG()];
		$data->{DELTAGERR} = [$self->ppo()->deltaGErr()];
		$data->{STRUCTURAL_CUES} = [split(/\|/,$self->ppo()->structuralCues())];
		$data->{"THERMODYNAMIC REVERSIBILITY"} = [$self->ppo()->thermoReversibility()];
	}
	$self->{_file} = ModelSEED::FIGMODEL::FIGMODELObject->new({
		filename=> $args->{filename},
		delimiter=>"\t",
		-load => 0,
		data => $data
	});
	$self->{_file}->save();
}
=head3 substrates_from_equation
Definition:
	([{}:reactant data],[{}:Product data]) = FIGMODELreaction->substrates_from_equation({});
	{}:Reactant/Product data = {
		DATABASE => [string],
		COMPARTMENT => [string],
		COEFFICIENT => [string]}]
	}
Description:
	This function parses the input reaction equation and returns the data on reactants and products.
=cut
sub substrates_from_equation {
	my ($self,$args) = @_;
	$args = $self->figmodel()->process_arguments($args,[],{equation => undef});
	my $Equation = $args->{equation};
	if (!defined($Equation)) {
		ModelSEED::FIGMODEL::FIGMODELERROR("Could not find reaction in database") if (!defined($self->ppo()));
		$Equation = $self->ppo()->equation();
	}
	my $Reactants;
	my $Products;
	if (defined($Equation)) {
		my @TempArray = split(/\s/,$Equation);
		my $Coefficient = 1;
		my $CurrentlyOnReactants = 1;
		for (my $i=0; $i < @TempArray; $i++) {
			if ($TempArray[$i] =~ m/^\(([\.\d]+)\)$/ || $TempArray[$i] =~ m/^([\.\d]+)$/) {
				$Coefficient = $1;
			} elsif ($TempArray[$i] =~ m/(cpd\d\d\d\d\d)/) {
				my $NewRow;
				$NewRow->{"DATABASE"}->[0] = $1;
				$NewRow->{"COMPARTMENT"}->[0] = "c";
				$NewRow->{"COEFFICIENT"}->[0] = $Coefficient;
				if ($TempArray[$i] =~ m/cpd\d\d\d\d\d\[(\D)\]/) {
					$NewRow->{"COMPARTMENT"}->[0] = lc($1);
				}
				if ($CurrentlyOnReactants == 1) {
					push(@{$Reactants},$NewRow);
				} else {
					push(@{$Products},$NewRow);
				}
				$Coefficient = 1;
			} elsif ($TempArray[$i] =~ m/=/) {
				$CurrentlyOnReactants = 0;
			}
		}
	}
	return ($Reactants,$Products);
}

=head2 Functions involving interactions with MFAToolkit

=head3 updateReactionData
Definition:
	string:error = FIGMODELreaction->updateReactionData();
Description:
	This function uses the MFAToolkit to process the reaction and reaction data is updated accordingly
=cut
sub updateReactionData {
	my ($self) = @_;
	ModelSEED::FIGMODEL::FIGMODELERROR("could not find ppo object") if (!defined($self->ppo()));
	my $data = $self->file({clear=>1});#Reloading the file data for the compound, which now has the updated data
	my $translations = {EQUATION => "equation",DELTAG => "deltaG",DELTAGERR => "deltaGErr","THERMODYNAMIC REVERSIBILITY" => "thermoReversibility",STATUS => "status",TRANSATOMS => "transportedAtoms"};#Translating MFAToolkit file headings into PPO headings
	foreach my $key (keys(%{$translations})) {#Loading file data into the PPO
		if (defined($data->{$key}->[0])) {
			my $function = $translations->{$key};
			$self->ppo()->$function($data->{$key}->[0]);
		}
	}
	if (defined($data->{"STRUCTURAL_CUES"}->[0])) {
		$self->ppo()->structuralCues(join("|",@{$data->{"STRUCTURAL_CUES"}}));	
	}
	my $codeOutput = $self->createReactionCode();
	if (defined($codeOutput->{code})) {
		$self->ppo()->code($codeOutput->{code});
	}
	if (defined($self->figmodel()->config("acceptable unbalanced reactions"))) {
		if ($self->ppo()->status() =~ m/OK/) {
			for (my $i=0; $i < @{$self->figmodel()->config("acceptable unbalanced reactions")}; $i++) {
				if ($self->figmodel()->config("acceptable unbalanced reactions")->[$i] eq $self->id()) {
					$self->ppo()->status("OK|".$self->ppo()->status());
					last;
				}	
			}
		}
		for (my $i=0; $i < @{$self->figmodel()->config("permanently knocked out reactions")}; $i++) {
			if ($self->figmodel()->config("permanently knocked out reactions")->[$i] eq $self->id() ) {
				if ($self->ppo()->status() =~ m/OK/) {
					$self->ppo()->status("BL");
				} else {
					$self->ppo()->status("BL|".$self->ppo()->status());
				}
				last;
			}	
		}
		for (my $i=0; $i < @{$self->figmodel()->config("spontaneous reactions")}; $i++) {
			if ($self->figmodel()->config("spontaneous reactions")->[$i] eq $self->id() ) {
				$self->ppo()->status("SP|".$self->ppo()->status());
				last;
			}
		}
		for (my $i=0; $i < @{$self->figmodel()->config("universal reactions")}; $i++) {
			if ($self->figmodel()->config("universal reactions")->[$i] eq $self->id() ) {
				$self->ppo()->status("UN|".$self->ppo()->status());
				last;
			}
		}
		if (defined($self->figmodel()->config("reversibility corrections")->{$self->id()})) {
			$self->ppo()->status("RC|".$self->ppo()->status());
		}
		if (defined($self->figmodel()->config("forward only reactions")->{$self->id()})) {
			$self->ppo()->status("FO|".$self->ppo()->status());
		}
		if (defined($self->figmodel()->config("reverse only reactions")->{$self->id()})) {
			$self->ppo()->status("RO|".$self->ppo()->status());
		}
	}
	return undef;
}

=head3 processReactionWithMFAToolkit
Definition:
	string:error message = FIGMODELreaction->processReactionWithMFAToolkit();
Description:
	This function uses the MFAToolkit to process the entire reaction database. This involves balancing reactions, calculating thermodynamic data, and parsing compound structure files for charge and formula.
	This function should be run when reactions are added or changed, or when structures are added or changed.
	The database should probably be backed up before running the function just in case something goes wrong.
=cut
sub processReactionWithMFAToolkit {
    my($self,$args) = @_;
    $args = $self->figmodel()->process_arguments($args,[],{
	overwriteReactionFile => 0,
	loadToPPO => 0,
	loadEquationFromPPO => 0,
	comparisonFile => undef
						 });
    
    my $fbaObj = $self->figmodel()->fba();

    print "Creating problem directory: ",$fbaObj->directory()."\n";
    $fbaObj->makeOutputDirectory({deleteExisting => $args->{overwrite}});    
    print "Writing reaction to file\n";
    $self->print_file_from_ppo({filename=>$fbaObj->directory()."/reactions/".$self->id()});
    
    my $filename = $fbaObj->filename();
    print $self->figmodel()->GenerateMFAToolkitCommandLineCall($filename,"processdatabase","NONE",["ArgonneProcessing"],{"load compound structure" => 0,"Calculations:reactions:process list" => "LIST:".$self->id()},"DBProcessing-".$self->id()."-".$filename.".log")."\n";
 
   return {};

}

#    #Backing up the old file
#    system("cp ".$self->figmodel()->config("reaction directory")->[0].$self->id()." ".$self->figmodel()->config("database root directory")->[0]."ReactionDB/oldreactions/".$self->id());
#    #Getting unique directory for output
#    my $filename = $self->figmodel()->filename();
    #Eliminating the mfatoolkit errors from the compound and reaction files
#    my $data = $self->file();
#
#    if (defined($self->ppo()) && $args->{loadEquationFromPPO} == 1) {
#	$data->{EQUATION}->[0] = $self->ppo()->equation();
#    }
#    $data->remove_heading("MFATOOLKIT ERRORS");
#    $data->remove_heading("STATUS");
#    $data->remove_heading("TRANSATOMS");
#    $data->remove_heading("DBLINKS");
#    $data->save();
#    #Running the mfatoolkit
#    print $self->figmodel()->GenerateMFAToolkitCommandLineCall($filename,"processdatabase","NONE",["ArgonneProcessing"],{"load compound structure" => 0,"Calculations:reactions:process list" => "LIST:".$self->id()},"DBProcessing-".$self->id()."-".$filename.".log")."\n";
#    system($self->figmodel()->GenerateMFAToolkitCommandLineCall($filename,"processdatabase","NONE",["ArgonneProcessing"],{"load compound structure" => 0,"Calculations:reactions:process list" => "LIST:".$self->id()},"DBProcessing-".$self->id()."-".$filename.".log"));
#	#Copying in the new file
#	print $self->figmodel()->config("MFAToolkit output directory")->[0].$filename."/reactions/".$self->id()."\n";
#	if (-e $self->figmodel()->config("MFAToolkit output directory")->[0].$filename."/reactions/".$self->id()) {
#		my $newData = $self->file({filename=>$self->figmodel()->config("MFAToolkit output directory")->[0].$filename."/reactions/".$self->id()});
#		if ($args->{overwriteReactionFile} == 1) {
#			system("cp ".$self->figmodel()->config("MFAToolkit output directory")->[0].$filename."/reactions/".$self->id()." ".$self->figmodel()->config("reaction directory")->[0].$self->id());
#		}
#		if ($args->{loadToPPO} == 1) {
#			$self->updateReactionData();
#		}
#		if (defined($args->{comparisonFile}) && $newData->{EQUATION}->[0] ne $data->{EQUATION}->[0]) {
#			if (-e $args->{comparisonFile}) {
#				$self->figmodel()->database()->print_array_to_file($args->{comparisonFile},["ID\tPPO equation\tOriginal equation\tNew equation\tStatus",$self->id()."\t".$data->ppo()->equation()."\t".$data->{EQUATION}->[0]."\t".$newData->{EQUATION}->[0]."\t".$newData->{STATUS}->[0]],1);
#			} else {
#				$self->figmodel()->database()->print_array_to_file($args->{comparisonFile},[$self->id()."\t".$data->ppo()->equation()."\t".$data->{EQUATION}->[0]."\t".$newData->{EQUATION}->[0]."\t".$newData->{STATUS}->[0]]);
#			}
#		}
#	} else {
#		ModelSEED::FIGMODEL::FIGMODELERROR("could not find output reaction file");	
#	}
#	$self->figmodel()->clearing_output($filename,"DBProcessing-".$self->id()."-".$filename.".log");
#	return {};
#}

=head3 get_neighboring_reactions
Definition:
	{string:metabolite ID => [string]:neighboring reaction IDs}:Output = FIGMODELreaction->get_neighboring_reactions({});
Description:
	This function identifies the other reactions that share the same metabolites as this reaction
=cut
sub get_neighboring_reactions {
	my($self,$args) = @_;
	$args = $self->figmodel()->process_arguments($args,[],{});
	#Getting the list of reactants for this reaction
	my $cpds = $self->figmodel()->database()->get_objects("cpdrxn",{REACTION=>$self->id(),cofactor=>0});
	my $neighbors;
	for (my $i=0; $i < @{$cpds}; $i++) {
		my $hash;
		my $rxns = $self->figmodel()->database()->get_objects("cpdrxn",{COMPOUND=>$cpds->[$i]->COMPOUND(),cofactor=>0});
		for (my $j=0; $j < @{$rxns}; $j++) {
			if ($rxns->[$j]->REACTION() ne $self->id()) {
				$hash->{$rxns->[$j]->REACTION()} = 1;
			}
		}
		push(@{$neighbors->{$cpds->[$i]->COMPOUND()}},keys(%{$hash}));
	}
	return $neighbors;
}

=head3 identify_dependant_reactions
Definition:
	FIGMODELreaction->identify_dependant_reactions({});
Description:
=cut
sub identify_dependant_reactions {
	my($self,$args) = @_;
	$args = $self->figmodel()->process_arguments($args,[],{biomass => undef,model => undef,media => "Complete"});
	my $fba = $self->figmodel()->fba($args);
	if (!defined($args->{model})) {
		if (!defined($args->{biomass})) {
			$args->{biomass} = "bio00001";	
		}
		$fba->model("Complete");
		$fba->set_parameters({"Complete model biomass reaction" => $args->{biomass}});
	}
	$fba->add_parameter_files(["ProductionCompleteClassification"]);
	$fba->set_parameters({"find tight bounds" => 1});
	$fba->add_constraint({objects => [$self->id()],coefficients => [1],rhs => 0.00001,sign => ">"});
	$fba->runFBA();
	my $essentials;
	my $results = $fba->parseTightBounds({});
	if (defined($results->{tb})) {
		foreach my $key (keys(%{$results->{tb}})) {
			if ($key =~ m/rxn\d\d\d\d\d/ && $results->{tb}->{$key}->{max} < -0.000001) {
				$essentials->{"for_rev"}->{$key} = 1;
			} elsif ($key =~ m/rxn\d\d\d\d\d/ && $results->{tb}->{$key}->{min} > 0.000001) {
				 $essentials->{"for_for"}->{$key} = 1;
			}
		}	
	}
	$fba->clear_constraints();
	$fba->add_constraint({objects => [$self->id()],coefficients => [1],compartments => ["c"],rhs => -0.000001,sign => "<"});
	$fba->runFBA();
	$results = $fba->parseTightBounds({});
	if (defined($results->{tb})) {
		foreach my $key (keys(%{$results->{tb}})) {
			if ($key =~ m/rxn\d\d\d\d\d/ && $results->{tb}->{$key}->{max} < 0 || $results->{tb}->{$key}->{min} > 0) {
				if ($key =~ m/rxn\d\d\d\d\d/ && $results->{tb}->{$key}->{max} < -0.000001) {
					$essentials->{"rev_rev"}->{$key} = 1;
				} elsif ($key =~ m/rxn\d\d\d\d\d/ && $results->{tb}->{$key}->{min} > 0.000001) {
					$essentials->{"rev_for"}->{$key} = 1;
				}
			}
		}
	}
	my $obj = $self->figmodel()->database()->get_object("rxndep",{REACTION=>$self->id(),MODEL=>$args->{model},BIOMASS=>$args->{biomass},MEDIA=>$args->{media}});
	if (!defined($obj)) {
		$obj = $self->figmodel()->database()->create_object("rxndep",{REACTION=>$self->id(),MODEL=>$args->{model},BIOMASS=>$args->{biomass},MEDIA=>$args->{media}});	
	}
	$obj->forrev(join("|",sort(keys(%{$essentials->{"for_rev"}}))));
	$obj->forfor(join("|",sort(keys(%{$essentials->{"for_for"}}))));
	$obj->revrev(join("|",sort(keys(%{$essentials->{"rev_rev"}}))));
	$obj->revfor(join("|",sort(keys(%{$essentials->{"rev_for"}}))));
}

=head3 build_complete_biomass_reaction
Definition:
	{}:Output = FIGMODELreaction->build_complete_biomass_reaction({});
Description:
	This function identifies the other reactions that share the same metabolites as this reaction
=cut
sub build_complete_biomass_reaction {
	my($self,$args) = @_;
	$args = $self->figmodel()->process_arguments($args,[],{});
    my $bioObj = $self->figmodel()->database()->get_object("bof",{id => "bio00001"});
    #Filling in miscellaneous data for biomass
    $bioObj->name("Biomass");
	$bioObj->owner("master");
	$bioObj->modificationDate(time());
	$bioObj->creationDate(time());
	$bioObj->unknownCoef("NONE");
	$bioObj->unknownPackage("NONE");
	my $oldEquation = $bioObj->equation();
    #Filling in fraction of main components of biomass
    foreach my $key (keys(%{$self->figmodel()->config("universalBiomass_fractions")})) {
    	$bioObj->$key($self->figmodel()->config("universalBiomass_fractions")->{$key}->[0]);
    }
    #Filing compound hash
    my $compoundHash;
    $compoundHash = {cpd00001 => -1*$self->figmodel()->config("universalBiomass_fractions")->{energy}->[0],
					cpd00002 => -1*$self->figmodel()->config("universalBiomass_fractions")->{energy}->[0],
					cpd00008 => $self->figmodel()->config("universalBiomass_fractions")->{energy}->[0],
					cpd00009 => $self->figmodel()->config("universalBiomass_fractions")->{energy}->[0],
					cpd00067 => $self->figmodel()->config("universalBiomass_fractions")->{energy}->[0]};    
    my $categories = ["RNA","DNA","protein","cofactor","lipid","cellWall"];
    my $categoryTranslation = {"cofactor" => "Cofactor","lipid" => "Lipid","cellWall" => "CellWall"};
    foreach my $category (@{$categories}) {
    	my $tempHash;
    	my @array = sort(keys(%{$self->figmodel()->config("universalBiomass_".$category)}));
    	my $fractionCount = 0;
    	foreach my $item (@array) {
    		if ($self->figmodel()->config("universalBiomass_".$category)->{$item}->[0] !~ m/cpd\d+/) {
    			if ($self->figmodel()->config("universalBiomass_".$category)->{$item}->[0] =~ m/FRACTION/) {
	    			$fractionCount++;
	    		} else {
	    			my $MW = 1;
	    			my $obj = $self->figmodel()->database()->get_object("compound",{"id"=>$item});
	    			if (defined($obj)) {
	    				$MW = $obj->mass();
	    			}
	    			if ($MW == 0) {
	    				$MW = 1;	
	    			}
	    			$tempHash->{$item} = $self->figmodel()->config("universalBiomass_fractions")->{$category}->[0]*$self->figmodel()->config("universalBiomass_".$category)->{$item}->[0]/$MW;
	    		}
    		}
    	}
    	foreach my $item (@array) {
    		if ($self->figmodel()->config("universalBiomass_".$category)->{$item}->[0] =~ m/FRACTION/) {
    			my $MW = 1;
    			my $obj = $self->figmodel()->database()->get_object("compound",{"id"=>$item});
    			if (defined($obj)) {
    				$MW = $obj->mass();
    			}
    			my $sign = 1;
    			if ($self->figmodel()->config("universalBiomass_".$category)->{$item}->[0] =~ m/^-/) {
    				$sign = -1;
    			}
    			if ($MW == 0) {
    				$MW = 1;	
    			}
    			$tempHash->{$item} = $sign*$self->figmodel()->config("universalBiomass_fractions")->{$category}->[0]/$fractionCount/$MW;
    		}
    	}
    	my $coefficients;
    	foreach my $item (@array) {
    		if ($self->figmodel()->config("universalBiomass_".$category)->{$item}->[0] =~ m/cpd\d+/) {
    			my $sign = 1;
    			if ($self->figmodel()->config("universalBiomass_".$category)->{$item}->[0] =~ m/^-(.+)/) {
    				$self->figmodel()->config("universalBiomass_".$category)->{$item}->[0] = $1;
    				$sign = -1;
    			}
    			my @array = split(/,/,$self->figmodel()->config("universalBiomass_".$category)->{$item}->[0]);
    			$tempHash->{$item} = 0;
    			foreach my $cpd (@array) {
    				if (!defined($tempHash->{$cpd})) {
    					print "Compound not found:".$item."=>".$cpd."\n";
    				}
    				$tempHash->{$item} += $tempHash->{$cpd};
    			}
    			$tempHash->{$item} = $sign*$tempHash->{$item};
    		}
    		if (!defined($compoundHash->{$item})) {
    			$compoundHash->{$item} = 0;	
    		}
    		$compoundHash->{$item} += $tempHash->{$item};
    		push(@{$coefficients},$tempHash->{$item});
    	}
    	if (defined($categoryTranslation->{$category})) {
    		my $arrayRef;
    		push(@{$arrayRef},@array);
    		my $group = $self->figmodel()->get_compound("cpd00001")->get_general_grouping({ids => $arrayRef,type => $categoryTranslation->{$category}."Package",create=>1});
    		my $function = $category."Package";
    		$bioObj->$function($group);
    	}
    	my $function = $category."Coef";
    	$bioObj->$function(join("|",@{$coefficients}));
    }
    #Filling out equation
    $compoundHash->{"cpd11416"} = 1;
    my $reactants;
    my $products;
    foreach my $cpd (sort(keys(%{$compoundHash}))) {
    	if ($compoundHash->{$cpd} > 0) {
    		$products .= " + (".$compoundHash->{$cpd}.") ".$cpd;
    	} elsif ($compoundHash->{$cpd} < 0) {
    		$reactants .= "(".-1*$compoundHash->{$cpd}.") ".$cpd." + ";
    	}
    }
    $reactants = substr($reactants,0,length($reactants)-2);
    $products = substr($products,2);
    $bioObj->equation($reactants."=>".$products);
	if ($bioObj->equation() ne $oldEquation) {
		$bioObj->essentialRxn("NONE");
		$self->figmodel()->add_job_to_queue({command => "runfigmodelfunction?determine_biomass_essential_reactions?bio00001",user => $self->figmodel()->user(),queue => "fast"});
	}
}
=head3 createReactionCode
Definition:
	{} = FIGMODELreaction->createReactionCode({
		equation => 
		translations => 
	});
	
	Output = {
		direction => <=/<=>/=>,
		code => string:canonical reaction equation with H+ removed,
		reverseCode => string:reverse canonical equation with H+ removed,
		fullEquation => string:full equation with H+ included,
		compartment => string:compartment of reaction,
		error => string:error message
	}
Description:
	This function is used to convert reaction equations to a standardized form that allows for reaction comparison.
	This function accepts a string containing a reaction equation and a referece to a hash translating compound IDs in the reaction equation to Argonne compound IDs.
	This function uses the hash to translate the IDs in the equation to Argonne IDs, and orders the reactants alphabetically.
	This function returns four strings. The first string is the directionality of the input reaction: <= for reverse, => for forward, <=> for reversible.
	The second string is the query equation for the reaction, which is the translated and sorted equation minus any cytosolic H+ terms.
	The third strings is the reverse reaction for the second string, for matching this reaction to an exact reverse version of this reaction.
	The final string is the full translated and sorted reaction equation with the cytosolic H+.
=cut
sub createReactionCode {
	my ($self,$args) = @_;
	$args = $self->figmodel()->process_arguments($args,[],{
		equation => undef,
		translations => {}
	});
	if (!defined($args->{equation})) {
		$args->{equation} = $self->ppo()->equation();
	}
	my $OriginalEquation = $args->{equation};
	my $CompoundHashRef = $args->{translations};
	#Dealing with the compartment at the front of the equation
	my $EquationCompartment = "c";
	if ($OriginalEquation =~ m/^\[[(a-z)]\]\s/i) {
		$EquationCompartment = lc($1);
		$OriginalEquation =~ s/^\[[(a-z)]\]\s//i;
	}
	$OriginalEquation =~ s/^:\s//;
	$OriginalEquation =~ s/^\s:\s//;
	#Dealing with obvious errors in equation
	while ($OriginalEquation =~ m/\s\s/) {
		$OriginalEquation =~ s/\s\s/ /g;
	}

	$OriginalEquation =~ s/([^\+]\s)\+([^\s])/$1+ $2/g;
	$OriginalEquation =~ s/([^\s])\+(\s[^\+<=])/$1 +$2/g;
	$OriginalEquation =~ s/-->/=>/;
	$OriginalEquation =~ s/<--/<=/;
	$OriginalEquation =~ s/<==>/<=>/;
	$OriginalEquation =~ s/([^\s^<])(=>)/$1 $2/;
	$OriginalEquation =~ s/(<=)([^\s^>])/$1 $2/;
	$OriginalEquation =~ s/(=>)([^\s])/$1 $2/;
	$OriginalEquation =~ s/([^\s])(<=)/$1 $2/;
	$OriginalEquation =~ s/\s(\[[a-z]\])\s/$1 /ig;
	$OriginalEquation =~ s/\s(\[[a-z]\])$/$1/ig;

	#Checking for reactions that have no products, no reactants, or neither products nor reactants
	if ($OriginalEquation =~ m/^\s[<=]/ || $OriginalEquation =~ m/^[<=]/ || $OriginalEquation =~ m/[=>]\s$/ || $OriginalEquation =~ m/[=>]$/) {
		ModelSEED::FIGMODEL::FIGMODELWARNING("Reaction either has no reactants or no products:".$OriginalEquation);
		return {success => 0,error => "Reaction either has no reactants or no products:".$OriginalEquation};
	}
	#Ready to start parsing equation
	my $Direction = "<=>";
	my @Data = split(/\s/,$OriginalEquation);
	my %ReactantHash;
	my %ProductHash;
	my $WorkingOnProducts = 0;
	my $CurrentReactant = "";
	my $CurrentString = "";
	my %RepresentedCompartments;
	my $success = 1;
	my $error = "";
	for (my $i =0; $i < @Data; $i++) {
		if ($Data[$i] eq "" || $Data[$i] eq ":") {
			#Do nothing
		} elsif ($Data[$i] eq "+") {
			if ($CurrentString eq "") {
				$error .= "Plus sign with no associated metabolite.";
			} elsif ($WorkingOnProducts == 0) {
				$ReactantHash{$CurrentReactant} = $CurrentString;
			} else {
				$ProductHash{$CurrentReactant} = $CurrentString;
			}
			$CurrentString = "";
			$CurrentReactant = "";
		} elsif ($Data[$i] eq "<=>" || $Data[$i] eq "=>" || $Data[$i] eq "<=") {
			$Direction = $Data[$i];
			$WorkingOnProducts = 1;
			if ($CurrentString eq "") {
				$error .= "Equal sign with no associated metabolite.";
			} else {
				$ReactantHash{$CurrentReactant} = $CurrentString;
			}
			$CurrentString = "";
			$CurrentReactant = "";
		} elsif ($Data[$i] !~ m/[ABCDFGHIJKLMNOPQRSTUVWXYZ\]\[]/i) {
			#Stripping off perenthesis if present
			if ($Data[$i] =~ m/^\((.+)\)$/) {
				$Data[$i] = $1;
			}
			#Converting scientific notation to normal notation
			if ($Data[$i] =~ m/[eE]/) {
				my $Coefficient = "";
				my @Temp = split(/[eE]/,$Data[$i]);
				my @TempTwo = split(/\./,$Temp[0]);
				if ($Temp[1] > 0) {
					my $Index = $Temp[1];
					if (defined($TempTwo[1]) && $TempTwo[1] != 0) {
						$Index = $Index - length($TempTwo[1]);
						if ($Index < 0) {
							$TempTwo[1] = substr($TempTwo[1],0,(-$Index)).".".substr($TempTwo[1],(-$Index))
						}
					}
					for (my $j=0; $j < $Index; $j++) {
						$Coefficient .= "0";
					}
					if ($TempTwo[0] == 0) {
						$TempTwo[0] = "";
					}
					if (defined($TempTwo[1])) {
						$Coefficient = $TempTwo[0].$TempTwo[1].$Coefficient;
					} else {
						$Coefficient = $TempTwo[0].$Coefficient;
					}
				} elsif ($Temp[1] < 0) {
					my $Index = -$Temp[1];
					$Index = $Index - length($TempTwo[0]);
					if ($Index < 0) {
						$TempTwo[0] = substr($TempTwo[0],0,(-$Index)).".".substr($TempTwo[0],(-$Index))
					}
					if ($Index > 0) {
						$Coefficient = "0.";
					}
					for (my $j=0; $j < $Index; $j++) {
						$Coefficient .= "0";
					}
					$Coefficient .= $TempTwo[0];
					if (defined($TempTwo[1])) {
						$Coefficient .= $TempTwo[1];
					}
				}
				$Data[$i] = $Coefficient;
			}
			#Removing trailing zeros
			if ($Data[$i] =~ m/(.+\..*?)0+$/) {
				$Data[$i] = $1;
			}
			$Data[$i] =~ s/\.$//;
			#Adding the coefficient to the current string
			if ($Data[$i] != 1) {
				$CurrentString = "(".$Data[$i].") ";
			}
		} else {
			my $CurrentCompartment = "c";
			if ($Data[$i] =~ m/(.+)\[(\D)\]$/) {
			    $Data[$i] = $1;
			    $CurrentCompartment = lc($2);
			} elsif ($Data[$i] =~ m/(.+)_(\D)$/) {
			    #Seaver 06/18/11
			    #Matching Compartment
			    #But not replacing reactant
			    #As needs to match in CompoundHashRef
			    $CurrentCompartment = lc($2);
			}
			$RepresentedCompartments{$CurrentCompartment} = 1;

			if (defined($CompoundHashRef->{$Data[$i]})) {
				$CurrentReactant = $CompoundHashRef->{$Data[$i]};
			} else {
				if ($Data[$i] !~ m/cpd\d\d\d\d\d/) {
					$error .= "Unmatched compound:".$Data[$i].".";
				}
				$CurrentReactant = $Data[$i];
			}
			$CurrentString .= $CurrentReactant;
			if ($CurrentCompartment ne "c") {
				$CurrentString .= "[".$CurrentCompartment."]";
			}
		}
	}
	if (length($CurrentReactant) > 0) {
		$ProductHash{$CurrentReactant} = $CurrentString;
	}
	#Checking if every reactant has the same compartment
	my @Compartments = keys(%RepresentedCompartments);
	if (@Compartments == 1) {
		$EquationCompartment = $Compartments[0];
	}
	#Checking if some reactants cancel out, since reactants will be canceled out by the MFAToolkit
#	my @Reactants = keys(%ReactantHash);
#	for (my $i=0; $i < @Reactants; $i++) {
#		my @ReactantData = split(/\s/,$ReactantHash{$Reactants[$i]});
#		my $ReactantCoeff = 1;
#		if ($ReactantData[0] =~ m/^\(([\d\.]+)\)$/) {
#		   $ReactantCoeff = $1;
#		}
#		my $ReactantCompartment = pop(@ReactantData);
#		if ($ReactantCompartment =~ m/(\[\D\])$/) {
#			$ReactantCompartment = $1;
#		} else {
#			$ReactantCompartment = "[c]";
#		}
#		if (defined($ProductHash{$Reactants[$i]})) {
#			my @ProductData = split(/\s/,$ProductHash{$Reactants[$i]});
#			my $ProductCoeff = 1;
#			if ($ProductData[0] =~ m/^\(([\d\.]+)\)$/) {
#			   $ProductCoeff = $1;
#			}
#			my $ProductCompartment = pop(@ProductData);
#			if ($ProductCompartment =~ m/(\[\D\])$/) {
#				$ProductCompartment = $1;
#			} else {
#				$ProductCompartment = "[c]";
#			}
#			if ($ReactantCompartment eq $ProductCompartment) {
#				#print "Exactly matching product and reactant pair found: ".$OriginalEquation."\n";
#				if ($ReactantCompartment eq "[c]") {
#					$ReactantCompartment = "";
#				}
#				if ($ReactantCoeff == $ProductCoeff) {
#					#delete $ReactantHash{$Reactants[$i]};
#					#delete $ProductHash{$Reactants[$i]};
#				} elsif ($ReactantCoeff > $ProductCoeff) {
#					#delete $ProductHash{$Reactants[$i]};
#					#$ReactantHash{$Reactants[$i]} = "(".($ReactantCoeff - $ProductCoeff).") ".$Reactants[$i].$ReactantCompartment;
#					#if (($ReactantCoeff - $ProductCoeff) == 1) {
#					#	$ReactantHash{$Reactants[$i]} = $Reactants[$i].$ReactantCompartment;
#					#}
#				} elsif ($ReactantCoeff < $ProductCoeff) {
#					#delete $ReactantHash{$Reactants[$i]};
#					#$ProductHash{$Reactants[$i]} = "(".($ProductCoeff - $ReactantCoeff).") ".$Reactants[$i].$ReactantCompartment;
#					#if (($ProductCoeff - $ReactantCoeff) == 1) {
#					#	$ProductHash{$Reactants[$i]} = $Reactants[$i].$ReactantCompartment;
#					#}
#				}
#			}
#		}
#	}
	#Sorting the reactants and products by the cpd ID
	my @Reactants = sort(keys(%ReactantHash));
	my $ReactantString = "";
	for (my $i=0; $i < @Reactants; $i++) {
		if ($ReactantHash{$Reactants[$i]} eq "") {
			$error .= "Empty reactant string.";
		} else {
			if ($i > 0) {
				$ReactantString .= " + ";
			}
			$ReactantString .= $ReactantHash{$Reactants[$i]};
		}
	}
	my @Products = sort(keys(%ProductHash));
	my $ProductString = "";
	for (my $i=0; $i < @Products; $i++) {
		if ($ProductHash{$Products[$i]} eq "") {
			$success = 0;
			$error .= "Empty product string. ";
		} else {
			if ($i > 0) {
			$ProductString .= " + ";
			}
			$ProductString .= $ProductHash{$Products[$i]};
		}
	}
	if (length($ReactantString) == 0 || length($ProductString) == 0) {
		$error .= "Empty products or products string.";
	}
	#Creating the forward, reverse, and full equations
	my $Equation = $ReactantString." <=> ".$ProductString;
	my $ReverseEquation = $ProductString." <=> ".$ReactantString;
	my $FullEquation = $Equation;
	#Removing protons from the equations used for matching
	$Equation =~ s/cpd00067\[e\]/TEMPH/gi;
	$Equation =~ s/\([^\)]+\)\scpd00067\s\+\s//g;
	$Equation =~ s/\s\+\s\([^\)]+\)\scpd00067//g;
	$Equation =~ s/cpd00067\s\+\s//g;
	$Equation =~ s/\s\+\scpd00067//g;
	$Equation =~ s/TEMPH/cpd00067\[e\]/g;
	$ReverseEquation =~ s/cpd00067\[e\]/TEMPH/gi;
	$ReverseEquation =~ s/\([^\)]+\)\scpd00067\s\+\s//g;
	$ReverseEquation =~ s/\s\+\s\([^\)]+\)\scpd00067//g;
	$ReverseEquation =~ s/cpd00067\s\+\s//g;
	$ReverseEquation =~ s/\s\+\scpd00067//g;
	$ReverseEquation =~ s/TEMPH/cpd00067\[e\]/g;
	#Clearing noncytosol compartment notation... compartment data is stored separately to improve reaction comparison
	if ($EquationCompartment eq "") {
		$EquationCompartment = "c";
	} elsif ($EquationCompartment ne "c") {
		$Equation =~ s/\[$EquationCompartment\]//g;
		$ReverseEquation =~ s/\[$EquationCompartment\]//g;
		$FullEquation =~ s/\[$EquationCompartment\]//g;
	}
	if ($EquationCompartment ne "c") {
		#print "\nCompartment:".$EquationCompartment."\n";
	}
	my $output = {
		direction => $Direction,
		code => $Equation,
		reverseCode => $ReverseEquation,
		fullEquation => $FullEquation,
		compartment => $EquationCompartment,
		success => 1
	};
	if (length($error) > 0) {
		$output->{success} = 0;
		$output->{error} = $error;
	}
	return $output;
}
=head2 Functions related to entire reaction database rather than individual reactions

=head3 printLinkFile
Definition:
	{} = FIGMODELreaction = FIGMODELreaction->printLinkFile({
		filename => 	
	});
Description:
	This function prints a file with data on the aliases, subsystems, KEGG map, roles, and scenarios for reactions
=cut
sub printLinkFile {
	my ($self,$args) = @_;
	$args = $self->figmodel()->process_arguments($args,[],{
		filename => ""
	});
	#Loading aliases for all reactions
	my $reactionHash;
	my $headingHash;
	my $KEGGHash;
	my $objs = $self->figmodel()->database()->get_objects("rxnals");
	for (my $i=0; $i < @{$objs}; $i++) {
		$headingHash->{$objs->[$i]->type()} = 1;
		push(@{$reactionHash->{$objs->[$i]->REACTION()}->{$objs->[$i]->type()}},$objs->[$i]->alias());
		if ($objs->[$i]->type() eq "KEGG") {
			$KEGGHash->{$objs->[$i]->alias()} = $objs->[$i]->REACTION();
		}
	}
	#Loading subsystem and role data
	my $roleHash = $self->figmodel()->mapping()->get_role_rxn_hash();
	foreach my $rxn (keys(%{$roleHash})) {
		foreach my $role (keys(%{$roleHash->{$rxn}})) {
			push(@{$reactionHash->{$rxn}->{ROLE}},$role);
		}
	}
	my $subsysHash = $self->figmodel()->mapping()->get_subsy_rxn_hash();
	foreach my $rxn (keys(%{$subsysHash})) {
		foreach my $subsys (keys(%{$subsysHash->{$rxn}})) {
			push(@{$reactionHash->{$rxn}->{SUBSYSTEM}},$subsys);
		}
	}
	#Loading kegg map data
	$objs = $self->figmodel()->database()->get_objects("dgmobj",{entitytype=>"reaction"});
	for (my $i=0; $i < @{$objs}; $i++) {
		push(@{$reactionHash->{$objs->[$i]->entity()}->{"KEGGMAP"}},$objs->[$i]->DIAGRAM());
	}
	#Loading scenario data
	my $scenarioData = $self->figmodel()->database()->load_single_column_file($self->figmodel()->config("scenarios file")->[0],"");
	for (my $i=0; $i < @{$scenarioData}; $i++) {
		my @tempArray = split(/\t/,$scenarioData->[$i]);
		if (defined($tempArray[1]) && defined($KEGGHash->{$tempArray[1]})) {
			push(@{$reactionHash->{$KEGGHash->{$tempArray[1]}}->{"SCENARIO"}},$tempArray[0]);
		}
	}
	#Printing results
	my $headings = ["REACTION","ROLE","SUBSYSTEM","SCENARIO","KEGGMAP",keys(%{$headingHash})];
	my $output = [join("\t",@{$headings})];
	foreach my $rxn (keys(%{$roleHash})) {
		my $line = $rxn;
		for (my $i=0; $i < @{$headings}; $i++) {
			$line .= "\t";
			if (defined($reactionHash->{$rxn}->{$headings->[$i]})) {
				$line .= join("|",@{$reactionHash->{$rxn}->{$headings->[$i]}});
			}
		}
		push(@{$output},$line);
	}
	$self->figmodel()->database()->print_array_to_file($args->{filename},$output);
}

=head3 get_new_temp_id
Definition:
	string = FIGMODELreaction->get_new_temp_id({});
Description:
=cut
sub get_new_temp_id {
	my ($self,$args) = @_;
	$args = $self->figmodel()->process_arguments($args,[],{});
	my $newID;
	my $largestID = 79999;
	my $objs = $self->figmodel()->database()->get_objects("reaction");
	for (my $i=0; $i < @{$objs}; $i++) {
		if (substr($objs->[$i]->id(),3) > $largestID) {
			$largestID = substr($objs->[$i]->id(),3);	
		}
	}
	$largestID++;
	return "rxn".$largestID;
}

=head3 parseGeneExpression
Definition:
	Output:{} = FIGMODELreaction->parseGeneExpression({
		expression => string:GPR gene expression
	});
	Output: {
		genes => [string]:gene IDs	
	}
Description:
=cut
sub parseGeneExpression {
	my ($self,$args) = @_;
	$args = $self->figmodel()->process_arguments($args,["expression"],{});
	my $PegString = $args->{expression};
	$PegString =~ s/\sor\s/|/g;
	$PegString =~ s/\sand\s/+/g;
	my @PegList = split(/[\+\|\s\(\)]/,$PegString);
	my $PegHash;
	for (my $i=0; $i < @PegList; $i++) {
	  if (length($PegList[$i]) > 0) {
	  	$PegHash->{$PegList[$i]} = 1;
	  }
	}
	return {genes => [keys(%{$PegHash})]};
}

=head3 collapseGeneExpression
Definition:
	Output:{} = FIGMODELreaction->collapseGeneExpression({
		originalGPR => [string]
	});
	Output: {
		genes => [string]:gene IDs	
	}
Description:
=cut
sub collapseGeneExpression {
	my ($self,$args) = @_;
	$args = $self->figmodel()->process_arguments($args,["originalGPR"],{});
	#Parsing expession
	my $geneHash;
	my $geneArrays;
	for (my $i=0; $i < @{$args->{originalGPR}}; $i++) {
		my $list = [split(/\+/,$args->{originalGPR}->[$i])];
		push(@{$geneArrays},$list);
		for (my $j=0; $j < @{$list}; $j++) {
			$geneHash->{$list->[$j]} = 1;
		}
	}
	#Identifying coessential gene sets
	my $allGenes = [keys(%{$geneHash})];
	my $genes = [@{$allGenes}];
	my $maxDeletions = 1;
	my $sets;
	while (@{$genes} > 0) {
		my $remainingGeneHash;
		my $geneActivity;
		
		for (my $j=0; $j < @{$genes}; $j++) {
			$remainingGeneHash->{$allGenes->[$j]} = 1;
		}
		my $start;
		for (my $j=0; $j < $maxDeletions; $j++) {
			$start->[$j] = $j;	
		}
		my $current = ($maxDeletions-1);
		while ($current != -1) {
			for (my $j=0; $j < @{$allGenes}; $j++) {
				$geneActivity->{$allGenes->[$j]} = 1;
			}
			my $continue = 1;
			for (my $j=0; $j < $maxDeletions; $j++) {
				if ($remainingGeneHash->{$genes->[$start->[$j]]} == 0) {
					$continue = 0;
					last;
				}
			}
			if ($continue == 1) {
				for (my $j=0; $j < $maxDeletions; $j++) {
					$geneActivity->{$genes->[$start->[$j]]} = 0;
				}
				my $result = $self->evaluateGeneExpression({
					geneActivityHash => $geneActivity,
					geneArrays => $geneArrays
				});
				if ($result == 0) {
					my $newSet;
					for (my $j=0; $j < $maxDeletions; $j++) {
						$remainingGeneHash->{$genes->[$start->[$j]]} = 0;
						push(@{$newSet},$genes->[$start->[$j]]);
					}
					push(@{$sets},$newSet);
				}
			}
			while ($current > -1) {
				$start->[$current]++;
				if ($start->[$current] == (@{$genes}-$maxDeletions+$current+1)) {
					$current--;
				} else {
					for (my $j=$current+1; $j < $maxDeletions; $j++) {
						$start->[$j] = $start->[$current]+1;	
					}
					$current = -1;
				}
			}
		}
		$genes = [];
		foreach my $gene (keys(%{$remainingGeneHash})) {
			if ($remainingGeneHash->{$gene} == 0) {
				push(@{$genes},$gene);
			}
		}
		$maxDeletions++;
	}
	for (my $i=0; $i < @{$genes}; $i++) {
		$geneHash->{$genes->[$i]} = 0;
	}	
}

=head3 evaluateGeneExpression
Definition:
	0/1 = FIGMODELreaction->evaluateGeneExpression({
		geneActivityHash => {},
		geneArrays => [[string]]
	});
Description:
=cut
sub evaluateGeneExpression {
	my ($self,$args) = @_;
	$args = $self->figmodel()->process_arguments($args,["geneActivityHash","geneArrays"],{});
	for (my $i=0; $i < @{$args->{geneArrays}}; $i++) {
		my $activity = 1;
		for (my $j=0; $j < @{$args->{geneArrays}->[$i]}; $j++) {
			if ($args->{geneActivityHash}->{$args->{geneArrays}->[$i]->[$j]} == 0) {
				$activity = 0;
				last;	
			}
		}
		if ($activity == 1) {
			return 1;
		}
	}
	return 0;
}
=head3 printDatabaseTable
Definition:
	undef = FIGMODELreaction->printDatabaseTable({
		filename => string
	});
Description:
=cut
sub printDatabaseTable {
	my ($self,$args) = @_;
	$args = $self->figmodel()->process_arguments($args,[],{
		filename => $self->figmodel()->config("bof data filename")->[0],
		biomassFilename => $self->figmodel()->config("reactions data filename")->[0]
	});
	my $rxn_config = {
		filename => $args->{filename},
		hash_headings => ['id', 'code'],
		delimiter => "\t",
		item_delimiter => "|",
	};
	my $rxntbl = $self->figmodel()->database()->ppo_rows_to_table($rxn_config,$self->figmodel()->database()->get_objects('reaction'));
	$rxntbl->save();
	$rxn_config = {
		filename => $args->{biomassFilename},
		hash_headings => ['id', 'code'],
		delimiter => "\t",
		item_delimiter => "|",
	};
	$rxntbl = $self->figmodel()->database()->ppo_rows_to_table($rxn_config,$self->figmodel()->database()->get_objects('bof'));
	$rxntbl->save();
}
=head3 add_biomass_reaction_from_equation
Definition:
	void FIGMODELdatabase>add_biomass_reaction_from_equation({
		equation => string,
		biomassID => string
	});
Description:
	This function adds a biomass reaction to the database based on its equation. If an ID is specified, that ID is used. Otherwise, a new ID is checked out from the database.
=cut
sub add_biomass_reaction_from_equation {
	my($self,$args) = @_;
	$args = $self->figmodel()->process_arguments($args,["equation"],{
		biomassID => $self->db()->check_out_new_id("bof")
	});
	#Deleting elements in cpdbof table associated with this ID
	my $objs = $self->db()->get_objects("cpdbof",{BIOMASS=>$args->{biomassID}});
	for (my $i=0; $i < @{$objs}; $i++) {
		$objs->[$i]->delete();
	}	
	#Parsing equation
	my ($reactants,$products) = $self->substrates_from_equation({equation => $args->{equation}});
	#Populating the compound biomass table
	my $energy = 0;
	my $compounds;
	$compounds->{RNA} = {cpd00002=>0,cpd00012=>0,cpd00038=>0,cpd00052=>0,cpd00062=>0};
	$compounds->{protein} = {cpd00001=>0,cpd00023=>0,cpd00033=>0,cpd00035=>0,cpd00039=>0,cpd00041=>0,cpd00051=>0,cpd00053=>0,cpd00054=>0,cpd00060=>0,cpd00065=>0,cpd00066=>0,cpd00069=>0,cpd00084=>0,cpd00107=>0,cpd00119=>0,cpd00129=>0,cpd00132=>0,cpd00156=>0,cpd00161=>0,cpd00322=>0};
	$compounds->{DNA} = {cpd00012=>0,cpd00115=>0,cpd00241=>0,cpd00356=>0,cpd00357=>0};
	for (my $j=0; $j < @{$reactants}; $j++) {
		my $category = "U";
		if ($reactants->[$j]->{DATABASE}->[0] eq "cpd00002" || $reactants->[$j]->{DATABASE}->[0] eq "cpd00001") {
			$category = "E";
			if ($energy < $reactants->[$j]->{COEFFICIENT}->[0]) {
				$energy = $reactants->[$j]->{COEFFICIENT}->[0];
			}
		}
		if (defined($compounds->{protein}->{$reactants->[$j]->{DATABASE}->[0]})) {
			$compounds->{protein}->{$reactants->[$j]->{DATABASE}->[0]} = -1*$reactants->[$j]->{COEFFICIENT}->[0];
			$category = "P";
		} elsif (defined($compounds->{RNA}->{$reactants->[$j]->{DATABASE}->[0]})) {
			$compounds->{RNA}->{$reactants->[$j]->{DATABASE}->[0]} = -1*$reactants->[$j]->{COEFFICIENT}->[0];
			$category = "R";
		} elsif (defined($compounds->{DNA}->{$reactants->[$j]->{DATABASE}->[0]})) {
			$compounds->{DNA}->{$reactants->[$j]->{DATABASE}->[0]} = -1*$reactants->[$j]->{COEFFICIENT}->[0];
			$category = "D";
		} else {
			my $obj = $self->db()->get_object("cpdgrp",{type=>"CofactorPackage",COMPOUND=>$reactants->[$j]->{DATABASE}->[0]});
			if (defined($obj)) {
				$compounds->{Cofactor}->{$reactants->[$j]->{DATABASE}->[0]} = -1*$reactants->[$j]->{COEFFICIENT}->[0];
				$category = "C";
			} else { 
				$obj = $self->db()->get_object("cpdgrp",{type=>"LipidPackage",COMPOUND=>$reactants->[$j]->{DATABASE}->[0]});
				if (defined($obj)) {
					$compounds->{Lipid}->{$reactants->[$j]->{DATABASE}->[0]} = -1*$reactants->[$j]->{COEFFICIENT}->[0];
					$category = "L";
				} else {
					$obj = $self->db()->get_object("cpdgrp",{type=>"CellWallPackage",COMPOUND=>$reactants->[$j]->{DATABASE}->[0]});
					if (defined($obj)) {
						$compounds->{CellWall}->{$reactants->[$j]->{DATABASE}->[0]} = -1*$reactants->[$j]->{COEFFICIENT}->[0];
						$category = "W";
					} else {
						$compounds->{Unknown}->{$reactants->[$j]->{DATABASE}->[0]} = -1*$reactants->[$j]->{COEFFICIENT}->[0];
						$category = "U";
					}
				}
			}
		}
		$self->db()->create_object("cpdbof",{COMPOUND=>$reactants->[$j]->{DATABASE}->[0],BIOMASS=>$args->{biomassID},coefficient=>-1*$reactants->[$j]->{COEFFICIENT}->[0],compartment=>$reactants->[$j]->{COMPARTMENT}->[0],category=>$category});
	}
	for (my $j=0; $j < @{$products}; $j++) {
		my $category = "U";
		if ($products->[$j]->{DATABASE}->[0] eq "cpd00008" || $products->[$j]->{DATABASE}->[0] eq "cpd00009" || $products->[$j]->{DATABASE}->[0] eq "cpd00067") {
			$category = "E";
			if ($energy < $products->[$j]->{COEFFICIENT}->[0]) {
				$energy = $products->[$j]->{COEFFICIENT}->[0];
			}
		} elsif ($products->[$j]->{DATABASE}->[0] eq "cpd11416") {
			$category = "M";
		}
		$self->db()->create_object("cpdbof",{COMPOUND=>$products->[$j]->{DATABASE}->[0],BIOMASS=>$args->{biomassID},coefficient=>$products->[$j]->{COEFFICIENT}->[0],compartment=>$products->[$j]->{COMPARTMENT}->[0],category=>$category});
	}
	my $package = {Lipid=>"NONE",CellWall=>"NONE",Cofactor=>"NONE",Unknown=>"NONE"};
	my $coef = {protein=>"NONE",DNA=>"NONE",RNA=>"NONE",Lipid=>"NONE",CellWall=>"NONE",Cofactor=>"NONE",Unknown=>"NONE"};
	my $types = ["protein","DNA","RNA","Lipid","CellWall","Cofactor","Unknown"];
	my $packages;
	my $packageHash;
	for (my $i=0; $i < @{$types}; $i++) {
		my @entities = sort(keys(%{$compounds->{$types->[$i]}}));
		if (@entities > 0) {
			$coef->{$types->[$i]} = "";
		}
		if (@entities > 0 && ($types->[$i] eq "Lipid" || $types->[$i] eq "CellWall" || $types->[$i] eq "Cofactor" || $types->[$i] eq "Unknown")) {
			my $cpdgrpObs = $self->db()->get_objects("cpdgrp",{type=>$types->[$i]."Package"});
			for (my $j=0; $j < @{$cpdgrpObs}; $j++) {
				$packages->{$types->[$i]}->{$cpdgrpObs->[$j]->grouping()}->{$cpdgrpObs->[$j]->COMPOUND()} = 1;
			}
			my @packageList = keys(%{$packages->{$types->[$i]}});
			for (my $j=0; $j < @packageList; $j++) {
				$packageHash->{join("|",sort(keys(%{$packages->{$types->[$i]}->{$packageList[$j]}})))} = $packageList[$j];
			}
			if (defined($packageHash->{join("|",@entities)})) {
				$package->{$types->[$i]} = $packageHash->{join("|",@entities)};
			} else {
				$package->{$types->[$i]} = $self->db()->check_out_new_id($types->[$i]."Package");
				my @cpdList = keys(%{$compounds->{$types->[$i]}});
				for (my $j=0; $j < @cpdList; $j++) {
					$self->db()->create_object("cpdgrp",{COMPOUND=>$cpdList[$j],grouping=>$package->{$types->[$i]},type=>$types->[$i]."Package"});
				}
			}
		}
		for (my $j=0; $j < @entities; $j++) {
			if ($j > 0) {
				$coef->{$types->[$i]} .= "|";
			}
			$coef->{$types->[$i]} .= $compounds->{$types->[$i]}->{$entities[$j]};
		}
	}
    my $data = { essentialRxn => "NONE", owner => "master", name => "Biomass", public => 1,
                 equation => $args->{equation}, modificationDate => time(), creationDate => time(),
                 id => $args->{biomassID}, cofactorPackage => $package->{Cofactor}, lipidPackage => $package->{Lipid},
                 cellWallPackage => $package->{CellWall}, unknownCoef => $coef->{Unknown},
                 unknownPackage => $package->{Unknown}, protein => "0", DNA => "0", RNA => "0",
                 lipid => "0", cellWall => "0", cofactor => "0", proteinCoef => $coef->{protein},
                 DNACoef => $coef->{DNA}, RNACoef => $coef->{RNA}, lipidCoef => $coef->{Lipid},
                 cellWallCoef => $coef->{CellWall}, cofactorCoef => $coef->{Cofactor}, energy => $energy };
	if (length($data->{unknownCoef}) >= 255) {
		$data->{unknownCoef} = substr($data->{unknownCoef},0,254);
	}
	my $bofobj = $self->db()->sudo_get_object("bof",{id=>$args->{biomassID}});
	if (!defined($bofobj)) {
		$bofobj = $self->db()->create_object("bof",$data);
	} else {
		foreach my $key (keys(%{$data})) {
			$bofobj->$key($data->{$key});
		}
	}
    return $bofobj;
}
=head3 add_biomass_reaction_from_file
definition:
	(success/fail) = figmodeldatabase>add_biomass_reaction_from_file(string:biomass id);
=cut
sub add_biomass_reaction_from_file {
	my($self,$biomassid) = @_;
	my $object = $self->figmodel()->loadobject($biomassid);
	$self->add_biomass_reaction_from_equation($object->{equation}->[0],$biomassid);
}


=head3 replacesReaction 
definition
    (success/fail) = figmodelreaction->replacesReaction(other_reaction)
    where other_reaction is either a FIGMODELreaction object or
    a string "rxn00001". The passed in reaction is replaced with
    the current reaction in the active database.
=cut
sub replacesReaction {
    my ($self, $reaction) = @_;
    unless(ref($reaction) =~ "FIGMODELreaction") {
        $reaction = $self->figmodel->get_reaction($reaction);
    }
    my $newId = $self->id();
    my $oldId = $reaction->id();
    # Reaction Alias
    my $newAliases = $self->db()->get_objects("rxnals", { 'REACTION' => $newId });
    my %newAliasHash = map { $_->type() => $_->alias() } @$newAliases;
    my $oldAliases = $self->db()->get_objects("rxnals", { 'REACTION' => $oldId });
    foreach my $als (@$oldAliases) {
        if(defined($newAliasHash{$als->type()}) &&
            $newAliasHash{$als->type()} eq $als->alias()) {
            $als->delete();
        } else {
            $als->REACTION($newId);
        }
    }
    # Reaction Compound
    my $oldRxnCpds = $self->db()->get_objects("cpdrxn", { 'REACTION' => $oldId});
    foreach my $rxnCpd (@$oldRxnCpds) {
        $rxnCpd->delete();
    }
    # Reaction Grouping
    my $newRxnGrps = $self->db()->get_objects("rxngrp", { "REACTION" => $newId});
    my %newRxnGrpHash = map { $_->grouping() => $_->type() } @$newRxnGrps;
    my $oldRxnGrps = $self->db()->get_objects("rxngrp", { "REACTION" => $oldId});
    foreach my $rxnGrp (@$oldRxnGrps) {
        if (defined($newRxnGrpHash{$rxnGrp->grouping()}) &&
            $newRxnGrpHash{$rxnGrp->grouping()} eq $rxnGrp->type()) {
            $rxnGrp->delete();
        } else {
            $rxnGrp->REACTION($newId);
        }
    }
    # Reaction Complex
    my $newRxnCpxs = $self->db()->get_objects("rxncpx", { "REACTION" => $newId});
    my %newRxnCpxHash = map { $_->COMPLEX() => $_ } @$newRxnCpxs;
    my $oldRxnCpxs = $self->db()->get_objects("rxncpx", { "REACTION" => $oldId});
    foreach my $rxnCpx (@$oldRxnCpxs) {
        if(defined($newRxnCpxHash{$rxnCpx->COMPLEX()})) {
            $rxnCpx->delete();
        } else {
            $rxnCpx->REACTION($newId);
        }
    }
    # Reaction Model
    my $newRxnMdls = $self->db()->get_objects("rxnmdl", { "REACTION" => $newId});
    my %newRxnMdlHash = map { $_->MODEL() => $_->compartment() } @$newRxnMdls;
    my $oldRxnMdls = $self->db()->get_objects("rxnmdl", { "REACTION" => $oldId});
    foreach my $rxnMdl (@$oldRxnMdls) {
        if(defined($newRxnMdlHash{$rxnMdl->MODEL()}) &&
            $newRxnMdlHash{$rxnMdl->MODEL()} eq $rxnMdl->compartment()) {
            $rxnMdl->delete();
        } else {
            $rxnMdl->REACTION($newId);
        }
    }
    # Now delete the old reaction
    my $oldRxns = $self->db()->get_objects("reaction", { "id" => $oldId});
    $oldRxns->[0]->delete() if(@$oldRxns > 0);
    # Now create the obsolete alias 
    my $rxnalsObs = $self->db()->get_object("rxnals", { "REACTION" => $newId, "type" => "obsolete", "alias" => $oldId});
    unless(defined($rxnalsObs)) {
        $self->db()->create_object("rxnals", { "REACTION" => $newId, "type" => "obsolete", "alias" => $oldId});
    }
    return 1;
}

=head3 get_reaction_reversibility_hash
Definition:
	Output = FIGMODELreaction->get_reaction_reversibility_hash();
	Output: {
		string:reaction ID => string:reversibility
	}
Description:
	This function returns a hash of all reactions with their reversiblities.
=cut
sub get_reaction_reversibility_hash {
	my ($self) = @_;
	my $objs = $self->db->get_objects("reaction");
	my $revHash;
	for (my $i=0; $i < @{$objs};$i++) {
		my $rev = "<=>";
		if ($objs->[$i]->id() =~ m/^bio/ || defined($self->figmodel()->{"forward only reactions"}->{$objs->[$i]->id()})) {
			$rev = "=>";
		} elsif (defined($self->figmodel()->{"reverse only reactions"}->{$objs->[$i]->id()})) {
			$rev = "<=";
		} elsif (defined($self->figmodel()->{"reversibility corrections"}->{$objs->[$i]->id()})) {
			$rev = "<=>";
		} else {
			$rev = $objs->[$i]->reversibility();
		}
		$revHash->{$objs->[$i]->id()} = $rev;
	}
	return $revHash;
}

1;
