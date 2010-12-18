use inc::Module::Install;
name 'I18N-Handle';
all_from 'lib/I18N/Handle.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;

readme_markdown_from 'lib/I18N/Handle.pm';

WriteAll;
