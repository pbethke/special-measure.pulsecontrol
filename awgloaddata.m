function awgloaddata
% awgloaddata
% load latest awgdata file saved by awgsavedata.

% (c) 2010 Hendrik Bluhm.  Please see LICENSE and COPYRIGHT information in plssetup.m.


global awgdata;
global plsdata;

d = dir(sprintf('%sawgdata_*', plsdata.grpdir));
[mi, mi] = max([d.datenum]);
load([plsdata.grpdir, d(mi).name]);

awg = awgdata.awg;
awgdata = data;
awgdata.awg = awg;
