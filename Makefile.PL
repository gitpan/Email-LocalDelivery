use strict;
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Email::LocalDelivery',
    'VERSION_FROM' => 'LocalDelivery.pm',
    'PREREQ_PM'    => { 'Email::Simple'      => '1.4',
                        'Email::FolderType'  => '0.3',
                        'File::Path::Expand' => 0,
                        'Test::More'         => 0 },
);
