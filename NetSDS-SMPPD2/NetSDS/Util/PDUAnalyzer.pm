package NetSDS::Util::PDUAnalyzer;

=head1 NAME

NetSDS::Util::PDUAnalyzer - turn Net::SMPP PDUs into human-readable descriptions

=head1 USAGE

	use NetSDS::Util::PDUAnalyzer;
	
	my @lines = NetSDS::Util::PDUAnalyzer->decode($command_id, $pdu);
	my $single_string = NetSDS::Util::PDUAnalyzer->decode($command_id, $pdu); # The same, joined 
		# with newlines

In this example, $command_id must contain a numeric command ID, as it is not passed
into the PDU record. $pdu is a Net::SMPP::PDU object, although any hash with known keys
would do.

Returned is a text transcript of the PDU. Parameters are ordered alphabetically.

If an unknown parameter is seen, it is transcribed as follows:

=over

=item *

An undef is turned into "(undefined)"

=item *

If the value looks like an integer, it is presented along with its hex value, like
255 (0xff).

=item *

If the value is a string which only contains printable ASCII characters, it is presented as
a double-quoted string.

=item *

Otherwise, a hex dump is presented.

=back

=cut

use strict;
use warnings;
use 5.8.0;

use constant {
	protocol_id_telematic_map => {
		0x00 => 'default',
		0x01 => 'telex',
		0x02 => 'group 3 telefax',
		0x03 => 'group 4 telefax',
		0x04 => 'voice telephone',
		0x05 => 'ERMES',
		0x06 => 'national paging system',
		0x07 => 'videotex (T.100/T.101)',
		0x08 => 'teletex, carrier unspecified',
		0x09 => 'teletex, in PSPDN',
		0x0a => 'teletex, in CSPDN',
		0x0b => 'teletex, in analogue PSTN',
		0x0c => 'teletex, in digital ISDN',
		0x0d => 'UCI',
		0x10 => 'a message handling facility',
		0x11 => 'X.400',
		0x12 => 'email',
		0x1f => 'GSM mobile station'
	},
	protocol_id_replace_map => {
		0x00 => 'short message type 0',
		0x01 => 'replace short message type 1',
		0x02 => 'replace short message type 2',
		0x03 => 'replace short message type 3',
		0x04 => 'replace short message type 4',
		0x05 => 'replace short message type 5',
		0x06 => 'replace short message type 6',
		0x07 => 'replace short message type 7',
		0x1f => 'return call message',
		0x3f => 'SIM data download'
	},
	ton_map => {
		0 => 'Unknown',
		1 => 'International',
		2 => 'National',
		3 => 'Network specific',
		4 => 'Subscriber number',
		5 => 'Alphanumeric',
		6 => 'Abbreviated'
	},
	npi_map => {
		0  => 'unknown',
		1  => 'ISDN (E163/E164)',
		3  => 'Data (X.121)',
		4  => 'Telex (F.69)',
		6  => 'Land Mobile (E.212)',
		8  => 'National',
		9  => 'Private',
		10 => 'ERMES',
		12 => 'Internet (IP)',
		18 => 'WAP Client ID'
	},
	esm_class_esme_mmode_map => {
		0 => 'default SMSC mode',
		1 => 'datagram',
		2 => 'forward',
		3 => 'store and forward'
	},
	esm_class_esme_mtype_map => {
		0 => 'default message type',
		2 => 'has ESME Delivery Acknowledgement',
		4 => 'has ESME Manual/User Acknowledgement'
	},
	esm_class_gsm_map => {
		0 => 'No features selected',
		1 => 'UDHI Indicator',
		2 => 'Reply Path'
	},
	esm_class_smsc_mtype_map => {
		0 => 'Default message type',
		1 => 'Contains SMSC Delivery Receipt',
		2 => 'Contains SME Delivery Acknowledgement',
		3 => '(reserved)',
		4 => 'Contains SME Manual/User Acknowledgement',
		5 => '(reserved)',
		6 => 'Contains Conversation Abort',
		7 => '(reserved)',
		8 => 'Contains Intermediate Delivery Notification'
	},
	priority_flag_map => {
		0 => 'lowest (level 0)',
		1 => 'level 1',
		2 => 'level 2',
		3 => 'highest (level 3)'
	},
	registered_delivery_smsc_dlr_map => {
		0 => 'No SMSC delivery',
		1 => 'SMSC success/failure receipt',
		2 => 'SMSC failure receipt',
		3 => '(reserved)',
	},
	registered_delivery_sme_oa_map => {
		0 => 'No SME acknowledgement',
		1 => 'SME delivery acknowledgement',
		2 => 'SME delivery failure receipt',
		3 => 'Both delivery and user/manual acknowledgement'
	},
	registered_delivery_sme_in_map => {
		0 => 'No intermediate notification',
		1 => 'Intermediate notification requested'
	},
	message_state_map => {
		1 => 'ENROUTE',
		2 => 'DELIVERED',
		3 => 'EXPIRED',
		4 => 'DELETED',
		5 => 'UNDELIVERABLE',
		6 => 'ACCEPTED',
		7 => 'UNKNOWN',
		8 => 'REJECTED',
	},
	command_id_map => {
		0x80000000 => 'generic_nack',
		0x00000001 => 'bind_receiver',
		0x80000001 => 'bind_receiver_resp',
		0x00000002 => 'bind_transmitter',
		0x80000002 => 'bind_transmitter_resp',
		0x00000003 => 'query_sm',
		0x80000003 => 'query_sm_resp',
		0x00000004 => 'submit_sm',
		0x80000004 => 'submit_sm_resp',
		0x00000005 => 'deliver_sm',
		0x80000005 => 'deliver_sm_resp',
		0x00000006 => 'unbind',
		0x80000006 => 'unbind_resp',
		0x00000007 => 'replace_sm',
		0x80000007 => 'replace_sm_resp',
		0x00000008 => 'cancel_sm',
		0x80000008 => 'cancel_sm_resp',
		0x00000009 => 'bind_transceiver',
		0x80000009 => 'bind_transceiver_resp',
		0x0000000b => 'outbind',
		0x00000015 => 'enquire_link',
		0x80000015 => 'enquire_link_resp',
		0x00000021 => 'submit_multi',
		0x80000021 => 'submit_multi_resp',
		0x00000102 => 'alert_notification',
		0x00000103 => 'data_sm',
		0x80000103 => 'data_sm_resp',
	},
	error_code_map => {
		0x00000000 => '(ESME_ROK) No error',
		0x00000001 => '(ESME_RINVMSGLEN) Message Length is invalid',
		0x00000002 => '(ESME_RINVCMDLEN) Command Length is invalid',
		0x00000003 => '(ESME_RINVCMDID) Invalid Command ID',
		0x00000004 => '(ESME_RINVBNDSTS) Incorrect BIND Status for given command',
		0x00000005 => '(ESME_RALYBND) ESME Already in Bound State',
		0x00000006 => '(ESME_RINVPRTFLG) Invalid Priority Flag',
		0x00000007 => '(ESME_RINVREGDLVFLG) Invalid Registered Delivery Flag',
		0x00000008 => '(ESME_RSYSERR) System Error',
		0x0000000a => '(ESME_RINVSRCADR) Invalid Source Address',
		0x0000000b => '(ESME_RINVDSTADR) Invalid Dest Addr',
		0x0000000c => '(ESME_RINVMSGID) Message ID is invalid',
		0x0000000d => '(ESME_RBINDFAIL) Bind Failed',
		0x0000000e => '(ESME_RINVPASWD) Invalid Password',
		0x0000000f => '(ESME_RINVSYSID) Invalid System ID',
		0x00000011 => '(ESME_RCANCELFAIL) Cancel SM Failed',
		0x00000013 => '(ESME_RREPLACEFAIL) Replace SM Failed',
	},
	data_coding_map => {
		0x00 => 'SMSC default',
		0x01 => 'IA5(CCITTT.50)/ASCII(ANSIX3.4)',
		0x02 => 'Octet unspecified (8-bit binary)',
		0x03 => 'Latin1 (ISO-8859-1)',
		0x04 => 'Octet unspecified (8-bit binary)',
		0x05 => 'JIS (X0208-1990)',
		0x06 => 'Cyrillic (ISO-8859-5)',
		0x07 => 'Latin/Hebrew (ISO-8859-8)',
		0x08 => 'UCS2(ISO/IEC-10646)',
		0x09 => 'Pictogram Encoding',
		0x0a => 'ISO-2022-JP (Music Codes)',
		0x0d => 'Extended Kanji JIS(X 0212-1990)',
		0x0e => 'KS C 5601',
		0xc0 => 'MWI group: discard | Indication inactive | Voicemail Message Waiting',
		0xc1 => 'MWI group: discard | Indication inactive | Fax Message Waiting',
		0xc2 => 'MWI group: discard | Indication inactive | Email Message Waiting',
		0xc3 => 'MWI group: discard | Indication inactive | Other Message Waiting',
		0xc4 => 'MWI group: discard | Indication active | Voicemail Message Waiting',
		0xc5 => 'MWI group: discard | Indication active | Fax Message Waiting',
		0xc6 => 'MWI group: discard | Indication active | Email Message Waiting',
		0xc7 => 'MWI group: discard | Indication active | Other Message Waiting',
		0xd0 => 'MWI group: store | Indication inactive | Voicemail Message Waiting',
		0xd1 => 'MWI group: store | Indication inactive | Fax Message Waiting',
		0xd2 => 'MWI group: store | Indication inactive | Email Message Waiting',
		0xd3 => 'MWI group: store | Indication inactive | Other Message Waiting',
		0xd4 => 'MWI group: store | Indication active | Voicemail Message Waiting',
		0xd5 => 'MWI group: store | Indication active | Fax Message Waiting',
		0xd6 => 'MWI group: store | Indication active | Email Message Waiting',
		0xd7 => 'MWI group: store | Indication active | Other Message Waiting',
		0xf0 => 'Message class: default alphabet | class 0',
		0xf1 => 'Message class: default alphabet | ME-specific',
		0xf2 => 'Message class: default alphabet | SIM-specific',
		0xf3 => 'Message class: default alphabet | TE-specific',
		0xf4 => 'Message class: 8-bit data | class 0',
		0xf5 => 'Message class: 8-bit data | ME-specific',
		0xf6 => 'Message class: 8-bit data | SIM-specific',
		0xf7 => 'Message class: 8-bit data | TE-specific',		
	}
};

sub decode {
	my ( $class, $command_id, $pdu ) = @_;
	my @result = ();
	push @result, "PDU BEGIN: " . __PACKAGE__->format_command_id( $command_id, $command_id, $pdu );
	foreach my $key ( sort( keys(%$pdu) ) ) {
		if ( __PACKAGE__->can( 'format_' . $key ) ) {
			my $m = 'format_' . $key;
			push @result, ( "  $key: " . $class->$m( $command_id, $pdu->{$key}, $pdu ) );
		} else {
			my @formatted       = $class->_format_universal( $pdu->{$key} );
			my $fmt_lines_count = @formatted;
			if ( $fmt_lines_count > 1 ) {
				push @result, ("  $key: ");
				push @result, @formatted;
			} else {
				push @result, ( "  $key: " . join( "-", @formatted ) );
			}
		}
	}
	push @result, "PDU END";
	if (wantarray) {
		return @result;
	}
	return join( "\n", @result );
} ## end sub decode

sub _format_str {
	my ( $this, $arg ) = @_;
	return "'" . $arg . "'";
}

sub _format_universal {
	my ( $this, $arg ) = @_;
	unless ( defined($arg) ) {
		return '(undefined)';
	}

	if ( $arg =~ /^-?[0-9]+$/ ) {
		return $this->_format_number($arg);
	} elsif ( $arg =~ /^[\x20-\x7e]+$/ ) {
		return $this->_format_str($arg);
	} elsif ( !defined($arg) ) {
		return '(undefined)';
	} else {
		return $this->_format_hex($arg);
	}
}

sub _format_number {
	my ( $this, $arg ) = @_;
	return sprintf( "%d (0x%x)", $arg, $arg );
}

sub _format_hex {
	use bytes;
	my ( $this, $arg ) = @_;
	my @result = ();
	my $width  = 16;
	my $offset = 0;
	while ( length($arg) > 0 ) {
		my @bufl = ();
		my $bufr = '';
		my $src  = substr( $arg, 0, $width );
		if ( $src ne $arg ) {
			$arg = substr( $arg, length($src) - 1 );
		} else {
			$arg = '';
		}
		for ( my $i = 0 ; $i < length($src) ; $i++ ) {
			my $c = substr( $src, $i, 1 );
			push @bufl, uc( sprintf( "%02x", ord($c) ) );
			if ( ( ord($c) >= 128 ) || ( ord($c) < 32 ) ) {
				$bufr .= '.';
			} else {
				$bufr .= $c;
			}
		}
		push @result, sprintf( "%04x: ", $offset ) . join( "    ", join( " ", @bufl ), " " x ( ( $width - length($src) ) * 3 ), $bufr );
		$offset += length($src);
	} ## end while ( length($arg) > 0 )
	no bytes;
	return @result;
} ## end sub _format_hex

sub _format_ton {
	my ( $this, $ton ) = @_;
	return sprintf( "%s (%x)", $this->ton_map->{$ton}, $ton );
}

sub _format_npi {
	my ( $this, $npi ) = @_;
	return sprintf( "%s (%x)", $this->npi_map->{$npi}, $npi );
}

sub format_addr_ton {
	my ( $this, $cmd, $ton, $pdu ) = @_;
	return $this->_format_ton($ton);
}

sub format_source_addr_ton {
	my ( $this, $cmd, $ton, $pdu ) = @_;
	return $this->_format_ton($ton);
}

sub format_dest_addr_ton {
	my ( $this, $cmd, $ton, $pdu ) = @_;
	return $this->_format_ton($ton);
}

sub format_destination_addr_ton {
	return format_dest_addr_ton(@_);
}

sub format_esme_addr_ton {
	my ( $this, $cmd, $ton, $pdu ) = @_;
	return $this->_format_ton($ton);
}

sub format_addr_npi {
	my ( $this, $cmd, $npi, $pdu ) = @_;
	return $this->_format_npi($npi);
}

sub format_source_addr_npi {
	my ( $this, $cmd, $npi, $pdu ) = @_;
	return $this->_format_npi($npi);
}

sub format_dest_addr_npi {
	my ( $this, $cmd, $npi, $pdu ) = @_;
	return $this->_format_npi($npi);
}

sub format_destination_addr_npi {
	return format_dest_addr_npi(@_);
}

sub format_esme_addr_npi {
	my ( $this, $cmd, $npi, $pdu ) = @_;
	return $this->_format_npi($npi);
}

sub format_interface_version {
	my ( $this, $cmd, $value, $pdu ) = @_;
	return "SMPP version " . ( ( $value >> 4 ) & 0x0F ) . "." . ( $value & 0x0F );
}

sub format_interface_type {
	return format_interface_version(@_);
}

sub format_command_id {
	my ( $this, $cmd, $value, $pdu ) = @_;
	my $result = $this->command_id_map->{$cmd};
	if ( !$result ) {
		return sprintf( "unknown command_id, %d (0x%08x)", $cmd, $cmd );
	}
	return $result;
}

sub format_cmd {
	return format_command_id(@_);
}

sub format_esme_addr {
	my ( $this, $cmd, $value, $pdu ) = @_;
	return $this->_format_str($value);
}

sub format_source_addr {
	my ( $this, $cmd, $value, $pdu ) = @_;
	return $this->_format_str($value);
}

sub format_dest_addr {
	my ( $this, $cmd, $value, $pdu ) = @_;
	return $this->_format_str($value);
}

sub format_destination_addr {
	return format_dest_addr(@_);
}

sub format_service_type {
	my ( $this, $cmd, $value, $pdu ) = @_;
	return $this->_format_str($value);
}

sub format_system_type {
	my ( $this, $cmd, $value, $pdu ) = @_;
	return $this->_format_str($value);
}

sub format_system_id {
	my ( $this, $cmd, $value, $pdu ) = @_;
	return $this->_format_number($value);
}

sub format_address_range {
	my ( $this, $cmd, $value, $pdu ) = @_;
	return $this->_format_str($value);
}

sub _format_esm_class {
	my ( $this, $value, $cmd ) = @_;
	my @mgsm_buf = ();
	my $result;
	foreach my $k ( keys( %{ $this->esm_class_gsm_map } ) ) {
		if ( ( $value >> 6 ) & $k ) {
			push @mgsm_buf, $this->esm_class_gsm_map->{$k};
		}
	}
	my $mgsm = join( " / ", @mgsm_buf );
	unless ($mgsm) {
		$mgsm = $this->esm_class_gsm_map->{0};
	}
	if ( ( $cmd == 0x04 ) || ( $cmd == 0x21 ) || ( $cmd == 0x103 ) ) {
		my $buf   = "Messaging mode: %s | Message type: %s | GSM Features: %s";
		my $mmode = $this->esm_class_esme_mmode_map->{ ( $value & 0x03 ) };
		my $mtype = $this->esm_class_esme_mtype_map->{ ( ( $value >> 2 ) & 0x0f ) };
		$result = sprintf( $buf, $mmode, $mtype, $mgsm );
	} else {
		my $buf = "Message type: %s | GSM Features: %s";
		my $mtype = $this->esm_class_smsc_mtype_map->{ ( ( $value >> 2 ) & 0x0f ) };
		$result = sprintf( $buf, $mtype, $mgsm );
	}
	return $result;
} ## end sub _format_esm_class

sub format_esm_class {
	my ( $this, $cmd, $value, $pdu ) = @_;
	return $this->_format_esm_class( $value, $cmd );
}

sub format_registered_delivery {
	my ( $this, $cmd, $value, $pdu ) = @_;
	my $buf    = "SMSC Delivery Receipt: %s | SME Originated Acknowledgement: %s | Intermediate Notification: %s";
	my $smsc   = $this->registered_delivery_smsc_dlr_map->{ ( $value & 0x03 ) };
	my $sme    = $this->registered_delivery_sme_oa_map->{ ( ( $value >> 2 ) & 0x03 ) };
	my $id     = $this->registered_delivery_sme_in_map->{ ( ( $value >> 4 ) & 0x01 ) };
	my $result = sprintf( $buf, $smsc, $sme, $id );
	return $result;
}

sub format_protocol_id {
	my ( $this, $cmd, $value, $pdu ) = @_;
	my $result = '';
	if ( ( $value & 0xC0 ) == 0 ) {
		if ( $value & 0x20 ) {
			$result = 'Telematic interworking: ' . $this->protocol_id_telematic_map->{ ( $value & 0x1f ) };
		} else {
			$result = 'SME-to-SME: ' . $this->protocol_id_telematic_map->{ ( $value & 0x1f ) };
		}
	} elsif ( ( $value & 0xC0 ) == 0x40 ) {
		$result = $this->protocol_id_replace_map->{ ( $value & 0x3f ) };
	}
	return $result;
}

sub format_message_state {
	my ( $this, $cmd, $value, $pdu ) = @_;
	return $this->message_state_map->{$value};
}

sub format_priority_flag {
	my ( $this, $cmd, $value, $pdu ) = @_;
	return $this->_format_number($value);
}

sub format_data_coding {
	my ( $this, $cmd, $value, $pdu ) = @_;
	return sprintf("%s (%02x)", $this->data_coding_map->{$value}, $value);
}

sub format_error_code {
	my ( $this, $cmd, $value, $pdu ) = @_;
	return sprintf("%s (%04x)", $this->error_code_map->{$value}, $value);	
}

1;
