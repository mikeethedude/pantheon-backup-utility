# pantheon-backup-utility

Somewhat useful backup script for use with Pantheon in local development.

Put it in your private/scripts directory in the root of your Drupal Repo for best results.

Usage: sh panback.sh site.env type
* site is the name of your Pantheon site. The first part of your Pantheon url blah.pantheonsite.io.
* env is the name of the Pantheopn environment. live, test, dev, or multidev names.
* type can be db, files, or all.


Example usage: sh panback.sh example-site.dev db
