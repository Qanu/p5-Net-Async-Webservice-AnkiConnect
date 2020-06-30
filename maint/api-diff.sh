#!/bin/bash

CURDIR=`dirname "$0"`
cd $CURDIR/..
GET_API_FROM_PM="grep '^api' lib/Renard/API/AnkiConnect/REST.pm | sed 's/ =>.*$//'"
GET_API_FROM_POD="grep '=head2' lib/Renard/API/AnkiConnect/REST.pod  | sed 's/=head2/api/g; s/C<//; s/>//;'"
echo -n "Checking if API is sorted in .pm: "
eval $GET_API_FROM_PM | sort -C; SORT_EXIT=$?; if [ $SORT_EXIT == 0 ]; then echo "✓"; else echo "✗" && exit $SORT_EXIT; fi

diff -U 3 <( eval $GET_API_FROM_PM  ) <( eval $GET_API_FROM_POD | sort );
DIFF_EXIT=$?; echo -n "Checking API diff: "; if [ $DIFF_EXIT == 0 ]; then echo "✓"; else echo "✗" && exit $DIFF_EXIT; fi
