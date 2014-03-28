Set( $rtname, "example.org" );
Set( $WebPort, 8080 );
Set( $WebDomain, "rt.example.org" );
Set( $DatabaseHost, $ENV{DB_1_PORT_5432_TCP_ADDR} || \
                    $ENV{DB_PORT_5432_TCP_ADDR} );
Set( $DatabasePassword, $ENV{RT_DATABASE_PW} );
Set( $LogToSyslog, "info" );
Set( $Timezone, "UTC" );

# GnuPG support requires extra work downstream to enable
Set( %GnuPG, Enable => 0 );

Plugin( "RT::Extension::ActivityReports" );
Plugin( "RT::Extension::ResetPassword" );
Plugin( "RT::Extension::MergeUsers" );
Plugin( "RT::Extension::SpawnLinkedTicketInQueue" );

Plugin( "RT::Extension::CommandByMail" );
Set( @MailPlugins, qw(Auth::MailFrom Filter::TakeAction) );

Plugin( "RT::Extension::RepeatTicket" );
Set( $RepeatTicketCoexistentNumber, 1 );
Set( $RepeatTicketLeadTime, 14 );
Set( $RepeatTicketSubjectFormat, '__Subject__' );

Set( %FullTextSearch,
    Enable     => 1,
    Indexed    => 1,
    Column     => 'ContentIndex',
    Table      => 'Attachments',
);

Set( @Active_MakeClicky, qw(httpurl_overwrite short_ticket_link) );

1;
