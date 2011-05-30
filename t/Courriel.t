use strict;
use warnings;

use Test::Fatal;
use Test::More 0.88;

use Courriel;

{
    my $text = <<'EOF';
Subject: Foo

This is the body
EOF

    my $email = Courriel->parse( text => \$text );

    is( $email->part_count(), 1, 'email has one part' );

    is_deeply(
        [ $email->headers()->headers() ],
        [ Subject => 'Foo' ],
        'headers were parsed correctly'
    );

    my ($part) = $email->parts();
    is(
        $part->content_type()->mime_type(),
        'text/plain',
        'email with no content type defaults to text/plain'
    );

    is(
        $part->content_type()->charset(),
        'us-ascii',
        'email with no charset defaults to us-ascii'
    );

    is(
        $part->encoding(),
        '8bit',
        'email with no encoding defaults to 8bit'
    );

    is_deeply(
        $part->content(),
        \$text,
        'content for part was parsed correctly'
    );

    isa_ok( $email->datetime(), 'DateTime' );
}

{
    my $text = <<'EOF';
From autarch@gmail.com Sun May 29 11:22:29 2011
MIME-Version: 1.0
Date: Sun, 29 May 2011 11:22:22 -0500
Message-ID: <BANLkTimjF2BDbOKO_2jFJsp6t+0KvqxCwQ@mail.gmail.com>
Subject: Testing
From: Dave Rolsky <autarch@gmail.com>
To: Dave Rolsky <autarch@urth.org>
Content-Type: multipart/alternative; boundary=20cf3071cfd06272ae04a46c9306


--20cf3071cfd06272ae04a46c9306
Content-Type: text/plain; charset=ISO-8859-1

This is a test email.

It has some *bold* text.

--20cf3071cfd06272ae04a46c9306
Content-Type: text/html; charset=ISO-8859-1

This is a test email.<br><br>It has some <b>bold</b> text.<br><br>

--20cf3071cfd06272ae04a46c9306--
EOF

    my $email = Courriel->parse( text => \$text );

    is( $email->part_count(), 2, 'email has two parts' );

    is_deeply(
        [ $email->headers()->headers() ],
        [
            'MIME-Version' => '1.0',
            'Date'         => 'Sun, 29 May 2011 11:22:22 -0500',
            'Message-ID' =>
                '<BANLkTimjF2BDbOKO_2jFJsp6t+0KvqxCwQ@mail.gmail.com>',
            'Subject' => 'Testing',
            'From'    => 'Dave Rolsky <autarch@gmail.com>',
            'To'      => 'Dave Rolsky <autarch@urth.org>',
            'Content-Type' =>
                'multipart/alternative; boundary=20cf3071cfd06272ae04a46c9306',
        ],
        'headers were parsed correctly'
    );

    my @parts = $email->parts();

    is(
        $parts[0]->content_type()->mime_type(),
        'text/plain',
        'first part is text/plain'
    );

    my $plain = <<'EOF';
This is a test email.

It has some *bold* text.

EOF

    is_deeply(
        $parts[0]->content(),
        \$plain,
        'plain content is as expected',
    );

    is(
        $parts[1]->content_type()->mime_type(),
        'text/html',
        'second part is text/html'
    );

    my $html = <<'EOF';
This is a test email.<br><br>It has some <b>bold</b> text.<br><br>

EOF

    is_deeply(
        $parts[1]->content(),
        \$html,
        'html content is as expected',
    );

    is(
        $email->datetime(),
        DateTime->new(
            year      => 2011,
            month     => 5,
            day       => 29,
            hour      => 11,
            minute    => 22,
            second    => 22,
            time_zone => '-0500',
        ),
        'email datetime is parsed from Date header correctly'
    );
}

{
    my $text = <<'EOF';
Received: from urth.org ([127.0.0.1])
    by localhost (urth.org [127.0.0.1]) (amavisd-new, port 10024)
    with ESMTP id LdGtFbrMk+AE for <autarch@urth.org>;
    Fri, 27 May 2011 11:24:48 -0500 (CDT)
Received: from exploreveg.org (exploreveg.org [173.11.48.51])
    (using TLSv1 with cipher ADH-AES256-SHA (256/256 bits))
    (No client certificate requested)
    by urth.org (Postfix) with ESMTPS id 08B6A171735
    for <autarch@urth.org>; Fri, 27 May 2011 11:24:44 -0500 (CDT)
MIME-Version: 1.0
Message-ID: <BANLkTimjF2BDbOKO_2jFJsp6t+0KvqxCwQ@mail.gmail.com>
Subject: Testing
From: Dave Rolsky <autarch@gmail.com>
To: Dave Rolsky <autarch@urth.org>
Content-Type: text/plain

Whatever
EOF

    my $email = Courriel->parse( text => \$text );

    is(
        $email->datetime(),
        DateTime->new(
            year      => 2011,
            month     => 5,
            day       => 27,
            hour      => 11,
            minute    => 24,
            second    => 44,
            time_zone => '-0500',
        ),
        'email datetime is parsed from Received header correctly'
    );
}

{
    my $text = <<'EOF';
From autarch@gmail.com Sun May 29 11:22:29 2011
MIME-Version: 1.0
Resent-Date: Sun, 29 May 2011 11:22:23 -0500
Message-ID: <BANLkTimjF2BDbOKO_2jFJsp6t+0KvqxCwQ@mail.gmail.com>
Subject: Testing
From: Dave Rolsky <autarch@gmail.com>
To: Dave Rolsky <autarch@urth.org>
Content-Type: text/plain

Whatever
EOF

    my $email = Courriel->parse( text => \$text );

    is(
        $email->datetime(),
        DateTime->new(
            year      => 2011,
            month     => 5,
            day       => 29,
            hour      => 11,
            minute    => 22,
            second    => 23,
            time_zone => '-0500',
        ),
        'email datetime is parsed from Resent-Date header correctly'
    );
}

done_testing();