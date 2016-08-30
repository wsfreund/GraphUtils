function [axesPosition,oldAxisLimits] = getAxesPosLimits(...
  curAxes,unitsType)
%
% Get axes position and its limits.
%
% [axesPosition,axesLimits] = getAxesPosLimits(curAxes,unitsType)
%

% - Creation Date: Thu, 05 Sep 2013
% - Last Modified: Sun, 10 Aug 2014
% - Author(s): 
%   - W.S.Freund <wsfreund_at_gmail_dot_com>

  if nargin < 2
    unitsType = 'normalized';
  end

  % Get current axes position:
  oldUnits=get(curAxes,'Units');
  set(curAxes,'Units',unitsType);
  axesPosition=get(curAxes,'Position');
  set(curAxes,'Units',oldUnits);
  oldAxisLimits = axis(curAxes);
end


