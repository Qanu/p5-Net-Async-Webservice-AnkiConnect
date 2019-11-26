#!/bin/bash

CURDIR=`dirname "$0"`
cd $CURDIR/..
diff -U 3 <( grep '^api' lib/Renard/API/AnkiConnect/REST.pm | sed 's/ =>.*$//' ) <( grep '=head3' lib/Renard/API/AnkiConnect/REST.pod  | sed 's/=head3/api/g' )
