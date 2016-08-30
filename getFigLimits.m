function [figPosition] = getFigLimits(figH,unitsType)
%
% Get figure position and its limits.
%
% [figPosition] = getFigLimits(figH,unitsType)
%

% - Creation Date: Thu, 05 Sep 2013
% - Last Modified: Sun, 10 Aug 2014
% - Author(s): 
%   - W.S.Freund <wsfreund_at_gmail_dot_com>

  if nargin < 2
    unitsType = 'normalized';
  end
  % Get current axes position:
  oldUnits=get(figH,'Units');
  set(figH,'Units',unitsType);
  figPosition=get(figH,'Position');
  set(figH,'Units',oldUnits);
end
