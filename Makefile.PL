use 5.022000;
use ExtUtils::MakeMaker;
WriteMakefile(
  NAME              => 'App::dwclean',
  VERSION_FROM      => 'lib/Geo/Coordinates/MGRS/XS.pm',
  PREREQ_PM         => { 'Test::More' => 0 },
  ABSTRACT_FROM     => '',
  AUTHOR            => 'christian svindseth <christian.svindseth@nhm.uio.no>',
  LICENSE           => 'perl',
  LIBS              => ['-lm'],
  DEFINE            => '',
  INC               => '-I.',
  OBJECT            => '$(O_FILES)',
);

