#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use OSL::CamelloBailarin;
OSL::CamelloBailarin->to_app;
